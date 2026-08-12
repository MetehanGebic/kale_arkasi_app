import 'package:flutter/material.dart';
import '../../../core/widgets/club_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/superlig_cubit.dart';
import '../cubit/superlig_state.dart';
import '../data/models/superlig_models.dart';
import 'team_profile_screen.dart';

const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

class SuperligScreen extends StatefulWidget {
  const SuperligScreen({super.key});

  @override
  State<SuperligScreen> createState() => _SuperligScreenState();
}

class _SuperligScreenState extends State<SuperligScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedWeek;
  String? _selectedTransferClubName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: turfGreen,
        title: const Text(
          'Süper Lig',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: teaBronze,
          indicatorWeight: 3,
          labelColor: teaBronze,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Puan Durumu'),
            Tab(text: 'Fikstür'),
            Tab(text: 'Gol Krallığı'),
            Tab(text: 'Son Transferler'),
          ],
        ),
      ),
      body: BlocBuilder<SuperligCubit, SuperligState>(
        builder: (context, state) {
          if (state is SuperligLoading || state is SuperligInitial) {
            return const Center(
              child: CircularProgressIndicator(color: turfGreen),
            );
          } else if (state is SuperligError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Hata: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<SuperligCubit>().fetchAllData(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (state is SuperligLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                KeepAlivePage(child: _buildStandingsTab(state.standings)),
                KeepAlivePage(child: _buildFixturesTab(state.fixtures)),
                KeepAlivePage(child: _buildTopScorersTab(state.topScorers)),
                KeepAlivePage(
                  child: _buildTransfersTab(state.transfers, state.standings),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStandingsTab(List<StandingsEntry> standings) {
    if (standings.isEmpty) {
      return const Center(child: Text('Puan durumu bulunamadı.'));
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: DataTable(
          showCheckboxColumn: false,
          horizontalMargin: 10,
          columnSpacing: 10,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: turfGreen,
          ),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Takım')),
            DataColumn(label: Text('O')),
            DataColumn(label: Text('G')),
            DataColumn(label: Text('B')),
            DataColumn(label: Text('M')),
            DataColumn(label: Text('A')),
            DataColumn(label: Text('Y')),
            DataColumn(label: Text('AV')),
            DataColumn(label: Text('P')),
          ],
          rows: standings.map((e) {
            return DataRow(
              onSelectChanged: (_) {
                final cubit = context.read<SuperligCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: cubit,
                      child: TeamProfileScreen(clubName: e.clubName),
                    ),
                  ),
                );
              },
              cells: [
                DataCell(
                  Text(
                    '${e.rank}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      ClubLogo(clubSlug: e.clubSlug, logoUrl: e.clubLogoUrl, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        e.clubName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                DataCell(Text('${e.played}')),
                DataCell(Text('${e.won}')),
                DataCell(Text('${e.drawn}')),
                DataCell(Text('${e.lost}')),
                DataCell(Text('${e.goalsFor}')),
                DataCell(Text('${e.goalsAgainst}')),
                DataCell(Text('${e.goalDiff}')),
                DataCell(
                  Text(
                    '${e.points}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFixturesTab(List<Fixture> fixtures) {
    if (fixtures.isEmpty) {
      return const Center(child: Text('Fikstür bulunamadı.'));
    }
    // Grouplayalım
    final Map<int, List<Fixture>> byWeek = {};
    for (var f in fixtures) {
      if (!byWeek.containsKey(f.week)) byWeek[f.week] = [];
      byWeek[f.week]!.add(f);
    }
    final sortedWeeks = byWeek.keys.toList()..sort();

    // Default to first week if none selected
    _selectedWeek ??= sortedWeeks.isNotEmpty ? sortedWeeks.first : 1;
    final currentWeek = _selectedWeek!;
    final weekFixtures = byWeek[currentWeek] ?? [];

    return Column(
      children: [
        // Hafta Seçici (Week Selector)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: currentWeek > 1
                    ? () => setState(() => _selectedWeek = currentWeek - 1)
                    : null,
                color: currentWeek > 1 ? turfGreen : Colors.grey,
              ),
              Text(
                '$currentWeek. Hafta',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: turfGreen,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: currentWeek < 34
                    ? () => setState(() => _selectedWeek = currentWeek + 1)
                    : null,
                color: currentWeek < 34 ? turfGreen : Colors.grey,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: weekFixtures.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final f = weekFixtures[index];
              return _buildFixtureCard(f);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFixtureCard(Fixture f) {
    final String dateStr =
        '${f.matchDate.day.toString().padLeft(2, '0')}.${f.matchDate.month.toString().padLeft(2, '0')}.${f.matchDate.year} ${f.matchDate.hour.toString().padLeft(2, '0')}:${f.matchDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    ClubLogo(clubSlug: f.homeClubSlug, logoUrl: f.homeClubLogoUrl, width: 32, height: 32),
                    const SizedBox(height: 6),
                    Text(
                      f.homeClubName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      (f.homeScore != null && f.awayScore != null)
                          ? '${f.homeScore} - ${f.awayScore}'
                          : 'v',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    ClubLogo(clubSlug: f.awayClubSlug, logoUrl: f.awayClubLogoUrl, width: 32, height: 32),
                    const SizedBox(height: 6),
                    Text(
                      f.awayClubName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopScorersTab(List<TopScorer> scorers) {
    if (scorers.isEmpty) {
      return const Center(child: Text('Gol krallığı bulunamadı.'));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: scorers.length,
      itemBuilder: (context, index) {
        final s = scorers[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: turfGreen,
              child: Text(
                '${s.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              s.playerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(s.clubName),
            trailing: Text(
              '${s.goals} Gol',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: teaBronze,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransfersTab(
    List<Transfer> allTransfers,
    List<StandingsEntry> standings,
  ) {
    if (allTransfers.isEmpty) {
      return const Center(child: Text('Transfer geçmişi bulunamadı.'));
    }

    // Filter logic
    List<Transfer> displayedTransfers = allTransfers;
    if (_selectedTransferClubName != null) {
      displayedTransfers = allTransfers
          .where(
            (t) =>
                t.toClubName == _selectedTransferClubName ||
                t.fromClubName == _selectedTransferClubName,
          )
          .toList();
    } else {
      // Default: Top 50 transfers
      displayedTransfers = allTransfers.take(50).toList();
    }

    return Column(
      children: [
        // Kulüp Filtresi (9 sütun, 2 satır grid)
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final s = standings[index];
              final isSelected = _selectedTransferClubName == s.clubName;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTransferClubName = null; // Toggle off
                    } else {
                      _selectedTransferClubName = s.clubName;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? teaBronze.withValues(alpha: 0.3)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: teaBronze, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClubLogo(clubSlug: s.clubSlug, logoUrl: s.clubLogoUrl, width: 20, height: 20, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Transfer Listesi
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: displayedTransfers.length,
            itemBuilder: (context, index) {
              final t = displayedTransfers[index];

              Color badgeBgColor = teaBronze.withValues(alpha: 0.2);
              Color badgeTextColor = turfGreen;
              if (_selectedTransferClubName != null) {
                if (t.fromClubName == _selectedTransferClubName) {
                  badgeBgColor = Colors.red.shade400;
                  badgeTextColor = Colors.white;
                } else if (t.toClubName == _selectedTransferClubName) {
                  badgeBgColor = Colors.green.shade500;
                  badgeTextColor = Colors.white;
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 45,
                    height: 45,
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
                                fit: BoxFit
                                    .contain, // Fotoğrafın tamamını sığdır
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.playerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.feeType,
                          style: TextStyle(
                            fontSize: 10,
                            color: badgeTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ClubLogo(clubSlug: t.fromClubSlug, logoUrl: t.fromClubLogoUrl, width: 16, height: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.fromClubName,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                          ClubLogo(clubSlug: t.toClubSlug, logoUrl: t.toClubLogoUrl, width: 16, height: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.toClubName,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
