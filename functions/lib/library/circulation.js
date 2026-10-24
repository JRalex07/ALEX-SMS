"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.returnLibraryBook = exports.issueLibraryBook = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.issueLibraryBook = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'librarian') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and librarians can issue books.');
    }
    const { bookId, studentId, dueDate } = data;
    if (!bookId || !studentId || !dueDate) {
        throw new functions.https.HttpsError('invalid-argument', 'bookId, studentId, and dueDate are required.');
    }
    const bookRef = db.collection('library_books').doc(bookId);
    const loanRef = db.collection('library_loans').doc();
    const dueDateParsed = new Date(dueDate);
    return await db.runTransaction(async (transaction) => {
        const bookDoc = await transaction.get(bookRef);
        if (!bookDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Book not found.');
        }
        const bookData = bookDoc.data();
        const availableCopies = bookData.availableCopies;
        if (availableCopies <= 0) {
            throw new functions.https.HttpsError('failed-precondition', 'No available copies of this title remaining.');
        }
        transaction.set(loanRef, {
            loanId: loanRef.id,
            bookId,
            bookTitle: bookData.title,
            studentId,
            issuedBy: context.auth.uid,
            issuedAt: admin.firestore.FieldValue.serverTimestamp(),
            dueDate: admin.firestore.Timestamp.fromDate(dueDateParsed),
            status: 'active',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(bookRef, {
            availableCopies: availableCopies - 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, loanId: loanRef.id, remainingCopies: availableCopies - 1 };
    });
});
exports.returnLibraryBook = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data()?.status !== 'active') {
        throw new functions.https.HttpsError('permission-denied', 'Active user status required.');
    }
    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'school_admin' && callerRole !== 'librarian') {
        throw new functions.https.HttpsError('permission-denied', 'Only school administrators and librarians can record returns.');
    }
    const { loanId, bookId } = data;
    if (!loanId || !bookId) {
        throw new functions.https.HttpsError('invalid-argument', 'loanId and bookId are required.');
    }
    const loanRef = db.collection('library_loans').doc(loanId);
    const bookRef = db.collection('library_books').doc(bookId);
    return await db.runTransaction(async (transaction) => {
        const loanDoc = await transaction.get(loanRef);
        if (!loanDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Loan record not found.');
        }
        const loanData = loanDoc.data();
        if (loanData.status === 'returned') {
            throw new functions.https.HttpsError('failed-precondition', 'Book has already been returned.');
        }
        const bookDoc = await transaction.get(bookRef);
        if (!bookDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Book record not found.');
        }
        const bookData = bookDoc.data();
        const availableCopies = bookData.availableCopies;
        const totalCopies = bookData.totalCopies;
        const newAvailable = Math.min(totalCopies, availableCopies + 1);
        transaction.update(loanRef, {
            status: 'returned',
            returnedAt: admin.firestore.FieldValue.serverTimestamp(),
            returnedToUid: context.auth.uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(bookRef, {
            availableCopies: newAvailable,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, loanId, availableCopies: newAvailable };
    });
});
//# sourceMappingURL=circulation.js.map