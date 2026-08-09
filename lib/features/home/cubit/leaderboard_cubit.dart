import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/leaderboard_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository _repository;
  final String _token;

  LeaderboardCubit(this._repository, this._token) : super(LeaderboardInitial());

  Future<void> fetchLeaderboard() async {
    emit(LeaderboardLoading());
    try {
      final entries = await _repository.getLeaderboard(_token);
      emit(LeaderboardLoaded(entries));
    } catch (e) {
      emit(LeaderboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
