// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Triggers isolated, clean web document printing directly in the current window.
///
/// Ensures ONLY the authoritative A4 document prints with official institutional letterhead,
/// vector tables, and precise page margins.
///
/// CRITICAL BROWSER UX GUARANTEES:
/// 1. NEVER opens a new browser tab or 'about:blank' window.
/// 2. Invokes [html.window.print] directly on the current tab.
/// 3. Suppresses Flutter application chrome, dark dialog overlays, sidebars, and navigation
///    during print via targeted @media print rules.
/// 4. Restores the application tab title and cleans up the DOM container immediately
///    after the print dialog is completed or dismissed.
void printHtmlDocument({
  required String htmlContent,
  String documentTitle = 'LAV Academy Document',
}) {
  // 1. Temporarily set the document title so browser print preview and
  // default PDF filename reflect the institutional document title.
  final previousTitle = html.document.title;
  html.document.title = documentTitle;

  // 2. Locate or create isolated in-page print container.
  // Avoids iframes completely, preventing Chrome from opening 'about:blank' tabs.
  var container = html.document.getElementById('__lav_print_container__');
  if (container == null) {
    container = html.DivElement()..id = '__lav_print_container__';
    html.document.body?.append(container);
  }

  // 3. Assemble document styling and content
  final styledHtml = '''
<style>
  @page {
    size: A4 portrait;
    margin: 15mm 15mm 15mm 15mm;
  }
  @media screen {
    #__lav_print_container__ {
      display: none !important;
      visibility: hidden !important;
    }
  }
  @media print {
    html, body {
      margin: 0 !important;
      padding: 0 !important;
      background: #FFFFFF !important;
      color: #0F172A !important;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    /* Suppress Flutter root, modal backdrops, navigation bars, and app chrome */
    body > :not(#__lav_print_container__) {
      display: none !important;
      visibility: hidden !important;
    }
    #__lav_print_container__ {
      display: block !important;
      position: static !important;
      width: 100% !important;
      margin: 0 !important;
      padding: 0 !important;
      background: #FFFFFF !important;
      color: #0F172A !important;
      visibility: visible !important;
      opacity: 1 !important;
      z-index: 9999999 !important;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    .no-print {
      display: none !important;
    }
  }
  #__lav_print_container__ * {
    box-sizing: border-box;
  }
  #__lav_print_container__ .print-document {
    width: 100%;
    max-width: 210mm;
    margin: 0 auto;
    background: #FFFFFF;
    color: #0F172A;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    font-size: 13px;
    line-height: 1.45;
    -webkit-font-smoothing: antialiased;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
  #__lav_print_container__ .letterhead {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 3px solid #1E3A8A;
    padding-bottom: 12px;
    margin-bottom: 20px;
  }
  #__lav_print_container__ .crest {
    font-size: 38px;
    margin-right: 14px;
    line-height: 1;
  }
  #__lav_print_container__ .school-title {
    font-size: 20px;
    font-weight: 800;
    color: #1E3A8A;
    letter-spacing: 1.5px;
    margin: 0 0 2px 0;
  }
  #__lav_print_container__ .school-subtitle {
    font-size: 10.5px;
    color: #475569;
    font-weight: 600;
    margin: 0 0 3px 0;
  }
  #__lav_print_container__ .school-address {
    font-size: 9.5px;
    color: #64748B;
    margin: 0;
  }
  #__lav_print_container__ .doc-meta {
    text-align: right;
  }
  #__lav_print_container__ .doc-meta-title {
    font-size: 11px;
    font-weight: 800;
    color: #1E3A8A;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin: 0 0 3px 0;
  }
  #__lav_print_container__ .doc-meta-ref {
    font-size: 10px;
    color: #64748B;
    margin: 0 0 2px 0;
  }
  #__lav_print_container__ .accent-bar {
    height: 2px;
    background: #F59E0B;
    margin-top: 2px;
    margin-bottom: 14px;
  }
  #__lav_print_container__ .doc-title-badge {
    text-align: center;
    margin: 14px 0 20px 0;
  }
  #__lav_print_container__ .doc-title-badge span {
    display: inline-block;
    background: #EEF2F6;
    color: #1E3A8A;
    font-weight: 800;
    font-size: 13px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
    padding: 4px 16px;
    border-radius: 4px;
    border: 1px solid #CBD5E1;
  }
  #__lav_print_container__ .info-card {
    background: #F8FAFC;
    border: 1px solid #CBD5E1;
    border-radius: 6px;
    padding: 10px 14px;
    margin-bottom: 16px;
    font-size: 11.5px;
  }
  #__lav_print_container__ .section-title {
    font-size: 11.5px;
    font-weight: 800;
    color: #1E3A8A;
    background: #F8FAFC;
    border-left: 3px solid #1E3A8A;
    padding: 4px 8px;
    margin: 16px 0 8px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  #__lav_print_container__ .grid-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    margin-bottom: 12px;
  }
  #__lav_print_container__ .grid-3 {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 12px;
    margin-bottom: 12px;
  }
  #__lav_print_container__ .data-item {
    padding: 4px 0;
  }
  #__lav_print_container__ .data-label {
    font-size: 10px;
    color: #64748B;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }
  #__lav_print_container__ .data-value {
    font-size: 12px;
    color: #0F172A;
    font-weight: 600;
    word-break: break-word;
  }
  #__lav_print_container__ table {
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0 16px 0;
    font-size: 11.5px;
  }
  #__lav_print_container__ table th {
    background: #F1F5F9;
    color: #1E293B;
    font-weight: 700;
    text-align: left;
    padding: 7px 10px;
    border: 1px solid #CBD5E1;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }
  #__lav_print_container__ table td {
    padding: 7px 10px;
    border: 1px solid #CBD5E1;
    color: #334155;
  }
  #__lav_print_container__ table tr:nth-child(even) td {
    background: #F8FAFC;
  }
  #__lav_print_container__ .text-right {
    text-align: right;
  }
  #__lav_print_container__ .text-center {
    text-align: center;
  }
  #__lav_print_container__ .font-bold {
    font-weight: bold;
  }
  #__lav_print_container__ .highlight-box {
    background: #EFF6FF;
    border: 1px solid #BFDBFE;
    border-radius: 6px;
    padding: 10px 14px;
    margin: 14px 0;
    display: flex;
    justify-content: space-between;
    font-size: 12px;
  }
  #__lav_print_container__ .badge {
    display: inline-block;
    padding: 2px 7px;
    border-radius: 3px;
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
  }
  #__lav_print_container__ .badge-approved, #__lav_print_container__ .badge-success {
    background: #DCFCE7;
    color: #15803D;
  }
  #__lav_print_container__ .badge-pending, #__lav_print_container__ .badge-warning {
    background: #FEF3C7;
    color: #B45309;
  }
  #__lav_print_container__ .badge-rejected, #__lav_print_container__ .badge-danger {
    background: #FEE2E2;
    color: #B91C1C;
  }
  #__lav_print_container__ .badge-neutral {
    background: #F1F5F9;
    color: #475569;
  }
  #__lav_print_container__ .signatures {
    display: flex;
    justify-content: space-between;
    margin-top: 48px;
    padding-top: 24px;
    border-top: 1px solid #CBD5E1;
    page-break-inside: avoid;
  }
  #__lav_print_container__ .sig-col {
    text-align: center;
    width: 180px;
  }
  #__lav_print_container__ .sig-line {
    border-top: 1px solid #334155;
    padding-top: 6px;
    font-size: 11px;
    font-weight: 600;
    color: #334155;
  }
  #__lav_print_container__ .footer {
    display: flex;
    justify-content: space-between;
    margin-top: 24px;
    text-align: center;
    font-size: 9.5px;
    color: #94A3B8;
    border-top: 1px dashed #E2E8F0;
    padding-top: 8px;
    page-break-inside: avoid;
  }
</style>
<div class="print-document">
  $htmlContent
</div>
''';

  container.setInnerHtml(
    styledHtml,
    treeSanitizer: html.NodeTreeSanitizer.trusted,
  );

  // 4. Trigger print on the CURRENT browser tab.
  // Chrome directly presents the native print preview dialog without opening
  // an 'about:blank' tab or popup.
  bool cleanupDone = false;
  void cleanup() {
    if (cleanupDone) return;
    cleanupDone = true;
    html.document.title = previousTitle;
    container?.children.clear();
  }

  // Register clean-up listener on afterprint event
  html.window.addEventListener('afterprint', (event) {
    cleanup();
  });

  // Short delay to allow the DOM to attach and styles to compute before invoking print
  Timer(const Duration(milliseconds: 50), () {
    try {
      html.window.print();
    } finally {
      // Fallback timer ensures title and DOM cleanup even if afterprint is cancelled or not fired
      Timer(const Duration(seconds: 2), cleanup);
    }
  });
}

/// Fallback browser print trigger (no-op)
void triggerBrowserPrint() {}
