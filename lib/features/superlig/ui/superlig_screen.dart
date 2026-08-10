import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/superlig_cubit.dart';
import '../cubit/superlig_state.dart';
import '../data/models/superlig_models.dart';

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
    context.read<SuperligCubit>().fetchAllData();
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
                  KeepAlivePage(child: _buildTransfersTab(state.transfers, state.standings)),
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
                      if (e.clubLogoUrl != null) ...[
                        Image.network(
                          e.clubLogoUrl!,
                          width: 24,
                          height: 24,
                          errorBuilder: (c, err, s) => const Icon(
                            Icons.shield,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (e.clubSlug != null) ...[
                        Image.asset(
                          'assets/images/clubs/${e.clubSlug}.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (c, err, s) => const Icon(
                            Icons.shield,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Icon(Icons.shield, size: 24, color: Colors.grey),
                        const SizedBox(width: 8),
                      ],
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (f.homeClubLogoUrl != null)
                      Image.network(f.homeClubLogoUrl!, width: 24, height: 24)
                    else if (f.homeClubSlug != null)
                      Image.asset(
                        'assets/images/clubs/${f.homeClubSlug}.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.shield,
                          size: 24,
                          color: Colors.grey,
                        ),
                      )
                    else
                      const Icon(Icons.shield, size: 24, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.homeClubName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        f.awayClubName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (f.awayClubLogoUrl != null)
                      Image.network(f.awayClubLogoUrl!, width: 24, height: 24)
                    else if (f.awayClubSlug != null)
                      Image.asset(
                        'assets/images/clubs/${f.awayClubSlug}.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.shield,
                          size: 24,
                          color: Colors.grey,
                        ),
                      )
                    else
                      const Icon(Icons.shield, size: 24, color: Colors.grey),
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

  Widget _buildTransfersTab(List<Transfer> allTransfers, List<StandingsEntry> standings) {
    if (allTransfers.isEmpty) {
      return const Center(child: Text('Transfer geçmişi bulunamadı.'));
    }

    // Filter logic
    List<Transfer> displayedTransfers = allTransfers;
    if (_selectedTransferClubName != null) {
      displayedTransfers = allTransfers.where((t) => 
        t.toClubName == _selectedTransferClubName || 
        t.fromClubName == _selectedTransferClubName
      ).toList();
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
                    color: isSelected ? teaBronze.withValues(alpha: 0.3) : Colors.transparent,
                    border: isSelected ? Border.all(color: teaBronze, width: 2) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: s.clubLogoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: s.clubLogoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(Icons.shield, size: 20),
                        )
                      : s.clubSlug != null
                          ? Image.asset('assets/images/clubs/${s.clubSlug}.png', fit: BoxFit.contain)
                          : const Icon(Icons.shield, size: 20),
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
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: t.playerPhotoUrl != null
                        ? CachedNetworkImageProvider(t.playerPhotoUrl!)
                        : null,
                    child: t.playerPhotoUrl == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    t.playerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (t.fromClubLogoUrl != null)
                            CachedNetworkImage(
                              imageUrl: t.fromClubLogoUrl!,
                              width: 16,
                              height: 16,
                              errorWidget: (c, u, e) => const Icon(Icons.shield, size: 16),
                            )
                          else if (t.fromClubSlug != null)
                            Image.asset('assets/images/clubs/${t.fromClubSlug}.png', width: 16, height: 16)
                          else
                            const Icon(Icons.shield, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.fromClubName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
                          ),
                          if (t.toClubLogoUrl != null)
                            CachedNetworkImage(
                              imageUrl: t.toClubLogoUrl!,
                              width: 16,
                              height: 16,
                              errorWidget: (c, u, e) => const Icon(Icons.shield, size: 16),
                            )
                          else if (t.toClubSlug != null)
                            Image.asset('assets/images/clubs/${t.toClubSlug}.png', width: 16, height: 16)
                          else
                            const Icon(Icons.shield, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.toClubName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: teaBronze.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t.feeType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: turfGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
