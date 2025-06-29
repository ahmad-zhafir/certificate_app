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


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SystemLogsAndStatsScreen extends StatefulWidget {
  const SystemLogsAndStatsScreen({super.key});

  @override
  State<SystemLogsAndStatsScreen> createState() => _SystemLogsAndStatsScreenState();
}

class _SystemLogsAndStatsScreenState extends State<SystemLogsAndStatsScreen> {
  String selectedRole = 'All';
  String? selectedUserId;
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsersByRole();
  }

  Future<void> fetchUsersByRole() async {
    if (selectedRole == 'All') {
      setState(() {
        filteredUsers = [];
        selectedUserId = null;
      });
      return;
    }

    setState(() => isLoading = true);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: selectedRole)
        .get();

    setState(() {
      filteredUsers = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unnamed',
          'email': data['email'] ?? '',
        };
      }).toList();
      selectedUserId = null;
      isLoading = false;
    });
  }

  Stream<QuerySnapshot> getLogStream() {
    var ref = FirebaseFirestore.instance.collection('logs').orderBy('timestamp', descending: true);

    if (selectedUserId != null) {
      // Filter by specific user
      return ref.where('userId', isEqualTo: selectedUserId).snapshots();
    } else if (selectedRole != 'All') {
      // Filter by role only
      return ref.where('role', isEqualTo: selectedRole).snapshots();
    } else {
      // No filters
      return ref.snapshots();
    }
  }


  Widget buildLogTable(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text("No logs found."));
    }

    final logs = snapshot.data!.docs;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text("Time")),
            DataColumn(label: Text("User")),
            DataColumn(label: Text("Action")),
            DataColumn(label: Text("Role")),
          ],
          rows: logs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final userDisplay = data['performedByName'] ?? data['performedBy'] ?? 'Unknown';

            return DataRow(cells: [
              DataCell(Text(timestamp != null ? "${timestamp.toLocal()}" : '')),
              DataCell(Text(userDisplay)),
              DataCell(Text(data['action'] ?? '')),
              DataCell(Text(data['role'] ?? '')),
            ]);
          }).toList(),
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // ← makes back button white
        title: const Text(
          "System Logs",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),


      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedRole,
                    borderRadius: BorderRadius.circular(8),
                    items: ['All', 'Certificate Authority', 'Client', 'Recipient']
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedRole = val!;
                        selectedUserId = null;
                      });
                      fetchUsersByRole();
                    },
                  ),
                  if (selectedRole != 'All' && filteredUsers.isNotEmpty)
                    DropdownButton<String>(
                      value: selectedUserId,
                      hint: const Text("Select User"),
                      borderRadius: BorderRadius.circular(8),
                      items: filteredUsers.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['uid'],
                          child: Text(user['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedUserId = val);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logs Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getLogStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return buildLogTable(snapshot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}