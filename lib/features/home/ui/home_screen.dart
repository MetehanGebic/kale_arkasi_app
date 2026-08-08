import 'package:flutter/material.dart';
import '../../auth/ui/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kale Arkası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Çay Bakiyesi Göstergesi
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_food_beverage,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '0', // İleride API'den gelen gerçek bakiye buraya yazılacak
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Şimdilik sadece Login ekranına geri atıyor.
              // İleride burada cihazdaki token'ı silme işlemi yapacağız.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMatchHeader(context),
            const SizedBox(height: 24),

            const Text(
              'Çay Ocağı (Görevler)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTasksCard(context),
            const SizedBox(height: 24),

            const Text(
              'Kahvehanenin Ağaları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLeaderboardCard(context),

            const SizedBox(
              height: 80,
            ), // FAB butonunun altındaki kartları kapatmaması için boşluk
          ],
        ),
      ),
      // Günlük Çayını Al Butonu (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Şimdilik sadece bir mesaj gösteriyoruz.
          // API bağlantısını kurduğumuzda burası Node.js ile konuşacak.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çay demleniyor... Alt yapı hazırlanıyor!'),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emoji_food_beverage),
        label: const Text(
          'Günlük Çayını Al',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 1. Yaklaşan Maç Vitrini (Header)
  Widget _buildMatchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.red.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Sıradaki Maç',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'TS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('VS', style: TextStyle(color: Colors.white54, fontSize: 16)),
              Text(
                'FB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Kalan Süre: 2 Gün 14 Saat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 2. Günlük Görevler Modülü
  Widget _buildTasksCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.article, color: Colors.blue),
            title: const Text('Günün Haberini Oku'),
            trailing: const Text(
              '+5 Çay',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.orange),
            title: const Text('İlk Yorumunu Yap'),
            trailing: const Text(
              '+10 Çay',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // 3. Liderlik Tablosu Modülü
  Widget _buildLeaderboardCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text('1', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('BordoMavi61'),
            subtitle: const Text('Tribün Lideri'),
            trailing: const Text(
              '1450 Çay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade400,
              child: const Text('2', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Firtina'),
            subtitle: const Text('Ateşli Taraftar'),
            trailing: const Text(
              '1200 Çay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
