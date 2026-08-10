import 'package:equatable/equatable.dart';
import '../data/models/superlig_models.dart';

abstract class SuperligState extends Equatable {
  const SuperligState();
  @override
  List<Object?> get props => [];
}

class SuperligInitial extends SuperligState {}

class SuperligLoading extends SuperligState {}

class SuperligLoaded extends SuperligState {
  final List<StandingsEntry> standings;
  final List<Fixture> fixtures;
  final List<TopScorer> topScorers;
  final List<Transfer> transfers;

  const SuperligLoaded({
    required this.standings,
    required this.fixtures,
    required this.topScorers,
    required this.transfers,
  });

  @override
  List<Object?> get props => [standings, fixtures, topScorers, transfers];
}

class SuperligError extends SuperligState {
  final String message;
  const SuperligError(this.message);
  @override
  List<Object?> get props => [message];
}
