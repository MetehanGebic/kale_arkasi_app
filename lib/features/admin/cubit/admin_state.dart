abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Map<String, dynamic>> trackedMatches;
  final List<Map<String, dynamic>> users;

  AdminLoaded({
    required this.trackedMatches,
    required this.users,
  });

  AdminLoaded copyWith({
    List<Map<String, dynamic>>? trackedMatches,
    List<Map<String, dynamic>>? users,
  }) {
    return AdminLoaded(
      trackedMatches: trackedMatches ?? this.trackedMatches,
      users: users ?? this.users,
    );
  }
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);
}
