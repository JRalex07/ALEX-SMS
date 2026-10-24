import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const approveAttendanceSession = functions.https.onCall(
  async (data: { sessionId: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active') {
      throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }

    const userRole = userDoc.data()?.role;
    if (userRole !== 'school_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only school administrators can approve attendance sessions.');
    }

    const { sessionId } = data;
    if (!sessionId) {
      throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');
    }

    const sessionRef = db.collection('attendance_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Attendance session not found.');
    }

    const sessionData = sessionDoc.data()!;
    if (sessionData.isApproved) {
      throw new functions.https.HttpsError('failed-precondition', 'Session is already approved.');
    }

    // Query all records for this session
    const recordsSnapshot = await sessionRef.collection('records').get();
    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;
    let excusedCount = 0;

    recordsSnapshot.forEach((recordDoc) => {
      const status = recordDoc.data()?.status;
      if (status === 'P') presentCount++;
      else if (status === 'A') absentCount++;
      else if (status === 'L') lateCount++;
      else if (status === 'E') excusedCount++;
    });

    const totalStudents = recordsSnapshot.size;
    const attendancePercentage = totalStudents > 0 
      ? Math.round(((presentCount + lateCount) / totalStudents) * 10000) / 100 
      : 0;

    const summary = {
      presentCount,
      absentCount,
      lateCount,
      excusedCount,
      totalStudents,
      attendancePercentage,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await sessionRef.update({
      isApproved: true,
      approvedBy: context.auth.uid,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      summary,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Write audit log
    await db.collection('audit_logs').add({
      logId: db.collection('audit_logs').doc().id,
      action: 'APPROVE_ATTENDANCE_SESSION',
      actorUid: context.auth.uid,
      actorRole: userRole,
      targetCollection: 'attendance_sessions',
      targetDocumentId: sessionId,
      beforeState: { isApproved: false },
      afterState: { isApproved: true, summary },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, sessionId, summary };
  }
);

export const finalizeAttendanceSession = functions.https.onCall(
  async (data: { sessionId: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active') {
      throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }

    const userRole = userDoc.data()?.role;
    if (userRole !== 'school_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only school administrators can finalize attendance sessions.');
    }

    const { sessionId } = data;
    if (!sessionId) {
      throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');
    }

    const sessionRef = db.collection('attendance_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Attendance session not found.');
    }

    const sessionData = sessionDoc.data()!;
    if (!sessionData.isApproved) {
      throw new functions.https.HttpsError('failed-precondition', 'Session must be approved before finalization.');
    }
    if (sessionData.isFinalized) {
      throw new functions.https.HttpsError('failed-precondition', 'Session is already finalized.');
    }

    await sessionRef.update({
      isFinalized: true,
      finalizedBy: context.auth.uid,
      finalizedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Write audit log
    await db.collection('audit_logs').add({
      logId: db.collection('audit_logs').doc().id,
      action: 'FINALIZE_ATTENDANCE_SESSION',
      actorUid: context.auth.uid,
      actorRole: userRole,
      targetCollection: 'attendance_sessions',
      targetDocumentId: sessionId,
      beforeState: { isFinalized: false },
      afterState: { isFinalized: true },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, sessionId };
  }
);
