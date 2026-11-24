/// Model representing a chat text or voice message between Farmer and Officer.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    this.senderName,
    this.senderRole,
    this.messageType = 'text',
    this.content,
    this.audioFileName,
    this.audioUrl,
    this.durationSeconds,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int requestId;
  final int senderId;
  final int receiverId;
  final String? senderName;
  final String? senderRole;
  final String messageType;
  final String? content;
  final String? audioFileName;
  final String? audioUrl;
  final int? durationSeconds;
  final bool isRead;
  final DateTime? createdAt;

  bool get isVoice => messageType.toLowerCase() == 'voice';
  bool get isFromOfficer => senderRole?.toLowerCase() == 'agricultural_officer';
  bool get isFromFarmer => senderRole?.toLowerCase() == 'farmer';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int? ?? 0,
      requestId: json['request_id'] as int? ?? 0,
      senderId: json['sender_id'] as int? ?? 0,
      receiverId: json['receiver_id'] as int? ?? 0,
      senderName: json['sender_name'] as String?,
      senderRole: json['sender_role'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String?,
      audioFileName: json['audio_file_name'] as String?,
      audioUrl: json['audio_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content};
  }
}

/// Abstract contract for sending and receiving messages in consultation chat.
abstract class ChatMessageProvider {
  Future<List<ChatMessageModel>> listMessages(int requestId);
  Future<ChatMessageModel> sendTextMessage(int requestId, String text);
}
