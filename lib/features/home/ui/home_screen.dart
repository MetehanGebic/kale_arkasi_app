import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/ui/login_screen.dart';
import '../cubit/economy_cubit.dart';
import '../cubit/economy_state.dart';
import '../cubit/leaderboard_cubit.dart';
import '../cubit/leaderboard_state.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../repository/economy_repository.dart';
import '../repository/leaderboard_repository.dart';
import '../repository/tasks_repository.dart';
import '../../../core/network/socket_client.dart';
import '../../superlig/ui/superlig_screen.dart';
import '../../superlig/cubit/superlig_cubit.dart';
import '../../superlig/cubit/superlig_state.dart';
import '../../superlig/data/repository/superlig_repository.dart';
import '../../superlig/data/models/superlig_models.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

// -- Renk Paleti (Turf Green & Tea Bronze) --
const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37); // Gold/Bronze
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

class HomeScreen extends StatelessWidget {
  final String userToken;
  const HomeScreen({super.key, this.userToken = ''});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              EconomyCubit(EconomyRepository())..fetchBalance(userToken),
        ),
        BlocProvider(
          create: (context) =>
              TasksCubit(TasksRepository(), userToken)..fetchTasks(),
        ),
        BlocProvider(
          create: (context) =>
              LeaderboardCubit(LeaderboardRepository(), userToken)
                ..fetchLeaderboard(),
        ),
        BlocProvider(
          create: (context) => SuperligCubit(SuperligRepository())..fetchAllData(),
        ),
      ],
      child: HomeView(userToken: userToken),
    );
  }
}

