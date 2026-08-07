import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// 1. Başlangıç durumu (Ekranda hiçbir şey yapılmıyorken)
class AuthInitial extends AuthState {}

// 2. Yüklenme durumu (Butona basıldığında dönen yuvarlak animasyon için)
class AuthLoading extends AuthState {}

// 3. Takımların başarıyla çekildiği durum (Dropdown menüsünü doldurmak için)
class AuthClubsLoaded extends AuthState {
  final List<dynamic> clubs;
  const AuthClubsLoaded(this.clubs);

  @override
  List<Object?> get props => [clubs];
}

// 4. Kayıt veya Girişin başarılı olduğu durum (Ana sayfaya geçiş için)
class AuthSuccess extends AuthState {
  final Map<String, dynamic> user;
  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

// 5. Hata durumu (Yanlış şifre, boş alan vb. uyarıları göstermek için)
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
