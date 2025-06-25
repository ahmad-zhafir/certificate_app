import 'package:certify_me/certify_me.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class CertificateService {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> uploadCertificate({
    required CertificateData certData,
    required String filePath,
  }) async {
    final file = File(filePath);
    final ref = _storage.ref().child('certificates/${certData.certificateId}.pdf');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('certificates').add({
      'recipientName': certData.recipientName,
      'courseTitle': certData.courseTitle,
      'description': certData.description,
      'issueDate': certData.issueDate.toIso8601String(),
      'issuerName': certData.issuerName,
      'issuerTitle': certData.issuerTitle,
      'certificateId': certData.certificateId,
      'url': url,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}