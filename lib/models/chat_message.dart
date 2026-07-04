class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? 'model').toString();
    return ChatMessage(
      role: (role == 'assistant' || role == 'model') ? 'model' : 'user',
      content: (json['content'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
