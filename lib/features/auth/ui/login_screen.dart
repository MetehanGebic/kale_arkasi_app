import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'register_screen.dart';
import '../../home/ui/home_screen.dart';

const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);
const Color surfaceColor = Color(0xFFF5F5F5);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSnackBar(context, state.message, Colors.red.shade700);
          } else if (state is AuthSuccess) {
            final token = state.user['token'];
            if (token == null) {
              _showSnackBar(context, 'Sistemsel Hata: Anahtar alınamadı!', Colors.red.shade700);
              return;
            }
            _showSnackBar(context, 'Kahvehaneye hoş geldin!', turfGreen);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(userToken: token.toString())),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / İkon alanı
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: turfGreen.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
                            ],
                          ),
                          child: const Icon(Icons.stadium_rounded, size: 60, color: turfGreen),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Kale Arkası',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: turfGreen, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kahvehaneye Giriş Yap',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 48),

                        _buildTextField(
                          controller: _emailController,
                          label: 'E-posta',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val!.contains('@') ? null : 'Geçerli bir e-posta girin',
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                          validator: (val) => val!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                        ),
                        const SizedBox(height: 12),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Şifremi Unuttum eklenebilir
                            },
                            child: const Text('Şifremi Unuttum', style: TextStyle(color: teaBronze, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: turfGreen,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: turfGreen.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: state is AuthLoading ? null : _onLoginPressed,
                          child: state is AuthLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Hesabın yok mu?', style: TextStyle(color: Colors.grey.shade700)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text('Kayıt Ol', style: TextStyle(color: turfGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: turfGreen,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: turfGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: turfGreen, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
