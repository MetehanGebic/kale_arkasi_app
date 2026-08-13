import 'package:flutter/material.dart';

const Set<String> localSuperLigClubs = {
  'alanyaspor',
  'amed-sk',
  'besiktas-istanbul',
  'buyuksehir-belediye-erzurumspor',
  'caykur-rizespor',
  'corum-fk',
  'eyupspor',
  'fenerbahce-istanbul',
  'galatasaray-istanbul',
  'gaziantep-fk',
  'genclerbirligi-ankara',
  'goztepe',
  'istanbul-basaksehir-fk',
  'kasimpasa',
  'kocaelispor',
  'konyaspor',
  'samsunspor',
  'trabzonspor'
};

class ClubLogo extends StatelessWidget {
  final String? clubSlug;
  final String? logoUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ClubLogo({
    super.key,
    required this.clubSlug,
    required this.logoUrl,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.contain,
  });

  static String? getSlugFromName(String name) {
    final normalized = name.toLowerCase().trim();
    const map = {
      'fenerbahçe': 'fenerbahce-istanbul',
      'fenerbahce': 'fenerbahce-istanbul',
      'galatasaray': 'galatasaray-istanbul',
      'beşiktaş': 'besiktas-istanbul',
      'besiktas': 'besiktas-istanbul',
      'trabzonspor': 'trabzonspor',
      'samsunspor': 'samsunspor',
      'göztepe': 'goztepe',
      'goztepe': 'goztepe',
      'rizespor': 'caykur-rizespor',
      'çaykur rizespor': 'caykur-rizespor',
      'caykur rizespor': 'caykur-rizespor',
      'konyaspor': 'konyaspor',
      'tümosan konyaspor': 'konyaspor',
      'kasımpaşa': 'kasimpasa',
      'kasimpasa': 'kasimpasa',
      'başakşehir': 'istanbul-basaksehir-fk',
      'ramsv başakşehir': 'istanbul-basaksehir-fk',
      'istanbul başakşehir': 'istanbul-basaksehir-fk',
      'gaziantep fk': 'gaziantep-fk',
      'gaziantep': 'gaziantep-fk',
      'eyüpspor': 'eyupspor',
      'ikas eyüpspor': 'eyupspor',
      'çorum fk': 'corum-fk',
      'ahlatcı çorum fk': 'corum-fk',
      'alanyaspor': 'alanyaspor',
      'corendon alanyaspor': 'alanyaspor',
      'amed sk': 'amed-sk',
      'amed sportif faaliyetler': 'amed-sk',
      'erzurumspor': 'buyuksehir-belediye-erzurumspor',
      'erzurumspor fk': 'buyuksehir-belediye-erzurumspor',
      'kocaelispor': 'kocaelispor',
      'gençlerbirliği': 'genclerbirligi-ankara',
      'genclerbirligi': 'genclerbirligi-ankara',
    };
    return map[normalized];
  }

  @override
  Widget build(BuildContext context) {
    if (clubSlug != null && localSuperLigClubs.contains(clubSlug)) {
      return Image.asset(
        'assets/images/clubs/$clubSlug.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Image.network(
        logoUrl!,
        width: width,
        height: height,
        fit: fit,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.sofascore.com/',
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Icon(
        Icons.shield,
        size: width * 0.6,
        color: const Color(0xFF1B5E20), // turfGreen
      ),
    );
  }
}
