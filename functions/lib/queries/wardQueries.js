"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getWardAttendanceHistory = exports.getWardMarks = exports.getWardInvoices = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.getWardInvoices = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'parent_guardian') {
        throw new functions.https.HttpsError('permission-denied', 'Active parent account required.');
    }
    const { studentId } = data;
    if (!studentId) {
        throw new functions.https.HttpsError('invalid-argument', 'studentId is required.');
    }
    // Authoritative Live Relationship Verification (Zero-Delay ReBAC)
    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Student record not found.');
    }
    const studentData = studentDoc.data();
    const guardianUserIds = studentData.guardianUserIds || [];
    if (!guardianUserIds.includes(context.auth.uid)) {
        throw new functions.https.HttpsError('permission-denied', 'Caller is not an authorized guardian of this student.');
    }
    // Scoped server-side query
    const invoicesSnapshot = await db.collection('student_invoices')
        .where('studentId', '==', studentId)
        .where('isArchived', '==', false)
        .orderBy('dueDate', 'desc')
        .get();
    return {
        invoices: invoicesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
    };
});
exports.getWardMarks = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'parent_guardian') {
        throw new functions.https.HttpsError('permission-denied', 'Active parent account required.');
    }
    const { studentId, examId } = data;
    if (!studentId) {
        throw new functions.https.HttpsError('invalid-argument', 'studentId is required.');
    }
    // Live ReBAC verification
    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Student record not found.');
    }
    const guardianUserIds = studentDoc.data()?.guardianUserIds || [];
    if (!guardianUserIds.includes(context.auth.uid)) {
        throw new functions.https.HttpsError('permission-denied', 'Caller is not an authorized guardian of this student.');
    }
    let query = db.collection('marks')
        .where('studentId', '==', studentId)
        .where('isPublished', '==', true);
    if (examId) {
        query = query.where('examId', '==', examId);
    }
    const marksSnapshot = await query.get();
    return {
        marks: marksSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
    };
});
exports.getWardAttendanceHistory = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'parent_guardian') {
        throw new functions.https.HttpsError('permission-denied', 'Active parent account required.');
    }
    const { studentId } = data;
    if (!studentId) {
        throw new functions.https.HttpsError('invalid-argument', 'studentId is required.');
    }
    // Live ReBAC verification
    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Student record not found.');
    }
    const guardianUserIds = studentDoc.data()?.guardianUserIds || [];
    if (!guardianUserIds.includes(context.auth.uid)) {
        throw new functions.https.HttpsError('permission-denied', 'Caller is not an authorized guardian of this student.');
    }
    // Query collectionGroup for records where studentId == data.studentId
    const recordsSnapshot = await db.collectionGroup('records')
        .where('studentId', '==', studentId)
        .get();
    const attendanceRecords = recordsSnapshot.docs.map(doc => ({
        sessionId: doc.data()?.sessionId,
        studentId: doc.data()?.studentId,
        status: doc.data()?.status,
        remarks: doc.data()?.remarks,
    }));
    return { records: attendanceRecords };
});
//# sourceMappingURL=wardQueries.js.map