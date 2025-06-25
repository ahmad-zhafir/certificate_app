import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:certificate_gen/screens/recipient/recipient_true_copy_request_detail_screen.dart';

class RecipientTrueCopyUploadScreen extends StatefulWidget {
  const RecipientTrueCopyUploadScreen({super.key});

  @override
  State<RecipientTrueCopyUploadScreen> createState() => _RecipientTrueCopyUploadScreenState();
}

class _RecipientTrueCopyUploadScreenState extends State<RecipientTrueCopyUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  File? selectedFile;
  bool isProcessing = false;
  bool isSubmitting = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  List<Map<String, dynamic>> caList = [];
  String? selectedCaUid;
  bool isLoadingCAs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCAs();

    // Attach listeners to text controllers to enable live validation
    nameController.addListener(_onFormChanged);
    titleController.addListener(_onFormChanged);
  }

  bool get isFormValid {
    return selectedFile != null &&
        nameController.text.trim().isNotEmpty &&
        titleController.text.trim().isNotEmpty &&
        selectedCaUid != null;
  }

  void _onFormChanged() {
    setState(() {}); // Trigger UI update for button state
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    _tabController.dispose();
    super.dispose();
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
        'organization': doc['organization'] ?? '',
      }).toList();
      isLoadingCAs = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        selectedFile = file;
      });

      if (p.extension(file.path).toLowerCase() != '.pdf') {
        _performOCR(file);
      }
    }
  }

  Future<void> _performOCR(File file) async {
    setState(() => isProcessing = true);

    final inputImage = InputImage.fromFile(file);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final lines = recognizedText.text.split('\n');

    nameController.text = lines.firstWhere((line) => line.toLowerCase().contains("name"), orElse: () => '');
    titleController.text = lines.firstWhere((line) => line.toLowerCase().contains("certificate"), orElse: () => '');

    setState(() => isProcessing = false);
  }

  Future<void> _submitForVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedFile == null || selectedCaUid == null) return;

    setState(() => isSubmitting = true);

    try {
      final fileName = p.basename(selectedFile!.path);
      final requestId = FirebaseFirestore.instance.collection('true_copy_requests').doc().id;

      // ✅ Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('true_copy_uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      await storageRef.putFile(selectedFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      // ✅ Get user display name from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final displayName = userDoc['name'] ?? user.email;

      // ✅ Save request to Firestore
      await FirebaseFirestore.instance.collection('true_copy_requests').doc(requestId).set({
        'recipientUid': user.uid,
        'recipientEmail': user.email,
        'recipientName': nameController.text.trim(),
        'title': titleController.text.trim(),
        'status': 'pending',
        'fileName': fileName,
        'fileUrl': downloadUrl, // ✅ now valid
        'submittedAt': FieldValue.serverTimestamp(),
        'caUid': selectedCaUid,
      });

      // ✅ Log action
      await FirebaseFirestore.instance.collection('logs').add({
        'action': 'Requested True Copy Certification',
        'performedBy': user.email,
        'performedByName': displayName,
        'role': 'Recipient',
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        isSubmitting = false;
        _tabController.index = 1;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Request submitted for verification.")));
    } catch (e) {
      print("Submission error: $e");
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to submit request.")));
    }
  }

  Widget _buildUploadTab() {
    final primaryColor = Colors.blue[700];


    return Container(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Certificate (Image or PDF)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (selectedFile != null) ...[
            const SizedBox(height: 24),
            const Text(
              "Extracted / Editable Metadata",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Recipient Name *",
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Certificate Title *",
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            isLoadingCAs
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: selectedCaUid,
              decoration: InputDecoration(
                labelText: "Select Certificate Authority *",
                prefixIcon: const Icon(Icons.verified_user),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => selectedCaUid = val),
              items: caList.map((ca) {
                return DropdownMenuItem<String>(
                  value: ca['uid'],
                  child: Text("${ca['name']} (${ca['organization']})"),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: (isSubmitting || !isFormValid) ? null : _submitForVerification,
            icon: const Icon(Icons.verified_user),
            label: isSubmitting
                ? const Text("Submitting...")
                : const Text("Submit for Verification"),
            style: ElevatedButton.styleFrom(
              backgroundColor: (isSubmitting || !isFormValid)
                  ? Colors.grey
                  : Colors.green[600],
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    final user = FirebaseAuth.instance.currentUser;
    final stream = FirebaseFirestore.instance
        .collection('true_copy_requests')
        .where('recipientUid', isEqualTo: user?.uid)
        .orderBy('submittedAt', descending: true)
        .snapshots();

    return Container(

      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No requests found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'unknown';

              Color badgeColor;
              switch (status) {
                case 'approved':
                  badgeColor = Colors.green;
                  break;
                case 'rejected':
                  badgeColor = Colors.red;
                  break;
                default:
                  badgeColor = Colors.orange;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    data['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text("Details"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipientTrueCopyRequestDetailScreen(
                            requestData: data,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload Certified True Copy",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Upload"),
            Tab(text: "My Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadTab(),
          _buildStatusTab(),
        ],
      ),
    );
  }

}