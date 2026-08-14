import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository _repository;
  final String _token;

  AdminCubit(this._repository, this._token) : super(AdminInitial());

  Future<void> loadDashboard() async {
    try {
      emit(AdminLoading());
      final matches = await _repository.getTrackedMatches(_token);
      final users = await _repository.getUsers(_token);
      emit(AdminLoaded(trackedMatches: matches, users: users));
    } catch (e) {
      emit(AdminError('Dashboard verileri alınamadı: $e'));
    }
  }

  Future<void> fetchTrackedMatches() async {
    try {
      if (state is AdminLoaded) {
        final matches = await _repository.getTrackedMatches(_token);
        emit((state as AdminLoaded).copyWith(trackedMatches: matches));
      } else {
        await loadDashboard();
      }
    } catch (e) {
      emit(AdminError('Takip edilen maçlar alınamadı: $e'));
    }
  }

  Future<void> fetchUsers() async {
    try {
      if (state is AdminLoaded) {
        final users = await _repository.getUsers(_token);
        emit((state as AdminLoaded).copyWith(users: users));
      } else {
        await loadDashboard();
      }
    } catch (e) {
      emit(AdminError('Kullanıcılar alınamadı: $e'));
    }
  }

  Future<void> addTrackedMatch(String url, {String? homeLogoUrl, String? awayLogoUrl}) async {
    try {
      await _repository.addTrackedMatch(_token, url, homeLogoUrl: homeLogoUrl, awayLogoUrl: awayLogoUrl);
      await fetchTrackedMatches();
    } catch (e) {
      emit(AdminError('Maç eklenirken hata oluştu: $e'));
      await loadDashboard();
    }
  }

  Future<void> removeTrackedMatch(String id) async {
    try {
      await _repository.removeTrackedMatch(_token, id);
      await fetchTrackedMatches();
    } catch (e) {
      emit(AdminError('Maç silinirken hata oluştu: $e'));
      await loadDashboard();
    }
  }

  Future<void> changeUserStatus(String userId, String status) async {
    try {
      await _repository.changeUserStatus(_token, userId, status);
      await fetchUsers(); // Refresh the user list
    } catch (e) {
      emit(AdminError('Kullanıcı durumu değiştirilemedi: $e'));
      await loadDashboard();
    }
  }

  Future<void> triggerScraper(String target) async {
    try {
      await _repository.triggerScraper(_token, target);
    } catch (e) {
      // Ignore or log error
    }
  }
}
