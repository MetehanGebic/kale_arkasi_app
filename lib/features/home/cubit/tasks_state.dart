import 'package:equatable/equatable.dart';
import '../repository/tasks_repository.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<TaskItem> tasks;
  const TasksLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

// Bir görev başarıyla tamamlandığında bir kerelik yayınlanır; TasksLoaded'i
// genişletir ki BlocBuilder listeyi normal şekilde çizmeye devam etsin,
// BlocListener ise `is TasksActionSuccess` ile ödül snackbar'ını gösterebilsin.
class TasksActionSuccess extends TasksLoaded {
  final String message;
  final int reward;

  const TasksActionSuccess(
    super.tasks, {
    required this.message,
    required this.reward,
  });

  @override
  List<Object?> get props => [tasks, message, reward];
}

// Bir görev tamamlanırken (o görevin butonunda spinner göstermek için)
// mevcut listeyi de birlikte taşır ki ekran boşalmasın.
class TaskCompleting extends TasksState {
  final List<TaskItem> tasks;
  final String taskId;
  const TaskCompleting(this.tasks, this.taskId);

  @override
  List<Object?> get props => [tasks, taskId];
}

class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
