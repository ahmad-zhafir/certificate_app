import 'package:certificate_gen/screens/admin/system_analytics_screen.dart';
import 'package:certificate_gen/screens/admin/system_logs_stats_screen.dart';
import 'package:certificate_gen/screens/ca/ca_true_copy_requests_screen.dart';
import 'package:certificate_gen/screens/pdf_preview_screen.dart';
import 'package:certificate_gen/screens/recipient/recipient_true_copy_upload_screen.dart';
import 'package:certificate_gen/screens/verify_certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Force sign out of Google and Firebase on every app restart
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Certificate Repository',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/admin-dashboard': (context) => const SystemAnalyticsScreen(),
        '/admin-logs': (context) => SystemLogsAndStatsScreen(),
        '/verify-certificate': (context) => const VerifyCertificateScreen(),
        '/true-copy-upload': (context) => const RecipientTrueCopyUploadScreen(),
        '/ca-true-copy-requests': (context) => const CaTrueCopyRequestsScreen(),
        '/pdf-preview': (context) {
          final url = ModalRoute.of(context)!.settings.arguments as String;
          return PdfPreviewScreen(url: url);
        },

      },
    );
  }
}
