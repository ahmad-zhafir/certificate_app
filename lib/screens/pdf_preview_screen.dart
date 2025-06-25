import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PdfPreviewScreen extends StatefulWidget {
  final String url;

  const PdfPreviewScreen({super.key, required this.url});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    final response = await http.get(Uri.parse(widget.url));
    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File(path.join(dir.path, "preview.pdf"));
    await file.writeAsBytes(bytes);

    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Certificates Preview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: localPath == null
          ? Center(child: CircularProgressIndicator())
          : PDFView(filePath: localPath!),
    );
  }
}