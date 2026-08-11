import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../../home/ui/main_navigation_screen.dart';
import 'login_screen.dart';

/// Uygulama açılışında kayıtlı bir JWT var mı diye bakar.
/// - Token varsa: kullanıcıyı tekrar login olmaya zorlamadan HomeScreen'e yönlendirir.
/// - Token yoksa: LoginScreen'i gösterir.
///
/// Not: Bu, token'ın backend'de hâlâ geçerli (süresi dolmamış) olduğunu
/// GARANTİ ETMEZ — sadece cihazda kayıtlı olduğunu kontrol eder. Token süresi
/// dolmuşsa ilk API isteğinde 401 dönecek ve o akışın ayrıca ele alınması gerekir
/// (örn. 401 alındığında otomatik logout).
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = context.read<AuthRepository>().getStoredToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return MainNavigationScreen(userToken: token);
        }
        return const LoginScreen();
      },
    );
  }
}
