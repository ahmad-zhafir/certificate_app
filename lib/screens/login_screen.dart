import 'package:certificate_gen/screens/donate_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'registration_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;

  void _login() async {
    setState(() => isLoading = true);

    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    User? user = await _authService.signInWithGoogle();

    if (user != null) {
      final profile = await _firestoreService.getUserData(user.uid);
      if (profile != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No profile found. Please register.")),
        );
        await FirebaseAuth.instance.signOut();
      }
    }

    setState(() => isLoading = false);
  }

  void _register() async {
    setState(() => isLoading = true);

    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    User? user = await _authService.signInWithGoogle();

    if (user != null) {
      final profile = await _firestoreService.getUserData(user.uid);
      if (profile == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(
              email: user.email ?? '',
              uid: user.uid,
            ),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You already have an account. Please login.")),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }

    setState(() => isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or header graphic
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
                    Icons.verified_user_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Welcome message
                Text(
                  'Welcome to CertiSafe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Your trusted digital certificate repository\nSecurely manage all your credentials',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else ...[
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Continue with Google',
                            style: TextStyle(letterSpacing: 0.5)),
                      ),
                      onPressed: _login,
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
                  const SizedBox(height: 16),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.app_registration, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Create New Account',
                            style: TextStyle(letterSpacing: 0.5)),
                      ),
                      onPressed: _register,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider with text
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Verify Certificate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified_outlined, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Verify Existing Certificate',
                            style: TextStyle(letterSpacing: 0.5)),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/verify-certificate');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Info text under verify button
                  Text(
                    'You can verify a certificate without an account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DonateScreen()),
                      );
                    },
                    icon: const Icon(Icons.volunteer_activism, color: Colors.pinkAccent),
                    label: const Text(
                      "Donate to Support CertiSafe",
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}