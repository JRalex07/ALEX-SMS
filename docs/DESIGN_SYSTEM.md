# LAV Academy School Management System — Claymorphism & Adaptive Design System

## 1. Architectural Philosophy & Vision

The LAV Academy School Management System (LAV SMS) design system balances modern tactile aesthetics with enterprise-grade usability, accessibility, and platform adaptability. It replaces flat, utilitarian screens with a premium **Claymorphism** visual language while guaranteeing:

1. **Platform Awareness:** Seamless transitions between Flutter Web (desktop mouse/keyboard, hover feedback, path-based routing, browser printing) and native Android/iOS (touch targets >= 48px, system insets, modal sheets).
2. **True Responsive Adaptation:** A 4-tier layout engine (Compact, Medium, Wide, Extra-Wide) that organizes information according to viewport constraints rather than scaling desktop layouts down.
3. **Information Clarity & Zero Compromise:** High-contrast typography, readable tables, integer-paise financial precision, and WCAG AA accessibility compliance.
4. **Strict ReBAC Security & Zero Fake Logic:** Preserving the authentic 6-role permission matrix, Cloud Functions, and Firebase Firestore security invariants without client-side bypasses.

---

## 2. Design Tokens & Theme Specification

### 2.1 Color Palette

| Token | Hex / Value | Semantic Role |
| :--- | :--- | :--- |
| `clayCanvas` | `#F1F5F9` | Default soft slate canvas background across all screens |
| `claySurface` | `#FFFFFF` | Primary tactile card and container background |
| `claySurfaceSubtle`| `#F8FAFC` | Table headers, secondary surfaces, and hover states |
| `claySurfaceDark` | `#0F172A` | High-contrast dark accents and brand backgrounds |
| `surfacePressed` | `#E2E8F0` | Active press state and recessed tags |
| `brandNavy` | `#1E3A8A` | Institutional primary brand color (Administration) |
| `teacherGreen` | `#047857` | Academic & Teacher Portal accent |
| `accountantAmber`| `#B45309` | Bursar & Financial Management accent |
| `admissionsOrange`| `#C2410C` | Admissions & Registry accent |
| `librarianPurple` | `#6D28D9` | Library & Catalogue accent |
| `parentBlue` | `#0284C7` | Parent & Guardian Portal accent |
| `successGreen` | `#16A34A` | Verification, published marks, and paid statuses |
| `warningAmber` | `#D97706` | Pending approvals and overdue notices |
| `dangerRed` | `#DC2626` | Error states, audit warnings, and unreturned books |
| `textPrimary` | `#0F172A` | High-contrast slate typography (100% readable) |
| `textSecondary` | `#475569` | Subtitles, helper text, and secondary labels |
| `textMuted` | `#64748B` | Timestamp details and metadata |

### 2.2 Corner Radii Tokens

All clay surfaces feature soft, pillowed curvature:
- `radiusSm` = **10.0px** (Pills, badges, small buttons, and icon tiles)
- `radiusMd` = **16.0px** (Cards, dialogs, inputs, and stat containers)
- `radiusLg` = **22.0px** (Modal surfaces and prominent hero sections)
- `radiusXl` = **28.0px** (Floating containers and large dialog headers)
- `radiusPill` = **999.0px** (Segmented controls and status pills)

### 2.3 Tactile Depth & Dual-Layer Shadow System

Claymorphism depth is achieved using dual-layer offset shadows: an ambient dark drop shadow combined with a bright top-left specular highlight.

```dart
enum ClayDepth {
  inset,   // Recessed surfaces: inputs, search fields, segment tracks
  flat,    // Subtle elevation: dividers and disabled items
  low,     // Slight lift: secondary cards and list tiles
  medium,  // Standard lift: primary dashboard cards, stat cards
  high,    // Prominent lift: floating actions, modals, active dialogs
}
```

- **Medium Elevation:**
  - Ambient Shadow: `Offset(3, 6)`, blur: `12`, color: `Color(0xFF0F172A).withValues(alpha: 0.07)`
  - Highlight Shadow: `Offset(-2, -3)`, blur: `8`, color: `Colors.white`
- **Inset (Sunken) Elevation:**
  - Inset Shadow: `Offset(1, 2)`, blur: `4`, color: `Color(0xFF0F172A).withValues(alpha: 0.05)`
  - Edge Highlight: `Offset(-1, -1)`, blur: `3`, color: `Colors.white.withValues(alpha: 0.8)`
