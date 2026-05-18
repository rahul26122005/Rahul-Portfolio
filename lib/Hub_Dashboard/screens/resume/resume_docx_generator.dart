import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'resume_data.dart';

Uint8List generateResumeDocx(
  Resume resume, {
  int nameFontSize = 42,
  int headlineFontSize = 20,
  int subHeadlineFontSize = 20,
  int contactFontSize = 13,
  int sectionHeaderFontSize = 16,
  int itemTitleFontSize = 14,
  int itemDateFontSize = 13,
  int itemSubTitleFontSize = 13,
  int bodyFontSize = 13,
}) {
  String escape(String s) => const HtmlEscape().convert(s);

  String fontSizeAttribute(int size) =>
      '<w:sz w:val="${size * 2}"/><w:szCs w:val="${size * 2}"/>';

  String runBold(String text, {int size = 22}) =>
      '<w:r><w:rPr><w:b/>${fontSizeAttribute(size)}</w:rPr><w:t xml:space="preserve">${escape(text)}</w:t></w:r>';

  String runNormal(String text, {int size = 22}) =>
      '<w:r><w:rPr>${fontSizeAttribute(size)}</w:rPr><w:t xml:space="preserve">${escape(text)}</w:t></w:r>';

  String paragraphWithRuns(List<String> runs, {bool divider = false}) {
    final runsXml = runs.join();
    final border = divider
        ? '<w:pPr><w:pBdr><w:bottom w:val="single" w:sz="4" w:color="000000"/></w:pBdr></w:pPr>'
        : '';
    return '<w:p>$border$runsXml</w:p>';
  }

  final content = StringBuffer();
  content.writeln(
    paragraphWithRuns([runBold(resume.name, size: nameFontSize)]),
  );
  content.writeln(
    paragraphWithRuns([runBold(resume.headline, size: headlineFontSize)]),
  );
  content.writeln(
    paragraphWithRuns([runBold(resume.subHeadline, size: subHeadlineFontSize)]),
  );
  content.writeln(
    paragraphWithRuns([
      runNormal(resume.contactLine, size: contactFontSize),
    ], divider: true),
  );
  content.writeln(
    paragraphWithRuns([
      runBold('SUMMARY', size: sectionHeaderFontSize),
    ], divider: true),
  );
  content.writeln(
    paragraphWithRuns([runNormal(resume.summary, size: bodyFontSize)]),
  );
  content.writeln(
    paragraphWithRuns([
      runBold('TECHNICAL SKILLS', size: sectionHeaderFontSize),
    ], divider: true),
  );
  for (var s in resume.skills) {
    content.writeln(paragraphWithRuns([runNormal('- $s', size: bodyFontSize)]));
  }
  content.writeln(
    paragraphWithRuns([
      runBold('PROJECTS/INTERNSHIPS', size: sectionHeaderFontSize),
    ], divider: true),
  );
  for (var p in resume.projects) {
    content.writeln(
      paragraphWithRuns([
        runBold(p.title, size: itemTitleFontSize),
        runNormal('   ${p.date}', size: itemDateFontSize),
      ]),
    );
    if (p.subTitle != null) {
      content.writeln(
        paragraphWithRuns([runNormal(p.subTitle!, size: itemSubTitleFontSize)]),
      );
    }
    for (var b in p.bullets) {
      content.writeln(
        paragraphWithRuns([runNormal('- $b', size: bodyFontSize)]),
      );
    }
  }
  content.writeln(
    paragraphWithRuns([
      runBold('EDUCATION', size: sectionHeaderFontSize),
    ], divider: true),
  );
  for (var e in resume.education) {
    content.writeln(
      paragraphWithRuns([
        runBold(e.title, size: itemTitleFontSize),
        runNormal('   ${e.date}', size: itemDateFontSize),
      ]),
    );
    if (e.subTitle != null) {
      content.writeln(
        paragraphWithRuns([runNormal(e.subTitle!, size: itemSubTitleFontSize)]),
      );
    }
    for (var b in e.bullets) {
      content.writeln(
        paragraphWithRuns([runNormal('- $b', size: bodyFontSize)]),
      );
    }
  }
  content.writeln(
    paragraphWithRuns([
      runBold('ADDITIONAL INFORMATION', size: sectionHeaderFontSize),
    ], divider: true),
  );
  for (var a in resume.additional) {
    content.writeln(paragraphWithRuns([runNormal('- $a', size: bodyFontSize)]));
  }

  final documentXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    ${content.toString()}
    <w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr>
  </w:body>
</w:document>''';

  final archive = Archive();

  void addText(String path, String data) {
    final bytes = utf8.encode(data);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  addText(
    '[Content_Types].xml',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
  );
  addText(
    '_rels/.rels',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
  );
  addText(
    'word/_rels/document.xml.rels',
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''',
  );
  addText('word/document.xml', documentXml);

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
