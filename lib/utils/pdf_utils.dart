import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<File> convertImageToPdf(File imageFile, String outputPath) async {
  final pdf = pw.Document();
  final image = pw.MemoryImage(await imageFile.readAsBytes());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Image(image),
      ),
    ),
  );

  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());
  return file;
}