class StandingsEntry {
  final int rank;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String? clubSlug;
  final String? clubPrimaryColor;
  final String? coachName;
  final String? totalMarketValue;
  final List<Player> players;

  StandingsEntry({
    required this.rank,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    this.clubSlug,
    this.clubPrimaryColor,
    this.coachName,
    this.totalMarketValue,
    this.players = const [],
  });

  factory StandingsEntry.fromJson(Map<String, dynamic> json) {
    return StandingsEntry(
      rank: json['rank'],
      played: json['played'],
      won: json['won'],
      drawn: json['drawn'],
      lost: json['lost'],
      goalsFor: json['goalsFor'],
      goalsAgainst: json['goalsAgainst'],
      goalDiff: json['goalDiff'],
      points: json['points'],
      clubId: json['club']?['id'] ?? '',
      clubName: json['club']?['name'] ?? 'Bilinmiyor',
      clubLogoUrl: json['club']?['logoUrl'],
      clubSlug: json['club']?['slug'],
      clubPrimaryColor: json['club']?['primaryColor'],
      coachName: json['club']?['coachName'],
      totalMarketValue: json['club']?['totalMarketValue'],
      players: json['club']?['players'] != null
          ? (json['club']['players'] as List)
                .map((p) => Player.fromJson(p))
                .toList()
          : [],
    );
  }
}

class Player {
  final String name;
  final String? photoUrl;
  final String? position;
  final String? shirtNumber;
  final String? nationality;
  final String? marketValue;

  Player({
    required this.name,
    this.photoUrl,
    this.position,
    this.shirtNumber,
    this.nationality,
    this.marketValue,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      photoUrl: json['photoUrl'],
      position: json['position'],
      shirtNumber: json['shirtNumber'],
      nationality: json['nationality'],
      marketValue: json['marketValue'],
    );
  }
}

class Fixture {
  final int week;
  final DateTime matchDate;
  final String? homeClubId;
  final String homeClubName;
  final String? homeClubLogoUrl;
  final String? homeClubSlug;
  final String? awayClubId;
  final String awayClubName;
  final String? awayClubLogoUrl;
  final String? awayClubSlug;
  final int? homeScore;
  final int? awayScore;

  Fixture({
    required this.week,
    required this.matchDate,
    this.homeClubId,
    required this.homeClubName,
    this.homeClubLogoUrl,
    this.homeClubSlug,
    this.awayClubId,
    required this.awayClubName,
    this.awayClubLogoUrl,
    this.awayClubSlug,
    this.homeScore,
    this.awayScore,
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      week: json['week'] ?? 0,
      matchDate: json['matchDate'] != null
          ? DateTime.tryParse(json['matchDate'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      homeClubId: json['homeClub']?['id'],
      homeClubName: json['homeClub']?['name'] ?? 'Bilinmiyor',
      homeClubLogoUrl: json['homeClub']?['logoUrl'],
      homeClubSlug: json['homeClub']?['slug'],
      awayClubId: json['awayClub']?['id'],
      awayClubName: json['awayClub']?['name'] ?? 'Bilinmiyor',
      awayClubLogoUrl: json['awayClub']?['logoUrl'],
      awayClubSlug: json['awayClub']?['slug'],
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
    );
  }
}

class TopScorer {
  final int rank;
  final String playerName;
  final String clubName;
  final int goals;

  TopScorer({
    required this.rank,
    required this.playerName,
    required this.clubName,
    required this.goals,
  });

  factory TopScorer.fromJson(Map<String, dynamic> json) {
    return TopScorer(
      rank: json['rank'],
      playerName: json['playerName'],
      clubName: json['clubName'],
      goals: json['goals'],
    );
  }
}

class Transfer {
  final String playerName;
  final String? playerPhotoUrl;
  final String fromClubName;
  final String? fromClubLogoUrl;
  final String? fromClubSlug;
  final String toClubName;
  final String? toClubLogoUrl;
  final String? toClubSlug;
  final String feeType;

  Transfer({
    required this.playerName,
    this.playerPhotoUrl,
    required this.fromClubName,
    this.fromClubLogoUrl,
    this.fromClubSlug,
    required this.toClubName,
    this.toClubLogoUrl,
    this.toClubSlug,
    required this.feeType,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      playerName: json['playerName'],
      playerPhotoUrl: json['playerPhotoUrl'],
      // Eğer fromClub varsa (bizim db) onu kullan, yoksa fromClubName kullan
      fromClubName: json['fromClub'] != null
          ? json['fromClub']['name']
          : json['fromClubName'],
      fromClubLogoUrl: json['fromClub'] != null
          ? json['fromClub']['logoUrl']
          : json['fromClubLogoUrl'],
      fromClubSlug: json['fromClub'] != null ? json['fromClub']['slug'] : null,
      toClubName: json['toClub'] != null
          ? json['toClub']['name']
          : json['toClubName'],
      toClubLogoUrl: json['toClub'] != null
          ? json['toClub']['logoUrl']
          : json['toClubLogoUrl'],
      toClubSlug: json['toClub'] != null ? json['toClub']['slug'] : null,
      feeType: json['feeType'],
    );
  }
}

class LiveMatch {
  final String id;
  final int tournamentId;
  final String tournamentName;
  final String status;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final int homeScore;
  final int awayScore;
  final int? minute;
  final bool isChatEnabled;
  final int? startTimestamp;

  LiveMatch({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeScore,
    required this.awayScore,
    this.minute,
    required this.isChatEnabled,
    this.startTimestamp,
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    return LiveMatch(
      id: json['id'],
      tournamentId: json['tournamentId'],
      tournamentName: json['tournamentName'],
      status: json['status'],
      homeTeam: json['homeTeam'],
      awayTeam: json['awayTeam'],
      homeLogo: json['homeLogo'],
      awayLogo: json['awayLogo'],
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      minute: json['minute'],
      isChatEnabled: json['isChatEnabled'] ?? false,
      startTimestamp: json['startTimestamp'],
    );
  }
}

class MatchComment {
  final String id;
  final String matchId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String username;
  final String? avatarUrl;
  final String? favoriteClubId;
  final bool isSystem;
  final String? incidentId;

  MatchComment({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl,
    this.favoriteClubId,
    this.isSystem = false,
    this.incidentId,
  });

  factory MatchComment.fromJson(Map<String, dynamic> json) {
    return MatchComment(
      id: json['id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now()
          : DateTime.now(),
      username: json['user']?['username'] as String? ?? 'Kullanıcı',
      avatarUrl: json['user']?['avatarUrl'] as String?,
      favoriteClubId: json['user']?['favoriteClubId'] as String?,
      isSystem: json['isSystem'] == true || json['role'] == 'BOT',
      incidentId: json['incidentId']?.toString(),
    );
  }
}

class MatchDetailsData {
  final Map<String, dynamic>? lineups;
  final Map<String, dynamic>? statistics;
  final Map<String, dynamic>? incidents;
  final Map<String, dynamic>? event;

  MatchDetailsData({this.lineups, this.statistics, this.incidents, this.event});

  factory MatchDetailsData.fromJson(Map<String, dynamic> json) {
    return MatchDetailsData(
      lineups: json['lineups'] as Map<String, dynamic>?,
      statistics: json['statistics'] as Map<String, dynamic>?,
      incidents: json['incidents'] as Map<String, dynamic>?,
      event: json['event'] as Map<String, dynamic>?,
    );
  }
}
