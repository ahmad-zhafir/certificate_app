import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String email;
  final String uid;

  RegistrationScreen({required this.email, required this.uid});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? fullName;
  String? selectedRole;
  String? organization;
  String? contactNumber;

  final List<String> roles = ['Admin', 'Certificate Authority', 'Client', 'Recipient'];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRole == 'Admin' &&
        !(widget.email.endsWith('@upm.edu.my') || widget.email.endsWith('@student.upm.edu.my'))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Only UPM emails allowed for Admin role."),
      ));
      return;
    }

    await FirestoreService().saveUserProfile(
      uid: widget.uid,
      name: fullName!.trim(), // ✅ Use the new name
      email: widget.email,
      role: selectedRole!,
      organization: organization ?? '',
      contactNumber: contactNumber ?? '',
    );

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 3,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.person_add_alt_1,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    "Complete Your Registration",
                    textAlign: TextAlign.center, // Add this
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),


                  // Subtitle
                  Text(
                    "Please enter your details to continue",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name input (original logic preserved)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.blueGrey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                    onChanged: (val) => fullName = val,
                    validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Role dropdown (original logic preserved)
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    hint: Text("Select Role", style: TextStyle(color: Colors.blueGrey[600])),
                    onChanged: (value) => setState(() => selectedRole = value),
                    validator: (value) => value == null ? "Please select a role" : null,
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conditional organization field (original logic preserved)
                  if (selectedRole == 'Certificate Authority' || selectedRole == 'Client') ...[
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Organization',
                        labelStyle: TextStyle(color: Colors.blueGrey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[700]!),
                        ),
                      ),
                      onChanged: (val) => organization = val,
                      validator: (val) =>
                      val == null || val.isEmpty ? "Organization is required" : null,
                    ),
                    const SizedBox(height: 16),
                  ],



                  // Contact number (original logic preserved)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      labelStyle: TextStyle(color: Colors.blueGrey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                    onChanged: (val) => contactNumber = val,
                  ),
                  const SizedBox(height: 40),

                  // Continue button (original logic preserved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'CONTINUE',
                          style: TextStyle(letterSpacing: 0.5),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 1,
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
