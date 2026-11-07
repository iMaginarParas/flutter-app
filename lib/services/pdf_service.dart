import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/client.dart';

class PdfService {
  Future<File> generateInvoicePdf({
    required Payment payment,
    required String merchantName,
    required String merchantEmail,
    Client? client,
    ClientMilestone? milestone,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo/brand
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6C5CE7'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '#${payment.paymentId.substring(0, 12).toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white.shade(0.7),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          merchantName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          merchantEmail,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white.shade(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Invoice Details Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Bill To
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#636E72'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        if (client != null) ...[
                          pw.Text(
                            client.name,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            client.email,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          if (client.phone != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              client.phone!,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                          if (client.walletAddress != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Wallet: ${client.walletAddress!.substring(0, 20)}...',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColor.fromHex('#636E72'),
                              ),
                            ),
                          ],
                        ] else ...[
                          pw.Text(
                            'Customer',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Invoice Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRow('Invoice Date:', dateFormat.format(payment.createdAt)),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Invoice Time:', timeFormat.format(payment.createdAt)),
                      if (payment.expiresAt != null) ...[
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Due Date:', dateFormat.format(payment.expiresAt!)),
                      ],
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Status:', payment.status.toUpperCase(),
                          statusColor: _getStatusColor(payment.status)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Line Items Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#DFE6E9')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#DFE6E9')),
                  ),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F6FA'),
                      ),
                      children: [
                        _buildTableHeader('DESCRIPTION'),
                        _buildTableHeader('AMOUNT', align: pw.TextAlign.right),
                      ],
                    ),
                    // Item
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                payment.description ?? 'Payment',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (milestone != null) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Milestone: ${milestone.title}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColor.fromHex('#636E72'),
                                  ),
                                ),
                              ],
                              if (payment.orderId != null) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Order ID: ${payment.orderId}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColor.fromHex('#636E72'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            '\$${payment.amount} ${payment.currency}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Total Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F5F6FA'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        _buildTotalRow('Subtotal:', '\$${payment.amount}'),
                        pw.Divider(color: PdfColor.fromHex('#DFE6E9')),
                        _buildTotalRow(
                          'TOTAL DUE:',
                          '\$${payment.amount} ${payment.currency}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Payment Instructions
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF5E6'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColor.fromHex('#FDCB6E')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT INSTRUCTIONS',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2D3436'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Please use the following link to complete your payment:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#636E72'),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      payment.checkoutUrl ?? 'N/A',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromHex('#0984E3'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Payment ID: ${payment.paymentId}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromHex('#636E72'),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColor.fromHex('#DFE6E9')),
                  ),
                ),
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for your business!',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated by PayLink - Crypto Payment Platform',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#636E72'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${payment.paymentId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildInfoRow(String label, String value, {PdfColor? statusColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#636E72'),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: statusColor ?? PdfColor.fromHex('#2D3436'),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#2D3436'),
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 11,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromHex('#2D3436'),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 11,
              fontWeight: pw.FontWeight.bold,
              color: isTotal ? PdfColor.fromHex('#6C5CE7') : PdfColor.fromHex('#2D3436'),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return PdfColor.fromHex('#00D4AA');
      case 'pending':
      case 'created':
        return PdfColor.fromHex('#FDCB6E');
      case 'failed':
        return PdfColor.fromHex('#FF7675');
      case 'expired':
        return PdfColor.fromHex('#B2BEC3');
      default:
        return PdfColor.fromHex('#636E72');
    }
  }
}
