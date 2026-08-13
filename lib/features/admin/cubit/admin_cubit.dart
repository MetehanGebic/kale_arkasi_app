import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository _repository;
  final String _token;

  AdminCubit(this._repository, this._token) : super(AdminInitial());

  Future<void> fetchTrackedMatches() async {
    try {
      emit(AdminLoading());
      final matches = await _repository.getTrackedMatches(_token);
      emit(AdminLoaded(matches));
    } catch (e) {
      emit(AdminError('Takip edilen maçlar alınamadı: $e'));
    }
  }

  Future<void> addTrackedMatch(String url) async {
    try {
      if (state is AdminLoaded) {
        final currentState = state as AdminLoaded;
        // İsteğe bağlı optimistic update veya loading overlay yapılabilir
        await _repository.addTrackedMatch(_token, url);
        // Refresh
        await fetchTrackedMatches();
      } else {
        await _repository.addTrackedMatch(_token, url);
        await fetchTrackedMatches();
      }
    } catch (e) {
      emit(AdminError('Maç eklenirken hata oluştu: $e'));
      // Hata sonrası tekrar listeyi yükle
      await fetchTrackedMatches();
    }
  }

  Future<void> removeTrackedMatch(String id) async {
    try {
      if (state is AdminLoaded) {
        await _repository.removeTrackedMatch(_token, id);
        await fetchTrackedMatches();
      }
    } catch (e) {
      emit(AdminError('Maç silinirken hata oluştu: $e'));
      await fetchTrackedMatches();
    }
  }
}
