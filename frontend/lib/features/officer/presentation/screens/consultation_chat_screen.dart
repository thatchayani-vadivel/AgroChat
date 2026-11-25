import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/chat_message_model.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing the Agricultural Officer and Farmer to communicate directly
/// regarding an active assistance request consultation.
class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({
    super.key,
    required this.requestId,
    required this.requestTitle,
    this.farmerName,
    this.officerName,
    required this.repository,
    this.isFarmerViewer = false,
  });

  final int requestId;
  final String requestTitle;
  final String? farmerName;
  final String? officerName;
  final ChatMessageProvider repository;
  final bool isFarmerViewer;

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ChatMessageModel> _messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await widget.repository.listMessages(widget.requestId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final newMsg = await widget.repository.sendTextMessage(
        widget.requestId,
        text,
      );
      if (mounted) {
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.isFarmerViewer
        ? (widget.officerName != null
              ? 'Officer ${widget.officerName}'
              : 'Agricultural Officer')
        : (widget.farmerName ?? 'Farmer');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advisory Chat with $partnerName',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.requestTitle,
              style: const TextStyle(fontSize: 11, color: AppColors.softMint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Messages',
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Expanded(child: _buildChatBody()),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    if (_isLoading) {
      return const AgroLoadingView(message: 'Loading consultation messages...');
    }

    if (_errorMessage != null && _messages.isEmpty) {
      return AgroEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Messages',
        description: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadMessages,
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 54,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                'No Messages Yet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start the conversation with ${widget.farmerName ?? "the farmer"} regarding this request.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return _buildMessageBubble(msg);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isMe = widget.isFarmerViewer
        ? message.isFromFarmer
        : message.isFromOfficer;

    String senderLabel;
    if (isMe) {
      senderLabel = widget.isFarmerViewer
          ? 'You (Farmer)'
          : 'You (Agricultural Officer)';
    } else {
      senderLabel = widget.isFarmerViewer
          ? (message.senderName != null
                ? 'Officer ${message.senderName}'
                : 'Agricultural Officer')
          : (message.senderName ?? 'Farmer');
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryGreen : AppColors.surfaceWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe
                        ? AppColors.softMint
                        : AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (message.isVoice)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.audiotrack_rounded,
                    size: 16,
                    color: isMe ? Colors.white : AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Voice Message (${message.durationSeconds ?? 0}s)',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              )
            else
              Text(
                message.content ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                message.createdAt != null
                    ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                    : '',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type agricultural advisory message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 38,
                    height: 38,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
}
