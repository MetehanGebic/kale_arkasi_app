import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/superlig_cubit.dart';
import '../cubit/superlig_state.dart';
import '../data/models/superlig_models.dart';

class TeamProfileScreen extends StatelessWidget {
  final String clubName;

  const TeamProfileScreen({super.key, required this.clubName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperligCubit, SuperligState>(
      builder: (context, state) {
        if (state is SuperligLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is SuperligError) {
          return Scaffold(body: Center(child: Text(state.message)));
        } else if (state is SuperligLoaded) {
          // Find club info
          final StandingsEntry? clubEntry = state.standings.where((s) => s.clubName == clubName).firstOrNull;

          if (clubEntry == null) {
            return const Scaffold(body: Center(child: Text('Takım bulunamadı.')));
          }

          // Filter other data
          final clubFixtures = state.fixtures
              .where((f) => f.homeClubName == clubName || f.awayClubName == clubName)
              .toList();
          final clubScorers = state.topScorers
              .where((s) => s.clubName == clubName)
              .toList();
          final clubTransfers = state.transfers
              .where((t) => t.fromClubName == clubName || t.toClubName == clubName)
              .toList();

          return DefaultTabController(
            length: 4,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 250.0,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Generic stadium background
                            Image.asset(
                              'assets/images/stadium_bg.jpg', // Assuming we have this or use a color
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.green.shade900),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                if (clubEntry.clubLogoUrl != null)
                                  CachedNetworkImage(
                                    imageUrl: clubEntry.clubLogoUrl!,
                                    height: 80,
                                    errorWidget: (c, u, e) => const Icon(Icons.shield, size: 80, color: Colors.white),
                                  )
                                else if (clubEntry.clubSlug != null)
                                  Image.asset(
                                    'assets/images/clubs/${clubEntry.clubSlug}.png',
                                    height: 80,
                                  )
                                else
                                  const Icon(Icons.shield, size: 80, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(
                                  clubEntry.clubName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lig Sırası: ${clubEntry.rank}. | Puan: ${clubEntry.points}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      bottom: const TabBar(
                        isScrollable: true,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        tabs: [
                          Tab(text: 'KADRO'),
                          Tab(text: 'FİKSTÜR'),
                          Tab(text: 'TRANSFERLER'),
                          Tab(text: 'İSTATİSTİK'),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildSquadTab(clubEntry.players),
                    _buildFixturesTab(clubFixtures, clubName),
                    _buildTransfersTab(clubTransfers, clubName),
                    _buildStatsTab(clubEntry, clubScorers),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSquadTab(List<Player> players) {
    if (players.isEmpty) {
      return const Center(child: Text('Kadro bilgisi bulunamadı veya henüz güncellenmedi.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: p.photoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: p.photoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(p.position ?? 'Mevki Bilinmiyor'),
            trailing: p.shirtNumber != null
                ? CircleAvatar(
                    backgroundColor: Colors.green.shade900,
                    radius: 16,
                    child: Text(
                      p.shirtNumber!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFixturesTab(List<Fixture> fixtures, String myClubName) {
    if (fixtures.isEmpty) return const Center(child: Text('Fikstür bulunamadı.'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: fixtures.length,
      itemBuilder: (context, index) {
        final f = fixtures[index];
        final isHome = f.homeClubName == myClubName;
        final opponentName = isHome ? f.awayClubName : f.homeClubName;
        final opponentLogoUrl = isHome ? f.awayClubLogoUrl : f.homeClubLogoUrl;

        Color resultColor = Colors.grey;
        String resultText = '-';
        if (f.homeScore != null && f.awayScore != null) {
          if (f.homeScore == f.awayScore) {
            resultColor = Colors.orange;
            resultText = 'B';
          } else if ((isHome && f.homeScore! > f.awayScore!) || (!isHome && f.awayScore! > f.homeScore!)) {
            resultColor = Colors.green;
            resultText = 'G';
          } else {
            resultColor = Colors.red;
            resultText = 'M';
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: resultColor,
              radius: 16,
              child: Text(resultText, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Row(
              children: [
                if (opponentLogoUrl != null)
                  CachedNetworkImage(imageUrl: opponentLogoUrl, width: 20, height: 20)
                else
                  const Icon(Icons.shield, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(opponentName, overflow: TextOverflow.ellipsis)),
              ],
            ),
            subtitle: Text('${f.week}. Hafta | ${f.matchDate.day.toString().padLeft(2, '0')}.${f.matchDate.month.toString().padLeft(2, '0')}.${f.matchDate.year}'),
            trailing: Text(
              f.homeScore != null ? '${f.homeScore} - ${f.awayScore}' : 'v',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransfersTab(List<Transfer> transfers, String myClubName) {
    if (transfers.isEmpty) return const Center(child: Text('Transfer bulunamadı.'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final t = transfers[index];
        final isIncoming = t.toClubName == myClubName;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: t.playerPhotoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: t.playerPhotoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(t.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Icon(
                  isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncoming ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isIncoming ? 'Geldiği Takım: ${t.fromClubName}' : 'Gittiği Takım: ${t.toClubName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isIncoming ? Colors.green.shade500 : Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                t.feeType,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(StandingsEntry club, List<TopScorer> scorers) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Puan Durumu Özeti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                _StatRow(label: 'Sıralama', value: '${club.rank}.'),
                _StatRow(label: 'Oynanan Maç', value: '${club.played}'),
                _StatRow(label: 'Galibiyet', value: '${club.won}'),
                _StatRow(label: 'Beraberlik', value: '${club.drawn}'),
                _StatRow(label: 'Mağlubiyet', value: '${club.lost}'),
                _StatRow(label: 'Atılan Gol', value: '${club.goalsFor}'),
                _StatRow(label: 'Yenilen Gol', value: '${club.goalsAgainst}'),
                _StatRow(label: 'Averaj', value: '${club.goalDiff}'),
                _StatRow(label: 'Puan', value: '${club.points}', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (scorers.isNotEmpty) ...[
          const Text('Takımın En Golcüleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 8),
          ...scorers.map((s) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade900,
                child: Text('${s.rank}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(s.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('${s.goals} Gol', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )),
        ]
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _StatRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
