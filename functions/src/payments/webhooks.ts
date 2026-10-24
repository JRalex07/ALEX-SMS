import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { safeTimingSafeEqual } from '../utils/crypto';

export const cashfreeWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const signature = req.headers['x-webhook-signature'] as string;
  const timestamp = req.headers['x-webhook-timestamp'] as string;
  const webhookSecret = process.env.CASHFREE_WEBHOOK_SECRET || 'test_webhook_secret';

  // Cashfree signature verification: signature = base64(hmac_sha256(timestamp + rawBody, secret))
  const rawBody = (req as any).rawBody || JSON.stringify(req.body);
  const dataToSign = timestamp + rawBody;
  const expectedSignature = crypto
    .createHmac('sha256', webhookSecret)
    .update(dataToSign)
    .digest('base64');

  if (!safeTimingSafeEqual(signature, expectedSignature)) {
    res.status(401).send('Invalid Webhook Signature');
    return;
  }

  const body = req.body;
  const orderId = body.data?.order?.order_id || body.orderId;
  const paymentId = body.data?.payment?.cf_payment_id?.toString() || body.referenceId || `CF_${Date.now()}`;
  const paymentStatus = body.data?.payment?.payment_status || body.txStatus;
  const amountRupees = parseFloat(body.data?.payment?.payment_amount || body.orderAmount || '0');
  const amountPaise = Math.round(amountRupees * 100);

  if (paymentStatus === 'SUCCESS') {
    await processPaymentSuccess({
      paymentId,
      gateway: 'cashfree',
      orderId,
      amountPaise,
      rawPayload: body,
    });
  }

  res.status(200).json({ status: 'OK' });
});

export const razorpayWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const signature = req.headers['x-razorpay-signature'] as string;
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || 'test_webhook_secret';
  const rawBody = (req as any).rawBody || JSON.stringify(req.body);

  const expectedSignature = crypto
    .createHmac('sha256', webhookSecret)
    .update(rawBody)
    .digest('hex');

  if (!safeTimingSafeEqual(signature, expectedSignature)) {
    res.status(401).send('Invalid Signature');
    return;
  }

  const event = req.body.event;
  if (event === 'payment.captured' || event === 'order.paid') {
    const payment = req.body.payload?.payment?.entity;
    const orderId = payment?.order_id || req.body.payload?.order?.entity?.id;
    const paymentId = payment?.id || `RZP_${Date.now()}`;
    const amountPaise = payment?.amount || 0; // Razorpay amounts are already in paise

    await processPaymentSuccess({
      paymentId,
      gateway: 'razorpay',
      orderId,
      amountPaise,
      rawPayload: req.body,
    });
  }

  res.status(200).json({ status: 'OK' });
});

export const phonepeWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const xVerify = req.headers['x-verify'] as string;
  const saltKey = process.env.PHONEPE_SALT_KEY || 'test_salt_key';
  const saltIndex = process.env.PHONEPE_SALT_INDEX || '1';

  // PhonePe signature: SHA256(base64Payload + "/v3/transaction/callback" + saltKey) + "###" + saltIndex
  const responseEncoded = req.body.response;
  if (responseEncoded) {
    const stringToHash = responseEncoded + '/v3/transaction/callback' + saltKey;
    const sha256 = crypto.createHash('sha256').update(stringToHash).digest('hex');
    const expectedXVerify = `${sha256}###${saltIndex}`;

    if (!safeTimingSafeEqual(xVerify, expectedXVerify)) {
      res.status(401).send('Invalid PhonePe Signature');
      return;
    }

    const decoded = JSON.parse(Buffer.from(responseEncoded, 'base64').toString('utf8'));
    if (decoded.code === 'PAYMENT_SUCCESS') {
      const data = decoded.data;
      const orderId = data.merchantTransactionId;
      const paymentId = data.transactionId || `PPE_${Date.now()}`;
      const amountPaise = data.amount; // PhonePe standard is paise

      await processPaymentSuccess({
        paymentId,
        gateway: 'phonepe',
        orderId,
        amountPaise,
        rawPayload: decoded,
      });
    }
  }

  res.status(200).json({ status: 'OK' });
});

