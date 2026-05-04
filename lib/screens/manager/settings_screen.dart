import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/organization_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ManagerSettingsScreen extends StatelessWidget {
  const ManagerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<OrganizationModel>(
        stream: userProv.orgStream(orgId),
        builder: (context, snap) {
          final org = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Name'),
                subtitle: Text(auth.currentUser!.name),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(auth.currentUser!.email),
              ),
              const Divider(),
              if (org != null) ...[
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Organization'),
                  subtitle: Text(org.name),
                ),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('Invite Code'),
                  subtitle: Text(
                    org.inviteCode,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: 'Copy code',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: org.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Invite code copied!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Regenerate code',
                        onPressed: () => _regenerate(context, orgId),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Share this code with employees when they sign up.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, String orgId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Regenerate Invite Code?'),
        content: const Text(
            'The old code will no longer work. Employees who haven\'t joined yet will need the new code.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Regenerate')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<UserProvider>().regenerateInviteCode(orgId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code regenerated!')),
      );
    }
  }
}
