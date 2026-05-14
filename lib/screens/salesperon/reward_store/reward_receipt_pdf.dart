import 'package:flutter/services.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RewardReceiptPdf {
  RewardReceiptPdf._();

  static const _brand      = 'LafargeHolcim — SalesQuest';
  static final _rankLabels = {1: '1st Place ${AppEmojis.gold}', 2: '2nd Place ${AppEmojis.silver}', 3: '3rd Place ${AppEmojis.bronze}'};

  static String _fmtMoney(double amount) {
    if (amount == amount.truncateToDouble()) return '${amount.toInt()} MAD';
    return '$amount MAD';
  }

  static Future<void> share({
    required String   userName,
    required int      rank,
    required double   rewardAmount,
    required DateTime closedAt,
    required String   userId,
  }) async {
    final doc = await _build(
      userName:     userName,
      rank:         rank,
      rewardAmount: rewardAmount,
      closedAt:     closedAt,
      userId:       userId,
    );

    await Printing.sharePdf(
      bytes:    await doc.save(),
      filename: 'reward_receipt_${userName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<pw.Document> _build({
    required String   userName,
    required int      rank,
    required double   rewardAmount,
    required DateTime closedAt,
    required String   userId,
  }) async {
    final doc  = pw.Document();
    final logo = await _loadLogo();

    final receiptId =
        '${userId.substring(0, 6).toUpperCase()}-'
        '${closedAt.year}${_pad(closedAt.month)}${_pad(closedAt.day)}';

    final eventDate =
        '${_pad(closedAt.day)}/${_pad(closedAt.month)}/${closedAt.year}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(40),
        build:      (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logo != null)
                  pw.Image(logo, width: 64, height: 64)
                else
                  pw.SizedBox(width: 64),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _brand,
                      style: pw.TextStyle(
                        fontSize:   13,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfColor.fromHex('#5B8E27'),
                      ),
                    ),
                    pw.Text(
                      'Reward Receipt',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color:    PdfColor.fromHex('#666666'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColor.fromHex('#5B8E27'), thickness: 2),
            pw.SizedBox(height: 20),

            // ── Title ───────────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'PRIZE RECEIPT',
                style: pw.TextStyle(
                  fontSize:      24,
                  fontWeight:    pw.FontWeight.bold,
                  color:         PdfColor.fromHex('#1A1A1A'),
                  letterSpacing: 2,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Receipt #$receiptId',
                style: pw.TextStyle(
                  fontSize: 11,
                  color:    PdfColor.fromHex('#888888'),
                ),
              ),
            ),

            pw.SizedBox(height: 32),

            // ── Details table ───────────────────────────────────────────────
            _row('Winner',     userName),
            _dividerLine(),
            _row('Rank',       _rankLabels[rank] ?? 'Rank $rank'),
            _dividerLine(),
            _row('Cash Prize', _fmtMoney(rewardAmount)),
            _dividerLine(),
            _row('Event Date', eventDate),

            pw.SizedBox(height: 40),

            // ── Footer ──────────────────────────────────────────────────────
            pw.Container(
              width:   double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color:        PdfColor.fromHex('#F5F5F5'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border:       pw.Border.all(color: PdfColor.fromHex('#DDDDDD')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Present this receipt to your market manager to claim your cash prize.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize:   11,
                      fontWeight: pw.FontWeight.bold,
                      color:      PdfColor.fromHex('#333333'),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'This receipt is valid only for the named winner above.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color:    PdfColor.fromHex('#888888'),
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Page bottom ─────────────────────────────────────────────────
            pw.Divider(color: PdfColor.fromHex('#DDDDDD')),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _brand,
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColor.fromHex('#AAAAAA')),
                ),
                pw.Text(
                  'Generated $eventDate',
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColor.fromHex('#AAAAAA')),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize:   11,
                fontWeight: pw.FontWeight.bold,
                color:      PdfColor.fromHex('#555555'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dividerLine() =>
      pw.Divider(color: PdfColor.fromHex('#EEEEEE'), thickness: 0.5);

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/app_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
