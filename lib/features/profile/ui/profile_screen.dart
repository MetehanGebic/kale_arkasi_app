// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kale_arkasi_app/core/api_constants.dart';
import '../../../core/widgets/club_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../home/cubit/economy_cubit.dart';
import '../../home/cubit/economy_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/ui/login_screen.dart';
import '../../admin/ui/admin_dashboard_screen.dart';
import '../../superlig/cubit/superlig_cubit.dart';

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
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _selectedAvatar;

  bool _matchNotifs = true;
  bool _goalNotifs = true;
  bool _systemNotifs = true;
  String _currentLanguage = 'tr';
  String _currentTheme = 'sistem'; // acik, koyu, sistem
  List<String> _roles = ['user'];
  String? _remoteAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final user = await context.read<AuthRepository>().getUserProfile(
        widget.userToken,
      );
      if (mounted) {
        setState(() {
          _roles = user['role'] != null
              ? [user['role'].toString().toLowerCase()]
              : ['user'];
          _remoteAvatarUrl = user['avatarUrl'];
        });
      }
    } catch (e) {
      debugPrint("Profil verisi çekilemedi: $e");
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _matchNotifs = prefs.getBool('matchNotifs') ?? true;
      _goalNotifs = prefs.getBool('goalNotifs') ?? true;
      _systemNotifs = prefs.getBool('systemNotifs') ?? true;
      _currentLanguage = prefs.getString('language') ?? 'tr';
      _currentTheme = prefs.getString('theme') ?? 'sistem';
      _selectedAvatar = prefs.getString('avatar');
      final imgPath = prefs.getString('profileImagePath');
      if (imgPath != null && File(imgPath).existsSync()) {
        _selectedImage = File(imgPath);
      }
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Map<String, dynamic> _decodeToken() {
    if (widget.userToken.isEmpty) {
      return {'username': 'Kullanıcı', 'clubId': null, 'role': 'user'};
    }
    try {
      final parts = widget.userToken.split('.');
      if (parts.length != 3) {
        return {'username': 'Kullanıcı', 'clubId': null, 'role': 'user'};
      }
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded);
      return map;
    } catch (e) {
      return {'username': 'Kullanıcı', 'clubId': null, 'role': 'user'};
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedAvatar = null;
        });
        await _savePreference('profileImagePath', image.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('avatar');

        // Backend'e Yükle
        if (mounted) {
          try {
            final newUrl = await context.read<AuthRepository>().uploadAvatar(
              widget.userToken,
              image.path,
            );
            if (mounted) {
              setState(() => _remoteAvatarUrl = newUrl);
            }
          } catch (uploadErr) {
            debugPrint("Fotoğraf yükleme hatası: $uploadErr");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fotoğraf sunucuya yüklenemedi.')),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Görsel seçilemedi: $e");
    }
  }

  void _showAvatarPicker() {
    final List<IconData> predefinedAvatars = [
      Icons.person,
      Icons.sports_soccer,
      Icons.sports_esports,
      Icons.stadium,
      Icons.local_fire_department,
      Icons.star,
      Icons.mood,
      Icons.rocket_launch,
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profil Fotoğrafı Seç',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: turfGreen),
                  title: const Text('Kameradan Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: turfGreen),
                  title: const Text('Galeriden Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                const Text(
                  'Veya Hazır Avatar Seç',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: predefinedAvatars.map((icon) {
                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedAvatar = icon.codePoint.toString();
                          _selectedImage = null;
                        });
                        await _savePreference(
                          'avatar',
                          icon.codePoint.toString(),
                        );
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('profileImagePath');
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: turfGreen.withValues(alpha: 0.1),
                        child: Icon(icon, color: turfGreen, size: 28),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bildirim Tercihleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      activeThumbColor: turfGreen,
                      title: const Text('Maç Başlıyor Bildirimi'),
                      value: _matchNotifs,
                      onChanged: (val) {
                        setState(() => _matchNotifs = val);
                        setModalState(() => _matchNotifs = val);
                        _savePreference('matchNotifs', val);
                      },
                    ),
                    SwitchListTile(
                      activeThumbColor: turfGreen,
                      title: const Text('Gol Bildirimleri'),
                      value: _goalNotifs,
                      onChanged: (val) {
                        setState(() => _goalNotifs = val);
                        setModalState(() => _goalNotifs = val);
                        _savePreference('goalNotifs', val);
                      },
                    ),
                    SwitchListTile(
                      activeThumbColor: turfGreen,
                      title: const Text('Önemli Sistem Mesajları'),
                      value: _systemNotifs,
                      onChanged: (val) {
                        setState(() => _systemNotifs = val);
                        setModalState(() => _systemNotifs = val);
                        _savePreference('systemNotifs', val);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dil Seçimi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('Türkçe'),
                  value: 'tr',
                  groupValue: _currentLanguage,
                  onChanged: (val) {
                    setState(() => _currentLanguage = val!);
                    _savePreference('language', val);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('English (Yakında)'),
                  value: 'en',
                  groupValue: _currentLanguage,
                  onChanged: null, // Disabled for now
                ),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('العربية (Yakında)'),
                  value: 'ar',
                  groupValue: _currentLanguage,
                  onChanged: null, // Disabled for now
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Uygulama Teması',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Not: Karanlık mod altyapısı şu an bakım aşamasındadır.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('Sistem Varsayılanı'),
                  value: 'sistem',
                  groupValue: _currentTheme,
                  onChanged: (val) {
                    setState(() => _currentTheme = val!);
                    _savePreference('theme', val);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('Açık Tema'),
                  value: 'acik',
                  groupValue: _currentTheme,
                  onChanged: (val) {
                    setState(() => _currentTheme = val!);
                    _savePreference('theme', val);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  activeColor: turfGreen,
                  title: const Text('Koyu Tema (Yakında)'),
                  value: 'koyu',
                  groupValue: _currentTheme,
                  onChanged: null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthRepository>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            child: const Text('Çıkış', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenData = _decodeToken();
    final String username = tokenData['username'] ?? 'Kullanıcı';
    final String? clubId = tokenData['clubId'];
    final List<String> roles = _roles;

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
            _buildSettingsList(context, roles),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String username) {
    const String userRank = "Tribün Lideri";

    Widget avatarContent;
    if (_selectedImage != null) {
      avatarContent = ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    } else if (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(
          '${ApiConstants.identityUrl.replaceAll('/api/identity', '')}$_remoteAvatarUrl',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.person, size: 56, color: Colors.white),
        ),
      );
    } else if (_selectedAvatar != null) {
      avatarContent = Icon(
        // ignore: non_const_argument_for_const_parameter
        IconData(int.parse(_selectedAvatar!), fontFamily: 'MaterialIcons'),
        size: 56,
        color: Colors.white,
      );
    } else {
      avatarContent = Text(
        username.isNotEmpty && username != 'Kullanıcı'
            ? username[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      );
    }

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
                radius: 50,
                backgroundColor: Colors.white24,
                child: avatarContent,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: teaBronze,
                    shape: BoxShape.circle,
                    border: Border.all(color: turfGreen, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 12, color: darkSurface),
                    onPressed: _showAvatarPicker,
                    constraints: const BoxConstraints(
                      minHeight: 15,
                      minWidth: 15,
                    ),
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
                        'Çay Bakiyesi',
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
                          const Text('☕ ', style: TextStyle(fontSize: 24)),
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
                    'İstatistikler',
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
                      _buildMiniStat(Icons.stadium, '12', 'Maç'),
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
              'Favori Takım',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (clubId == null)
              const Text(
                "Favori takım seçilmemiş.",
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
                          ClubLogo(
                            clubSlug: club['slug'],
                            logoUrl: club['logoUrl'],
                            width: 48,
                            height: 48,
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
                      return const Text("Takım bilgisi bulunamadı.");
                    }
                  }
                  return const Text("Hata oluştu.");
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, List<String> roles) {
    // TODO: Revert to roles check after backend Phase 2 is complete.
    final bool isAdminOrMod = true; // roles.contains('admin') || roles.contains('moderator');
    final bool isCreator = roles.contains('creator');
    final bool showCreatorPanel = isAdminOrMod || isCreator;

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
              if (isAdminOrMod) ...[
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    'Yönetim Paneli',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminDashboardScreen(
                          userToken: widget.userToken,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<SuperligCubit>().fetchAllData();
                    }
                  },
                ),
                const Divider(height: 1),
              ],

              if (showCreatorPanel) ...[
                ListTile(
                  leading: const Icon(Icons.stars, color: teaBronze),
                  title: const Text(
                    'İçerik Üreticisi Paneli',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: teaBronze,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İçerik üreticisi özellikleri yakında!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ],

              ListTile(
                leading: const Icon(Icons.language, color: turfGreen),
                title: const Text(
                  'Dil Seçimi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showLanguageSettings,
              ),
              const Divider(height: 1),
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
                onTap: _showNotificationSettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: turfGreen),
                title: const Text(
                  'Uygulama Teması',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showThemeSettings,
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline, color: turfGreen),
                title: Text(
                  'Hakkında (Sürüm 1.0.0)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
