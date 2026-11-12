import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool loading = false;
  bool showPassword = false;

  Future<void> submit() async {
    if (loading) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      showMessage('Enter email and password.');
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      showMessage('Enter a valid email address.');
      return;
    }
    if (register && password.text.length < 6) {
      showMessage('Use at least 6 characters for your password.');
      return;
    }

    setState(() => loading = true);

    try {
      final auth = Supabase.instance.client.auth;

      if (register) {
        final result = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );

        if (!mounted) return;

        if (result.session == null) {
          showMessage('Check your email to confirm registration.');
        } else {
          showMessage('Registration successful!');
          Navigator.of(context).pop();
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balkan Connect')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, size: 65, color: Color(0xFF38BDF8)),
                const SizedBox(height: 15),
                Text(
                  register ? 'Create account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: email,
                  enabled: !loading,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  enabled: !loading,
                  obscureText: !showPassword,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: showPassword ? 'Hide password' : 'Show password',
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!loading) submit();
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const CircularProgressIndicator()
                          : Text(register ? 'Register' : 'Login'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Already have an account? Login'
                        : 'No account? Register',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
