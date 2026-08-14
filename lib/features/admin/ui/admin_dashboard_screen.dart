import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../data/admin_repository.dart';

const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);

class AdminDashboardScreen extends StatelessWidget {
  final String userToken;

  const AdminDashboardScreen({super.key, required this.userToken});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCubit(AdminRepository(), userToken)..fetchTrackedMatches(),
      child: _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _homeLogoController = TextEditingController();
  final TextEditingController _awayLogoController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    _homeLogoController.dispose();
    _awayLogoController.dispose();
    super.dispose();
  }

  void _addMatch(BuildContext context) {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    final homeLogo = _homeLogoController.text.trim();
    final awayLogo = _awayLogoController.text.trim();
    context.read<AdminCubit>().addTrackedMatch(link, homeLogoUrl: homeLogo, awayLogoUrl: awayLogo);
    _linkController.clear();
    _homeLogoController.clear();
    _awayLogoController.clear();
  }

  void _removeMatch(BuildContext context, String id) {
    context.read<AdminCubit>().removeTrackedMatch(id);
  }

  Widget _buildSyncButton(BuildContext context, String label, String target) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: turfGreen)),
      onPressed: () {
        context.read<AdminCubit>().triggerScraper(target);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label tetiklendi.'), duration: const Duration(seconds: 2), backgroundColor: turfGreen),
        );
      },
      backgroundColor: Colors.white,
      side: const BorderSide(color: turfGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🛡️ Yönetim Paneli'),
        backgroundColor: turfGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          bool isLoading = state is AdminLoading;
          List<Map<String, dynamic>> matches = [];
          if (state is AdminLoaded) {
            matches = state.trackedMatches;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Veri Senkronizasyonu (Manuel)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: turfGreen),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSyncButton(context, 'Puan Durumu', 'standings'),
                    _buildSyncButton(context, 'Fikstür', 'fixtures'),
                    _buildSyncButton(context, 'Gol Krallığı', 'topscorers'),
                    _buildSyncButton(context, 'Transferler', 'transfers'),
                    _buildSyncButton(context, 'Kadrolar', 'squads'),
                    _buildSyncButton(context, 'Günün Maçları', 'live-matches'),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'SofaScore Canlı Maç Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: turfGreen),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SofaScore sitesinden kopyaladığınız maç bağlantısını aşağıya yapıştırın. Sistem bağlantıdan ID\'yi çekip takibe alacaktır.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    hintText: 'https://www.sofascore.com/...#id:12404099',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _homeLogoController,
                        decoration: InputDecoration(
                          hintText: 'Ev Sahibi Logo URL (İsteğe Bağlı)',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _awayLogoController,
                        decoration: InputDecoration(
                          hintText: 'Deplasman Logo URL (İsteğe Bağlı)',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _addMatch(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teaBronze,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Takibe Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Takip Edilen Manuel Maçlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: turfGreen),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading && matches.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : matches.isEmpty
                          ? const Center(
                              child: Text('Şu anda manuel takip edilen maç yok.', style: TextStyle(color: Colors.black54)),
                            )
                          : ListView.separated(
                              itemCount: matches.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final match = matches[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: turfGreen,
                                      child: Icon(Icons.sports_soccer, color: Colors.white),
                                    ),
                                    title: Text('SofaScore ID: ${match['sofaScoreId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Eklendi: ${match['createdAt'].toString().substring(0,10)}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _removeMatch(context, match['id']),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

