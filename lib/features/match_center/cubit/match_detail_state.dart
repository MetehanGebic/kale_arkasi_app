import 'package:equatable/equatable.dart';
import '../../superlig/data/models/superlig_models.dart';

abstract class MatchDetailState extends Equatable {
  const MatchDetailState();
  @override
  List<Object?> get props => [];
}

class MatchDetailInitial extends MatchDetailState {}

class MatchDetailLoading extends MatchDetailState {}

class MatchDetailLoaded extends MatchDetailState {
  final List<MatchComment> comments;
  final MatchDetailsData? details;
  const MatchDetailLoaded({required this.comments, this.details});
  @override
  List<Object?> get props => [comments, details];
}

class MatchDetailError extends MatchDetailState {
  final String message;
  const MatchDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