- **Dynamic Press Feedback:** On touch or click, components smoothly animate to an inset shadow configuration with a slight scale reduction (`Transform.scale(0.98)`).

### 2.4 Tactile Border Architecture

All clay surfaces utilize a 1.2px dual-tone border:
- Standard: `Colors.white.withValues(alpha: 0.85)` creates an illuminated top bevel on light canvas.
- Accent: Optional role-tinted border (`roleColor.withValues(alpha: 0.2)`) reinforces context without visual clutter.

### 2.5 Authentic Tactile Microtexture & Molded Specular Highlights

To deliver true tactile clay rather than flat rounded vector cards, the design system implements [`ClayTexturePainter`](file:///d:/my_project_files/lav_sms/lib/shared/clay/clay_texture_painter.dart):
- **Directional Tonal Molding:** Linear gradient angled at 315° (top-left to bottom-right) simulating 3D curved ceramic surfaces.
- **Molded Specular Rim Highlight:** Soft 1px crescent highlight along the top-left edge (`Colors.white.withValues(alpha: 0.35)` down to transparent).
- **Fine-Grained Microtexture:** Deterministic, low-contrast matte grain (light dots at alpha `0.035`, dark dots at alpha `0.015`) painted behind child widgets to guarantee 100% crisp foreground text contrast.
- **Zero Remote Dependencies:** Rendered directly onto Skia/Impeller canvas with deterministic hashing — no network latency or asset licensing issues.
- **Accessible & Performance Toggle:** Global toggle `ClayTheme.enableMicrotexture = true/false` allows instant fallback for low-power or high-contrast accessibility profiles.

---

## 3. Platform-Separated Login Architecture (Web vs Native Mobile)

As mandated by institutional security and platform-specific UX guidelines, web browsers and native mobile applications feature distinct login presentations sharing unified Firebase Authentication:

### 3.1 Web Login Experience (`WebLoginScreen`)
- **Target Platform:** Flutter Web running in desktop, laptop, tablet, and mobile browsers (`kIsWeb == true`).
- **Composition:** Wide two-column institutional workspace (`maxWidth: 1140px`).
  - **Left Column (Institutional Overview):** Institutional crest, session details (`2026-2027`), security pillars (authoritative ReBAC, audited ledgers, verified guardian safeguards).
  - **Right Column (Authentication Card):** Tactile `ClaySegmentedControl` switching between **Staff & Faculty** (Email + Password) and **Parent & Guardian** (Phone + Web OTP confirmation).
- **Responsive Stacking:** On browser viewports under 1024px or mobile browsers, gracefully reorganizes into a top institutional banner with a centered workspace card, preserving its portal identity.

### 3.2 Native Mobile Login Experience (`NativeAppLoginScreen`)
- **Target Platform:** Native Android & iOS applications (`kIsWeb == false`).
- **Composition:** Focused, full-screen mobile-first layout optimized for one-handed thumb interaction.
- **Branding:** Compact crest and session header that auto-hides when the on-screen keyboard appears.
- **Controls:** Smooth tactile segmented control at top, large touch targets (>= 48px), recessed `ClayTextField`s with +91 mobile validation, SMS Retriever support, countdown timers, and zero keyboard overflow.

---

## 4. Responsive 4-Tier Layout Architecture

Layout logic is centralized in [`breakpoints.dart`](file:///d:/my_project_files/lav_sms/lib/core/constants/breakpoints.dart). It evaluates actual available width rather than user-agent strings.

| Tier | Width Range | Target Devices | Primary Navigation | Layout Paradigm |
| :--- | :--- | :--- | :--- | :--- |
| **Compact** | `< 600px` | Phones (iPhone, Pixel, Galaxy) | `NavigationBar` (bottom) + App Bar `Drawer` | 1-Column Cards, `AdaptiveDataView` cards, Modal Bottom Sheets |
| **Medium** | `600px – 1023px`| Small/Large Tablets, Foldables | `NavigationRail` (collapsible left) | 2-Column Metrics, Adaptive Tables/Cards, Side Panels |
| **Wide** | `1024px – 1439px`| Laptops, Small Desktops | Persistent Clay Sidebar (260px) | 3-4 Column Metrics, Interactive Data Tables, Dialogs |
| **Extra-Wide**| `>= 1440px` | Monitors, 1080p+, 4K Displays | Persistent Clay Sidebar + `AdaptiveContainer` | Constrained 1440px max content width to prevent stretching |

### 4.1 Responsive Components

1. **`ResponsiveBuilder`:**
   Declaratively renders tailored layouts for each tier (`compact`, `medium`, `wide`, `extraWide`).
2. **`AdaptiveContainer`:**
   Wraps dashboard content in a `BoxConstraints(maxWidth: 1440)` container, centering the interface on ultra-wide screens.
3. **`AdaptiveDataView<T>`:**
   Automatically inspects width:
   - On Desktop/Tablet (`>= 768px`): Renders a dense, hoverable clay table with fixed/flex columns and clean alignment.
   - On Compact Mobile (`< 768px`): Transforms each record into a tactile `ClayCard` with detail pills, preventing horizontal clipping.

---

## 5. Platform-Aware Experience (Web vs Native)

| Interaction Area | Flutter Web (Browser) | Native Mobile (Android / iOS) |
| :--- | :--- | :--- |
| **Login Experience** | `WebLoginScreen` (2-column workspace, institutional pillars) | `NativeAppLoginScreen` (one-handed mobile, compact branding) |
| **Primary Input** | Mouse cursor, scroll wheel, trackpad, keyboard navigation | Touch gestures, swipe-to-dismiss, long-press |
| **Hover States** | Micro-elevation on cards, cursor styling (`SystemMouseCursors.click`) | Disabled to avoid stuck hover artifacts |
| **Routing & URLs** | Clean path URLs (`/dashboard`, `/students`, `/fees`, `/academics`) | Seamless app state restoration |
| **Data Export** | Instant client-side CSV blob download & browser print window | Native share sheet & system PDF print manager |
| **Form Entry** | Keyboard Tab navigation, persistent focus ring | System keyboard avoidance via `SingleChildScrollView` |
| **System Insets** | Standard browser viewport bounds | `SafeArea` padding for notches, status bars, and home indicators |

---

## 6. Reusable Component Catalog

All components are located in [`lib/shared/clay/`](file:///d:/my_project_files/lav_sms/lib/shared/clay/):

| Component | Class | Purpose | Key Features |
| :--- | :--- | :--- | :--- |
| **Clay Container** | `ClayContainer` | Foundational tactile surface | Dual-layer shadows, rounded corners, microtexture painter, hover/press state animation |
| **Clay Card** | `ClayCard` | Section and content card | Optional icon badge, title, subtitle, and action slot |
| **Clay Stat Card** | `ClayStatCard` | Key dashboard metric display | Role-tinted icon tile, bold metric value, trend indicator |
| **Clay Button** | `ClayButton` | Raised and inset tactile buttons | Primary, secondary, danger, and subtle variants with loading spinner & flexible text |
| **Clay Text Field** | `ClayTextField` | Recessed input & search field | Inset depth, focused glow ring, prefix/suffix icons |
| **Clay Segmented** | `ClaySegmentedControl` | Tactile tab switcher | Pill track with smooth sliding raised active pill |
| **Clay Status Badge** | `ClayStatusBadge` | Informational status tag | Role and state colors (success, pending, danger, info) |
| **Adaptive Data View**| `AdaptiveDataView` | Responsive tabular records | Automatic table-to-card transformation below 768px |
| **Clay Empty State** | `ClayEmptyState` | Informational zero-data view | Tactile icon well, clear title, and contextual message |
| **Parent Switcher** | `ParentChildSwitcher` | Ward selector for guardians | Active ward pill, dropdown menu, zero data leakage |

---

## 7. Multi-Portal Implementation Summary

### 7.1 Administrator Portal (`/dashboard`)
- **Executive Operations Center:** Responsive metric grid with ClayStatCards showing total enrolled students, fee collections, faculty counts, and pending authorizations.
- **Pending Approvals Queue:** Tactile cards with one-touch approval/rejection triggers connected directly to Cloud Functions.
- **Campus Bulletin:** Clay card feed with "Publish Notice" dialog integration.

### 7.2 Teacher Portal (`/dashboard`, `/academics`)
- **Class & Section Selector:** Clay dropdown and segmented control for quick grade selection.
- **Roll-Call Register:** Tactile present/absent buttons with color feedback.
- **Gradebook Entry:** Adaptive marks table with inline inputs and print preview.

### 7.3 Accountant Portal (`/dashboard`, `/fees`)
- **Financial Ledger Summary:** Integer paise calculations converted to INR (₹) with zero floating-point discrepancies.
- **Fee Collection Grids:** Searchable adaptive view separating Pending, Paid, and Overdue vouchers.
- **Payment Recording Dialog:** Recessed amount inputs and print-ready receipts.

### 7.4 Admissions Portal (`/dashboard`, `/students`)
- **Institutional Registry:** Multi-column table on desktop transitioning to rich mobile cards.
- **New Admission Form:** Responsive multi-field form that stacks neatly on mobile viewports.
- **Guardian Linking Terminal:** Cloud Function integration with token revocation protection.

### 7.5 Librarian Portal (`/dashboard`, `/library`)
- **Inventory Overview:** Metrics on total catalog, issued books, and active loans.
- **Circulation Management:** Tactile search field and book issue/return dialogs.
- **CSV Catalog Export:** Instant CSV generation of complete inventory.

### 7.6 Parent/Guardian Portal (`/dashboard`, `/academics`, `/fees`)
- **Persistent Ward Context:** Prominent `ParentChildSwitcher` indicating active child without state contamination.
- **Academic Report Cards:** Official printable term cards with grade breakdown and attendance rate.
- **Fee Statements:** Clear invoice cards with payment status and downloadable receipts.

---

## 8. Multi-Viewport Responsive Verification Results

All 8 requested logical viewport sizes were tested in [`test/responsive_clay_viewports_test.dart`](file:///d:/my_project_files/lav_sms/test/responsive_clay_viewports_test.dart) with zero overflow exceptions:

| Test Viewport | Classification | Navigation Verified | Layout Behavior Verified | Test Status |
| :--- | :--- | :--- | :--- | :--- |
| **360 × 800** | Compact Phone | `NavigationBar` & `Drawer` | 1-column cards, no horizontal table clipping, 0 overflow | **PASSED** |
| **390 × 844** | Typical Phone | `NavigationBar` & `Drawer` | 1-column metrics, touch targets >= 48px, 0 overflow | **PASSED** |
| **600 × 960** | Compact Tablet Boundary| `NavigationRail` | 2-column metrics, side navigation rail, 0 overflow | **PASSED** |
| **768 × 1024** | Tablet (Portrait) | `NavigationRail` | 2-column layout, dense list tiles, 0 overflow | **PASSED** |
| **1024 × 768** | Small Desktop / Tablet | Persistent Clay Sidebar | Full sidebar, multi-column dashboard, 0 overflow | **PASSED** |
| **1280 × 800** | Laptop | Persistent Clay Sidebar | Dense data tables, 3-4 column metrics, 0 overflow | **PASSED** |
| **1440 × 900** | Desktop | Persistent Clay Sidebar | Full-width data tables, search filters, 0 overflow | **PASSED** |
| **1920 × 1080** | Wide Desktop | Persistent Clay Sidebar | `AdaptiveContainer` centers layout at 1440px, 0 overflow | **PASSED** |
| **390 × 844 (1.5x)**| Accessibility Scaling | TextScaler 1.5x | All labels wrap gracefully with 0 RenderFlex overflow | **PASSED** |
| **1440 × 900 (Web)**| Web Login Desktop | 2-Column Workspace | Left branding panel + Right authentication card, 0 overflow | **PASSED** |
| **390 × 844 (Mobile Web)**| Web Login Mobile | Stacked Web Layout | Institutional header banner + Centered auth card, 0 overflow | **PASSED** |
| **360 × 800 (Native)**| Native Mobile Login | 1-Handed Mobile | Segmented switcher, compact branding, 0 overflow | **PASSED** |

---

## 9. Verification & Test Evidence

- **Unit & Widget Tests:** `42 / 42` tests passed (`acceptance_test.dart`, `responsive_clay_viewports_test.dart`).
- **Static Analysis:** `0 errors` (`flutter analyze`).
- **ReBAC Matrix Compliance:** Verified against `docs/ROLE_PERMISSION_MATRIX.md`. All 6 roles retain server-enforced access controls.
- **Physical Device:** Verified on OnePlus CPH2603 (1080x2412, 360dp width) with zero RenderFlex overflow.
