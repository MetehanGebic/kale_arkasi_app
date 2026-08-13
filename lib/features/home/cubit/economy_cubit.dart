import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/economy_repository.dart';
import 'economy_state.dart';

class EconomyCubit extends Cubit<EconomyState> {
  final EconomyRepository _repository;

  EconomyCubit(this._repository) : super(const EconomyInitial());

  // HomeScreen açılır açılmaz çağrılır: sunucudaki güncel bakiyeyi çeker.
  // Sessiz çalışır (EconomyLoading yaymaz) ki "Günlük Çayını Al" butonunun
  // görünümünü/kilidini etkilemesin; başarısız olursa mevcut (0) bakiye
  // olduğu gibi kalır, kullanıcıyı hata mesajıyla rahatsız etmeyiz.
  Future<void> fetchBalance(String token) async {
    try {
      final result = await _repository.getBalance(token);
      final balance = result['teaBalance'] as int;
      final dateStr = result['lastDailyTeaClaimAt'] as String?;
      final lastClaim = dateStr != null ? DateTime.parse(dateStr) : null;
      emit(EconomyBalanceLoaded(balance, lastClaimTime: lastClaim));
    } catch (_) {
      // Sessizce geç
    }
  }

  Future<void> claimDailyTea(String token) async {
    if (state is EconomyLoading) return;
    final currentBalance = state.balance;
    final currentLastClaim = state.lastClaimTime;
    emit(EconomyLoading(currentBalance, lastClaimTime: currentLastClaim));

    try {
      final result = await _repository.claimDailyTea(token);
      final dateStr = result['lastDailyTeaClaimAt'] as String?;
      final lastClaim = dateStr != null ? DateTime.parse(dateStr) : null;

      emit(
        EconomySuccess(
          newBalance: result['newBalance'],
          reward: result['reward'],
          message: result['message'],
          lastClaimTime: lastClaim,
        ),
      );
    } catch (e) {
      emit(
        EconomyError(
          e.toString().replaceAll('Exception: ', ''),
          currentBalance,
          lastClaimTime: currentLastClaim,
        ),
      );
    }
  }
}
