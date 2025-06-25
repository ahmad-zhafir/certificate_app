import 'package:flutter/material.dart';
import 'package:certificate_gen/screens/ca/preview_and_generate_screen.dart';

class CaRequestDetailScreen extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const CaRequestDetailScreen({
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
          'Review Certificate Request',
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

            Text("Recipients", style: TextStyle(fontWeight: FontWeight.bold)),
            ...recipients.map((r) => ListTile(
              title: Text(r['name'] ?? ''),
              subtitle: Text(r['email'] ?? ''),
            )),

            if (status != 'completed') ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Generate All Certificates"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviewAndGenerateScreen(
                        request: requestData,
                        requestId: requestId,
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              SizedBox(height: 24),
              Text("✅ Certificates already generated."),
            ],
          ],
        ),
      ),
    );
  }
}
