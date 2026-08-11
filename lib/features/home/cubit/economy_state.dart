abstract class EconomyState {
  // Her state kendi bakiye bilgisini taşır ki hata/yükleme anlarında
  // ekranda bakiye sıfıra düşmesin, son bilinen değer korunsun.
  final int balance;
  final DateTime? lastClaimTime;

  const EconomyState(this.balance, {this.lastClaimTime});
}

class EconomyInitial extends EconomyState {
  const EconomyInitial() : super(0);
}

class EconomyLoading extends EconomyState {
  const EconomyLoading(super.balance, {super.lastClaimTime});
}

// Bakiyenin sunucudan sadece okunduğu (bir ödül kazanılmadığı) durum için.
// HomeScreen açılışında mevcut bakiyeyi göstermek amacıyla kullanılır.
class EconomyBalanceLoaded extends EconomyState {
  const EconomyBalanceLoaded(super.balance, {super.lastClaimTime});
}

class EconomySuccess extends EconomyState {
  final int reward;
  final String message;

  const EconomySuccess({
    required int newBalance,
    required this.reward,
    required this.message,
    DateTime? lastClaimTime,
  }) : super(newBalance, lastClaimTime: lastClaimTime);

  int get newBalance => balance;
}

class EconomyError extends EconomyState {
  final String message;

  const EconomyError(this.message, super.balance, {super.lastClaimTime});
}
