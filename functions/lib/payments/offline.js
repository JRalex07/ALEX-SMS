"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processRefund = exports.createFeeStructure = exports.createFeeInvoice = exports.recordOfflinePayment = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.recordOfflinePayment = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'accountant') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and accountants can record offline payments.');
    }
    const { invoiceId, studentId, amountPaise, paymentMethod = 'cash', notes = '' } = data;
    if (!invoiceId || !studentId) {
        throw new functions.https.HttpsError('invalid-argument', 'invoiceId and studentId are required.');
    }
    if (!Number.isInteger(amountPaise) || amountPaise <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'amountPaise must be a positive integer.');
    }
    const invoiceRef = db.collection('student_invoices').doc(invoiceId);
    const paymentRef = db.collection('payments').doc();
    const allocationRef = db.collection('payment_allocations').doc();
    const auditRef = db.collection('audit_logs').doc();
    return await db.runTransaction(async (transaction) => {
        const invoiceDoc = await transaction.get(invoiceRef);
        if (!invoiceDoc.exists) {
            throw new functions.https.HttpsError('not-found', `Invoice ${invoiceId} does not exist.`);
        }
        const invoiceData = invoiceDoc.data();
        const totalAmountPaise = invoiceData.totalAmountPaise;
        const currentPaid = invoiceData.paidAmountPaise || 0;
        const currentOutstanding = invoiceData.outstandingBalancePaise ?? totalAmountPaise;
        if (currentOutstanding <= 0) {
            throw new functions.https.HttpsError('failed-precondition', 'Invoice is already fully paid.');
        }
        if (amountPaise > currentOutstanding) {
            throw new functions.https.HttpsError('invalid-argument', `Payment amount (${amountPaise} paise) exceeds outstanding balance (${currentOutstanding} paise).`);
        }
        const newPaid = currentPaid + amountPaise;
        const newOutstanding = Math.max(0, currentOutstanding - amountPaise);
        const newStatus = newOutstanding === 0 ? 'paid' : 'partially_paid';
        // Record trusted payment document
        transaction.set(paymentRef, {
            paymentId: paymentRef.id,
            invoiceId,
            studentId,
            payerUserId: data.payerUserId || studentId,
            amountPaise,
            gateway: 'offline',
            paymentMethod,
            status: 'successful',
            notes: notes || 'Offline collection verified by bursar',
            capturedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Record immutable payment allocation
        transaction.set(allocationRef, {
            allocationId: allocationRef.id,
            paymentId: paymentRef.id,
            invoiceId,
            studentId,
            amountPaise,
            allocatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Update invoice balances and status
        transaction.update(invoiceRef, {
            paidAmountPaise: newPaid,
            outstandingBalancePaise: newOutstanding,
            status: newStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Record authoritative audit log
        transaction.set(auditRef, {
            logId: auditRef.id,
            action: 'RECORD_OFFLINE_PAYMENT',
            actorUid: context.auth.uid,
            actorRole: callerRole,
            targetCollection: 'student_invoices',
            targetDocumentId: invoiceId,
            amountPaise,
            beforeState: { paidAmountPaise: currentPaid, outstandingBalancePaise: currentOutstanding, status: invoiceData.status },
            afterState: { paidAmountPaise: newPaid, outstandingBalancePaise: newOutstanding, status: newStatus },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            paymentId: paymentRef.id,
            newStatus,
            newPaid,
            newOutstanding,
        };
    });
});
exports.createFeeInvoice = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'accountant') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and accountants can create invoices.');
    }
    const { studentId, academicYearId, title, totalAmountPaise, dueDate } = data;
    if (!studentId || !academicYearId || !title || !totalAmountPaise || !dueDate) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required invoice parameters.');
    }
    if (!Number.isInteger(totalAmountPaise) || totalAmountPaise <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'totalAmountPaise must be a positive integer.');
    }
    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
        throw new functions.https.HttpsError('not-found', `Student ${studentId} does not exist.`);
    }
    const invoiceRef = db.collection('student_invoices').doc();
    const dueDateParsed = new Date(dueDate);
    await invoiceRef.set({
        invoiceId: invoiceRef.id,
        studentId,
        academicYearId,
        title,
        totalAmountPaise,
        paidAmountPaise: 0,
        outstandingBalancePaise: totalAmountPaise,
        dueDate: admin.firestore.Timestamp.fromDate(dueDateParsed),
        status: 'unpaid',
        isArchived: false,
        createdBy: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, invoiceId: invoiceRef.id };
});
exports.createFeeStructure = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'accountant') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and accountants can create fee structures.');
    }
    const { title, amountPaise, frequency, classId, academicYearId } = data;
    if (!title || !frequency || !academicYearId || amountPaise === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fee structure fields.');
    }
    if (!Number.isInteger(amountPaise) || amountPaise < 0) {
        throw new functions.https.HttpsError('invalid-argument', 'amountPaise must be a non-negative integer.');
    }
    const structureRef = db.collection('fee_structures').doc();
    await structureRef.set({
        structureId: structureRef.id,
        title,
        amountPaise,
        frequency,
        classId: classId || null,
        academicYearId,
        schoolId: 'SCH_001',
        createdBy: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, structureId: structureRef.id };
});
exports.processRefund = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'accountant') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and accountants can process refunds.');
    }
    const { paymentId, invoiceId, amountPaise, reason } = data;
    if (!paymentId || !invoiceId || !amountPaise || !reason) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required refund fields.');
    }
    const paymentRef = db.collection('payments').doc(paymentId);
    const invoiceRef = db.collection('student_invoices').doc(invoiceId);
    const refundRef = db.collection('refunds').doc();
    return await db.runTransaction(async (transaction) => {
        const paymentDoc = await transaction.get(paymentRef);
        if (!paymentDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Payment not found.');
        }
        const invoiceDoc = await transaction.get(invoiceRef);
        if (!invoiceDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Invoice not found.');
        }
        const invoiceData = invoiceDoc.data();
        const currentPaid = invoiceData.paidAmountPaise || 0;
        const currentOutstanding = invoiceData.outstandingBalancePaise || 0;
        if (amountPaise > currentPaid) {
            throw new functions.https.HttpsError('invalid-argument', 'Refund amount cannot exceed amount paid.');
        }
        const newPaid = currentPaid - amountPaise;
        const newOutstanding = currentOutstanding + amountPaise;
        const newStatus = newPaid === 0 ? 'unpaid' : 'partially_paid';
        transaction.set(refundRef, {
            refundId: refundRef.id,
            paymentId,
            invoiceId,
            studentId: invoiceData.studentId,
            amountPaise,
            reason,
            status: 'completed',
            refundedBy: context.auth.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(invoiceRef, {
            paidAmountPaise: newPaid,
            outstandingBalancePaise: newOutstanding,
            status: newStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, refundId: refundRef.id, newOutstanding };
    });
});
//# sourceMappingURL=offline.js.map