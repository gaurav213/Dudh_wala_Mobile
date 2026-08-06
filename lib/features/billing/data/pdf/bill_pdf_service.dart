import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/formatters/indian_formatters.dart';

class BillPdfService {
  Future<Uint8List> buildPdf({
    required Map<String, Object?> bill,
    required Map<String, Object?> customer,
    required List<Map<String, Object?>> items,
    String supplierName = 'Doodh Khata',
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            supplierName,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Milk bill'),
          pw.SizedBox(height: 16),
          pw.Text('Bill no: ${bill['bill_number']}'),
          pw.Text('Customer: ${customer['name']}'),
          pw.Text('Phone: ${customer['phone']}'),
          pw.Text(
            'Period: ${formatDate(bill['period_start'] as DateTime)} – ${formatDate(bill['period_end'] as DateTime)}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Qty', 'Rate', 'Amount'],
            data: [
              for (final item in items)
                [
                  formatDate(item['item_date'] as DateTime),
                  item['description'],
                  formatLitres(item['quantity_litres'] as num),
                  formatRupees(item['rate_per_litre'] as num),
                  formatRupees(item['amount'] as num),
                ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${formatRupees(bill['subtotal'] as num)}'),
                pw.Text('Adjustments: ${formatRupees(bill['adjustments'] as num)}'),
                pw.Text(
                  'Total: ${formatRupees(bill['total'] as num)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Paid: ${formatRupees(bill['paid_amount'] as num)}'),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareBillPdf({
    required Map<String, Object?> bill,
    required Map<String, Object?> customer,
    required List<Map<String, Object?>> items,
    String supplierName = 'Doodh Khata',
  }) async {
    final bytes = await buildPdf(
      bill: bill,
      customer: customer,
      items: items,
      supplierName: supplierName,
    );
    final name = 'bill_${bill['bill_number']}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  Future<void> shareViaSharePlus({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'application/pdf', name: filename),
    ], text: 'Doodh Khata bill');
  }
}
