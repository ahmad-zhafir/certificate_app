import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});

  @override
  State<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController certIdController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController courseTitleController = TextEditingController();
  DateTime? selectedDate;
  bool isVerifying = false;
  String? verificationResult;
  bool isFormComplete = false;

  @override
  void initState() {
    super.initState();
    certIdController.addListener(_checkFormCompletion);
    recipientNameController.addListener(_checkFormCompletion);
    courseTitleController.addListener(_checkFormCompletion);
  }

  void _checkFormCompletion() {
    final complete = certIdController.text.isNotEmpty &&
        recipientNameController.text.isNotEmpty &&
        courseTitleController.text.isNotEmpty &&
        selectedDate != null;

    if (complete != isFormComplete) {
      setState(() {
        isFormComplete = complete;
      });
    }
  }

  Future<void> verifyCertificate() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;

    setState(() {
      isVerifying = true;
      verificationResult = null;
    });

    final certId = certIdController.text.trim();
    final recipientName = recipientNameController.text.trim().toLowerCase();
    final courseTitle = courseTitleController.text.trim().toLowerCase();
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('certificates')
          .where('certificateId', isEqualTo: certId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          verificationResult = "❌ Certificate not found.";
        });
      } else {
        final data = snap.docs.first.data();

        final match = (data['recipientName'] as String).toLowerCase().contains(recipientName) &&
            (data['courseTitle'] as String).toLowerCase().contains(courseTitle) &&
            (data['issueDate'] as String).startsWith(formattedDate);

        setState(() {
          verificationResult = match
              ? "✅ Certificate is valid and authentic."
              : "❌ Certificate data mismatch.";
        });
      }
    } catch (e) {
      setState(() {
        verificationResult = "❌ Error verifying certificate.";
      });
    } finally {
      setState(() => isVerifying = false);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _checkFormCompletion();
    }
  }

  @override
  void dispose() {
    certIdController.dispose();
    recipientNameController.dispose();
    courseTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Certificate Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Verify Certificate",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Enter certificate details to verify authenticity",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Certificate ID
                  TextFormField(
                    controller: certIdController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.tag),
                      labelText: "Certificate ID",
                      labelStyle: TextStyle(color: Colors.blueGrey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Recipient Name
                  TextFormField(
                    controller: recipientNameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: "Recipient Name",
                      labelStyle: TextStyle(color: Colors.blueGrey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Course Title
                  TextFormField(
                    controller: courseTitleController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.workspace_premium),
                      labelText: "Certificate Title",
                      labelStyle: TextStyle(color: Colors.blueGrey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text(
                    "Issue/Certify Date",
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Text(
                            selectedDate == null
                                ? "No date selected"
                                : DateFormat('yyyy-MM-dd').format(selectedDate!),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _pickDate(context),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text("Pick Date"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!isFormComplete || isVerifying) ? null : verifyCertificate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text(
                        "VERIFY CERTIFICATE",
                        style: TextStyle(letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Result message same width as button
                  if (verificationResult != null)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: verificationResult!.contains("✅")
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border.all(
                            color: verificationResult!.contains("✅")
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          verificationResult!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: verificationResult!.contains("✅")
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
