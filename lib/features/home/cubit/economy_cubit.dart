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
      final balance = await _repository.getBalance(token);
      emit(EconomyBalanceLoaded(balance));
    } catch (_) {
      // Sessizce geç: profil bilgisi çekilemedi, kullanıcı yine de
      // "Günlük Çayını Al" tuşuyla normal akışa devam edebilir.
    }
  }

  Future<void> claimDailyTea(String token) async {
    // Mevcut state'teki bakiyeyi koru; loading/error anlarında da
    // ekranda son bilinen bakiye görünsün, sıfıra düşmesin.
    final currentBalance = state.balance;
    emit(EconomyLoading(currentBalance));

    try {
      final result = await _repository.claimDailyTea(token);

      emit(
        EconomySuccess(
          newBalance: result['newBalance'],
          reward: result['reward'],
          message: result['message'],
        ),
      );
    } catch (e) {
      emit(
        EconomyError(
          e.toString().replaceAll('Exception: ', ''),
          currentBalance,
        ),
      );
    }
  }
}
