/// Data model for a single Worry entry.
///
/// Follows the schema from SPEC.md §4.
/// Timestamps are stored as epoch milliseconds (never ISO strings)
/// to avoid timezone ambiguity.
class Worry {
  final String id;
  final String text;
  final int createdAt;
  final int unlockAt;
  String status; // "locked" | "revealed" | "released" | "kept"

  Worry({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.unlockAt,
    this.status = 'locked',
  });

  /// Creates a new Worry from user input.
  ///
  /// Validates text (1–280 chars, trimmed, non-empty).
  /// Computes [unlockAt] based on the provided unlock hour/minute.
  factory Worry.create({
    required String text,
    required int unlockHour,
    required int unlockMinute,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Worry text cannot be empty.');
    }
    if (trimmed.length > 280) {
      throw ArgumentError('Worry text cannot exceed 280 characters.');
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Build today's unlock moment in local time
    var unlockMoment = DateTime(
      now.year,
      now.month,
      now.day,
      unlockHour,
      unlockMinute,
    );

    // If unlock time has already passed today, roll to tomorrow
    if (unlockMoment.isBefore(now) || unlockMoment.isAtSameMomentAs(now)) {
      unlockMoment = unlockMoment.add(const Duration(days: 1));
    }

    // Generate a unique ID: epoch-randomString
    final random = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final id = '$nowMs-${random.substring(random.length > 5 ? random.length - 5 : 0)}';

    return Worry(
      id: id,
      text: trimmed,
      createdAt: nowMs,
      unlockAt: unlockMoment.millisecondsSinceEpoch,
      status: 'locked',
    );
  }

  /// Creates a Worry with a custom short unlock duration (for dev/testing).
  factory Worry.createDev({
    required String text,
    required int unlockSeconds,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Worry text cannot be empty.');
    }
    if (trimmed.length > 280) {
      throw ArgumentError('Worry text cannot exceed 280 characters.');
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final id = '$nowMs-${random.substring(random.length > 5 ? random.length - 5 : 0)}';

    return Worry(
      id: id,
      text: trimmed,
      createdAt: nowMs,
      unlockAt: nowMs + (unlockSeconds * 1000),
      status: 'locked',
    );
  }

  /// Whether this worry's unlock time has passed.
  bool get isUnlockable =>
      DateTime.now().millisecondsSinceEpoch >= unlockAt && status == 'locked';

  /// Whether this worry is still pending (locked and not yet unlockable).
  bool get isPending =>
      status == 'locked' && DateTime.now().millisecondsSinceEpoch < unlockAt;

  /// Returns a human-readable "put away X ago" string.
  String get relativeTime {
    final diff = DateTime.now().millisecondsSinceEpoch - createdAt;
    final minutes = (diff / 60000).floor();
    final hours = (diff / 3600000).floor();

    if (hours > 0) {
      return 'put away $hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (minutes > 0) {
      return 'put away $minutes ${minutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'put away just now';
    }
  }

  /// Deserializes from JSON map.
  factory Worry.fromJson(Map<String, dynamic> json) {
    return Worry(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: json['createdAt'] as int,
      unlockAt: json['unlockAt'] as int,
      status: json['status'] as String? ?? 'locked',
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt,
      'unlockAt': unlockAt,
      'status': status,
    };
  }

  @override
  String toString() => 'Worry(id: $id, status: $status, text: "${text.length > 30 ? '${text.substring(0, 30)}...' : text}")';
}
