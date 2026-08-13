import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'match_detail_state.dart';
import '../../superlig/data/repository/superlig_repository.dart';

class MatchDetailCubit extends Cubit<MatchDetailState> {
  final SuperligRepository repository;
  Timer? _timer;

  MatchDetailCubit(this.repository) : super(MatchDetailInitial());

  Future<void> fetchData(String matchId, {bool isSilent = false}) async {
    if (isClosed) return;
    if (!isSilent) emit(MatchDetailLoading());
    try {
      final comments = await repository.getMatchComments(matchId);
      final details = await repository.getMatchDetails(matchId);
      if (!isClosed) emit(MatchDetailLoaded(comments: comments, details: details));
    } catch (e) {
      if (!isClosed && !isSilent) emit(MatchDetailError(e.toString()));
    }
  }

  void startPolling(String matchId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchData(matchId, isSilent: true);
    });
  }

  Future<void> addComment(String matchId, String content) async {
    try {
      final newComment = await repository.addMatchComment(matchId, content);
      if (state is MatchDetailLoaded) {
        final loadedState = state as MatchDetailLoaded;
        emit(MatchDetailLoaded(comments: [newComment, ...loadedState.comments], details: loadedState.details));
      } else {
        await fetchData(matchId);
      }
    } catch (e) {
      if (!isClosed) emit(MatchDetailError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
