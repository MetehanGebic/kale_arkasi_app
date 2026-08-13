import 'package:flutter_bloc/flutter_bloc.dart';
import 'superlig_state.dart';
import '../data/repository/superlig_repository.dart';
import '../data/models/superlig_models.dart';

class SuperligCubit extends Cubit<SuperligState> {
  final SuperligRepository repository;

  SuperligCubit(this.repository) : super(SuperligInitial());

  Future<void> fetchAllData() async {
    if (isClosed) return;
    emit(SuperligLoading());
    try {
      final results = await Future.wait([
        repository.getStandings(),
        repository.getFixtures(),
        repository.getTopScorers(),
        repository.getTransfers(),
        repository.getLiveMatches(),
      ]);
      
      if (!isClosed) {
        emit(SuperligLoaded(
          standings: results[0] as List<StandingsEntry>,
          fixtures: results[1] as List<Fixture>,
          topScorers: results[2] as List<TopScorer>,
          transfers: results[3] as List<Transfer>,
          liveMatches: results[4] as List<LiveMatch>,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SuperligError(e.toString()));
      }
    }
  }
}
