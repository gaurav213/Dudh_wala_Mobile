import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/formatters/indian_formatters.dart';

class BillPdfLine {
  const BillPdfLine({
    required this.date,
    required this.description,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  final String date;
  final String description;
  final String qty;
  final String rate;
  final String amount;
}

class BillPdfData {
  const BillPdfData({
    required this.brandName,
    required this.farmName,
    required this.billNumber,
    required this.periodLabel,
    required this.generatedOn,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.lines,
    required this.totalLitres,
    required this.milkCharges,
    required this.previousBalance,
    required this.paid,
    required this.due,
    this.statusNote = 'Pay anytime this month',
  });

  final String brandName;
  final String farmName;
  final String billNumber;
  final String periodLabel;
  final String generatedOn;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final List<BillPdfLine> lines;
  final String totalLitres;
  final String milkCharges;
  final String previousBalance;
  final String paid;
  final String due;
  final String statusNote;
}

/// Builds a clean A4 milk bill PDF (preview + share).
class BillPdfService {
  static final _leaf = PdfColor.fromInt(0xFF2F6B3A);
  static final _cream = PdfColor.fromInt(0xFFF7F3EA);
  static final _ink = PdfColor.fromInt(0xFF1C1C1C);
  static final _muted = PdfColor.fromInt(0xFF5C5C5C);
  static final _line = PdfColor.fromInt(0xFFD9D2C5);

  Future<Uint8List> build(BillPdfData data) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        header: (_) => _header(data),
        footer: (ctx) => _footer(data, ctx.pageNumber, ctx.pagesCount),
        build: (_) => [
          pw.SizedBox(height: 8),
          _parties(data),
          pw.SizedBox(height: 16),
          _metaRow(data),
          pw.SizedBox(height: 18),
          pw.Text(
            'Delivery details',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 8),
          _linesTable(data),
          pw.SizedBox(height: 18),
          _totals(data),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _cream,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _line),
            ),
            child: pw.Text(
              data.statusNote,
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> previewAndShare(BillPdfData data) async {
    final bytes = await build(data);
    final name = 'bill_${data.billNumber.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.pdf';
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
  }

  Future<void> shareOnly(BillPdfData data) async {
    final bytes = await build(data);
    final name = 'bill_${data.billNumber.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  /// Legacy SQLite / farm bill maps → PDF (keeps BillDetailsScreen working).
  Future<void> shareBillPdf({
    required Map<String, Object?> bill,
    required Map<String, Object?> customer,
    required List<Map<String, Object?>> items,
    String supplierName = 'Doodh Wala',
  }) async {
    final periodStart = _fmtDate(bill['period_start']);
    final periodEnd = _fmtDate(bill['period_end']);
    final total = _asNum(bill['total'] ?? bill['totalAmount']);
    final paid = _asNum(bill['paid_amount'] ?? bill['paidAmount']);
    final due = (total - paid) < 0 ? 0.0 : (total - paid);
    final data = BillPdfData(
      brandName: 'Doodh Wala',
      farmName: supplierName,
      billNumber: '${bill['bill_number'] ?? bill['id'] ?? 'BILL'}',
      periodLabel: '$periodStart – $periodEnd',
      generatedOn: formatDate(DateTime.now()),
      customerName: '${customer['name'] ?? 'Customer'}',
      customerPhone: '${customer['phone'] ?? customer['mobileNumber'] ?? ''}',
      customerAddress: customer['address']?.toString(),
      lines: [
        for (final item in items)
          BillPdfLine(
            date: _fmtDate(item['item_date'] ?? item['itemDate']),
            description: '${item['description'] ?? 'Milk'}',
            qty: formatLitres(_asNum(
                item['quantity_litres'] ?? item['quantity'] ?? 0)),
            rate: formatRupees(_asNum(
                item['rate_per_litre'] ?? item['rate'] ?? 0)),
            amount: formatRupees(_asNum(item['amount'] ?? 0)),
          ),
      ],
      totalLitres: formatLitres(items.fold<num>(
        0,
        (a, i) =>
            a + _asNum(i['quantity_litres'] ?? i['quantity'] ?? 0),
      )),
      milkCharges: formatRupees(_asNum(bill['subtotal'] ?? total)),
      previousBalance: formatRupees(_asNum(bill['previousBalance'] ?? 0)),
      paid: formatRupees(paid),
      due: formatRupees(due),
      statusNote: 'Thank you for choosing $supplierName.',
    );
    await previewAndShare(data);
  }

  pw.Widget _header(BillPdfData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _leaf, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.brandName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _leaf,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  data.farmName,
                  style: pw.TextStyle(fontSize: 11, color: _ink),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _leaf,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'MILK BILL',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _parties(BillPdfData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO',
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: _muted,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(data.customerName,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink)),
                if (data.customerPhone.isNotEmpty)
                  pw.Text(data.customerPhone,
                      style: pw.TextStyle(fontSize: 9, color: _muted)),
                if ((data.customerAddress ?? '').isNotEmpty)
                  pw.Text(data.customerAddress!,
                      style: pw.TextStyle(fontSize: 9, color: _muted)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FROM',
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: _muted,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(data.farmName,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink)),
                pw.Text(data.brandName,
                    style: pw.TextStyle(fontSize: 9, color: _muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _metaRow(BillPdfData data) {
    pw.Widget cell(String label, String value) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.SizedBox(height: 2),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
            ],
          ),
        );
    return pw.Row(
      children: [
        cell('Bill no.', data.billNumber),
        cell('Period', data.periodLabel),
        cell('Generated', data.generatedOn),
        cell('Total milk', data.totalLitres),
      ],
    );
  }

  pw.Widget _linesTable(BillPdfData data) {
    if (data.lines.isEmpty) {
      return pw.Text('No delivered milk in this period yet.',
          style: pw.TextStyle(fontSize: 10, color: _muted));
    }
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      headerDecoration: pw.BoxDecoration(color: _cream),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: _ink,
      ),
      cellStyle: pw.TextStyle(fontSize: 9, color: _ink),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(1.2),
      },
      headers: const ['Date', 'Description', 'Qty', 'Rate', 'Amount'],
      data: [
        for (final line in data.lines)
          [line.date, line.description, line.qty, line.rate, line.amount],
      ],
    );
  }

  pw.Widget _totals(BillPdfData data) {
    pw.Widget row(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: _ink,
                )),
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: _ink,
                )),
          ],
        ),
      );
    }

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            row('Milk charges', data.milkCharges),
            row('Previous balance', data.previousBalance),
            row('Paid / given', data.paid),
            pw.Divider(color: _line, thickness: 0.8),
            row('Amount due', data.due, bold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _footer(BillPdfData data, int page, int pages) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page $page of $pages · ${data.brandName}',
        style: pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  static DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _fmtDate(Object? value) {
    final d = _asDate(value);
    return d != null ? formatDate(d) : '—';
  }

  static num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
