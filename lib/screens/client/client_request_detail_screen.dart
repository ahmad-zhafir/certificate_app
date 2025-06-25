import 'package:certificate_gen/screens/pdf_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class ClientRequestDetailScreen extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const ClientRequestDetailScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final recipients = requestData['recipients'] as List<dynamic>? ?? [];
    final status = requestData['status'] ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Requests Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
            children: [
              Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(requestData['courseTitle'] ?? '', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),

              Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(requestData['description'] ?? '', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),

              Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
              Chip(
                label: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: status == 'completed' ? Colors.green : Colors.orange,
              ),
              SizedBox(height: 24),

              if (status != 'completed') ...[
                Text("Recipients", style: TextStyle(fontWeight: FontWeight.bold)),
                ...recipients.map((r) => ListTile(
                  title: Text(r['name'] ?? ''),
                  subtitle: Text(r['email'] ?? ''),
                )),
              ],

              if (status == 'completed') ...[
                Text("Generated Certificates", style: TextStyle(fontWeight: FontWeight.bold)),
                _buildCertificateList(),
              ],
            ],
        ),
      ),
    );
  }

  Widget _buildCertificateList() {
    final certStream = FirebaseFirestore.instance
        .collection('certificates')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: certStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No certificates found."),
          );

        final certs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: certs.length,
          itemBuilder: (context, index) {
            final cert = certs[index].data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(cert['recipientName'] ?? ''),
                subtitle: Text(cert['recipientEmail'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.picture_as_pdf),
                  onPressed: () {
                    final url = cert['url'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(url: url),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
