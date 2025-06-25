import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class RecipientTrueCopyRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const RecipientTrueCopyRequestDetailScreen({super.key, required this.requestData});

  @override
  Widget build(BuildContext context) {
    final status = requestData['status'] ?? 'unknown';
    final title = requestData['title'] ?? '';
    final recipientName = requestData['recipientName'] ?? '';
    final fileUrl = requestData['fileUrl'];
    final fileName = requestData['fileName'] ?? '';
    final certId = requestData['certId'];
    final approvedAt = requestData['approvedAt'];
    final rejectedAt = requestData['rejectedAt'];
    final submittedAt = requestData['submittedAt'];

    String formatTimestamp(Timestamp? ts) {
      if (ts == null) return '-';
      final dt = ts.toDate();
      return DateFormat.yMMMd().add_jm().format(dt);
    }

    bool isPdf(String name) {
      return p.extension(name).toLowerCase() == '.pdf';
    }

    bool isImage(String name) {
      final ext = p.extension(name).toLowerCase();
      return ['.png', '.jpg', '.jpeg'].contains(ext);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text(
          "Request Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Certificate Title", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            Text("Recipient Name", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(recipientName, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
            Chip(
              label: Text(status.toUpperCase(), style: TextStyle(color: Colors.white)),
              backgroundColor: status == 'approved'
                  ? Colors.green
                  : status == 'rejected'
                  ? Colors.red
                  : Colors.orange,
            ),
            const SizedBox(height: 16),

            Text("Submitted At", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(formatTimestamp(submittedAt)),
            const SizedBox(height: 12),

            if (approvedAt != null) ...[
              Text("Approved At", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatTimestamp(approvedAt)),
              const SizedBox(height: 12),
            ],

            if (rejectedAt != null) ...[
              Text("Rejected At", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatTimestamp(rejectedAt)),
              const SizedBox(height: 12),
            ],

            if (certId != null) ...[
              Text("Certificate ID", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(certId, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
            ],

            if (fileUrl != null && status == 'pending') ...[
              const SizedBox(height: 16),
              Text("Preview", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (isImage(fileName))
                Image.network(fileUrl, height: 300, fit: BoxFit.contain)
              else if (isPdf(fileName))
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pdf-preview', arguments: fileUrl);
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("View PDF"),
                )
              else
                Text("Preview not supported for this file type."),
            ],

            if (fileUrl != null && status == 'approved') ...[
              const SizedBox(height: 16),
              Text("Certified Document", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/pdf-preview', arguments: fileUrl);
                },
                icon: Icon(Icons.picture_as_pdf),
                label: Text("View Certified PDF"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
