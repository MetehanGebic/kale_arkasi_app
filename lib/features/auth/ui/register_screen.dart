import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../ui/login_screen.dart';
import '../../home/ui/home_screen.dart';

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
            // 1. Önce Node.js'ten (API) bize tam olarak ne geldiğini konsola yazdıralım ki görelim
            print("🏟️ API'DEN GELEN VERİ: ${state.user}");

            // 2. Token'ı kesin String olarak değil, 'dynamic' (veya nullable) olarak alalım
            final token = state.user['token'];

            // 3. Eğer token gerçekten gelmiyorsa (null ise), uygulamayı dondurmak yerine hata gösterelim
            if (token == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sistemsel Hata: Sunucudan dijital anahtar (token) gelmedi!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return; // Aşağıdaki yönlendirme (Navigator) kodlarının çalışmasını durdur
            }

            // 4. Token varsa her şey yolunda demektir, yönlendirmeyi yapabiliriz
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Giriş Başarılı!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userToken: token.toString()),
              ),
              (Route<dynamic> route) => false,
            );
          }
        },
        builder: (context, state) {
          // Yüklenme durumunda ekranda sadece dönen ikon göster
          if (state is AuthLoading && _clubs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Takımlar hiç yüklenemediyse (örn. ağ hatası) kullanıcıyı
          // boş bir dropdown'la sonsuza kadar bekletmek yerine tekrar
          // deneme imkânı veriyoruz.
          if (state is AuthError && _clubs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Takımlar yüklenemedi: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AuthCubit>().fetchClubs(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
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
                    initialValue: _selectedClubId,
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
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Zaten hesabın var mı? Giriş Yap'),
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
