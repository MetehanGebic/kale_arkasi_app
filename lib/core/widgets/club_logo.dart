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
