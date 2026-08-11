import 'package:flutter_bloc/flutter_bloc.dart';
import 'superlig_state.dart';
import '../data/repository/superlig_repository.dart';

class SuperligCubit extends Cubit<SuperligState> {
  final SuperligRepository repository;

  SuperligCubit(this.repository) : super(SuperligInitial());

  Future<void> fetchAllData() async {
    if (isClosed) return;
    emit(SuperligLoading());
    try {
      final standings = await repository.getStandings();
      final fixtures = await repository.getFixtures();
      final topScorers = await repository.getTopScorers();
      final transfers = await repository.getTransfers();
      
      if (!isClosed) {
        emit(SuperligLoaded(
          standings: standings,
          fixtures: fixtures,
          topScorers: topScorers,
          transfers: transfers,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SuperligError(e.toString()));
      }
    }
  }
}
