import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const publishNotice = functions.https.onCall(
  async (data: { noticeId: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'school_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only school administrators can publish notices.');
    }

    const { noticeId } = data;
    if (!noticeId) {
      throw new functions.https.HttpsError('invalid-argument', 'noticeId is required.');
    }

    const noticeRef = db.collection('notices').doc(noticeId);
    const noticeDoc = await noticeRef.get();
    if (!noticeDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Notice not found.');
    }

    await noticeRef.update({
      isPublished: true,
      publishedAt: admin.firestore.FieldValue.serverTimestamp(),
      publishedBy: context.auth.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, noticeId };
  }
);

export const unpublishNotice = functions.https.onCall(
  async (data: { noticeId: string }, context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.status !== 'active' || userDoc.data()?.role !== 'school_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only school administrators can unpublish notices.');
    }

    const { noticeId } = data;
    if (!noticeId) {
      throw new functions.https.HttpsError('invalid-argument', 'noticeId is required.');
    }

    const noticeRef = db.collection('notices').doc(noticeId);
    const noticeDoc = await noticeRef.get();
    if (!noticeDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Notice not found.');
    }

    await noticeRef.update({
      isPublished: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, noticeId };
  }
);
