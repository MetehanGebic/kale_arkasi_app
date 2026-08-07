import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/ui/register_screen.dart';

void main() {
  runApp(const KaleArkasiApp());
}

class KaleArkasiApp extends StatelessWidget {
  const KaleArkasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Veri tesisatımızı (Repository) uygulamanın köküne yerleştiriyoruz
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      // 2. Durum yöneticimizi (Cubit) Repository ile besleyerek başlatıyoruz
      child: BlocProvider(
        create: (context) => AuthCubit(context.read<AuthRepository>()),
        child: MaterialApp(
          title: 'Kale Arkası',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
            ),
            useMaterial3: true,
          ),
          // Uygulama açılır açılmaz doğrudan Kayıt Ekranına gidecek
          home: const RegisterScreen(),
        ),
      ),
    );
  }
}
