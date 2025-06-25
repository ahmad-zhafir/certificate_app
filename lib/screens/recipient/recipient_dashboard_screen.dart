import 'package:certificate_gen/screens/pdf_preview_screen.dart';
import 'package:certificate_gen/utils/share_token.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipientDashboardScreen extends StatelessWidget {
  const RecipientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[700],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'My Certificates',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Text("You are not logged in."),
        ),
      );
    }

    final certStream = FirebaseFirestore.instance
        .collection('certificates')
        .where('recipientEmail', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Certificates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        color: Colors.blueGrey[50], // ✅ Soft background added
        child: StreamBuilder<QuerySnapshot>(
          stream: certStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No certificates found.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            final certs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: certs.length,
              itemBuilder: (context, index) {
                final cert = certs[index].data() as Map<String, dynamic>;

                final isTrueCopy = cert['fromTrueCopy'] == true;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Icon(
                      isTrueCopy ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                      color: isTrueCopy ? Colors.green : Colors.blueAccent,
                      size: 32,
                    ),
                    title: Text(
                      cert['courseTitle'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      (isTrueCopy ? "Certified by: " : "Issued by: ") +
                          (cert['issuerName'] ?? 'Unknown'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'preview') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPreviewScreen(url: cert['url']),
                            ),
                          );
                        } else if (value == 'share') {
                          _copyToClipboard(context, cert['url']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'preview', child: Text('Preview')),
                        const PopupMenuItem(value: 'share', child: Text('Copy Share Link')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }



  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Share link copied to clipboard")),
    );
  }

  void _downloadCertificate(String url) async {
    final uri = Uri.parse(Uri.decodeFull(url));

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView); // 💡 This avoids intent fallback
    } else {
      print("Could not launch $url");
    }
  }

  void _generateShareToken(BuildContext context, String certificateId, String url, String recipientEmail) async {
    final token = generateShareToken();

    await FirebaseFirestore.instance.collection('shared_certificates').doc(token).set({
      'token': token,
      'certificateId': certificateId,
      'certUrl': url,
      'recipientEmail': recipientEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Shareable Link"),
        content: SelectableText("https://yourapp.com/share/$token"),
        actions: [
          TextButton(
            child: Text("Copy"),
            onPressed: () {
              // Optionally use Clipboard.setData to copy
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

}