class HomeView extends StatefulWidget {
  final String userToken;
  const HomeView({super.key, required this.userToken});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Socket.io Başlatma ve Dinleme
    SocketClient().init();
    SocketClient().onLeaderboardUpdated(() {
      if (mounted) {
        context.read<LeaderboardCubit>().fetchLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    SocketClient().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: turfGreen,
        elevation: 0,
        title: const Text(
          'Skorla!',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        actions: [
          BlocBuilder<EconomyCubit, EconomyState>(
            builder: (context, state) {
              final int currentBalance = state.balance;
              return Container(
                margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teaBronze, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_food_beverage,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$currentBalance',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sports_soccer, color: Colors.white),
            tooltip: 'Süper Lig',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => SuperligCubit(SuperligRepository()),
                    child: const SuperligScreen(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await context.read<AuthRepository>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
      body: BlocListener<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is TasksActionSuccess) {
            _showModernSnackBar(
              context,
              '🍵 ${state.message} (+${state.reward})',
              turfGreen,
            );
            context.read<EconomyCubit>().fetchBalance(widget.userToken);
          } else if (state is TasksError) {
            _showModernSnackBar(
              context,
              '⚠️ ${state.message}',
              Colors.red.shade700,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMatchHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Günün Görevleri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: turfGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTasksSection(context),
                    const SizedBox(height: 32),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kahvehanenin Ağaları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: turfGreen,
                          ),
                        ),
                        Icon(
                          Icons.live_tv,
                          color: Colors.red,
                          size: 20,
                        ), // Real-time indikatörü
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLeaderboardCard(context),
                    const SizedBox(height: 100), // FAB boşluğu
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showModernSnackBar(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFab() {
    return BlocConsumer<EconomyCubit, EconomyState>(
      listener: (context, state) {
        if (state is EconomySuccess) {
          _showModernSnackBar(
            context,
            '🍵 ${state.message} (+${state.reward})',
            turfGreen,
          );
        } else if (state is EconomyError) {
          _showModernSnackBar(
            context,
            '⚠️ ${state.message}',
            Colors.red.shade700,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is EconomyLoading;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: FloatingActionButton.extended(
                onPressed: isLoading
                    ? null
                    : () => context.read<EconomyCubit>().claimDailyTea(
                        widget.userToken,
                      ),
                backgroundColor: isLoading ? Colors.grey : teaBronze,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.local_cafe_rounded),
                label: const Text(
                  'Günlük Çayını Al',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchHeader(BuildContext context) {
    return BlocBuilder<SuperligCubit, SuperligState>(
      builder: (context, state) {
        if (state is SuperligLoading || state is SuperligInitial) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: const BoxDecoration(
              color: turfGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        Fixture? nextMatch;
        if (state is SuperligLoaded) {
          final now = DateTime.now();
          final authState = context.read<AuthCubit>().state;
          String? favoriteTeamId;
          
          if (authState is AuthSuccess) {
            favoriteTeamId = authState.user['clubId'] ?? authState.user['favoriteTeamId'];
          }

          var futureMatches = state.fixtures
              .where((f) => f.matchDate.isAfter(now))
              .toList()
            ..sort((a, b) => a.matchDate.compareTo(b.matchDate));

          if (favoriteTeamId != null) {
            final userTeamMatches = futureMatches.where((f) => 
                f.homeClubId == favoriteTeamId || f.awayClubId == favoriteTeamId).toList();
            if (userTeamMatches.isNotEmpty) {
              nextMatch = userTeamMatches.first;
            }
          }

          // Fallback if user's team has no future match or user not logged in
          if (nextMatch == null && futureMatches.isNotEmpty) {
            nextMatch = futureMatches.first;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: const BoxDecoration(
            color: turfGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            image: DecorationImage(
              image: AssetImage(
                'assets/images/stadium_bg.jpg',
              ), // İleride eklenebilir, sorun çıkarmaz
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nextMatch != null
                      ? '${nextMatch.week}. Hafta Karşılaşması'
                      : 'Sıradaki Maç',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (nextMatch?.homeClubLogoUrl != null)
                    Image.network(nextMatch!.homeClubLogoUrl!, width: 60, height: 60)
                  else if (nextMatch?.homeClubSlug != null)
                    Image.asset('assets/images/clubs/${nextMatch!.homeClubSlug}.png', width: 60, height: 60, errorBuilder: (c,e,s) => _buildTeamLogoPlaceholder(nextMatch?.homeClubName.substring(0, 2).toUpperCase() ?? 'EV', Colors.blue.shade900))
                  else
                    _buildTeamLogoPlaceholder(
                        nextMatch?.homeClubName.substring(0, 2).toUpperCase() ?? 'EV',
                        Colors.blue.shade900),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: teaBronze,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (nextMatch?.awayClubLogoUrl != null)
                    Image.network(nextMatch!.awayClubLogoUrl!, width: 60, height: 60)
                  else if (nextMatch?.awayClubSlug != null)
                    Image.asset('assets/images/clubs/${nextMatch!.awayClubSlug}.png', width: 60, height: 60, errorBuilder: (c,e,s) => _buildTeamLogoPlaceholder(nextMatch?.awayClubName.substring(0, 2).toUpperCase() ?? 'DEP', Colors.yellow.shade700))
                  else
                    _buildTeamLogoPlaceholder(
                        nextMatch?.awayClubName.substring(0, 2).toUpperCase() ?? 'DEP',
                        Colors.yellow.shade700),
                ],
              ),
              const SizedBox(height: 20),
              if (nextMatch != null)
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final diff = nextMatch!.matchDate.difference(DateTime.now());
                    if (diff.isNegative) {
                      return const Text(
                        'Maç Başladı!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      );
                    }
                    final days = diff.inDays;
                    final hours = diff.inHours.remainder(24);
                    final minutes = diff.inMinutes.remainder(60);
                    final secs = diff.inSeconds.remainder(60);
                    return Text(
                      '${days > 0 ? '$days Gün ' : ''}$hours Saat $minutes Dk $secs Sn Kaldı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  },
                )
              else
                const Text(
                  'Gelecek maç bulunamadı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamLogoPlaceholder(String text, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading || state is TasksInitial) {
          return const Center(
            child: CircularProgressIndicator(color: turfGreen),
          );
        }
        if (state is TasksError) {
          return Text(
            'Görevler yüklenemedi: ${state.message}',
            style: const TextStyle(color: Colors.red),
          );
        }
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
        if (tasks.isEmpty) return const Text('Görev bulunamadı.');
        return Column(
          children: tasks.asMap().entries.map((entry) {
            final int index = entry.key;
            final TaskItem task = entry.value;
            final bool isCompleting = task.id == completingTaskId;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: task.completedToday
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: task.completedToday
                                ? Colors.green.shade50
                                : turfGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            task.completedToday
                                ? Icons.check_circle_rounded
                                : Icons.star_rounded,
                            color: task.completedToday ? turfGreen : teaBronze,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: task.completedToday
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        trailing: isCompleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: turfGreen,
                                  strokeWidth: 2,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: task.completedToday
                                      ? Colors.grey.shade100
                                      : teaBronze.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${task.rewardTea}',
                                  style: TextStyle(
                                    color: task.completedToday
                                        ? Colors.grey
                                        : teaBronze,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                        onTap: (task.completedToday || isCompleting)
                            ? null
                            : () => context.read<TasksCubit>().completeTask(
                                task.id,
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading || state is LeaderboardInitial) {
          return const Center(
            child: CircularProgressIndicator(color: turfGreen),
          );
        }
        if (state is LeaderboardError) {
          return Text(
            'Liderlik tablosu yüklenemedi: ${state.message}',
            style: const TextStyle(color: Colors.red),
          );
        }
        final entries = (state as LeaderboardLoaded).entries;
        if (entries.isEmpty) return const Text('Kimse yok.');
        return Column(
          children: entries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;

            final Color primary =
                _parseHexColor(entry.clubPrimaryColorHex) ?? turfGreen;
            final Color secondary =
                _parseHexColor(entry.clubSecondaryColorHex) ?? primary;
            final bool isLight = primary.computeLuminance() > 0.55;
            final Color textColor = isLight ? Colors.black87 : Colors.white;
            return TweenAnimationBuilder<double>(
              key: ValueKey(
                '${entry.username}_${entry.teaBalance}',
              ), // Bakiye değiştiğinde animasyon baştan oynar
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      '${entry.rank}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.username,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: entry.clubName != null
                      ? Text(
                          entry.clubName!,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.teaBalance}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.emoji_food_beverage,
                          color: teaBronze,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final intVal = int.tryParse(value, radix: 16);
    if (intVal == null) return null;
    return Color(intVal);
  }
}
