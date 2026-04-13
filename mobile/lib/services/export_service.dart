import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {

  // ── Formater les événements ─────────────────────────────────────────────
  static String _formatDate(String? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(dt).toLocal());
  }

  static String _formatTime(String? dt) {
    if (dt == null) return '-';
    return DateFormat('HH:mm').format(DateTime.parse(dt).toLocal());
  }

  // ── Export PDF ──────────────────────────────────────────────────────────
  static Future<void> exportPDF(List<dynamic> events, BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'AGENDA PERSONNEL',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Exporté le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            '${events.length} événement(s)',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Titre', 'Date', 'Début', 'Fin', 'Lieu'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(6),
            data: events.map((e) => [
              e['title'] ?? '',
              _formatDate(e['start_at']),
              _formatTime(e['start_at']),
              e['end_at'] != null ? _formatTime(e['end_at']) : '-',
              e['location'] ?? '-',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'agenda-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  // ── Export Emploi du temps PDF ──────────────────────────────────────────
  static Future<void> exportEmploiDuTempsPDF(
    List<dynamic> events,
    DateTime weekStart,
  ) async {
    final pdf  = pw.Document();
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final hours = List.generate(14, (i) => i + 7); // 7h → 20h

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EMPLOI DU TEMPS — Semaine du ${DateFormat('d MMMM yyyy').format(weekStart)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  for (int i = 1; i <= 7; i++)
                    i: const pw.FlexColumnWidth(),
                },
                children: [
                  // En-tête
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue700),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('H', style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        )),
                      ),
                      ...days.map((d) => pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          DateFormat('EEE\nd/MM').format(d),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      )),
                    ],
                  ),
                  // Lignes horaires
                  ...hours.map((hour) {
                    return pw.TableRow(
                      decoration: hours.indexOf(hour) % 2 == 0
                        ? const pw.BoxDecoration(color: PdfColors.blue50)
                        : null,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            '${hour.toString().padLeft(2,'0')}h',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        ...days.map((day) {
                          final dayEvents = events.where((e) {
                            final d = DateTime.parse(e['start_at']).toLocal();
                            return d.year == day.year &&
                                   d.month == day.month &&
                                   d.day == day.day &&
                                   d.hour == hour;
                          }).toList();
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: dayEvents.map((e) => pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 2),
                                padding: const pw.EdgeInsets.all(2),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.blue200,
                                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                                child: pw.Text(
                                  e['title'] ?? '',
                                  style: const pw.TextStyle(fontSize: 6),
                                ),
                              )).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'emploi-du-temps-${DateFormat('yyyy-MM-dd').format(weekStart)}.pdf',
    );
  }

  // ── Export Excel ────────────────────────────────────────────────────────
  static Future<void> exportExcel(List<dynamic> events) async {
    final excel = Excel.createExcel();
    final sheet = excel['Événements'];

    // En-tête
    final headers = ['Titre', 'Date', 'Heure début', 'Heure fin', 'Lieu', 'Description'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i]);
    }

    // Données
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      final row = [
        e['title']       ?? '',
        _formatDate(e['start_at']),
        _formatTime(e['start_at']),
        e['end_at'] != null ? _formatTime(e['end_at']) : '-',
        e['location']    ?? '-',
        e['description'] ?? '-',
      ];
      for (int j = 0; j < row.length; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
          ..value = TextCellValue(row[j]);
      }
    }

    final dir      = await getTemporaryDirectory();
    final fileName = 'agenda-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Mon agenda exporté');
  }

  // ── Export CSV ──────────────────────────────────────────────────────────
  static Future<void> exportCSV(List<dynamic> events) async {
    final headers = 'Titre,Date,Heure début,Heure fin,Lieu,Description\n';
    final rows = events.map((e) =>
      '"${e['title'] ?? ''}","${_formatDate(e['start_at'])}","${_formatTime(e['start_at'])}",'
      '"${e['end_at'] != null ? _formatTime(e['end_at']) : '-'}","${e['location'] ?? '-'}","${e['description'] ?? '-'}"'
    ).join('\n');

    final dir      = await getTemporaryDirectory();
    final fileName = 'agenda-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsString('\uFEFF$headers$rows');
    await Share.shareXFiles([XFile(file.path)], text: 'Mon agenda exporté');
  }
}