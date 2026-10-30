import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export all Cloud Functions
export { approveAttendanceSession, finalizeAttendanceSession } from './attendance/attendance';
export { adminCorrectMark, publishExamResults } from './examinations/marks';
export { publishNotice, unpublishNotice } from './notices/notices';
export { linkGuardian, unlinkGuardian } from './guardians/guardians';
export { getWardInvoices, getWardMarks, getWardAttendanceHistory } from './queries/wardQueries';
export { getReportCardDownloadUrl, getReceiptDownloadUrl } from './reports/signedUrls';
export { cashfreeWebhook, razorpayWebhook, phonepeWebhook } from './payments/webhooks';
export { recordOfflinePayment, createFeeInvoice, createFeeStructure, processRefund } from './payments/offline';
export { updateStaffStatus, updateStaffRole, assignTeacherScope, initiateAdminEmailChange } from './admin/staff';
export { transferStudentCohort } from './admin/students';
export { issueLibraryBook, returnLibraryBook } from './library/circulation';
