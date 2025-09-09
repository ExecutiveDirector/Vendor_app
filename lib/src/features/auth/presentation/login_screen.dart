import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_api.dart';
import '../../../core/services/local_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setState(() => loading = true);
                try {
                  final data = await AuthApi.login(_email.text, _password.text);
                  if (data['token'] != null) await LocalStorage.setToken(data['token']);
                  if (mounted) context.go('/dashboard');
                } finally { if (mounted) setState(() => loading = false); }
              },
              child: Text(loading ? 'Signing in...' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}
