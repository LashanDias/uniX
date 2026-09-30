import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

class RecruitmentDocument {
  const RecruitmentDocument(this.name, this.text);
  final String name;
  final String text;
}

class RecruitmentDocuments {
  static Future<RecruitmentDocument?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (files.isEmpty) return null;
    final file = files.single;
    if ((await file.length() ?? 0) > 5 * 1024 * 1024) {
      throw const FormatException('Choose a document smaller than 5 MB.');
    }
    final bytes = await file.readAsBytes();
    return RecruitmentDocument(file.name, await extract(file.name, bytes));
  }

  static Future<String> extract(String name, Uint8List bytes) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose a document smaller than 5 MB.');
    }
    String text;
    final extension = name.split('.').last.toLowerCase();
    if (extension == 'txt') {
      text = utf8.decode(bytes);
    } else if (extension == 'docx') {
      final archive = ZipDecoder().decodeBytes(bytes);
      final document = archive.findFile('word/document.xml');
      if (document == null || document.size > 2 * 1024 * 1024) {
        throw const FormatException(
          'This DOCX document cannot be read. Paste its text instead.',
        );
      }
      final xml = XmlDocument.parse(utf8.decode(document.content as List<int>));
      text = xml.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'p')
          .map(
            (paragraph) => paragraph.descendants
                .whereType<XmlElement>()
                .where((element) => element.name.local == 't')
                .map((element) => element.innerText)
                .join(),
          )
          .join('\n');
    } else if (extension == 'pdf') {
      await pdfrxFlutterInitialize();
      final document = await PdfDocument.openData(bytes);
      try {
        if (document.pages.length > 30) {
          throw const FormatException('Use a document with 30 pages or fewer.');
        }
        final buffer = StringBuffer();
        for (final page in document.pages) {
          final pageText = await page.loadText();
          buffer.writeln(pageText?.fullText ?? '');
        }
        text = buffer.toString();
      } finally {
        await document.dispose();
      }
    } else {
      throw const FormatException('Use a PDF, DOCX or UTF-8 TXT document.');
    }
    text = text.replaceAll('\u0000', '').trim();
    if (text.isEmpty) {
      throw const FormatException(
        'No readable text found. For scanned files, paste the document text below.',
      );
    }
    if (text.length > 100000) {
      throw const FormatException(
        'This document is too long. Use a shorter CV or requirements file.',
      );
    }
    return text;
  }
}
