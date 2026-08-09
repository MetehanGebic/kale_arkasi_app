import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  // Başlangıçta uygulamanın durumu "AuthInitial" olarak ayarlanıyor
  AuthCubit(this._repository) : super(AuthInitial());

  // UI açıldığında takımları getirmek için kullanılacak
  Future<void> fetchClubs() async {
    emit(AuthLoading());
    try {
      final clubs = await _repository.getClubs();
      emit(AuthClubsLoaded(clubs));
    } catch (e) {
      // "Exception: " kısmını temizleyerek sadece mesajı gösteriyoruz
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Kayıt işlemi
  Future<void> register(
    String username,
    String email,
    String password,
    String clubId,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        username: username,
        email: email,
        password: password,
        favoriteClubId: clubId,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Giriş işlemi
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(email: email, password: password);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Şifremi unuttum işlemi
  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      final message = await _repository.forgotPassword(email);
      emit(AuthForgotPasswordSuccess(message));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
