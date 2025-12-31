class Message {
  final String id;
  final String chatId;
  final String text;
  final String senderId;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? attachmentUrl;
  final String? attachmentType; // 'image', 'video', 'file'

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderId,
    required this.sentAt,
    this.readAt,
    this.attachmentUrl,
    this.attachmentType,
  });

  bool isMe(String currentUserId) => senderId == currentUserId;

  // Create Message from JSON (database)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chat_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
    );
  }

  // Convert Message to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'text': text,
      'sender_id': senderId,
      'sent_at': sentAt.toIso8601String(),
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentType != null) 'attachment_type': attachmentType,
    };
  }

  // Factory for creating new messages (backward compatibility)
  factory Message.create({
    required String text,
    required String senderId,
    required String chatId,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      text: text,
      senderId: senderId,
      sentAt: DateTime.now(),
    );
  }
}

