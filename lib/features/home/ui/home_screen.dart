import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/economy_cubit.dart';
import '../cubit/economy_state.dart';
import '../cubit/leaderboard_cubit.dart';
import '../cubit/leaderboard_state.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../repository/tasks_repository.dart';
import '../../../core/network/socket_client.dart';
import '../../superlig/cubit/superlig_cubit.dart';
import '../../superlig/cubit/superlig_state.dart';
import '../../superlig/data/models/superlig_models.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../live_chat/ui/live_match_screen.dart';

// -- Renk Paleti (Turf Green & Tea Bronze) --
const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37); // Gold/Bronze
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

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
    // Socket.io BaÅŸlatma ve Dinleme
    SocketClient().init(token: widget.userToken);
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(
                _decodeUsername(widget.userToken).isNotEmpty &&
                        _decodeUsername(widget.userToken) != 'KullanÄ±cÄ±'
                    ? _decodeUsername(widget.userToken)[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is TasksActionSuccess) {
            _showModernSnackBar(
              context,
              'â˜• ${state.message} (+${state.reward})',
              turfGreen,
            );
            context.read<EconomyCubit>().fetchBalance(widget.userToken);
          } else if (state is TasksError) {
            _showModernSnackBar(
              context,
              'âš ï¸ ${state.message}',
              Colors.red.shade700,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMatchHeader(context),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildUserDashboard(context),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'GÃ¼nÃ¼n GÃ¶revleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: turfGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTasksSection(context),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiryakiler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: turfGreen,
                      ),
                    ),
                    Icon(Icons.emoji_events, color: teaBronze, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLeaderboardCard(context),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son Transferler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: turfGreen,
                      ),
                    ),
                    Icon(Icons.swap_horiz, color: teaBronze, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTransfersShowcase(context),
              const SizedBox(height: 100), // FAB boÅŸluÄŸu
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
            'â˜• ${state.message} (+${state.reward})',
            turfGreen,
          );
        } else if (state is EconomyError) {
          _showModernSnackBar(
            context,
            'âš ï¸ ${state.message}',
            Colors.red.shade700,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is EconomyLoading;
        final lastClaim = state.lastClaimTime;

        return StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            bool isReady = true;
            String label = 'GÃ¼nlÃ¼k Ã‡ayÄ±nÄ± Al';
            if (lastClaim != null) {
              // But timestamp might be UTC from DB, ensure both are same timezone
              final diff = DateTime.now().difference(lastClaim.toLocal());
              if (diff.inHours < 24) {
                isReady = false;
                final remaining = const Duration(hours: 24) - diff;
                final h = remaining.inHours.toString().padLeft(2, '0');
                final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
                final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                label = '$h:$m:$s KaldÄ±';
              }
            }

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
                        : () {
                            if (!isReady) {
                              _showModernSnackBar(
                                context,
                                'âš ï¸ Ã‡ay henÃ¼z demini almadÄ±! $label sonra tekrar gel.',
                                Colors.orange.shade800,
                              );
                              return;
                            }
                            context.read<EconomyCubit>().claimDailyTea(
                              widget.userToken,
                            );
                          },
                    backgroundColor: isLoading || !isReady
                        ? Colors.grey.shade600
                        : teaBronze,
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
                        : Icon(
                            isReady
                                ? Icons.local_cafe_rounded
                                : Icons.timer_outlined,
                          ),
                    label: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _decodeUsername(String token) {
    if (token.isEmpty) return 'KullanÄ±cÄ±';
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'KullanÄ±cÄ±';
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded);
      return map['username'] ?? 'KullanÄ±cÄ±';
    } catch (e) {
      return 'KullanÄ±cÄ±';
    }
  }

  Widget _buildUserDashboard(BuildContext context) {
    String username = _decodeUsername(widget.userToken);

    return BlocBuilder<EconomyCubit, EconomyState>(
      builder: (context, ecoState) {
        final balance = ecoState.balance;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [turfGreen, Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: turfGreen.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  username.isNotEmpty && username != 'KullanÄ±cÄ±'
                      ? username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, $username!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'GÃ¼nÃ¼n gÃ¶revlerini tamamlamayÄ± unutma.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(providers: [BlocProvider.value(value: context.read<EconomyCubit>()), BlocProvider.value(value: context.read<TasksCubit>()), BlocProvider.value(value: context.read<SuperligCubit>())], child: const LiveMatchScreen(homeLogo: 'https://tmssl.akamaized.net/images/wappen/normquad/3041.png', awayLogo: 'https://tmssl.akamaized.net/images/wappen/normquad/141.png')),
                          ),
                        );
                      },
                      icon: const Icon(Icons.forum, size: 16),
                      label: const Text('CanlÄ± Kahvehane (Test)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teaBronze,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: teaBronze,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_food_beverage,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$balance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        Fixture? nextMatch;
        if (state is SuperligLoaded) {
          final now = DateTime.now();
          final authState = context.read<AuthCubit>().state;
          String? favoriteTeamId;

          if (authState is AuthSuccess) {
            favoriteTeamId =
                authState.user['clubId'] ?? authState.user['favoriteTeamId'];
          }

          var futureMatches =
              state.fixtures.where((f) => f.matchDate.isAfter(now)).toList()
                ..sort((a, b) => a.matchDate.compareTo(b.matchDate));

          if (favoriteTeamId != null) {
            final userTeamMatches = futureMatches
                .where(
                  (f) =>
                      f.homeClubId == favoriteTeamId ||
                      f.awayClubId == favoriteTeamId,
                )
                .toList();
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
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextMatch != null
                          ? '${nextMatch.week}. Hafta KarÅŸÄ±laÅŸmasÄ±'
                          : 'SÄ±radaki MaÃ§',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      if (nextMatch?.homeClubLogoUrl != null)
                        Image.network(
                          nextMatch!.homeClubLogoUrl!,
                          width: 48,
                          height: 48,
                        )
                      else if (nextMatch?.homeClubSlug != null)
                        Image.asset(
                          'assets/images/clubs/${nextMatch!.homeClubSlug}.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (c, e, s) => _buildTeamLogoPlaceholder(
                            nextMatch?.homeClubName
                                    .substring(0, 2)
                                    .toUpperCase() ??
                                'EV',
                            Colors.blue.shade900,
                          ),
                        )
                      else
                        _buildTeamLogoPlaceholder(
                          nextMatch?.homeClubName
                                  .substring(0, 2)
                                  .toUpperCase() ??
                              'EV',
                          Colors.blue.shade900,
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          nextMatch?.homeClubName ?? 'Ev Sahibi',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: teaBronze,
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Column(
                    children: [
                      if (nextMatch?.awayClubLogoUrl != null)
                        Image.network(
                          nextMatch!.awayClubLogoUrl!,
                          width: 48,
                          height: 48,
                        )
                      else if (nextMatch?.awayClubSlug != null)
                        Image.asset(
                          'assets/images/clubs/${nextMatch!.awayClubSlug}.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (c, e, s) => _buildTeamLogoPlaceholder(
                            nextMatch?.awayClubName
                                    .substring(0, 2)
                                    .toUpperCase() ??
                                'DEP',
                            Colors.yellow.shade700,
                          ),
                        )
                      else
                        _buildTeamLogoPlaceholder(
                          nextMatch?.awayClubName
                                  .substring(0, 2)
                                  .toUpperCase() ??
                              'DEP',
                          Colors.yellow.shade700,
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          nextMatch?.awayClubName ?? 'Deplasman',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (nextMatch != null)
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final diff = nextMatch!.matchDate.difference(
                      DateTime.now(),
                    );
                    if (diff.isNegative) {
                      return const Text(
                        'MaÃ§ BaÅŸladÄ±!',
                        style: TextStyle(
                          color: turfGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      );
                    }
                    final days = diff.inDays;
                    final hours = diff.inHours.remainder(24);
                    final minutes = diff.inMinutes.remainder(60);
                    final secs = diff.inSeconds.remainder(60);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${days > 0 ? '$days GÃ¼n ' : ''}$hours Saat $minutes Dk $secs Sn KaldÄ±',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                )
              else
                const Text(
                  'Gelecek maÃ§ bulunamadÄ±',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
            'GÃ¶revler yÃ¼klenemedi: ${state.message}',
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
        if (tasks.isEmpty) return const Text('GÃ¶rev bulunamadÄ±.');
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final bool isCompleting = task.id == completingTaskId;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.95 + (value * 0.05),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: task.completedToday
                              ? Colors.green.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: task.completedToday
                                ? Colors.green.shade200
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.completedToday
                                    ? turfGreen
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                task.completedToday
                                    ? Icons.check_circle
                                    : Icons.star_rounded,
                                color: task.completedToday
                                    ? Colors.white
                                    : teaBronze,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: Text(
                                  task.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: task.completedToday
                                        ? turfGreen
                                        : Colors.black87,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isCompleting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: turfGreen,
                                  strokeWidth: 2,
                                ),
                              )
                            else if (task.completedToday)
                              const Text(
                                'TamamlandÄ±',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => context
                                    .read<TasksCubit>()
                                    .completeTask(task.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teaBronze,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(double.infinity, 28),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '+${task.rewardTea}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
            'Liderlik tablosu yÃ¼klenemedi: ${state.message}',
            style: const TextStyle(color: Colors.red),
          );
        }
        final entries = (state as LeaderboardLoaded).entries;
        if (entries.isEmpty) return const Text('Kimse yok.');
        // Sadece ilk 5'i gÃ¶ster
        final top5 = entries.take(5).toList();
        return Column(
          children: top5.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;

            final Color primary =
                _parseHexColor(entry.clubPrimaryColorHex) ?? turfGreen;
            final Color secondary =
                _parseHexColor(entry.clubSecondaryColorHex) ?? primary;
            final bool isLight = primary.computeLuminance() > 0.55;
            final Color textColor = isLight ? Colors.black87 : Colors.white;
            return TweenAnimationBuilder<double>(
              key: ValueKey('${entry.username}_${entry.teaBalance}'),
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
                    backgroundColor: index == 0
                        ? teaBronze
                        : (index == 1
                              ? Colors.grey.shade400
                              : Colors.brown.shade300),
                    child: Text(
                      '${entry.rank}',
                      style: const TextStyle(
                        color: Colors.white,
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

  Widget _buildTransfersShowcase(BuildContext context) {
    return BlocBuilder<SuperligCubit, SuperligState>(
      builder: (context, state) {
        if (state is! SuperligLoaded) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: turfGreen)),
          );
        }
        final transfers = state.transfers.take(10).toList();
        if (transfers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('HenÃ¼z transfer verisi yok.'),
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final t = transfers[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: t.playerPhotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                t.playerPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.playerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: turfGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  t.toClubName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: teaBronze.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.feeType,
                              style: const TextStyle(
                                fontSize: 10,
                                color: teaBronze,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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