interface PaymentSuccessPayload {
  paymentId: string;
  gateway: string;
  orderId: string;
  amountPaise: number;
  rawPayload: any;
}

async function processPaymentSuccess(payload: PaymentSuccessPayload): Promise<void> {
  const db = admin.firestore();
  const paymentRef = db.collection('payments').doc(payload.paymentId);

  await db.runTransaction(async (transaction) => {
    const existingPayment = await transaction.get(paymentRef);
    if (existingPayment.exists && existingPayment.data()?.status === 'successful') {
      // Idempotent: already processed
      return;
    }

    // Lookup order / invoice reference
    // The orderId typically maps to an invoice or invoiceId is extracted from metadata
    let invoiceId = payload.orderId;
    let invoiceRef = db.collection('student_invoices').doc(invoiceId);
    let invoiceDoc = await transaction.get(invoiceRef);

    if (!invoiceDoc.exists) {
      // Check if orderId is stored in a field
      const invoicesQuery = await db.collection('student_invoices')
        .where('paymentOrderId', '==', payload.orderId)
        .limit(1)
        .get();
      if (!invoicesQuery.empty) {
        invoiceRef = invoicesQuery.docs[0].ref;
        invoiceDoc = await transaction.get(invoiceRef);
        invoiceId = invoiceRef.id;
      }
    }

    if (!invoiceDoc.exists) {
      // Record payment without invoice link if invoice not found
      transaction.set(paymentRef, {
        paymentId: payload.paymentId,
        gateway: payload.gateway,
        orderId: payload.orderId,
        amountPaise: payload.amountPaise,
        status: 'successful',
        unallocated: true,
        capturedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const invoiceData = invoiceDoc.data()!;
    const outstandingBefore = invoiceData.outstandingBalancePaise || 0;
    const paidBefore = invoiceData.paidAmountPaise || 0;
    const studentId = invoiceData.studentId;
    const payerUserId = invoiceData.payerUserId || 'unknown_payer';

    const newPaidAmountPaise = paidBefore + payload.amountPaise;
    const newOutstandingBalancePaise = Math.max(0, outstandingBefore - payload.amountPaise);
    const newStatus = newOutstandingBalancePaise === 0 ? 'paid' : 'partially_paid';

    // 1. Record Payment
    transaction.set(paymentRef, {
      paymentId: payload.paymentId,
      gateway: payload.gateway,
      orderId: payload.orderId,
      invoiceId,
      studentId,
      payerUserId,
      amountPaise: payload.amountPaise,
      currency: 'INR',
      status: 'successful',
      capturedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Update Invoice Balance in Integer Paise
    transaction.update(invoiceRef, {
      paidAmountPaise: newPaidAmountPaise,
      outstandingBalancePaise: newOutstandingBalancePaise,
      status: newStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Create Payment Allocation Record
    const allocationRef = db.collection('payment_allocations').doc();
    transaction.set(allocationRef, {
      allocationId: allocationRef.id,
      paymentId: payload.paymentId,
      invoiceId,
      studentId,
      allocatedAmountPaise: payload.amountPaise,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Audit Log
    const auditRef = db.collection('audit_logs').doc();
    transaction.set(auditRef, {
      logId: auditRef.id,
      action: 'PAYMENT_CAPTURED',
      actorUid: `system:${payload.gateway}`,
      actorRole: 'system',
      targetCollection: 'payments',
      targetDocumentId: payload.paymentId,
      beforeState: { outstandingBalancePaise: outstandingBefore },
      afterState: {
        outstandingBalancePaise: newOutstandingBalancePaise,
        amountPaise: payload.amountPaise,
        invoiceId
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}
