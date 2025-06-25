import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestCertificateScreen extends StatefulWidget {
  @override
  _RequestCertificateScreenState createState() => _RequestCertificateScreenState();
}

class _RequestCertificateScreenState extends State<RequestCertificateScreen> {
  final _formKey = GlobalKey<FormState>();

  String courseTitle = '';
  String description = '';
  List<Map<String, String>> recipients = [
    {'name': '', 'email': ''}
  ];

  List<Map<String, dynamic>> caList = [];
  String? selectedCaUid;
  bool isLoadingCAs = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCAs();
  }

  Future<void> fetchCAs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Certificate Authority')
        .get();

    setState(() {
      caList = snapshot.docs.map((doc) => {
        'uid': doc.id,
        'name': doc['name'] ?? '',
        'organization': doc['organization'] ?? 'Unknown',
      }).toList();
      isLoadingCAs = false;
    });
  }

  void addRecipient() {
    setState(() {
      recipients.add({'name': '', 'email': ''});
    });
  }

  void removeRecipient(int index) {
    setState(() {
      recipients.removeAt(index);
    });
  }

  bool get isFormFilled {
    if (courseTitle.isEmpty || description.isEmpty || selectedCaUid == null) return false;
    for (var r in recipients) {
      if ((r['name'] ?? '').isEmpty || (r['email'] ?? '').isEmpty) return false;
    }
    return true;
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || selectedCaUid == null) return;

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection('certificate_requests').add({
      'courseTitle': courseTitle,
      'description': description,
      'recipients': recipients,
      'clientUid': currentUser.uid,
      'caUid': selectedCaUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final userName = userDoc['name'] ?? currentUser.email;

    await FirebaseFirestore.instance.collection('logs').add({
      'action': 'Submitted Certificate Request',
      'performedBy': currentUser.email,
      'performedByName': userName,
      'role': 'Client',
      'userId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request submitted!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Request Certificates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoadingCAs
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: ListView(
            children: [
              // Title
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.title),
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.blueGrey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => courseTitle = val,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.description),
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.blueGrey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => description = val,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // CA Dropdown
              DropdownButtonFormField<String>(
                value: selectedCaUid,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.account_circle),
                  labelText: 'Select Certificate Authority',
                  labelStyle: TextStyle(color: Colors.blueGrey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => setState(() => selectedCaUid = value),
                validator: (val) => val == null ? 'Please select a CA' : null,
                items: caList.map((ca) {
                  return DropdownMenuItem<String>(
                    value: ca['uid'],
                    child: Text('${ca['name']} - ${ca['organization']}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Text("Recipients",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
              const SizedBox(height: 8),

              ...recipients.asMap().entries.map((entry) {
                int index = entry.key;
                return Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: Colors.blueGrey[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => recipients[index]['name'] = val,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.blueGrey[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => recipients[index]['email'] = val,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    if (recipients.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => removeRecipient(index),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Remove'),
                          style:
                          TextButton.styleFrom(foregroundColor: Colors.red[600]),
                        ),
                      ),
                    const Divider(height: 24),
                  ],
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: addRecipient,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipient'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  isSubmitting || !isFormFilled ? null : submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'SUBMIT REQUEST',
                    style: TextStyle(letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
