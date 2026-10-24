import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const transferStudentCohort = functions.https.onCall(
  async (data: { studentId: string; targetClassId: string; targetSectionId: string; transferReason: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
      throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }

    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'admissions_officer') {
      throw new functions.https.HttpsError('permission-denied', 'Only school administrators and admissions officers can transfer students.');
    }

    const { studentId, targetClassId, targetSectionId, transferReason } = data;
    if (!studentId || !targetClassId || !targetSectionId || !transferReason || transferReason.trim().length < 3) {
      throw new functions.https.HttpsError('invalid-argument', 'studentId, targetClassId, targetSectionId, and valid transferReason are required.');
    }

    const studentRef = db.collection('students').doc(studentId);
    const auditRef = db.collection('audit_logs').doc();

    const result = await db.runTransaction(async (transaction) => {
      const studentDoc = await transaction.get(studentRef);
      if (!studentDoc.exists) {
        throw new functions.https.HttpsError('not-found', `Student ${studentId} not found.`);
      }

      const currentData = studentDoc.data()!;
      const previousClassId = currentData.currentClassId;
      const previousSectionId = currentData.currentSectionId;

      transaction.update(studentRef, {
        currentClassId: targetClassId,
        currentSectionId: targetSectionId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      transaction.set(auditRef, {
        logId: auditRef.id,
        action: 'TRANSFER_STUDENT_COHORT',
        actorUid: context.auth!.uid,
        actorRole: callerRole,
        targetCollection: 'students',
        targetDocumentId: studentId,
        beforeState: { classId: previousClassId, sectionId: previousSectionId },
        afterState: { classId: targetClassId, sectionId: targetSectionId, reason: transferReason },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        guardians: currentData.guardianUserIds || [],
        previousClassId,
        previousSectionId,
      };
    });

    // Refresh guardian claims for all linked guardians asynchronously
    for (const guardianUid of result.guardians) {
      try {
        const studentsSnapshot = await db.collection('students')
          .where('guardianUserIds', 'array-contains', guardianUid)
          .where('status', '==', 'enrolled')
          .get();

        const wardClassesSet = new Set<string>();
        const wardSectionsSet = new Set<string>();
        const wardStudentIds: string[] = [];

        studentsSnapshot.forEach((doc) => {
          const sData = doc.data();
          wardStudentIds.push(doc.id);
          if (sData.currentClassId) wardClassesSet.add(sData.currentClassId);
          if (sData.currentSectionId) wardSectionsSet.add(sData.currentSectionId);
        });

        await admin.auth().setCustomUserClaims(guardianUid, {
          role: 'parent_guardian',
          isActive: true,
          wardStudentIds,
          wardClasses: Array.from(wardClassesSet),
          wardSections: Array.from(wardSectionsSet),
        });

        await db.collection('users').doc(guardianUid).update({
          tokenVersion: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    return {
      success: true,
      studentId,
      targetClassId,
      targetSectionId,
    };
  }
);
