# School Management System (SMS) — Design System & Architecture Specifications
**Document Version:** 2.5.0  
**Design Reference:** Google Stitch MCP ("MPS School Management UI System" - `projects/6002049475132200951` & `projects/9785850018733652103`)  
**Implementation Target:** Flutter Web & Mobile • Firebase (Asia-South1) • Single-Tenant Institution

---

## 1. Visual Philosophy & Core Aesthetic

The design aesthetic delivers a clean, high-density, tactile institutional experience tailored for education professionals, parents, and administrative staff. It balances academic authority with daily ergonomic speed:

- **Surface System:** Crisp neutral surfaces (`#F8FAFC`) with subtle elevations, fine-line borders (`1px solid #E2E8F0`), and soft ambient shadows (`0 4px 6px -1px rgb(0 0 0 / 0.05)`).
- **Typography:** Modern geometric sans-serif **Plus Jakarta Sans** (with fallback to **Inter**), featuring clear tabular figures for marks, financial ledgers, and roll numbers.
- **Role Identity:** Every authenticated role is immediately identifiable by a dedicated semantic accent badge and navigation banner, preventing confusion on shared workstations.

---

## 2. Color Palette & Semantic Tokens

### 2.1 Institutional Core
- **Navy Primary (`BrandBlue`):** `#1E3A8A` (Deep Academic Blue)
- **Primary Hover:** `#172554`
- **Slate Dark (`TextPrimary`):** `#0F172A`
- **Slate Muted (`TextSecondary`):** `#475569`
- **Slate Subtle (`TextMuted`):** `#94A3B8`
- **Neutral Surface (`Background`):** `#F8FAFC`
- **Card Surface (`Surface`):** `#FFFFFF`
- **Border Default (`Border`):** `#E2E8F0`
- **Border Strong (`BorderStrong`):** `#CBD5E1`

### 2.2 Semantic States
- **Success (`SuccessGreen`):** `#059669` (Dark: `#10B981`, Background: `#ECFDF5`)
- **Warning / Pending (`WarningAmber`):** `#D97706` (Dark: `#F59E0B`, Background: `#FFFBEB`)
- **Danger / Overdue (`DangerRed`):** `#DC2626` (Dark: `#EF4444`, Background: `#FEF2F2`)
- **Info (`InfoSky`):** `#0284C7` (Dark: `#38BDF8`, Background: `#F0F9FF`)

### 2.3 Six Role Accent Tokens
| Role Key | Name | Primary Accent | Light Container | Icon Badge |
| :--- | :--- | :--- | :--- | :--- |
| `school_admin` | School Administrator | `#4F46E5` (Indigo) | `#EEF2FF` | Shield |
| `teacher` | Academic Teacher | `#0D9488` (Teal) | `#F0FDFA` | BookOpen |
| `accountant` | Bursar / Accountant | `#059669` (Emerald) | `#ECFDF5` | ReceiptIndianRupee |
| `admissions_officer` | Admissions Officer | `#EA580C` (Orange) | `#FFF7ED` | UserPlus |
| `librarian` | School Librarian | `#7C3AED` (Violet) | `#F5F3FF` | Library |
| `parent_guardian` | Parent & Guardian | `#2563EB` (Royal Blue) | `#EFF6FF` | Users |

---

## 3. Typography Scale (Plus Jakarta Sans)

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `DisplayLarge` | 32px | 700 (Bold) | 40px | -0.02em | Main Page Titles, Dashboard Greetings |
| `DisplayMedium` | 24px | 700 (Bold) | 32px | -0.01em | Section Headers, Metric Highlights |
| `HeadlineSmall` | 20px | 600 (SemiBold)| 28px | -0.01em | Card Titles, Modal Headers |
| `TitleMedium` | 16px | 600 (SemiBold)| 24px | 0.0em | Table Column Headers, Form Section Labels |
| `BodyLarge` | 15px | 400 (Regular) | 22px | 0.0em | Primary content, student demographic cards |
| `BodyMedium` | 14px | 400 (Regular) | 20px | 0.0em | Data table cells, list items, remarks |
| `LabelLarge` | 13px | 600 (SemiBold)| 18px | 0.01em | Action buttons, tabs, status pills |
| `LabelSmall` | 11px | 500 (Medium) | 16px | 0.02em | Badges, timestamps, fine print |

