# LAV School Management System (SMS)
**Dedicated Single-Institution Cross-Platform School Management Platform**  
*Built with Flutter, Firebase, and TypeScript Cloud Functions*

---

## 1. System Overview

LAV SMS is an enterprise-grade school management platform engineered for a single dedicated educational institution. It implements a zero-trust client security boundary, role-based access control, integer paise financial ledger tracking, and an authoritative **Parent-Managed Student Access Model**.

### Core Architecture Attributes
- **Target Audience:** Single educational institution (`SCH_001`) — strictly non-SaaS, eliminating multi-tenant partitioning risks and noisy-neighbor throttling.
- **Client Application:** Flutter (Cross-platform for Android, iOS, and Web Administration).
- **Backend & Cloud Infrastructure:** Google Firebase
  - **Firebase Authentication:** Multi-role token management with live status checking.
  - **Cloud Firestore:** Document database with security rules enforcing live ReBAC and live user status.
  - **Firebase Cloud Storage:** Bucket with strict role allowlists and signed-URL-only report access.
  - **Cloud Functions (TypeScript):** Privileged server operations for approvals, marks publication, guardian linkage, and payment webhooks.
  - **Firebase Project:** `lav-school-sms-2026` (`981819763614`, region: `asia-south1`).

---

## 2. Six Active Authentication Roles

In accordance with Blueprint v2.4.0, the system features exactly **SIX active authentication roles**:

| Role Key | Role Title | Dashboard Capabilities | Security Boundary |
| :--- | :--- | :--- | :--- |
| `school_admin` | School Administrator | Overview metrics, attendance session approvals, exam results publication, notice broadcasts, audit logs | Live document status check (`isLiveSchoolAdmin()`) |
| `teacher` | Academic Teacher | Assigned class & section roll call, draft marks entry (CA1, CA2, Exam Score), study materials | Scoped to assigned classes and sections; cannot self-approve |
| `accountant` | Bursar / Accountant | Fee structures, student invoices, counter/offline payments, gateway settlement reconciliation | Full ledger read; balance mutations restricted to trusted server/functions |
| `admissions_officer` | Admissions Officer | Student enrollment registry, demographic editing, guardian-student account linking | Demographic allowlist writes only; identity and guardian linkage via function |
| `librarian` | School Librarian | Catalogue inventory, active loan tracking, 14-day book issuance and returns | Transactional counter checkouts; student loan history |
| `parent_guardian` | Parent & Guardian | **Parent-Managed Access:** Linked child switcher, attendance logs, published marks, fee invoices, PDF reports | Authoritative live ReBAC (`uid in student.guardianUserIds`); 0s revocation delay |

> [!NOTE]
> **Parent-Managed Student Access Model:** Students do not receive direct authentication credentials in this release. Parents log in and utilize the `ParentChildSwitcher` widget to switch between their linked children, driving scoped queries for attendance, published marks, and fee invoices.

---

## 3. Financial Architecture (Integer Paise Model)

All monetary transactions, invoice totals, fee structures, and payments are strictly represented and calculated in **integer paise** (₹ 1 = 100 paise) to eliminate floating-point calculation and rounding discrepancies:
- Base utility: `lib/core/utils/currency_formatter.dart`
- Formats paise to Indian Rupee strings with Indian numbering: `CurrencyFormatter.formatPaiseToInr(150000)` -> `₹1,500.00`
- Safe input parser: `CurrencyFormatter.parseInrToPaise("1,500.50")` -> `150050 paise`
- Webhook handlers for Cashfree, Razorpay, and PhonePe process integer paise with constant-time signature validation (`safeTimingSafeEqual`).

---

## 4. Project Structure

```
lav_sms/
├── android/                   # Native Android configuration (package: com.lav.schoolsms)
│   └── app/google-services.json
├── ios/                       # Native iOS configuration (bundle: com.lav.schoolsms)
│   └── Runner/GoogleService-Info.plist
├── web/                       # Web deployment files
├── lib/
│   ├── app/
│   │   ├── app.dart           # MaterialApp.router root widget
│   │   ├── router/            # GoRouter with role redirection and auth guards
│   │   └── theme/             # Design tokens & typography
│   ├── core/
│   │   ├── constants/         # Role keys, color tokens
│   │   └── utils/             # Integer paise currency formatter
│   ├── models/                # Domain models (User, Student, Attendance, Exam, Fee, Library, Notice)
│   ├── repositories/          # Firestore and Cloud Function repositories
│   ├── providers/             # Riverpod providers (auth, child context, feature streams)
│   ├── shared/                # Status badges, currency displays, stat cards, parent child switcher
│   └── features/              # Role dashboards (Admin, Teacher, Accountant, Admissions, Librarian, Parent)
├── functions/                 # TypeScript Firebase Cloud Functions
│   └── src/
│       ├── attendance/        # approveAttendanceSession, finalizeAttendanceSession
│       ├── examinations/      # adminCorrectMark, publishExamResults
│       ├── notices/           # publishNotice, unpublishNotice
│       ├── guardians/         # linkGuardian, unlinkGuardian (instant tokenVersion revocation)
│       ├── queries/           # getWardInvoices, getWardMarks (Trusted-backend reads)
│       ├── reports/           # getReportCardDownloadUrl, getReceiptDownloadUrl (15m signed URLs)
│       └── payments/          # cashfreeWebhook, razorpayWebhook, phonepeWebhook
├── firestore.rules            # Production Firestore security rules with live ReBAC
├── storage.rules              # Production Cloud Storage security rules with signed-URL model
├── firestore.indexes.json     # Required composite indexes
└── DESIGN.md                  # Comprehensive Design System Documentation
```

---

## 5. Development & Testing Commands

### Prerequisites
- Flutter SDK 3.47+ & Dart 3.13+
- Node.js 20+ & npm
- Firebase CLI (`npm install -g firebase-tools`)

### Running Local Automated Tests
```bash
# Run Flutter unit test suite
flutter test

# Run Flutter static analysis
flutter analyze

# Compile TypeScript Cloud Functions
npm --prefix functions run build

# Validate Firebase Security Rules
# (Both rules validated with "OK: No errors detected")
```

### Building for Platforms
```bash
# Build Flutter Web bundle
flutter build web --release

# Build Android APK
flutter build apk --debug
```

### Local Firebase Emulator
```bash
firebase emulators:start
```
