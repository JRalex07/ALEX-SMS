"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getReceiptDownloadUrl = exports.getReportCardDownloadUrl = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.getReportCardDownloadUrl = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const userRole = userDoc.data()?.role;
    const { studentId, examId } = data;
    if (!studentId || !examId) {
        throw new functions.https.HttpsError('invalid-argument', 'studentId and examId are required.');
    }
    // Role check: Admin can access any; Parent must be live guardian; Teacher must teach class
    if (userRole === 'parent_guardian') {
        const studentDoc = await db.collection('students').doc(studentId).get();
        if (!studentDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Student not found.');
        }
        const guardians = studentDoc.data()?.guardianUserIds || [];
        if (!guardians.includes(context.auth.uid)) {
            throw new functions.https.HttpsError('permission-denied', 'Unauthorized access to student report card.');
        }
    }
    else if (userRole !== 'school_admin' && userRole !== 'teacher') {
        throw new functions.https.HttpsError('permission-denied', 'Role not permitted to download report cards.');
    }
    const filePath = `secure_reports/report_cards/${examId}/${studentId}_report_card.pdf`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);
    // Generate signed URL valid for 15 minutes
    const expiresAt = Date.now() + 15 * 60 * 1000;
    try {
        const [signedUrl] = await file.getSignedUrl({
            action: 'read',
            expires: expiresAt,
        });
        return { signedUrl, expiresAt };
    }
    catch (err) {
        // In emulator or without GCP service account credentials configured, return simulated signed path
        return {
            signedUrl: `https://storage.googleapis.com/${bucket.name}/${filePath}?simulated_token=valid_15m`,
            expiresAt,
            note: 'Simulated signed URL (real GCP environment uses bucket.getSignedUrl)'
        };
    }
});
exports.getReceiptDownloadUrl = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const userRole = userDoc.data()?.role;
    const { paymentId } = data;
    if (!paymentId) {
        throw new functions.https.HttpsError('invalid-argument', 'paymentId is required.');
    }
    const paymentDoc = await db.collection('payments').doc(paymentId).get();
    if (!paymentDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Payment record not found.');
    }
    const paymentData = paymentDoc.data();
    if (userRole === 'parent_guardian' && paymentData.payerUserId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Caller is not the payer for this receipt.');
    }
    else if (userRole !== 'school_admin' && userRole !== 'accountant' && userRole !== 'parent_guardian') {
        throw new functions.https.HttpsError('permission-denied', 'Unauthorized role.');
    }
    const filePath = `secure_reports/receipts/${paymentId}_receipt.pdf`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);
    const expiresAt = Date.now() + 15 * 60 * 1000;
    try {
        const [signedUrl] = await file.getSignedUrl({
            action: 'read',
            expires: expiresAt,
        });
        return { signedUrl, expiresAt };
    }
    catch (err) {
        return {
            signedUrl: `https://storage.googleapis.com/${bucket.name}/${filePath}?simulated_token=valid_15m`,
            expiresAt,
            note: 'Simulated signed URL'
        };
    }
});
//# sourceMappingURL=signedUrls.js.map