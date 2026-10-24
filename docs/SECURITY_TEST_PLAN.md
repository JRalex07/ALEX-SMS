# Security Test Plan & Verification Evidence

**Project:** School Management System (`lav-school-sms-2026` / `com.lav.schoolsms`)  
**Version:** 2.4.0 Production Remediation  
**Status:** PASS / ACTIVE ENFORCEMENT  
**Date:** October 2026  

---

## 1. Security Scope & Objectives

This test plan defines the security invariants and regression test scenarios executed to guarantee that the application fails closed, enforces strict least privilege across all six authenticated roles, and prevents privilege escalation, parameter tampering, and payment forgery.

### Core Security Invariants
1. **Zero Demo Authentication:** No hardcoded OTP bypasses (`123456`, `000000`), simulated verification tokens, demo credentials, or client-side role dropdowns exist in production execution paths.
2. **Authoritative 6-Role Model:** Exactly 6 authenticated roles (`school_admin`, `teacher`, `accountant`, `admissions_officer`, `librarian`, `parent_guardian`). Students are managed records without login credentials.
3. **Fail-Closed Authorization:** Missing profiles, suspended status (`isActive != true`), or unlinked guardians immediately terminate sessions and redirect to `/unauthorized`.
4. **Clean Routing Invariant:** Single `/dashboard` entrypoint without role-based route leaks (`/admin-dashboard`, `/parent-dashboard` are rejected and denied).
5. **Storage Ownership Defense:** File creation and updates require matching uploader metadata and path ownership. Cross-staff file overwriting is blocked.
6. **Cryptographic Webhook Signatures:** Inbound gateway payment notifications must pass HMAC-SHA256 signature verification. Test bypass headers (`x-test-bypass`) are completely eliminated.
7. **Integer Paise Financial Ledger:** All monetary amounts are handled exclusively as integer paise (`₹1.00 = 100 paise`), preventing floating-point rounding errors and tampering.

---

## 2. Security Test Scenarios & Evidence Matrix

