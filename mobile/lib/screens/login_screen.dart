import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _storage      = const FlutterSecureStorage();

  bool _isLogin  = true;
  bool _loading  = false;
  String _error  = '';

  @override
  void initState() {
    super.initState();
    ApiService.init();
    _checkAlreadyLoggedIn();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final token = await _storage.read(key: 'token');
    if (token != null && mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() { _loading = true; _error = ''; });
    try {
      Map<String, dynamic> data;
      if (_isLogin) {
        data = await ApiService.login(_emailCtrl.text, _passwordCtrl.text);
      } else {
        data = await ApiService.register(
          _emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);
      }
      await ApiService.saveToken(data['token']);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = 'Email ou mot de passe incorrect'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo
              const Icon(Icons.calendar_month, size: 64, color: Color(0xFF1A73E8)),
              const SizedBox(height: 8),
              const Text('Agenda Personnel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A73E8))),
              const SizedBox(height: 4),
              Text(_isLogin ? 'Connexion' : 'Créer un compte',
                style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Card formulaire
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? 'Se connecter' : "S'inscrire",
                              style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _error = ''; }),
                child: Text(_isLogin
                  ? "Pas de compte ? S'inscrire"
                  : 'Déjà un compte ? Se connecter',
                  style: const TextStyle(color: Color(0xFF1A73E8))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}