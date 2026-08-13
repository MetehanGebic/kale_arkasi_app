import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/tasks_repository.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  final TasksRepository _repository;
  final String _token;

  TasksCubit(this._repository, this._token) : super(TasksInitial());

  List<TaskItem> get _currentTasks {
    final s = state;
    if (s is TasksLoaded) return s.tasks;
    if (s is TaskCompleting) return s.tasks;
    return const [];
  }

  Future<void> fetchTasks() async {
    // İlk yüklemede spinner göster; bir görev tamamlandıktan sonraki
    // sessiz yenilemede ekranı boşaltmamak için önceki listeyi koru.
    if (state is TasksInitial) {
      emit(TasksLoading());
    }
    try {
      final tasks = await _repository.getTasks(_token);
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> completeTask(String taskId) async {
    if (state is TaskCompleting) return;
    
    final currentTasks = _currentTasks;
    emit(TaskCompleting(currentTasks, taskId));

    try {
      final result = await _repository.completeTask(_token, taskId);

      // Listeyi tazeleyip (completedToday güncellensin) başarı state'ini yayınla.
      final refreshedTasks = await _repository.getTasks(_token);
      emit(
        TasksActionSuccess(
          refreshedTasks,
          message: result['message'] as String,
          reward: result['reward'] as int,
        ),
      );
    } catch (e) {
      // Hata anında da elimizdeki listeyi kaybetmeyelim.
      emit(TasksError(e.toString().replaceAll('Exception: ', '')));
      // UI hatayı okuduktan sonra ekranın boş kalmaması için eski listeye dön.
      emit(TasksLoaded(currentTasks));
    }
  }
}