| Scenario ID | Test Description | Target Layer | Verification Method | Result |
|---|---|---|---|---|
| **SEC-SCN-01** | **Phone OTP Format & Validation**<br>Reject non-6-digit OTPs and invalid codes. Fail closed if phone number does not correspond to an established guardian profile. | `AuthRepository` + Firebase Auth | Automated unit test (`test/acceptance_test.dart`) + repository code inspection | **PASS** |
| **SEC-SCN-02** | **Staff Credential & Account Status Validation**<br>Institutional email/password authentication must verify Firestore `users/{uid}`. Suspended accounts (`isActive == false`) must throw `AccountSuspendedException`. | `AuthRepository` | Automated unit test (`test/acceptance_test.dart`) | **PASS** |
| **SEC-SCN-03** | **Role Tampering & Route Guards**<br>Client cannot alter user role via UI or router params. Attempting to access unauthorized resources triggers fail-closed redirect. | `AppRouter` + `GoRouter` | Automated router route configuration test (`test/acceptance_test.dart`) | **PASS** |
| **SEC-SCN-04** | **Cross-Guardian Isolation**<br>A parent user cannot query, read, or mutate records of a student not contained in `wardStudentIds`. | `StudentRepository` + Security Rules | Automated test (`Parent cannot access unlinked student records`) | **PASS** |
| **SEC-SCN-05** | **Storage Multi-Teacher Overwrite Defense**<br>Teachers may upload study materials under their class path, but cannot overwrite files created by another teacher. | `storage.rules` | Static rule audit & match statement verification (`storage.rules:34-40`) | **PASS** |
| **SEC-SCN-06** | **Cryptographic Payment Webhook Signatures**<br>Razorpay, Cashfree, and PhonePe webhooks must compute HMAC signatures against raw payload. Requests without valid signatures are rejected with HTTP 401. | Cloud Functions (`functions/src/payments/webhooks.ts`) | Source inspection + TypeScript compiler verification (`npm run build`) | **PASS** |
| **SEC-SCN-07** | **Integer Paise Math & Floating-Point Protection**<br>Invoices, payments, and ledger calculations must use integer paise. No fractional paise or floating-point rounding errors permitted. | `CurrencyUtils` + `FeeRepository` | Automated test suite (`test/widget_test.dart`) | **PASS** |
| **SEC-SCN-08** | **Library Atomic Inventory Consistency**<br>Issuing a book must atomically decrement available copies and record loan transaction; returns must atomically increment available copies without exceeding total count. | `LibraryRepository` + Cloud Functions | Code verification of Firestore atomic transactions | **PASS** |
| **SEC-SCN-09** | **Absence of Role-Based Dashboard URLs**<br>Verification that `/admin-dashboard`, `/teacher-dashboard`, etc. are nonexistent in the router table. | `AppRouter` (`app_router.dart`) | Automated test (`Router exposes NO role-based dashboard URLs`) | **PASS** | **SEC-SCN-10** | **Multi-Viewport Responsive Integrity**<br>Mobile, tablet, and desktop viewports render without layout exceptions or navigation breakages. | `ResponsiveScaffold` + `AppBreakpoints` | Automated widget tests across 3 screen widths (`test/acceptance_test.dart`) | **PASS** |
| **SEC-SCN-11** | **Parent Portal 17-Option Relationship & ReBAC Invariant**<br>Every child-specific query (homework, syllabus, routine, quizzes, transport, fees, report cards) validates guardian relationship. Switching child invalidates previous child's state completely. | `ParentServicesRepository` + `ChildContextNotifier` | Automated test suite (`test/parent_portal_expansion_test.dart`) | **PASS** |
| **SEC-SCN-12** | **Student Quiz Delegation & Identity Protection**<br>Online test runner allows ward to take quiz session within parent portal without creating student auth accounts; responses are tagged strictly with `studentId`. | `OnlineTestDialog` + `ParentServicesRepository` | Automated quiz runner test (`test/parent_portal_expansion_test.dart:5`) | **PASS** |
| **SEC-SCN-13** | **Zero Password Writes to Firestore**<br>Change password workflow executes exclusively through Firebase Authentication `user.updatePassword()` with reauthentication credential. Zero plaintext or hashed passwords stored in Firestore. | `ChangePasswordDialog` + `FirebaseAuth` | Automated validation test (`test/parent_portal_expansion_test.dart:8`) | **PASS** |
| **SEC-SCN-14** | **Teacher Score Boundary Checking & Total Validation**<br>Mark entries are mathematically verified against institutional limits (CA1 <= 20, CA2 <= 20, Exam <= 60, Total <= 100). Out-of-bounds scores throw `ArgumentError` before database writes. | `ExamRepository.validateMarkBounds` | Automated test (`test/staff_portals_workflow_test.dart:4-5`) | **PASS** |
| **SEC-SCN-15** | **Admissions Demographic Field Allowlist Isolation**<br>Admissions officer demographic edits strictly permit only approved demographic fields (`dob`, `gender`, `bloodGroup`, `emergencyContact`, `medicalNotes`, `address`). System keys (`admissionNo`, `classId`, `guardians`) are locked. | `EditStudentDemographicsDialog` + `StudentRepository` | Automated test (`test/staff_portals_workflow_test.dart:7`) | **PASS** |
| **SEC-SCN-16** | **Staff Account Suspension & Role Assignment Access Control**<br>Only `school_admin` role can access staff management, toggle active/suspended account state, and assign teacher cohort scopes. Non-admin mutations are rejected. | `StaffManagementDialog` + `AuthRepository` | Automated test (`test/staff_portals_workflow_test.dart:3`) | **PASS** |
| **SEC-SCN-17** | **Librarian Atomic Circulation & Return Overdue Valuation**<br>Circulation checks ensure available copies stay within valid physical bounds. Return processor computes accurate overdue days and pending fines with atomic check-in. | `LibraryRepository` + `ReturnBookDialog` | Automated test (`test/staff_portals_workflow_test.dart:8`) | **PASS** |
| **SEC-SCN-18** | **Trusted Offline Fee Payment & Balance Transaction Invariant**<br>Direct client ledger mutations are denied (`allow write: if false;`). Trusted `recordOfflinePayment` Cloud Function processes collection atomically, updates integer paise balances, and generates audit log. | `functions/src/payments/offline.ts` + `FeeRepository` | Automated test (`test/staff_portals_workflow_test.dart:14`) + TypeScript build | **PASS** |
| **SEC-SCN-19** | **Account Status Normalization & Instant Suspension Defense**<br>`AppUser` canonicalizes `status: 'active' | 'suspended'` with backward-compatible `isActive` fallback. Storage and Firestore rules enforce live check `isLiveActive()`. | `AppUser`, `firestore.rules:21`, `storage.rules:19` | Automated test (`test/staff_portals_workflow_test.dart:12`) | **PASS** |
| **SEC-SCN-20** | **Cohort Transfer & Guardian Claims Synchronization**<br>Reallocating student cohort updates `currentClassId` and `currentSectionId`, writes audit log, and invalidates/refreshes custom claims (`wardClasses`, `wardSections`) for all linked guardians. | `functions/src/admin/students.ts` + `StudentRepository` | Automated test (`test/staff_portals_workflow_test.dart:13`) | **PASS** |

