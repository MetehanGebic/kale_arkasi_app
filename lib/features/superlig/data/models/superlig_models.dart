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
  final String clubName;
  final String? clubLogoUrl;
  final String? clubSlug;
  final String? clubPrimaryColor;
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
    required this.clubName,
    this.clubLogoUrl,
    this.clubSlug,
    this.clubPrimaryColor,
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
      clubName: json['club']['name'],
      clubLogoUrl: json['club']['logoUrl'],
      clubSlug: json['club']['slug'],
      clubPrimaryColor: json['club']['primaryColor'],
      players: json['club']['players'] != null
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

  Player({
    required this.name,
    this.photoUrl,
    this.position,
    this.shirtNumber,
    this.nationality,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      photoUrl: json['photoUrl'],
      position: json['position'],
      shirtNumber: json['shirtNumber'],
      nationality: json['nationality'],
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
      week: json['week'],
      matchDate: DateTime.parse(json['matchDate']).toLocal(),
      homeClubId: json['homeClub']['id'],
      homeClubName: json['homeClub']['name'],
      homeClubLogoUrl: json['homeClub']['logoUrl'],
      homeClubSlug: json['homeClub']['slug'],
      awayClubId: json['awayClub']['id'],
      awayClubName: json['awayClub']['name'],
      awayClubLogoUrl: json['awayClub']['logoUrl'],
      awayClubSlug: json['awayClub']['slug'],
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
      fromClubName: json['fromClub'] != null ? json['fromClub']['name'] : json['fromClubName'],
      fromClubLogoUrl: json['fromClub'] != null ? json['fromClub']['logoUrl'] : json['fromClubLogoUrl'],
      fromClubSlug: json['fromClub'] != null ? json['fromClub']['slug'] : null,
      toClubName: json['toClub'] != null ? json['toClub']['name'] : json['toClubName'],
      toClubLogoUrl: json['toClub'] != null ? json['toClub']['logoUrl'] : json['toClubLogoUrl'],
      toClubSlug: json['toClub'] != null ? json['toClub']['slug'] : null,
      feeType: json['feeType'],
    );
  }
}
