"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.publishExamResults = exports.adminCorrectMark = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.adminCorrectMark = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'school_admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators can correct marks.');
    }
    const { markId, correctionReason } = data;
    if (!markId || !correctionReason || correctionReason.trim().length < 5) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid markId and correctionReason (>= 5 chars) required.');
    }
    const markRef = db.collection('marks').doc(markId);
    const markDoc = await markRef.get();
    if (!markDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Mark record not found.');
    }
    const existingData = markDoc.data();
    const examDoc = await db.collection('examinations').doc(existingData.examId).get();
    if (!examDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Associated examination not found.');
    }
    const examData = examDoc.data();
    const struct = examData.assessmentStructure || { ca1Max: 20, ca2Max: 20, examMax: 60 };
    const ca1 = data.newCa1 !== undefined ? data.newCa1 : (existingData.continuousAssessment?.ca1 ?? 0);
    const ca2 = data.newCa2 !== undefined ? data.newCa2 : (existingData.continuousAssessment?.ca2 ?? 0);
    const examScore = data.newExamScore !== undefined ? data.newExamScore : (existingData.examScore ?? 0);
    if (ca1 < 0 || ca1 > struct.ca1Max) {
        throw new functions.https.HttpsError('invalid-argument', `ca1 must be between 0 and ${struct.ca1Max}`);
    }
    if (ca2 < 0 || ca2 > struct.ca2Max) {
        throw new functions.https.HttpsError('invalid-argument', `ca2 must be between 0 and ${struct.ca2Max}`);
    }
    if (examScore < 0 || examScore > struct.examMax) {
        throw new functions.https.HttpsError('invalid-argument', `examScore must be between 0 and ${struct.examMax}`);
    }
    const totalScore = ca1 + ca2 + examScore;
    // Run transaction: write revision and update mark
    await db.runTransaction(async (transaction) => {
        const revisionRef = markRef.collection('revisions').doc();
        transaction.set(revisionRef, {
            revisionId: revisionRef.id,
            markId,
            previousState: {
                continuousAssessment: existingData.continuousAssessment,
                examScore: existingData.examScore,
                totalScore: existingData.totalScore,
            },
            newState: {
                continuousAssessment: { ca1, ca2 },
                examScore,
                totalScore,
            },
            correctionReason,
            correctedBy: context.auth.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(markRef, {
            'continuousAssessment.ca1': ca1,
            'continuousAssessment.ca2': ca2,
            examScore,
            totalScore,
            updatedBy: context.auth.uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const auditRef = db.collection('audit_logs').doc();
        transaction.set(auditRef, {
            logId: auditRef.id,
            action: 'ADMIN_CORRECT_MARK',
            actorUid: context.auth.uid,
            actorRole: 'school_admin',
            targetCollection: 'marks',
            targetDocumentId: markId,
            beforeState: { totalScore: existingData.totalScore },
            afterState: { totalScore, correctionReason },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    return { success: true, markId, newTotalScore: totalScore };
});
exports.publishExamResults = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'school_admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators can publish examination results.');
    }
    const { examId, classId } = data;
    if (!examId) {
        throw new functions.https.HttpsError('invalid-argument', 'examId is required.');
    }
    let query = db.collection('marks').where('examId', '==', examId);
    if (classId) {
        query = query.where('classId', '==', classId);
    }
    const marksSnapshot = await query.get();
    if (marksSnapshot.empty) {
        return { success: true, count: 0, message: 'No marks to publish.' };
    }
    const batch = db.batch();
    let count = 0;
    marksSnapshot.forEach((doc) => {
        batch.update(doc.ref, {
            isApproved: true,
            isPublished: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        count++;
    });
    // Also update exam isPublished
    batch.update(db.collection('examinations').doc(examId), {
        isPublished: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return { success: true, publishedCount: count };
});
//# sourceMappingURL=marks.js.map