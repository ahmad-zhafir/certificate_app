import 'package:certificate_gen/screens/pdf_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CaIssuedCertificatesScreen extends StatelessWidget {
  const CaIssuedCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(child: Text("User not logged in"));
    }

    final certStream = FirebaseFirestore.instance
        .collection('certificates')
        .where('issuerUid', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Issued Certificates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: certStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No certificates issued yet."));
          }

          // Group by requestId
          final grouped = <String, List<Map<String, dynamic>>>{};
          final courseDetails = <String, Map<String, dynamic>>{};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final requestId = data['requestId'] ?? 'unknown';

            if (!grouped.containsKey(requestId)) {
              grouped[requestId] = [];
            }

            grouped[requestId]!.add(data);

            // store course details for header (from first cert)
            courseDetails[requestId] = {
              'courseTitle': data['courseTitle'] ?? '',
              'description': data['description'] ?? '',
            };
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: grouped.entries.map((entry) {
              final requestId = entry.key;
              final certList = entry.value;
              final details = courseDetails[requestId]!;

              final hasTrueCopy = certList.any((c) => c['fromTrueCopy'] == true);
              final iconData = hasTrueCopy
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded;
              final iconColor = hasTrueCopy ? Colors.green : Colors.blueAccent;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT ICON like 'leading'
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 18),
                      child: Icon(
                        certList.any((c) => c['fromTrueCopy'] == true)
                            ? Icons.verified_rounded
                            : Icons.workspace_premium_rounded,
                        color: certList.any((c) => c['fromTrueCopy'] == true)
                            ? Colors.green
                            : Colors.blueAccent,
                        size: 32,
                      ),
                    ),

                    // RIGHT EXPANSION TILE (fills remaining space)
                    Expanded(
                      child: ExpansionTile(
                        title: Text(
                          details['courseTitle'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          details['description'] ?? '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        children: certList.map((cert) {
                          final isTrueCopy = cert['fromTrueCopy'] == true;
                          return ListTile(
                            title: Text(cert['recipientName'] ?? ''),
                            subtitle: Text(cert['recipientEmail'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.picture_as_pdf),
                              onPressed: () {
                                final url = cert['url'];
                                if (url != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfPreviewScreen(url: url),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),
          );
        },
      ),
    );
  }
}
