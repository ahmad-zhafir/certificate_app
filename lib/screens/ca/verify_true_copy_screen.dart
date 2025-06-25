import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:certify_me/certify_me.dart';

class VerifyTrueCopyRequestScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const VerifyTrueCopyRequestScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<VerifyTrueCopyRequestScreen> createState() => _VerifyTrueCopyRequestScreenState();
}

class _VerifyTrueCopyRequestScreenState extends State<VerifyTrueCopyRequestScreen> {
  bool _isProcessing = false;

  Future<void> _approve(BuildContext context) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser!;
      final caDoc = await firestore.collection('users').doc(currentUser.uid).get();
      final org = caDoc['organization'] ?? 'UPM';
      final caName = caDoc['name'] ?? currentUser.displayName ?? 'Certificate Authority';
      final verifiedByLine = 'Verified by $caName ($org)';

      final fileUrl = widget.requestData['fileUrl'];
      final fileName = widget.requestData['fileName'] ?? 'uploaded_file';
      final fileExt = p.extension(fileName).toLowerCase();
      final certId = CertificateGenerator.generateCertificateId();
      final now = DateTime.now();
      final formattedDate = DateFormat('MMMM d, y').format(now);

      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/$fileName';
      final file = File(localPath);

      final bytes = await FirebaseStorage.instance.refFromURL(fileUrl).getData();
      await file.writeAsBytes(bytes!);

      final PdfDocument document;

      if (fileExt == '.pdf') {
        document = PdfDocument(inputBytes: file.readAsBytesSync());
        final page = document.pages[0];
        final graphics = page.graphics;
        final bounds = Rect.fromLTWH(10.0, 10.0, page.size.width - 20.0, 100.0);

        graphics.drawString(
          'Certified True Copy\n$verifiedByLine\nCertified on: $formattedDate\nCertificate ID: $certId',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: bounds,
          brush: PdfBrushes.red,
        );
      } else {
        document = PdfDocument();
        final page = document.pages.add();
        final imageBytes = file.readAsBytesSync();
        final image = PdfBitmap(imageBytes);

        final pageSize = page.getClientSize();
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();
        final imageSize = Size(imageWidth, imageHeight);

        final maxImageHeight = pageSize.height - 120.0;
        final widthScale = pageSize.width / imageSize.width;
        final heightScale = maxImageHeight / imageSize.height;
        final scale = widthScale < heightScale ? widthScale : heightScale;

        final scaledWidth = imageSize.width * scale;
        final scaledHeight = imageSize.height * scale;
        final imageX = (pageSize.width - scaledWidth) / 2.0;
        final imageY = 70.0;

        page.graphics.drawImage(
          image,
          Rect.fromLTWH(imageX, imageY, scaledWidth, scaledHeight),
        );

        page.graphics.drawString(
          'Certified True Copy\n$verifiedByLine\nCertified on: $formattedDate\n$certId',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(10.0, 10.0, pageSize.width - 20.0, 60.0),
          brush: PdfBrushes.red,
        );
      }

      final pdfBytes = await document.save();
      document.dispose();

      final pdfPath = '${tempDir.path}/$certId.pdf';
      final pdfFile = File(pdfPath)..writeAsBytesSync(pdfBytes);

      final ref = FirebaseStorage.instance.ref().child('certificates/$certId.pdf');
      await ref.putFile(pdfFile);
      final url = await ref.getDownloadURL();

      await firestore.collection('certificates').add({
        'recipientName': widget.requestData['recipientName'] ?? widget.requestData['extractedName'],
        'recipientEmail': widget.requestData['recipientEmail'],
        'certificateId': certId,
        'issuerName': currentUser.displayName ?? 'Certificate Authority',
        'issuerTitle': org,
        'courseTitle': widget.requestData['title'] ?? widget.requestData['extractedTitle'],
        'description': 'Certified True Copy',
        'issueDate': now.toIso8601String(),
        'url': url,
        'fromTrueCopy': true,
        'requestId': widget.requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('true_copy_requests').doc(widget.requestId).update({
        'status': 'approved',
        'certId': certId,
        'approvedAt': FieldValue.serverTimestamp(),
        'fileUrl': url,
      });

      await firestore.collection('logs').add({
        'action': 'Approved True Copy Request',
        'performedBy': currentUser.email,
        'performedByName': caDoc['name'] ?? currentUser.displayName ?? 'CA',
        'role': 'Certificate Authority',
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request approved successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Approve error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to approve request: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final caDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      await FirebaseFirestore.instance.collection('true_copy_requests').doc(widget.requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('logs').add({
        'action': 'Rejected True Copy Request',
        'performedBy': currentUser.email,
        'performedByName': caDoc['name'] ?? currentUser.displayName ?? 'CA',
        'role': 'Certificate Authority',
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request rejected.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Reject error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to reject request: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.requestData['fileUrl'];
    final fileName = widget.requestData['fileName'] ?? '';
    final status = widget.requestData['status'] ?? 'pending';
    final ext = p.extension(fileName).toLowerCase();

    final isImage = ['.png', '.jpg', '.jpeg'].contains(ext);
    final isPdf = ext == '.pdf' || status == 'approved';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Review True Copy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (fileUrl != null) ...[
              const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              (status != 'approved' && isImage)
                  ? Image.network(fileUrl, height: 300, fit: BoxFit.contain)
                  : ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("View PDF"),
                onPressed: () {
                  Navigator.pushNamed(context, '/pdf-preview', arguments: fileUrl);
                },
              ),
              const SizedBox(height: 20),
            ],
            Text("Name: ${widget.requestData['recipientName'] ?? widget.requestData['extractedName'] ?? '-'}",
                style: const TextStyle(fontSize: 16)),
            Text("Title: ${widget.requestData['title'] ?? widget.requestData['extractedTitle'] ?? '-'}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            if (status != 'approved') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isProcessing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.check),
                      onPressed: _isProcessing ? null : () => _approve(context),
                      label: Text(_isProcessing ? "Processing..." : "Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isProcessing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.close),
                      onPressed: _isProcessing ? null : () => _reject(context),
                      label: Text(_isProcessing ? "Processing..." : "Reject"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing ? Colors.grey : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
