import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface LinkGuardianRequest {
  studentId: string;
  guardianUid: string;
  relationship: string; // e.g. "Father", "Mother", "Guardian"
}

export const linkGuardian = functions.https.onCall(
  async (data: LinkGuardianRequest, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
      throw new functions.https.HttpsError('permission-denied', 'Active caller required.');
    }

    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'admissions_officer') {
      throw new functions.https.HttpsError('permission-denied', 'Only admin or admissions can link guardians.');
    }

    const { studentId, guardianUid } = data;
    if (!studentId || !guardianUid) {
      throw new functions.https.HttpsError('invalid-argument', 'studentId and guardianUid are required.');
    }

    // Verify student exists
    const studentRef = db.collection('students').doc(studentId);
    const studentDoc = await studentRef.get();
    if (!studentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Student not found.');
    }

    // Verify guardian user exists
    const guardianRef = db.collection('users').doc(guardianUid);
    const guardianDoc = await guardianRef.get();
    if (!guardianDoc.exists || guardianDoc.data()?.role !== 'parent_guardian') {
      throw new functions.https.HttpsError('not-found', 'Valid parent_guardian user account not found.');
    }

    // Update student guardianUserIds
    await studentRef.update({
      guardianUserIds: admin.firestore.FieldValue.arrayUnion(guardianUid),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Recompute claims for guardian
    await refreshGuardianClaims(guardianUid);

    return { success: true, studentId, guardianUid };
  }
);

export const unlinkGuardian = functions.https.onCall(
  async (data: { studentId: string; guardianUid: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
      throw new functions.https.HttpsError('permission-denied', 'Active caller required.');
    }

    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'admissions_officer') {
      throw new functions.https.HttpsError('permission-denied', 'Only admin or admissions can unlink guardians.');
    }

    const { studentId, guardianUid } = data;
    if (!studentId || !guardianUid) {
      throw new functions.https.HttpsError('invalid-argument', 'studentId and guardianUid are required.');
    }

    const studentRef = db.collection('students').doc(studentId);
    const studentDoc = await studentRef.get();
    if (!studentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Student not found.');
    }

    await studentRef.update({
      guardianUserIds: admin.firestore.FieldValue.arrayRemove(guardianUid),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Recompute claims and increment tokenVersion for instant revocation
    await refreshGuardianClaims(guardianUid);

    return { success: true, studentId, guardianUid };
  }
);

async function refreshGuardianClaims(guardianUid: string): Promise<void> {
  const db = admin.firestore();
  
  // Find all active students where guardianUserIds contains guardianUid
  const studentsSnapshot = await db.collection('students')
    .where('guardianUserIds', 'array-contains', guardianUid)
    .where('status', '==', 'enrolled')
    .get();

  const wardStudentIds: string[] = [];
  const wardClassesSet = new Set<string>();
  const wardSectionsSet = new Set<string>();

  studentsSnapshot.forEach((doc) => {
    const data = doc.data();
    wardStudentIds.push(doc.id);
    if (data.currentClassId) wardClassesSet.add(data.currentClassId);
    if (data.currentSectionId) wardSectionsSet.add(data.currentSectionId);
  });

  const wardClasses = Array.from(wardClassesSet);
  const wardSections = Array.from(wardSectionsSet);

  // Set Firebase Auth custom claims
  await admin.auth().setCustomUserClaims(guardianUid, {
    role: 'parent_guardian',
    isActive: true,
    wardStudentIds,
    wardClasses,
    wardSections,
  });

  // Increment tokenVersion in user document to invalidate stale client tokens
  await db.collection('users').doc(guardianUid).update({
    tokenVersion: admin.firestore.FieldValue.increment(1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
