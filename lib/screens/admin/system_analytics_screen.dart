import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  int totalCAs = 0;
  int totalClients = 0;
  int totalRecipients = 0;
  int totalRequests = 0;
  int totalCertificates = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final requestsSnap = await FirebaseFirestore.instance.collection('certificate_requests').get();
    final certsSnap = await FirebaseFirestore.instance.collection('certificates').get();

    int cas = 0, clients = 0, recipients = 0;

    for (var doc in usersSnap.docs) {
      final role = doc['role'] ?? '';
      if (role == 'Certificate Authority') cas++;
      else if (role == 'Client') clients++;
      else if (role == 'Recipient') recipients++;
    }

    setState(() {
      totalCAs = cas;
      totalClients = clients;
      totalRecipients = recipients;
      totalRequests = requestsSnap.size;
      totalCertificates = certsSnap.size;
      isLoading = false;
    });
  }

  Widget buildCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Icon(icon, size: 32, color: color)),
            const SizedBox(height: 8),
            Flexible(
              child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 6),
            Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      buildCard("Certificate Authorities", totalCAs, Icons.admin_panel_settings, Colors.blue),
      buildCard("Clients", totalClients, Icons.business, Colors.teal),
      buildCard("Recipients", totalRecipients, Icons.person, Colors.indigo),
      buildCard("Total Certificate Requests", totalRequests, Icons.request_page, Colors.orange),
      buildCard("Total Issued Certificates", totalCertificates, Icons.picture_as_pdf, Colors.green),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // ← makes back button white
        title: const Text(
          "System Analytics",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
      ),
    );
  }
}