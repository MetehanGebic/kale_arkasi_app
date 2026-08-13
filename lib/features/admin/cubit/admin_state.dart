abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Map<String, dynamic>> trackedMatches;

  AdminLoaded(this.trackedMatches);
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);
}
