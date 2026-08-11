import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/ui/login_screen.dart';
import '../../home/cubit/economy_cubit.dart';
import '../../home/cubit/economy_state.dart';

// -- Renk Paleti --
const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

class ProfileScreen extends StatefulWidget {
  final String userToken;

  const ProfileScreen({super.key, required this.userToken});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _decodeToken() {
    if (widget.userToken.isEmpty) {
      return {'username': 'Kullanıcı', 'clubId': null};
    }
    try {
      final parts = widget.userToken.split('.');
      if (parts.length != 3) {
        return {'username': 'Kullanıcı', 'clubId': null};
      }
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded);
      return map;
    } catch (e) {
      return {'username': 'KullanÃ„Â±cÃ„Â±', 'clubId': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenData = _decodeToken();
    final String username = tokenData['username'] ?? 'KullanÃ„Â±cÃ„Â±';
    final String? clubId = tokenData['clubId'];

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: turfGreen,
        elevation: 0,
        title: const Text(
          'Profilim',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(username),
            const SizedBox(height: 16),
            _buildStatsAndBalance(context),
            const SizedBox(height: 16),
            _buildFavoriteTeam(clubId),
            const SizedBox(height: 16),
            _buildSettingsList(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

    Widget _buildHeader(String username) {
    // Mock RÃ¼tbe (Ä°leride backend'den alÄ±nacak)
    const String userRank = "TribÃ¼n Lideri";

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: turfGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                child: Text(
                  username.isNotEmpty && username != 'KullanÄ±cÄ±'
                      ? username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: teaBronze,
                    shape: BoxShape.circle,
                    border: Border.all(color: turfGreen, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: darkSurface),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil fotoÄŸrafÄ± dÃ¼zenleme Ã§ok yakÄ±nda!')),
                      );
                    },
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: teaBronze,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  userRank,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndBalance(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<EconomyCubit, EconomyState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      const Text(
                        'Ãƒâ€¡ay Bakiyesi',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Ã¢Ëœâ€¢', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            '${state.balance}',
                            style: const TextStyle(
                              color: turfGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Ã„Â°statistikler',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat(Icons.stadium, '12', 'MaÃƒÂ§'),
                      _buildMiniStat(Icons.poll, '45', 'Oy'),
                      _buildMiniStat(Icons.chat, '128', 'Mesaj'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: teaBronze, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFavoriteTeam(String? clubId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favori Takim',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (clubId == null)
              const Text(
                "Favori takim secilmemis.",
                style: TextStyle(color: Colors.grey),
              )
            else
              FutureBuilder<List<dynamic>>(
                future: context.read<AuthRepository>().getClubs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: turfGreen),
                    );
                  }
                  if (snapshot.hasData) {
                    try {
                      final clubs = snapshot.data!;
                      final club = clubs.firstWhere((c) => c['id'] == clubId);
                      return Row(
                        children: [
                          if (club['logoUrl'] != null &&
                              club['logoUrl'].toString().isNotEmpty)
                            Image.network(
                              club['logoUrl'],
                              width: 48,
                              height: 48,
                            )
                          else
                            const Icon(
                              Icons.shield,
                              size: 48,
                              color: turfGreen,
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              club['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: darkSurface,
                              ),
                            ),
                          ),
                        ],
                      );
                    } catch (e) {
                      return const Text("Takim bilgisi bulunamadi.");
                    }
                  }
                  return const Text("Hata olustu.");
                },
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildSettingsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: turfGreen,
                ),
                title: const Text(
                  'Bildirim Tercihleri',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bildirim ayarlari cok yakinda!'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: turfGreen),
                title: const Text(
                  'Uygulama Temasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tema secimi yakinda!')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: turfGreen),
                title: const Text(
                  'Hakkinda (Surum 1.0.0)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Cikis Yap',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
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
        ),
      ),
    );
  }
}



