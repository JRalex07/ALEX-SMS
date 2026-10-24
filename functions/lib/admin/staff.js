"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.assignTeacherScope = exports.updateStaffRole = exports.updateStaffStatus = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.updateStaffStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators can update staff status.');
    }
    const { uid, status } = data;
    if (!uid || (status !== 'active' && status !== 'suspended')) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid uid and status ("active" | "suspended") required.');
    }
    if (uid === context.auth.uid && status === 'suspended') {
        throw new functions.https.HttpsError('failed-precondition', 'Administrators cannot suspend their own account.');
    }
    const targetUserRef = db.collection('users').doc(uid);
    const targetDoc = await targetUserRef.get();
    if (!targetDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Target staff account not found.');
    }
    const targetData = targetDoc.data();
    const isActiveBool = status === 'active';
    // Atomically update user document, increment tokenVersion for instant invalidation
    await targetUserRef.update({
        status,
        isActive: isActiveBool,
        tokenVersion: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Update Firebase Auth custom claims
    try {
        const existingClaims = (await admin.auth().getUser(uid)).customClaims || {};
        await admin.auth().setCustomUserClaims(uid, {
            ...existingClaims,
            isActive: isActiveBool,
        });
    }
    catch (authError) {
        // In local testing/emulator without auth user record, proceed safely
    }
    // Write audit log
    await db.collection('audit_logs').add({
        logId: db.collection('audit_logs').doc().id,
        action: 'UPDATE_STAFF_STATUS',
        actorUid: context.auth.uid,
        actorRole: callerRole,
        targetCollection: 'users',
        targetDocumentId: uid,
        beforeState: { status: targetData.status, isActive: targetData.isActive },
        afterState: { status, isActive: isActiveBool },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, uid, status };
});
exports.updateStaffRole = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active' || callerDoc.data()?.role !== 'school_admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators can assign roles.');
    }
    const { uid, newRole } = data;
    const permittedRoles = ['school_admin', 'teacher', 'accountant', 'admissions_officer', 'librarian', 'parent_guardian'];
    if (!uid || !permittedRoles.includes(newRole)) {
        throw new functions.https.HttpsError('invalid-argument', `Invalid role. Must be one of: ${permittedRoles.join(', ')}`);
    }
    if (uid === context.auth.uid && newRole !== 'school_admin') {
        throw new functions.https.HttpsError('failed-precondition', 'Administrators cannot demote their own account.');
    }
    const targetUserRef = db.collection('users').doc(uid);
    const targetDoc = await targetUserRef.get();
    if (!targetDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Staff user not found.');
    }
    const oldRole = targetDoc.data()?.role;
    await targetUserRef.update({
        role: newRole,
        tokenVersion: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    try {
        const existingClaims = (await admin.auth().getUser(uid)).customClaims || {};
        await admin.auth().setCustomUserClaims(uid, {
            ...existingClaims,
            role: newRole,
        });
    }
    catch (_) { }
    await db.collection('audit_logs').add({
        logId: db.collection('audit_logs').doc().id,
        action: 'UPDATE_STAFF_ROLE',
        actorUid: context.auth.uid,
        actorRole: 'school_admin',
        targetCollection: 'users',
        targetDocumentId: uid,
        beforeState: { role: oldRole },
        afterState: { role: newRole },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, uid, newRole };
});
exports.assignTeacherScope = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active' || callerDoc.data()?.role !== 'school_admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators can assign teacher scope.');
    }
    const { uid, classes, sections } = data;
    if (!uid || !Array.isArray(classes) || !Array.isArray(sections)) {
        throw new functions.https.HttpsError('invalid-argument', 'uid, classes array, and sections array required.');
    }
    const targetUserRef = db.collection('users').doc(uid);
    const targetDoc = await targetUserRef.get();
    if (!targetDoc.exists || targetDoc.data()?.role !== 'teacher') {
        throw new functions.https.HttpsError('not-found', 'Target user must exist and have role "teacher".');
    }
    await targetUserRef.update({
        assignedClasses: classes,
        assignedSections: sections,
        tokenVersion: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    try {
        const existingClaims = (await admin.auth().getUser(uid)).customClaims || {};
        await admin.auth().setCustomUserClaims(uid, {
            ...existingClaims,
            assignedClasses: classes,
            assignedSections: sections,
        });
    }
    catch (_) { }
    await db.collection('audit_logs').add({
        logId: db.collection('audit_logs').doc().id,
        action: 'ASSIGN_TEACHER_SCOPE',
        actorUid: context.auth.uid,
        actorRole: 'school_admin',
        targetCollection: 'users',
        targetDocumentId: uid,
        afterState: { assignedClasses: classes, assignedSections: sections },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, uid, assignedClasses: classes, assignedSections: sections };
});
//# sourceMappingURL=staff.js.map