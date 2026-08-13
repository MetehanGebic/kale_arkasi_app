import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/match_detail_cubit.dart';
import '../cubit/match_detail_state.dart';
import '../../superlig/data/models/superlig_models.dart';


const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);

class MatchDetailScreen extends StatefulWidget {
  final LiveMatch match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MatchDetailCubit>().fetchData(widget.match.id);
    if (widget.match.status == 'inprogress' || widget.match.status == 'halftime') {
      context.read<MatchDetailCubit>().startPolling(widget.match.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: turfGreen,
        title: const Text(
          'Maç Merkezi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: teaBronze,
          labelColor: teaBronze,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'ÖZET'),
            Tab(text: 'KADRO'),
            Tab(text: 'FORUM'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildScoreboard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildSquadTab(),
                _buildForumTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }  Widget _buildScoreboard() {
    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        String matchStatus = widget.match.status;
        int? matchMinute = widget.match.minute;
        int homeScore = widget.match.homeScore;
        int awayScore = widget.match.awayScore;

        if (state is MatchDetailLoaded && state.details?.event != null) {
          final event = state.details!.event!;
          if (event['status'] != null) {
            if (event['status']['type'] == 'inprogress' || event['status']['type'] == 'live') matchStatus = 'live';
            if (event['status']['type'] == 'finished') matchStatus = 'finished';
          }
          if (matchStatus == 'finished') {
            matchMinute = 90;
          } else if (event['time'] != null) {
            if (event['time']['currentPeriodStartTimestamp'] != null) {
              matchMinute = ((DateTime.now().millisecondsSinceEpoch / 1000 - event['time']['currentPeriodStartTimestamp']) / 60).floor();
              if (event['status'] != null && event['status']['description'] == '2nd half') matchMinute = (matchMinute ?? 0) + 45;
              if (event['status'] != null && event['status']['description'] == 'Halftime') matchMinute = 45;
            } else if (event['time']['played'] != null) {
              matchMinute = event['time']['played'];
            }
          }
          if (event['homeScore'] != null && event['homeScore']['current'] != null) {
            homeScore = event['homeScore']['current'];
          }
          if (event['awayScore'] != null && event['awayScore']['current'] != null) {
            awayScore = event['awayScore']['current'];
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: const BoxDecoration(
            color: turfGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      widget.match.homeLogo,
                      width: 64,
                      height: 64,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.shield, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.homeTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$homeScore - $awayScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      matchStatus == 'live'
                          ? (matchMinute != null
                                ? '$matchMinute\''
                                : 'Canlı')
                          : 'MS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      widget.match.awayLogo,
                      width: 64,
                      height: 64,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.shield, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.awayTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSummaryTab() {
    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        if (state is MatchDetailLoading || state is MatchDetailInitial) {
          return const Center(child: CircularProgressIndicator(color: turfGreen));
        }
        if (state is MatchDetailError) {
          return Center(child: Text('Hata: ${state.message}'));
        }
        if (state is MatchDetailLoaded) {
          final details = state.details;
          if (details == null || details.statistics == null) {
            return const Center(child: Text('İstatistik bulunamadı.', style: TextStyle(color: Colors.grey)));
          }

          final statsData = details.statistics!['statistics'] as List<dynamic>?;
          if (statsData == null || statsData.isEmpty) {
            return const Center(child: Text('İstatistik bulunamadı.', style: TextStyle(color: Colors.grey)));
          }

          final groups = statsData[0]['groups'] as List<dynamic>?;
          if (groups == null || groups.isEmpty) {
            return const Center(child: Text('İstatistik bulunamadı.', style: TextStyle(color: Colors.grey)));
          }

          final items = groups[0]['statisticsItems'] as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name'] as String;
              final homeValStr = item['home'].toString();
              final awayValStr = item['away'].toString();
              
              // Normalize values for progress bar
              double homeVal = double.tryParse(item['homeValue']?.toString() ?? '0') ?? 0;
              double awayVal = double.tryParse(item['awayValue']?.toString() ?? '0') ?? 0;
              
              if (homeVal == 0 && awayVal == 0) {
                homeVal = 1; awayVal = 1; // dummy for zero-zero
              }
              
              final total = homeVal + awayVal;
              final homeFraction = total > 0 ? homeVal / total : 0.5;
              final awayFraction = total > 0 ? awayVal / total : 0.5;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(homeValStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(name, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(awayValStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: homeFraction,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: turfGreen,
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            height: 8,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: awayFraction,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: teaBronze,
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      }
    );
  }

  Widget _buildPlayerList(List<dynamic> players, List<dynamic> incidents, int? motmId) {
    final starters = players.where((p) => p['substitute'] != true).toList();
    final subs = players.where((p) => p['substitute'] == true).toList();

    return ListView(
      children: [
        if (starters.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('İlk 11', style: TextStyle(fontWeight: FontWeight.bold, color: turfGreen)),
          ),
          ...starters.map((p) => _buildPlayerTile(p, incidents, motmId)),
        ],
        if (subs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Yedekler', style: TextStyle(fontWeight: FontWeight.bold, color: turfGreen)),
          ),
          ...subs.map((p) => _buildPlayerTile(p, incidents, motmId)),
        ],
      ],
    );
  }

  Widget _buildPlayerTile(dynamic playerData, List<dynamic> incidents, int? motmId) {
    final player = playerData['player'];
    if (player == null) return const SizedBox.shrink();

    final playerId = player['id'];
    final number = playerData['jerseyNumber'] ?? '';
    final isMotm = motmId != null && playerId == motmId;

    // Find icons
    List<Widget> icons = [];
    for (var inc in incidents) {
      if (inc['player']?['id'] == playerId) {
        if (inc['incidentType'] == 'goal') icons.add(const Text('⚽', style: TextStyle(fontSize: 12)));
        if (inc['incidentType'] == 'card' && inc['incidentClass'] == 'yellow') icons.add(const Text('🟨', style: TextStyle(fontSize: 12)));
        if (inc['incidentType'] == 'card' && inc['incidentClass'] == 'red') icons.add(const Text('🟥', style: TextStyle(fontSize: 12)));
      }
      if (inc['assist1']?['id'] == playerId) {
        icons.add(const Text('👟', style: TextStyle(fontSize: 12)));
      }
      if (inc['incidentType'] == 'substitution' && inc['playerIn']?['id'] == playerId) {
        icons.add(const Icon(Icons.arrow_upward, color: Colors.green, size: 14));
      }
      if (inc['incidentType'] == 'substitution' && inc['playerOut']?['id'] == playerId) {
        icons.add(const Icon(Icons.arrow_downward, color: Colors.red, size: 14));
      }
    }

    return Container(
      decoration: isMotm ? BoxDecoration(
        color: teaBronze.withValues(alpha: 0.15),
        border: Border.all(color: teaBronze, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ) : null,
      margin: isMotm ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2) : EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMotm ? teaBronze : Colors.grey.shade200,
          radius: 14,
          child: Text(number.toString(), style: TextStyle(fontSize: 11, color: isMotm ? Colors.white : Colors.black, fontWeight: isMotm ? FontWeight.bold : FontWeight.normal)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player['shortName'] ?? player['name'] ?? '',
                style: TextStyle(fontSize: 13, fontWeight: isMotm ? FontWeight.w900 : FontWeight.bold, color: isMotm ? teaBronze : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMotm) const Text('🌟', style: TextStyle(fontSize: 14)),
          ],
        ),
        trailing: icons.isNotEmpty ? Row(
          mainAxisSize: MainAxisSize.min,
          children: icons,
        ) : null,
        dense: true,
      ),
    );
  }

  Widget _buildSquadTab() {
    return BlocBuilder<MatchDetailCubit, MatchDetailState>(
      builder: (context, state) {
        if (state is MatchDetailLoading || state is MatchDetailInitial) {
          return const Center(child: CircularProgressIndicator(color: turfGreen));
        }
        if (state is MatchDetailError) {
          return Center(child: Text('Hata: ${state.message}'));
        }
        if (state is MatchDetailLoaded) {
          final details = state.details;
          if (details == null || details.lineups == null) {
            return const Center(child: Text('Kadro bilgisi bulunamadı.', style: TextStyle(color: Colors.grey)));
          }

          final confirmed = details.lineups!['confirmed'] == true;
          final homePlayers = details.lineups!['home']?['players'] as List<dynamic>? ?? [];
          final awayPlayers = details.lineups!['away']?['players'] as List<dynamic>? ?? [];
          final incidents = details.incidents?['incidents'] as List<dynamic>? ?? [];

          if (homePlayers.isEmpty && awayPlayers.isEmpty) {
            return const Center(child: Text('Kadro bilgisi bulunamadı.', style: TextStyle(color: Colors.grey)));
          }

          int? motmId;
          if (widget.match.status == 'finished') {
            double highestRating = 0;
            for (var p in [...homePlayers, ...awayPlayers]) {
              final rating = p['statistics']?['rating'];
              if (rating != null && rating is num && rating > highestRating) {
                highestRating = rating.toDouble();
                motmId = p['player']?['id'];
              }
            }
          }

          return Column(
            children: [
              if (confirmed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.green.shade50,
                  child: const Text('Kadrolar Onaylandı', textAlign: TextAlign.center, style: TextStyle(color: turfGreen, fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: teaBronze,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black54,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(widget.match.homeLogo, width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(widget.match.homeTeam, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(widget.match.awayLogo, width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(widget.match.awayTeam, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPlayerList(homePlayers, incidents, motmId),
                            _buildPlayerList(awayPlayers, incidents, motmId),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      }
    );
  }

  Widget _buildForumTab() {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<MatchDetailCubit, MatchDetailState>(
            builder: (context, state) {
              if (state is MatchDetailLoading || state is MatchDetailInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: turfGreen),
                );
              }
              if (state is MatchDetailError) {
                return Center(
                  child: Text(
                    'Hata: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (state is MatchDetailLoaded) {
                final comments = state.comments;
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz yorum yapılmamış. İlk yorumu sen yap!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    
                    if (comment.isSystem) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            comment.content,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: turfGreen,
                            child: Text(
                              comment.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${comment.createdAt.hour.toString().padLeft(2, '0')}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 13),
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
              return const SizedBox.shrink();
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Yorum yap...',
                    hintStyle: const TextStyle(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: turfGreen),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: turfGreen,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      context.read<MatchDetailCubit>().addComment(
                        widget.match.id,
                        text,
                      );
                      _commentController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
