class ApiConstants {
  ApiConstants._();

  // Android emülatörler localhost (127.0.0.1) yerine 10.0.2.2 kullanır.
  // Gerçek cihaz kullanıyorsan buraya bilgisayarının yerel ağ (LAN) IP adresini yazmalısın.
  //
  // Bu değeri artık kod değiştirmeden, uygulamayı çalıştırırken/derlerken
  // override edebilirsin — böylece IP her değiştiğinde bu dosyayı elle
  // güncelleyip yeniden derlemek zorunda kalmazsın:
  //
  //   flutter run --dart-define=API_BASE_URL=http://YENI_IP:3000
  //   flutter build apk --dart-define=API_BASE_URL=http://YENI_IP:3000
  //
  // --dart-define verilmezse aşağıdaki defaultValue kullanılır.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.kalearkasi.com',
  );

  static const String identityUrl = '$baseUrl/api/identity';
  static const String economyUrl = '$baseUrl/api/economy';
  static const String tasksUrl = '$baseUrl/api/tasks';
  static const String superligUrl = '$baseUrl/api/superlig';
}
