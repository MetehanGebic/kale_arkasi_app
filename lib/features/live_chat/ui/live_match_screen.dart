import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/widgets/club_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import '../../../core/network/socket_client.dart';
import '../../home/cubit/economy_cubit.dart';
import '../../home/cubit/economy_state.dart';

const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;

  const LiveMatchScreen({
    super.key,
    required this.matchId,
    this.homeTeam = 'Çorum FK',
    this.awayTeam = 'Galatasaray',
    this.homeLogo,
    this.awayLogo,
  });

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  late ConfettiController _confettiController;
  bool _isFlashing = false;

  int _capoMessagesLeft = 0;
  final Map<String, bool> _redCardHistory = {};
  final Set<String> _myVotedPolls = {};
  final Map<String, DateTime> _pollStartTimes = {};
  Timer? _pollTimer;
  final List<String> _activeUsers = [
    'Veli',
    'Ahmet',
    'Mehmet',
    'Ayşe',
    'Burak',
  ];

  final Map<String, dynamic> _pinnedMessage = {
    'sender': 'Ahmet',
    'message': 'Saldır Çorum FK!',
    'team': 'home',
  };

  // Live Data for messages
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });

    // 3 sekmeli tab controller: 0 -> Ev Sahibi, 1 -> Tarafsız (default), 2 -> Deplasman
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {}); // Rebuild UI for dynamic colors
    });

    // Bağlan ve olayları dinle
    SocketClient().joinMatch(widget.matchId);

    SocketClient().onPollUpdated((data) {
      if (mounted) {
        setState(() {
          final String pollId = data['pollId'];
          final List options = data['options'] ?? [];
          for (int i = 0; i < _messages.length; i++) {
            final msg = _messages[i];
            if (msg['isPoll'] == true && msg['pollData']['id'] == pollId) {
              msg['pollData']['options'] = options;
            }
          }
        });
      }
    });

    SocketClient().onChatMessage((data) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': data['sender'],
            'isBot': data['isSystem'] ?? false,
            'message': data['text'],
            'team': data['isSystem'] == true ? 'system' : 'neutral',
            'isCapo': data['isCapo'] ?? false,
            'isTeaGift': false,
            'isPredictionCard': false,
            'storeAsset': null,
            'isPoll': data['isPoll'] ?? false,
            'pollData': data['pollData'],
          });
        });
      }
    });

    SocketClient().onAddonEvent((data) {
      if (mounted) {
        final type = data['type'];
        if (type == 'capo') {
          setState(() => _capoMessagesLeft = 3);
        } else if (type == 'red_card' && data['target'] != null) {
          setState(() {
            _redCardHistory[data['target']] = true;
          });
        }
        
        String? asset = data['storeAsset'];
        if (asset != null) {
          asset = asset.replaceAll('mesale.png', 'mesale.gif');
          asset = asset.replaceAll('kirmizi_kart.png', 'kart.png');
          asset = asset.replaceAll('cekirdek.png', 'cekirdek.gif');
        }

        setState(() {
          _messages.add({
            'sender': data['sender'],
            'isBot': data['isSystem'] ?? false,
            'message': data['text'],
            'team': 'system',
            'isCapo': false,
            'isTeaGift': type == 'cay',
            'storeAsset': asset,
          });
        });
      }
    });

    SocketClient().onSocketError((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  void dispose() {
    SocketClient().offChatMessage();
    SocketClient().offPollUpdated();
    SocketClient().offAddonEvent();
    SocketClient().leaveMatch(widget.matchId);
    
    _pollTimer?.cancel();
    _confettiController.dispose();
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showStoreMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'KAHVEHANE EKLENTİLERİ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: teaBronze,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: [
                    _buildStoreItem(
                      'Çay Ismarla',
                      'Herkese çay',
                      '50 ☕',
                      'assets/images/store/cay.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'cay');
                      },
                    ),
                    _buildStoreItem(
                      'Amigo Modu',
                      'Devasa mesaj',
                      '400 ☕',
                      'assets/images/store/capo.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'capo');
                      },
                    ),
                    _buildStoreItem(
                      'Yabancı Madde',
                      'Şişe fırlat',
                      '50 ☕',
                      'assets/images/store/madde.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'madde');
                      },
                    ),
                    _buildStoreItem(
                      'Meşale Yak',
                      'Tribün ateşi',
                      '200 ☕',
                      'assets/images/store/mesale.gif',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'mesale');
                      },
                    ),
                    _buildStoreItem(
                      'Çekirdek',
                      'Çitleyip izle',
                      '30 ☕',
                      'assets/images/store/cekirdek.gif',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'cekirdek');
                      },
                    ),
                    _buildStoreItem(
                      'Davul Çal',
                      'Ritme ayak uydur',
                      '100 ☕',
                      'assets/images/store/davul.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'davul');
                      },
                    ),
                    _buildStoreItem(
                      'Kırmızı Kart',
                      'Sustur (Ã…Âaka)',
                      '100 ☕',
                      'assets/images/store/kart.png',
                      () {
                        Navigator.pop(context);
                        _showRedCardDialog();
                      },
                    ),
                    _buildStoreItem(
                      'Gözlük',
                      'Hakem kör',
                      '25 ☕',
                      'assets/images/store/gozluk.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'gozluk');
                      },
                    ),
                    _buildStoreItem(
                      'Küfür',
                      'Hakeme isyan',
                      '30 ☕',
                      'assets/images/store/kufur.png',
                      () {
                        Navigator.pop(context);
                        SocketClient().buyAddon('match_1', 'kufur');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRedCardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Kırmızı Kart Kime?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
            physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemCount: _activeUsers.length,
              itemBuilder: (c, i) {
                final user = _activeUsers[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(user[0])),
                  title: Text(user),
                  onTap: () {
                    Navigator.pop(ctx); // Dialog'u kapat
                    if (_redCardHistory[user] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$user bu maçta zaten kırmızı kart gördü!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      SocketClient().buyAddon(
                        'match_1',
                        'red_card',
                        target: user,
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreItem(
    String title,
    String description,
    String price,
    String assetPath,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: const TextStyle(fontSize: 8, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: teaBronze.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      fontSize: 9,
                      color: teaBronze,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(
    String sender,
    String text, {
    bool isSystem = false,
    bool isTeaGift = false,
    bool isCapo = false,
    bool isPredictionCard = false,
    bool isGoal = false,
    String? storeAsset,
  }) {
    if (text.trim().isEmpty && !isPredictionCard) return;

    if (isGoal) {
      _triggerGoal();
    }

    if (!isSystem && !isPredictionCard && text.trim().isNotEmpty) {
      bool sendAsCapo = _capoMessagesLeft > 0;
      if (sendAsCapo) {
        setState(() => _capoMessagesLeft--);
      }
      SocketClient().sendMessage('match_1', text, isCapo: sendAsCapo);
    } else {
      // Local fallbacks or prediction cards
      String? asset = storeAsset;
      if (asset != null) {
        asset = asset.replaceAll('mesale.png', 'mesale.gif');
        asset = asset.replaceAll('kirmizi_kart.png', 'kart.png');
        asset = asset.replaceAll('cekirdek.png', 'cekirdek.gif');
      }
      
      setState(() {
        _messages.add({
          'sender': sender,
          'isBot': isSystem,
          'message': text,
          'team': isSystem ? 'system' : 'home',
          'isCapo': isCapo,
          'isTeaGift': isTeaGift,
          'isPredictionCard': isPredictionCard,
          'storeAsset': asset,
        });
      });
    }
    _messageController.clear();
  }

  void _triggerGoal() {
    _confettiController.play();
    setState(() {
      _isFlashing = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = teaBronze;
    if (_tabController.index == 0) activeColor = Colors.red.shade700;
    if (_tabController.index == 2) activeColor = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: turfGreen,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CANLI KAHVEHANE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: teaBronze,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.homeLogo != null 
                    ? ClubLogo(clubSlug: null, logoUrl: widget.homeLogo, width: 20, height: 20)
                    : const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          'Ç',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(width: 6),
                Text(
                  widget.homeTeam,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '0 - 0',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: teaBronze,
                    ),
                  ),
                ),
                Text(
                  widget.awayTeam,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                widget.awayLogo != null 
                    ? ClubLogo(clubSlug: null, logoUrl: widget.awayLogo, width: 20, height: 20)
                    : const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          'GS',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "12'",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: teaBronze,
          labelColor: teaBronze,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: widget.homeTeam),
            const Tab(text: 'Meydan'),
            Tab(text: widget.awayTeam),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Flashing background for goals
          if (_isFlashing)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: sin(value * pi),
                  child: Container(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                );
              },
            ),

          Column(
            children: [
              _buildPinnedMessage(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatRoom('home'),
                    _buildChatRoom('neutral'),
                    _buildChatRoom('away'),
                  ],
                ),
              ),
              _buildMessageInput(activeColor),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // downwards
              maxBlastForce: 20, // set a lower max blast force
              minBlastForce: 5, // set a lower min blast force
              emissionFrequency: 0.05,
              numberOfParticles: 20, // a lot of particles at once
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: teaBronze.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: teaBronze, width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: teaBronze, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📌 Sabitlenmiş Mesaj: ${_pinnedMessage['sender']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: teaBronze,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _pinnedMessage['message'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoom(String roomType) {
    Widget? watermark;
    Color bgColor = surfaceColor;
    DecorationImage? subtleTexture;

    if (roomType == 'home') {
      bgColor = Colors.red.withValues(
        alpha: 0.92,
      ); // 92% opacity to let 8% of the stadium bleed through as a subtle texture
      watermark = Icon(
        Icons.shield,
        size: 250,
        color: Colors.white.withValues(alpha: 0.15),
      );
      subtleTexture = const DecorationImage(
        image: AssetImage('assets/images/stadium_bg.jpg'),
        fit: BoxFit.cover,
      );
    } else if (roomType == 'away') {
      bgColor = Colors.orange.withValues(alpha: 0.92);
      watermark = Icon(
        Icons.security,
        size: 250,
        color: Colors.white.withValues(alpha: 0.15),
      );
      subtleTexture = const DecorationImage(
        image: AssetImage('assets/images/stadium_bg.jpg'),
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: BoxDecoration(color: surfaceColor, image: subtleTexture),
      child: Stack(
        children: [
          if (subtleTexture != null) Container(color: bgColor),
          if (watermark != null) Center(child: watermark),
          ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildMessageBubble(msg, roomType);
            },
          ),
        ],
      ),
    );
  }

    Widget _buildPollWidget(Map<String, dynamic> pollData) {
    final String pollId = pollData['id'] ?? '';
    final String question = pollData['question'] ?? 'Anket';
    final List options = pollData['options'] ?? [];

    _pollStartTimes.putIfAbsent(pollId, () => DateTime.now());
    final elapsed = DateTime.now().difference(_pollStartTimes[pollId]!);
    final remaining = const Duration(minutes: 10) - elapsed;
    final bool isExpired = remaining.isNegative;

    int totalVotes = 0;
    for (var opt in options) {
      totalVotes += ((opt['votes'] ?? 0) as num).toInt();
    }

    final bool hasVoted = _myVotedPolls.contains(pollId) || isExpired;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.poll, color: teaBronze, size: 16),
              const SizedBox(width: 6),
              const Text(
                'SISTEM ANKETI',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: teaBronze,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(Icons.timer_outlined, color: isExpired ? Colors.redAccent : Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                isExpired ? 'Bitti' : '${(remaining.inMinutes).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.redAccent : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((entry) {
            final opt = entry.value;
            final String text = opt['text'];
            final int votes = ((opt['votes'] ?? 0) as num).toInt();
            final double percentage = totalVotes > 0 ? votes / totalVotes : 0.0;

            return GestureDetector(
              onTap: () {
                  if (!hasVoted) {
                    setState(() {
                      _myVotedPolls.add(pollId);
                    });
                    SocketClient().submitPollVote(widget.matchId, pollId, opt['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$text" seçeneğine oy verdiniz!'),
                      backgroundColor: turfGreen,
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasVoted ? Colors.white38 : Colors.white24,
                  ),
                ),
                child: Stack(
                  children: [
                    if (hasVoted)
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: teaBronze.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          if (hasVoted)
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: teaBronze,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, String currentRoom) {
    final bool isBot = msg['isBot'] ?? false;
    final bool isTeaGift = msg['isTeaGift'] ?? false;
    final bool isMatchEvent = msg['isMatchEvent'] ?? false;
    final bool isCapo = msg['isCapo'] ?? false;
    final String team = msg['team'] ?? 'neutral';

    Color borderColor = Colors.grey;
    if (team == 'home') borderColor = Colors.red; // Çorum mock color
    if (team == 'away') borderColor = Colors.orange; // GS mock color

    if (isBot) {
      final bool isPoll = msg['isPoll'] ?? false;
      if (isPoll && msg['pollData'] != null) {
        return _buildPollWidget(msg['pollData']);
      }

      if (isMatchEvent) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_soccer,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                msg['message'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      final Color customTeaColor = const Color(0xFF6F1A0C);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: customTeaColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (msg.containsKey('storeAsset') && msg['storeAsset'] != null)
              Image.asset(
                msg['storeAsset'],
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              )
            else if (isTeaGift)
              Icon(Icons.emoji_food_beverage, color: customTeaColor)
            else
              const Text("👨", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg['message'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: customTeaColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color activeTeamColor = Colors.grey;
    if (currentRoom == 'home') activeTeamColor = Colors.red.shade700;
    if (currentRoom == 'away') activeTeamColor = Colors.orange.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                msg['sender'][0],
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      msg['sender'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: currentRoom != 'neutral'
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    if (isCapo) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: teaBronze, width: 1),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.star, color: teaBronze, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'AĞA',
                              style: TextStyle(
                                fontSize: 9,
                                color: teaBronze,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(10),
                  width: isCapo ? double.infinity : null,
                  decoration: BoxDecoration(
                    color: isCapo
                        ? teaBronze.withValues(alpha: 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: currentRoom != 'neutral' && !isCapo
                        ? Border(
                            left: BorderSide(color: activeTeamColor, width: 4),
                          )
                        : (isCapo
                              ? Border.all(color: teaBronze, width: 2)
                              : null),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isCapo
                        ? msg['message'].toString().toUpperCase()
                        : msg['message'],
                    textAlign: isCapo ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      fontSize: isCapo ? 18 : 14,
                      fontWeight: isCapo ? FontWeight.w900 : FontWeight.normal,
                      color: isCapo ? teaBronze : Colors.black87,
                      letterSpacing: isCapo ? 1.2 : null,
                    ),
                  ),
                ),
                if (msg.containsKey('reactions')) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: (msg['reactions'] as Map<String, int>).entries
                        .map((e) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Color activeColor) {
    Color iconColor = activeColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.storefront,
                    color: teaBronze,
                    size: 28,
                  ),
                  onPressed: _showStoreMenu,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                  const SizedBox(height: 2),
                  BlocBuilder<EconomyCubit, EconomyState>(
                    builder: (context, state) {
                      return Text(
                        '${state.balance} ☕',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: teaBronze,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: _capoMessagesLeft > 0
                    ? const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: teaBronze,
                      )
                    : null,
                decoration: InputDecoration(
                  hintText: _capoMessagesLeft > 0
                      ? '📢 Amigo Modu ($_capoMessagesLeft)'
                      : 'Mesaj yaz...',
                  hintStyle: _capoMessagesLeft > 0
                      ? const TextStyle(color: teaBronze)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: _capoMessagesLeft > 0
                      ? Colors.black87
                      : surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: activeColor,
              child: IconButton(
                icon: Icon(Icons.send, color: iconColor, size: 20),
                onPressed: () {
                  final txt = _messageController.text;
                  if (txt.isEmpty) return;
                  bool isCapo = _capoMessagesLeft > 0;
                  _sendMessage('Ben', txt, isCapo: isCapo);
                  if (isCapo) {
                    setState(() => _capoMessagesLeft--);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



