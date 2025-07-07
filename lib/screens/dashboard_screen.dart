import 'package:certificate_gen/screens/ca/ca_dashboard_screen.dart';
import 'package:certificate_gen/screens/ca/ca_issued_certificates_screen.dart';
import 'package:certificate_gen/screens/client/client_request_list_screen.dart';
import 'package:certificate_gen/screens/client/request_certificate_screen.dart';
import 'package:certificate_gen/screens/recipient/recipient_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? role;
  String? name;
  bool isLoading = true;
  String? photoUrl;


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }


  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          role = doc['role'];
          name = doc['name'];
          photoUrl = user?.photoURL;
          isLoading = false;
        });
      }
    }
  }

  /// Dynamically builds dashboard based on role
  Widget _buildDashboard(BuildContext context) {
    switch (role) {
      case 'Admin':
        return _adminView(context, name ?? '');
      case 'Certificate Authority':
        return _caView();
      case 'Client':
        return _clientView();
      case 'Recipient':
        return _recipientView();
      default:
        return Center(child: Text("Role not recognized."));
    }
  }

  Widget _adminView(BuildContext context, String name) => _buildRoleDashboard(
    name: name,
    icon: Icons.admin_panel_settings,
    color: Colors.indigo,
    actions: [
      _dashboardButton(
        icon: Icons.analytics,
        label: "System Analytics",
        onTap: () => Navigator.pushNamed(context, '/admin-dashboard'),
      ),
      _dashboardButton(
        icon: Icons.list_alt,
        label: "System Logs",
        onTap: () => Navigator.pushNamed(context, '/admin-logs'),
      ),
    ],
  );

  Widget _caView() => _buildRoleDashboard(
    name: name ?? '',
    icon: Icons.verified_user,
    color: Colors.deepPurple,
    actions: [
      _dashboardButton(
        icon: Icons.assignment,
        label: "Certificate Requests",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaDashboardScreen())),
      ),
      _dashboardButton(
        icon: Icons.verified,
        label: "Issued Certificates",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaIssuedCertificatesScreen())),
      ),
      _dashboardButton(
        icon: Icons.upload_file,
        label: "True Copy Requests",
        onTap: () => Navigator.pushNamed(context, '/ca-true-copy-requests'),
      ),
    ],
  );

  Widget _clientView() => _buildRoleDashboard(
    name: name ?? '',
    icon: Icons.business_center,
    color: Colors.teal,
    actions: [
      _dashboardButton(
        icon: Icons.add_box,
        label: "Request Certificates",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestCertificateScreen())),
      ),
      _dashboardButton(
        icon: Icons.list,
        label: "My Requests",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRequestListScreen())),
      ),
    ],
  );

  Widget _recipientView() => _buildRoleDashboard(
    name: name ?? '',
    icon: Icons.person,
    color: Colors.orange,
    actions: [
      _dashboardButton(
        icon: Icons.badge,
        label: "My Certificates",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipientDashboardScreen())),
      ),
      _dashboardButton(
        icon: Icons.file_upload,
        label: "Upload True Copy",
        onTap: () => Navigator.pushNamed(context, '/true-copy-upload'),
      ),
    ],
  );

  Widget _buildRoleDashboard({
    required String name,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Dashboard Actions
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _dashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      height: 140, // Increased from 120 to prevent overflow
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: Colors.blue[700]),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleMessage(String? role) {
    switch (role) {
      case 'Admin':
        return 'Monitor user activity and manage the system.';
      case 'Certificate Authority':
        return 'Approve and issue certificates with confidence.';
      case 'Client':
        return 'Request and track certificates for your events.';
      case 'Recipient':
        return 'Manage and verify your earned certificates easily.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 24,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                backgroundColor: Colors.blue[100],
                child: photoUrl == null
                    ? Icon(Icons.person, size: 28, color: Colors.blue[900])
                    : null,
              ),
              const SizedBox(width: 12),
              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout')),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Fixed Welcome Banner Below AppBar
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "👋 Welcome Back!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRoleMessage(role),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Main Dashboard Content
          Expanded(child: _buildDashboard(context)),
        ],
      ),
    );
  }
}
