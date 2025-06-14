import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final client = Supabase.instance.client;
  String email = 'Tidak diketahui';
  String uid = 'Tidak diketahui';
  String username = 'Tidak diketahui';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() {
      email = user.email ?? 'Tidak diketahui';
      uid = user.id;
    });

    final profile = await client
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .single();

    if (mounted && profile != null && profile['username'] != null) {
      setState(() {
        username = profile['username'];
      });
    }
  }

  String getInitials(String? text) {
    if (text == null || text.isEmpty) return '?';
    return text[0].toUpperCase();
  }

  void editUsernameDialog() {
    final controller = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Username baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) return;

              await client
                  .from('profiles')
                  .update({'username': newUsername})
                  .eq('id', uid);

              Navigator.pop(context);
              setState(() {
                username = newUsername;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Username berhasil diperbarui')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueGrey.shade200,
              child: Text(
                getInitials(username),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Akun Terdaftar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 30, thickness: 1),

            // Username (editable)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Username'),
                subtitle: Text(username),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: editUsernameDialog,
                ),
              ),
            ),

            // Email
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
            ),

            // UID
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.key),
                title: const Text('User ID'),
                subtitle: Text(uid),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah kamu yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await client.auth.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