---

## 4. Navigation Architecture & Clean URLs

### 4.1 Single Unified Dashboard URL (`/dashboard`)
- **NO role-based dashboard URLs:** Never expose `/parents`, `/parent-dashboard`, `/teacher`, `/teacher-dashboard`, `/admin-dashboard`, etc.
- All six authenticated roles enter via `/dashboard`.
- GoRouter inspects the authenticated user's trusted role from Firebase Authentication and live profile data, then dynamically presents the permitted role view.
- Role selection is never accepted as proof of authorization.

### 4.2 Resource-Based URLs
URLs represent institutional resources and workflows, not roles:
- `/dashboard` — Role-aware home portal
- `/attendance` — Role-aware roll call (Teacher) / approval queue (Admin) / ward logs (Parent)
- `/academics` — Role-aware marks entry (Teacher) / moderation (Admin) / ward report cards (Parent)
- `/fees` — Role-aware fee structures & reconciliation (Accountant) / online invoices (Parent)
- `/students` — Searchable student roster (Staff) / linked wards (Parent)
- `/students/:studentId` — Student profile detail (Access restricted to staff or linked parent)
- `/library` — Book catalog & loan management (Librarian) / student loan history
- `/notices` — Institutional circulars & broadcast announcements
- `/settings` — Profile, security tokens, and session management
- `/unauthorized` — 403 Forbidden screen for permission or parameter tampering rejections

---

## 5. Separate Authentication Experiences

The system implements two distinct authentication portals with distinct visual identities and workflows:

### 5.1 Parent & Guardian Mobile OTP Flow (`/login/parent`)
- Dedicated, approachable family portal.
- Phone number input with country code validation (+91).
- 6-digit SMS OTP entry with 60-second cooldown timer.
- Live Firebase Phone Authentication with anti-abuse safety.
- Instant redirect to `/dashboard` upon successful code verification.

### 5.2 Staff & Administrative Institutional Flow (`/login/staff`)
- Formal, professional administrative portal.
- Institutional email and password fields with show/hide password toggle.
- Secure password recovery flow (`/forgot-password`).
- Verifies institutional active status and custom claims before permitting access.
- Instant redirect to `/dashboard` upon successful authentication.

### 5.3 Unified Entry Point (`/login`)
- Clean split card interface allowing users to choose either Parent Mobile OTP or Staff Institutional Login.

---

## 6. Responsive Breakpoint Standards & Layout Strategies

| Device Type | Viewport Width | Navigation Pattern | Layout Strategy |
| :--- | :--- | :--- | :--- |
| **Mobile** | `< 600px` (`320–599px`) | Bottom `NavigationBar` (top 4 destinations) + Drawer | Single-column vertical stack, full-width touch cards, full-width modal sheets. |
| **Tablet** | `600px – 1023px` | Collapsible `NavigationRail` + top sub-tabs chip row | 2-column forms, split view for lists and detail panes, expanded table columns. |
| **Desktop** | `>= 1024px` | Persistent `260px` Sidebar + Sticky Top Header | High-density tables, multi-column forms, max content width `1440px`. |

---

## 7. Financial Precision & Integer Paise Standards
- All monetary balances, fee items, invoices, and payments are stored and processed strictly as integer paise (`₹ 1.00 = 100 paise`).
- Zero floating-point drift in storage or calculations.
- Displayed using `CurrencyFormatter.formatPaiseToInr()` conforming to Indian numbering system (`₹ X,XX,XXX.00`).
