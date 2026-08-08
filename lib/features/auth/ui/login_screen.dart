import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'register_screen.dart';
import '../../home/ui/home_screen.dart';

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
      appBar: AppBar(title: const Text('Kahvehaneye Giriş'), centerTitle: true),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Giriş Başarılı!'),
                backgroundColor: Colors.green,
              ),
            );
            // Kullanıcıyı Ana Sayfaya yönlendir ve geri tuşuna basıp tekrar login'e dönmesini engelle
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.login, size: 80, color: Colors.green),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.contains('@')
                        ? null
                        : 'Geçerli bir e-posta girin',
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => value!.length < 6
                        ? 'Şifre en az 6 karakter olmalı'
                        : null,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: state is AuthLoading ? null : _onLoginPressed,
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Kayıt ekranına geçiş butonu
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Hesabın yok mu? Kayıt Ol'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
