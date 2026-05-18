import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'resume_data.dart';

Future<Uint8List> generateResumePdf(Resume resume) async {
  final pdf = pw.Document();

  // Load embedded font from assets to make typography identical across platforms
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);

  // Styles matching on-screen sizes
  final nameStyle = pw.TextStyle(
    font: ttf,
    fontSize: 42,
    fontWeight: pw.FontWeight.bold,
  );
  final headerStyle = pw.TextStyle(
    font: ttf,
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
  );
  final subHeaderStyle = pw.TextStyle(
    font: ttf,
    fontSize: 20,
    fontWeight: pw.FontWeight.normal,
  );
  final bodyStyle = pw.TextStyle(font: ttf, fontSize: 13);
  final smallStyle = pw.TextStyle(font: ttf, fontSize: 11);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      footer: (context) {
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: smallStyle,
          ),
        );
      },
      build: (context) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(resume.name, style: nameStyle),
            pw.SizedBox(height: 6),
            pw.Text(resume.headline, style: headerStyle),
            pw.Text(resume.subHeadline, style: subHeaderStyle),
            pw.SizedBox(height: 8),
            pw.Text(resume.contactLine, style: smallStyle),
            pw.SizedBox(height: 12),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 12),

            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),
            pw.Text(
              resume.summary,
              style: bodyStyle,
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'TECHNICAL SKILLS',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),
            ...resume.skills.map(
              (s) => pw.Row(
                children: [
                  pw.Text('- ', style: bodyStyle),
                  pw.Expanded(child: pw.Text(s, style: bodyStyle)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'PROJECTS/INTERNSHIPS',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),
            ...resume.projects.expand((p) sync* {
              yield pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      p.title,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(p.date, style: smallStyle),
                ],
              );
              if (p.subTitle != null) {
                yield pw.Text(p.subTitle!, style: smallStyle);
              }
              for (var b in p.bullets) {
                yield pw.Row(
                  children: [
                    pw.Text('- ', style: bodyStyle),
                    pw.Expanded(child: pw.Text(b, style: bodyStyle)),
                  ],
                );
              }
              yield pw.SizedBox(height: 6);
            }),

            pw.Text(
              'EDUCATION',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),
            ...resume.education.expand((e) sync* {
              yield pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      e.title,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(e.date, style: smallStyle),
                ],
              );
              if (e.subTitle != null) {
                yield pw.Text(e.subTitle!, style: smallStyle);
              }
              for (var b in e.bullets) {
                yield pw.Row(
                  children: [
                    pw.Text('- ', style: bodyStyle),
                    pw.Expanded(child: pw.Text(b, style: bodyStyle)),
                  ],
                );
              }
              yield pw.SizedBox(height: 6);
            }),

            pw.Text(
              'ADDITIONAL INFORMATION',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),
            ...resume.additional.map(
              (a) => pw.Row(
                children: [
                  pw.Text('- ', style: bodyStyle),
                  pw.Expanded(child: pw.Text(a, style: bodyStyle)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}
