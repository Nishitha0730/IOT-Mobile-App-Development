import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Cart',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<FirebaseApp> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error initializing Firebase: ${snapshot.error}'),
              ),
            ),
          );
        }
        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_isLogin ? 'Login' : 'Register', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter password';
                          if (v.length < 6) return 'Password must be at least 6 chars';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? 'Login' : 'Create account'),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                }),
                        child: Text(_isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login'),
                      ),
                      if (_isLogin)
                        TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email to reset password');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _error = 'Password reset email sent (check inbox)');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Sign out',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hello, ${user?.email ?? 'User'}'),
            const SizedBox(height: 16),
            const Text('This is the home page. Replace with your app UI.'),
            const SizedBox(height: 12),
            // ElevatedButton(
            //   onPressed: () async {
            //     final uid = user?.uid ?? 'anonymous';
            //     try {
            //       await FirestoreService.instance.writeSampleUser(uid, {
            //         'email': user?.email ?? '',
            //         'name': 'Demo User',
            //       });
            //       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrote sample user to Firestore')));
            //     } catch (e) {
            //       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error writing to Firestore: $e')));
            //     }
            //   },
            //   child: const Text('Write sample user to Firestore'),
            // ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final uid = user?.uid;
                if (uid == null) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
                  return;
                }
                try {
                  final data = await FirestoreService.instance.getUser(uid);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('User document (once)'),
                        content: Text(data == null ? 'No document found' : data.toString()),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading user: $e')));
                }
              },
              child: const Text('Read user document once'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Append a timestamped message to an array field 'messages' in users/{uid}
                final uid = user?.uid;
                if (uid == null) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
                  return;
                }
                try {
                  final msg = {'text': 'Button pressed', 'at': DateTime.now().toIso8601String()};
                  await FirestoreService.instance.appendToArrayField('users/$uid', 'messages', msg);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appended message to user document')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error appending message: $e')));
                }
              },
              child: const Text('Append message to user doc'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Add a history doc under users/{uid}/history so previous entries are preserved
                final uid = user?.uid;
                if (uid == null) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
                  return;
                }
                try {
                  final entry = {'action': 'button_press', 'time': FieldValue.serverTimestamp()};
                  await FirestoreService.instance.addSubcollectionDocument('users/$uid', 'history', entry);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added history entry')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding history entry: $e')));
                }
              },
              child: const Text('Add history entry'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final uid = user?.uid;
                if (uid == null) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
                  return;
                }
                showDialog(
                  context: context,
                  builder: (ctx) => StreamBuilder<Map<String, dynamic>?>(
                    stream: FirestoreService.instance.streamUser(uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())));
                      return AlertDialog(
                        title: const Text('Live user document'),
                        content: Text(snap.data == null ? 'No document' : snap.data.toString()),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                      );
                    },
                  ),
                );
              },
              child: const Text('Show live user updates'),
            ),
          ],
        ),
      ),
    );
  }
}