import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/app/widgets/screens/home/widgets/molecules/message_bubble.dart';

class MessageList extends StatefulWidget {
  final List<ChirpMessage> messages;

  const MessageList({super.key, required this.messages});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.microtask(() {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(child: Text("Silêncio no bando... envie um chirp!"));
    }

    final theme = Theme.of(context);
    final isFlat = theme.extension<ChirpPanelTheme>()?.blurSigma == 0;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isFlat ? 12 : 20,
          vertical: 20,
        ),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages[index];

          final prevMessage = index > 0 ? widget.messages[index - 1] : null;
          final nextMessage = index < widget.messages.length - 1
              ? widget.messages[index + 1]
              : null;

          final bool isSameAuthorAsPrev = prevMessage?.author == message.author;

          final bool isSameAuthorAsNext = nextMessage?.author == message.author;

          final bool isRecent =
              isSameAuthorAsPrev &&
              message.dateCreated
                      .difference(prevMessage!.dateCreated)
                      .inMinutes <
                  5;

          final bool shouldShowAuthor = !isSameAuthorAsPrev || !isRecent;

          final bool isFirstInGroup = !isSameAuthorAsPrev || !isRecent;

          final bool isLastInGroup =
              !isSameAuthorAsNext ||
              (nextMessage != null &&
                  nextMessage.dateCreated
                          .difference(message.dateCreated)
                          .inMinutes >=
                      5);

          return MessageBubble(
            key: ValueKey(message.id),
            message: message,
            showAuthor: !message.isFromMe && shouldShowAuthor,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
