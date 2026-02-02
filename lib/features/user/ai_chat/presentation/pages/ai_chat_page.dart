// ai_chat/presentation/pages/ai_chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_conversation_drawer.dart';
import '../../domain/models/ai_message.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // 会話がない場合は新規作成
    var conversationId = ref.read(selectedConversationIdProvider);
    if (conversationId == null) {
      final notifier = ref.read(aiConversationsProvider.notifier);
      conversationId = notifier.createConversation();
      ref.read(selectedConversationIdProvider.notifier).state = conversationId;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(aiConversationsProvider.notifier)
          .generateAiResponse(conversationId, message);
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startNewConversation() {
    ref.read(selectedConversationIdProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final currentConversation = ref.watch(currentConversationProvider);
    final messages = currentConversation?.messages ?? [];

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          currentConversation?.title ?? 'AI',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: ColorPalette.neutral0),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: ColorPalette.neutral0),
            onPressed: _startNewConversation,
            tooltip: '新しい会話',
          ),
        ],
      ),
      drawer: const AiConversationDrawer(),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(messages),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 64,
            color: ColorPalette.neutral600,
          ),
          const SizedBox(height: SpacePalette.base),
          Text(
            '就活に関する質問をどうぞ',
            style: TextStylePalette.smHeader.copyWith(
              color: ColorPalette.neutral400,
            ),
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            '面接対策、自己PR、企業研究など\n何でもお気軽にお聞きください',
            textAlign: TextAlign.center,
            style: TextStylePalette.subText,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<AiMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(SpacePalette.base),
      itemCount: messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == messages.length) {
          return _buildLoadingIndicator();
        }
        final message = messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacePalette.sm),
        padding: const EdgeInsets.all(SpacePalette.sm),
        decoration: BoxDecoration(
          color: ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorPalette.primaryColor,
              ),
            ),
            const SizedBox(width: SpacePalette.sm),
            Text(
              '考え中...',
              style: TextStylePalette.subText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: SpacePalette.base,
        right: SpacePalette.base,
        top: SpacePalette.sm,
        bottom: MediaQuery.of(context).padding.bottom + SpacePalette.sm,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        border: Border(
          top: BorderSide(color: ColorPalette.neutral600, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStylePalette.normalText,
              decoration: InputDecoration(
                hintText: '質問を入力...',
                hintStyle: TextStylePalette.subText,
                filled: true,
                fillColor: ColorPalette.neutral600,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpacePalette.base,
                  vertical: SpacePalette.sm,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: SpacePalette.sm),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: Icon(
              Icons.send,
              color: _isLoading
                  ? ColorPalette.neutral600
                  : ColorPalette.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacePalette.sm),
        padding: const EdgeInsets.all(SpacePalette.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? ColorPalette.primaryColor : ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacePalette.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: ColorPalette.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStylePalette.subText.copyWith(
                        color: ColorPalette.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: TextStylePalette.normalText.copyWith(
                color: isUser ? ColorPalette.neutral0 : ColorPalette.neutral100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
