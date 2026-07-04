class GoalItem {
  GoalItem({
    required this.text,
    this.id,
    this.done = false,
    this.kind = 'reflection',
    this.content,
    this.durationSeconds = 10,
  });

  final String? id;
  final String text;
  bool done;
  final String kind;
  final String? content;
  final int durationSeconds;

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      text: (json['text'] ?? json['title'] ?? json['goal'] ?? '').toString(),
      done: json['done'] == true || json['completed'] == true,
      kind: json['kind']?.toString() ?? 'reflection',
      content: json['content']?.toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 10,
    );
  }
}
