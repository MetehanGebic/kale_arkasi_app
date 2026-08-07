import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedClubId;
  List<dynamic> _clubs = []; // API'den gelecek takımları burada tutacağız

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz Cubit'e "Takımları getir" emrini veriyoruz
    context.read<AuthCubit>().fetchClubs();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState!.validate() && _selectedClubId != null) {
      context.read<AuthCubit>().register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedClubId!,
      );
    } else if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir takım seçin!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kahvehaneye Katıl'), centerTitle: true),
      // BlocConsumer: Cubit'teki durum değişikliklerini hem dinler hem de ekranı çizer
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthClubsLoaded) {
            setState(() {
              _clubs = state.clubs;
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kayıt Başarılı! Hoş geldin!'),
                backgroundColor: Colors.green,
              ),
            );
            // İleride buraya Ana Sayfaya (Home) yönlendirme kodu gelecek
          }
        },
        builder: (context, state) {
          // Yüklenme durumunda ekranda sadece dönen ikon göster
          if (state is AuthLoading && _clubs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),

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
                    validator: (value) =>
                        value!.length < 6 ? 'En az 6 karakter olmalı' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gönül Verdiğin Takım',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedClubId,
                    items: _clubs.map((club) {
                      return DropdownMenuItem<String>(
                        value: club['id'],
                        child: Text(club['name']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedClubId = value),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: state is AuthLoading ? null : _onRegisterPressed,
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 18),
                          ),
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
