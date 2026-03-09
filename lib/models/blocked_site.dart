class BlockedSite {
  const BlockedSite({
    this.id,
    required this.url,
    required this.removalCodeHash,
    required this.dateAdded,
  });

  static const tableName = 'blocked_sites';

  final int? id;
  final String url;
  final String removalCodeHash;
  final DateTime dateAdded;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'removal_code_hash': removalCodeHash,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory BlockedSite.fromMap(Map<String, dynamic> map) {
    return BlockedSite(
      id: map['id'] as int?,
      url: map['url'] as String,
      removalCodeHash: map['removal_code_hash'] as String,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
    );
  }

  BlockedSite copyWith({
    int? id,
    String? url,
    String? removalCodeHash,
    DateTime? dateAdded,
  }) {
    return BlockedSite(
      id: id ?? this.id,
      url: url ?? this.url,
      removalCodeHash: removalCodeHash ?? this.removalCodeHash,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}
