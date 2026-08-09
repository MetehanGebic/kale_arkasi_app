import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/ui/login_screen.dart';
import '../cubit/economy_cubit.dart';
import '../cubit/economy_state.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../repository/economy_repository.dart';
import '../repository/tasks_repository.dart';

class HomeScreen extends StatelessWidget {
  // Token, login/register akışından ya da AuthWrapper'ın SharedPreferences'tan
  // okuduğu kayıtlı oturumdan gelir.
  final String userToken;

  const HomeScreen({super.key, this.userToken = ''});

  @override
  Widget build(BuildContext context) {
    // Sayfayı MultiBlocProvider ile sarıyoruz.
    // Her iki cubit de oluşturulur oluşturulmaz sunucudan veri çekiyor;
    // aksi halde ekran her açıldığında bakiye/görevler "işlem yapılana
    // kadar" boş/0 görünüyordu.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = EconomyCubit(EconomyRepository());
            cubit.fetchBalance(userToken);
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) {
            final cubit = TasksCubit(TasksRepository(), userToken);
            cubit.fetchTasks();
            return cubit;
          },
        ),
      ],
      child: HomeView(userToken: userToken),
    );
  }
}

class HomeView extends StatelessWidget {
  final String userToken;

  const HomeView({super.key, required this.userToken});

  @override
  Widget build(BuildContext context) {
    final String token = userToken;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kale Arkası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Çay Bakiyesi Göstergesi - Artık Cubit'i dinliyor!
          BlocBuilder<EconomyCubit, EconomyState>(
            builder: (context, state) {
              final int currentBalance = state.balance;
              // İleride Initial stateteyken de mevcut bakiyeyi API'den (örneğin getProfile) çekip göstereceğiz.

              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_food_beverage,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentBalance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Token'ı cihazdan sil, yoksa AuthWrapper bir sonraki açılışta
              // kullanıcıyı otomatik olarak tekrar içeri alır.
              await context.read<AuthRepository>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: BlocListener<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is TasksActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🍵 ${state.message} (+${state.reward})'),
                backgroundColor: Colors.green.shade700,
              ),
            );
            // Görev tamamlanınca kazanılan çay AppBar'daki bakiyeye de
            // yansısın diye EconomyCubit'i tazeliyoruz.
            context.read<EconomyCubit>().fetchBalance(token);
          } else if (state is TasksError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ ${state.message}'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMatchHeader(context),
              const SizedBox(height: 24),

              const Text(
                'Çay Ocağı (Görevler)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTasksSection(context),
              const SizedBox(height: 24),

              const Text(
                'Kahvehanenin Ağaları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLeaderboardCard(context),

              const SizedBox(
                height: 80,
              ), // FAB butonunun altındaki kartları kapatmaması için boşluk
            ],
          ),
        ),
      ),
      // FAB Butonu - Artık API'ye istek atıyor!
      floatingActionButton: BlocConsumer<EconomyCubit, EconomyState>(
        listener: (context, state) {
          if (state is EconomySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🍵 ${state.message} (+${state.reward})'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else if (state is EconomyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ ${state.message}'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EconomyLoading;

          return FloatingActionButton.extended(
            onPressed: isLoading
                ? null
                : () => context.read<EconomyCubit>().claimDailyTea(token),
            backgroundColor: isLoading
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.emoji_food_beverage),
            label: const Text(
              'Günlük Çayını Al',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // 1. Yaklaşan Maç Vitrini (Header)
  // NOT: Şu an tamamen statik/mock veri gösteriyor (TS vs FB, "2 Gün 14 Saat").
  // Gerçek maç verisini çekecek bir API endpoint'i (ve muhtemelen bir
  // MatchCubit) henüz yok — bu bir sonraki geliştirme adımı olabilir.
  Widget _buildMatchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.red.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Sıradaki Maç',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'TS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('VS', style: TextStyle(color: Colors.white54, fontSize: 16)),
              Text(
                'FB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Kalan Süre: 2 Gün 14 Saat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 2. Günlük Görevler Modülü — artık TasksCubit'ten gerçek veriyle besleniyor.
  // Yükleniyor / hata / liste durumlarını ayrı ayrı ele alıyoruz.
  Widget _buildTasksSection(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading || state is TasksInitial) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is TasksError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Görevler yüklenemedi: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<TasksCubit>().fetchTasks(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        // Bu noktada state TasksLoaded (ya da alt sınıfı TasksActionSuccess)
        // veya TaskCompleting olabilir — ikisi de kendi listesini taşır ama
        // birbirinin alt sınıfı değil, o yüzden ayrı ayrı ele alıyoruz.
        List<TaskItem> tasks;
        String? completingTaskId;
        if (state is TasksLoaded) {
          tasks = state.tasks;
          completingTaskId = null;
        } else {
          final completing = state as TaskCompleting;
          tasks = completing.tasks;
          completingTaskId = completing.taskId;
        }

        if (tasks.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Şu an aktif görev yok, daha sonra tekrar bak!'),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tasks.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _buildTaskTile(
                  context,
                  tasks[i],
                  isCompleting: tasks[i].id == completingTaskId,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskItem task, {
    required bool isCompleting,
  }) {
    return ListTile(
      leading: Icon(
        task.completedToday ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.completedToday ? Colors.green : Colors.blue,
      ),
      title: Text(task.title),
      subtitle: task.description != null ? Text(task.description!) : null,
      trailing: isCompleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              '+${task.rewardTea} Çay',
              style: TextStyle(
                color: task.completedToday ? Colors.grey : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
      onTap: (task.completedToday || isCompleting)
          ? null
          : () => context.read<TasksCubit>().completeTask(task.id),
    );
  }

  // 3. Liderlik Tablosu Modülü
  // NOT: Bu da mock veri — gerçek liderlik tablosu için sunucudan
  // (teaBalance'a göre sıralanmış) kullanıcı listesi çeken bir
  // GET /api/economy/leaderboard gibi bir endpoint gerekecek.
  Widget _buildLeaderboardCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text('1', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('BordoMavi61'),
            subtitle: const Text('Tribün Lideri'),
            trailing: const Text(
              '1450 Çay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade400,
              child: const Text('2', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Firtina'),
            subtitle: const Text('Ateşli Taraftar'),
            trailing: const Text(
              '1200 Çay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
