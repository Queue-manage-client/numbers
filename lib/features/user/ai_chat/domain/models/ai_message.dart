// ai_chat/domain/models/ai_message.dart

class AiMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;

  AiMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  AiMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? createdAt,
  }) {
    return AiMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
