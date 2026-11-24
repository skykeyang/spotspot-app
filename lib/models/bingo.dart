// Bingo event types — mirrors the web app's pool.ts

class BingoEvent {
  final String text;
  final String category;
  final int difficulty;
  final bool active;

  const BingoEvent({
    required this.text,
    required this.category,
    required this.difficulty,
    required this.active,
  });

  factory BingoEvent.fromJson(Map<String, dynamic> json) {
    return BingoEvent(
      text: json['text'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'category': category,
    'difficulty': difficulty,
    'active': active,
  };
}

class BingoPool {
  final String id;
  final String name;
  final String description;
  final String color;
  final String startDate;
  final String endDate;
  final String type;
  final String emoji;
  final String tagline;
  final bool active;
  final List<BingoEvent> events;

  const BingoPool({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.emoji,
    required this.tagline,
    required this.active,
    required this.events,
  });
}