import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:certify_me/certify_me.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';


class PreviewAndGenerateScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final String requestId;

  const PreviewAndGenerateScreen({
    super.key,
    required this.request,
    required this.requestId,
  });

  @override
  State<PreviewAndGenerateScreen> createState() => _PreviewAndGenerateScreenState();
}

class _PreviewAndGenerateScreenState extends State<PreviewAndGenerateScreen> {
  CertificateTemplate? selectedTemplate;
  String? selectedTemplateKey;
  List<CertificateData> allCertData = [];
  bool isGenerating = false;

  final List<GlobalKey> previewKeys = [];

  @override
  void initState() {
    super.initState();
    _buildAllCertificates();
  }

  Future<void> _buildAllCertificates() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final caOrg = userDoc['organization'] ?? "UPM Organization";
    final issuerName = currentUser.displayName ?? "Certificate Authority";

    final recipients = widget.request['recipients'] as List;

    setState(() {
      allCertData = recipients.map((r) {
        return CertificateData(
          recipientName: r['name'],
          courseTitle: widget.request['courseTitle'],
          description: widget.request['description'],
          issueDate: DateTime.now(),
          issuerName: issuerName,
          issuerTitle: caOrg,
          certificateId: CertificateGenerator.generateCertificateId(),
        );
      }).toList();
      previewKeys.addAll(List.generate(recipients.length, (_) => GlobalKey()));
    });
  }

  Future<void> _generateAllCertificates() async {
    if (selectedTemplate == null || allCertData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a template first")));
      return;
    }

    setState(() => isGenerating = true);

    try {
      final recipients = widget.request['recipients'] as List;

      for (int i = 0; i < allCertData.length; i++) {
        final certData = allCertData[i];
        final key = previewKeys[i];

        // Wait for widget to stabilize
        await Future.delayed(Duration(milliseconds: 500));

        final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // ✅ Convert to real PDF using `pdf` package
        final pdf = pw.Document();
        final imageProvider = pw.MemoryImage(pngBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => pw.Center(child: pw.Image(imageProvider)),
          ),
        );

        final outputDir = await getTemporaryDirectory();
        final pdfPath = p.join(outputDir.path, "${certData.certificateId}.pdf");
        final file = File(pdfPath);
        await file.writeAsBytes(await pdf.save());

        // Upload to Firebase
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates/${certData.certificateId}.pdf');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('certificates').add({
          'recipientName': certData.recipientName,
          'recipientEmail': recipients[i]['email'],
          'certificateId': certData.certificateId,
          'issuerName': certData.issuerName,
          'issuerTitle': certData.issuerTitle,
          'courseTitle': certData.courseTitle,
          'description': certData.description,
          'issueDate': certData.issueDate.toIso8601String(),
          'url': url,
          'requestId': widget.requestId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('certificate_requests')
          .doc(widget.requestId)
          .update({'status': 'completed'});

      final currentUser = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final name = userDoc['name'] ?? currentUser.email;

      await FirebaseFirestore.instance.collection('logs').add({
        'action': 'Generated Certificates',
        'performedBy': currentUser.email,
        'performedByName': name, // ✅ Add this
        'role': 'Certificate Authority',
        'userId': currentUser.uid,
        'requestId': widget.requestId,
        'count': allCertData.length,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("All certificates generated.")));
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    } catch (e) {
      print("Generation error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to generate some certificates.")));
    } finally {
      setState(() => isGenerating = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final previews = {
      "Elegant": CertificateTemplate.elegant(),
      "Modern": CertificateTemplate.modern(),
      "Minimalist": CertificateTemplate.minimalist(),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Preview & Generate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select Certificate Theme"),
              value: selectedTemplateKey,
              items: previews.keys
                  .map((key) => DropdownMenuItem(value: key, child: Text(key)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedTemplateKey = val;
                  selectedTemplate = previews[val];
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: selectedTemplate == null || allCertData.isEmpty
                  ? Center(child: Text("Select a template to preview certificates"))
                  : ListView.builder(
                itemCount: allCertData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: RepaintBoundary(
                      key: previewKeys[index],
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.white,
                          child: CertificateGenerator(
                            data: allCertData[index],
                            template: selectedTemplate!,
                          ).buildPreview(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isGenerating ? null : _generateAllCertificates,
              icon: Icon(Icons.picture_as_pdf),
              label: isGenerating
                  ? Text("Generating...")
                  : Text("Generate All Certificates"),
            )
          ],
        ),
      ),
    );
  }
}