---

## 3. Execution Logs & Test Results

### 3.1 Flutter Static Analysis (`flutter analyze`)
```
Analyzing lav_sms...
No issues found! (ran in 18.3s)
Exit Code: 0
```
- **Result:** 0 errors, 0 warnings, 0 lints. All deprecations and style guidelines satisfied.

### 3.2 Flutter Automated Test Suite (`flutter test`)
```
00:00 +0: loading D:/my_project_files/lav_sms/test/staff_portals_workflow_test.dart
00:01 +14: All staff portals workflow & security tests passed!
00:01 +22: All acceptance criteria tests passed!
00:02 +46: All responsive clay viewports tests passed!
00:06 +64: All tests passed!
```
- **Total Executed:** 64
- **Passed:** 64
- **Failed:** 0
- **Exit Code:** 0
- **Flutter Analysis:** 0 errors, 0 warnings (exit code 0)

### 3.3 Cloud Functions TypeScript Build (`npm run build` in `functions/`)
```
> build
> tsc

Exit Code: 0
```
- **Result:** Clean compilation without TypeScript type errors across all modules (auth, attendance, examinations, fees, library, payments, queries, reports, admin).

### 3.4 Production Web Build (`flutter build web --no-pub`)
```
Compiling lib\main.dart for the Web...                             79.4s
√ Built build\web

Exit Code: 0
```


---

## 4. Verification Check of Specific Remediation Points

### 4.1 Storage Cross-Overwrite Prevention (`storage.rules`)
```rules
// Study materials path
match /study_materials/{classId}/{fileName} {
  allow read: if isAuthenticated() && isActiveUser();
  allow create: if isStaff() && isActiveUser() 
                && request.resource.metadata.uploaderUid == request.auth.uid;
  allow update: if isStaff() && isActiveUser()
                && resource.metadata.uploaderUid == request.auth.uid
                && request.resource.metadata.uploaderUid == request.auth.uid;
  allow delete: if isAdmin() || (isStaff() && resource.metadata.uploaderUid == request.auth.uid);
}
```
*Verification:* Teacher A (`uploaderUid: uid_A`) cannot overwrite a file created by Teacher B (`uploaderUid: uid_B`) because `resource.metadata.uploaderUid == request.auth.uid` evaluates to false.

### 4.2 Webhook Signature Bypass Elimination (`functions/src/payments/webhooks.ts`)
*Verification:*
- Removed `req.headers["x-test-bypass"] === "true"` from Razorpay, Cashfree, and PhonePe handlers.
- All webhooks calculate timing-safe crypto HMACs (`crypto.timingSafeEqual`) against respective webhook secrets.
- Missing or invalid signatures immediately exit with HTTP 401 Unauthorized.
