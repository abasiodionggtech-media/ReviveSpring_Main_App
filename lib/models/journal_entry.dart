class JournalEntry {
  const JournalEntry({
    required this.body,
    required this.createdAt,
    this.id,
  });

  final String? id;
  final String body;
  final DateTime createdAt;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      body: (json['body'] ?? json['content'] ?? json['entry'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_date'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
