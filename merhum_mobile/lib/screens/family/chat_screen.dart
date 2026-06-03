import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const _quickActions = [
    'Koja groblja su dostupna?',
    'Kako zakazati termin?',
    'Koje su prosječne cijene usluga?',
    'Koje je stanje moje procedure?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadHistory().then((_) => _scrollToBottom());
    });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend([String? overrideText]) async {
    final provider = context.read<ChatProvider>();
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || provider.isSending) return;
    _controller.clear();
    await provider.sendMessage(text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši razgovor'),
        content: const Text(
          'Da li ste sigurni da želite obrisati cijelu historiju razgovora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Obriši',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ChatProvider>().clearChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Merhum asistent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('AI pomoć za porodice', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Obriši razgovor',
            icon: const Icon(Icons.delete_outline),
            onPressed: messages.isEmpty ? null : _confirmClear,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (messages.isEmpty && !provider.isLoadingHistory) _buildWelcomeBanner(),
            Expanded(
              child: provider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: messages.length + (provider.isSending ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (provider.isSending && i == 0) {
                          return const _TypingIndicator();
                        }
                        final reversedIndex = messages.length - 1 - (provider.isSending ? i - 1 : i);
                        final msg = messages[reversedIndex];
                        return _MessageBubble(
                          message: msg,
                          onRetry: msg.isError ? () => context.read<ChatProvider>().retryLast() : null,
                        );
                      },
                    ),
            ),
            _buildInputBar(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 18,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esselamu alejkum, kako mogu pomoći?',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Postavite pitanje o procedurama, terminima, grobljima ili uslugama.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickActions
                .map((q) => ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      onPressed: () => _handleSend(q),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider provider) {
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = hasText && !provider.isSending;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              enabled: !provider.isSending,
              decoration: InputDecoration(
                hintText: 'Postavite pitanje...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: canSend ? AppColors.primary : AppColors.textLight,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canSend ? () => _handleSend() : null,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onRetry;
  const _MessageBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width * (isUser ? 0.75 : 0.80);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.primary
            : (message.isError ? AppColors.error.withValues(alpha: 0.1) : const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isUser
                  ? Colors.white
                  : (message.isError ? AppColors.error : AppColors.textDark),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh, size: 14, color: AppColors.error),
                  SizedBox(width: 4),
                  Text(
                    'Pokušaj ponovo',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(child: bubble),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              left: isUser ? 0 : 36,
              right: isUser ? 4 : 0,
            ),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Asistent piše',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (ctx, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final t = ((_controller.value * 3) - i).clamp(0.0, 1.0);
                        final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Opacity(
                            opacity: opacity,
                            child: const CircleAvatar(
                              radius: 2.5,
                              backgroundColor: AppColors.textMedium,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
