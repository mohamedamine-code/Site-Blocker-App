class BlockingEvent {
  const BlockingEvent({
    this.id,
    required this.domain,
    required this.timestamp,
  });

  static const tableName = 'blocking_events';

  final int? id;
  final String domain;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory BlockingEvent.fromMap(Map<String, dynamic> map) {
    return BlockingEvent(
      id: map['id'] as int?,
      domain: map['domain'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
