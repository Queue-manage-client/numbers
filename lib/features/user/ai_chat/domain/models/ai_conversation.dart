// ai_chat/domain/models/ai_conversation.dart

import 'ai_message.dart';

class AiConversation {
  final String id;
  final String title;
  final List<AiMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  AiConversation copyWith({
    String? id,
    String? title,
    List<AiMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
