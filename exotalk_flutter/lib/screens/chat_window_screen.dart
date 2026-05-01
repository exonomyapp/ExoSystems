// =============================================================================
// chat_window_screen.dart — Active Conversation View (Sovereign Generation)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../providers/chat_provider.dart';
import '../src/theme.dart';
import '../src/rust/api/willow.dart';
import '../widgets/modals/group_manager.dart';
import '../providers/toast_provider.dart';

class ChatWindowScreen extends ConsumerStatefulWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarVisible;
  
  const ChatWindowScreen({super.key, required this.onToggleSidebar, required this.isSidebarVisible});

  @override
  ConsumerState<ChatWindowScreen> createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends ConsumerState<ChatWindowScreen> {
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  void _scrollToBottom() {
    if (scrollCtrl.hasClients) {
      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConvoId = ref.watch(activeConversationIdProvider);
    if (activeConvoId == null) return const SizedBox.shrink();

    final conversations = ref.watch(conversationListProvider);
    final activeConvo = conversations.cast<Conversation?>().firstWhere((c) => c?.id == activeConvoId, orElse: () => null);
    
    if (activeConvo == null) return const SizedBox.shrink();

    final messages = ref.watch(messagesProvider(activeConvoId));
    final scale = ref.watch(uiScaleProvider);

    ref.listen<int>(
      messagesProvider(activeConvoId).select((msgs) => msgs.length),
      (prev, next) {
        if (prev != next) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
    );

    return Column(
      children: [
        _ChatHeader(
          convo: activeConvo,
          isSidebarVisible: widget.isSidebarVisible,
          onToggleSidebar: widget.onToggleSidebar,
          scale: scale,
        ),
        Expanded(
          child: _MessageList(
            messages: messages,
            scrollCtrl: scrollCtrl,
            scale: scale,
          ),
        ),
        _ChatInput(
          textCtrl: textCtrl,
          onSend: (text) {
            ref.read(messagesProvider(activeConvoId).notifier).send(text);
            textCtrl.clear();
          },
          scale: scale,
        ),
      ],
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  final Conversation convo;
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;
  final double scale;

  const _ChatHeader({required this.convo, required this.isSidebarVisible, required this.onToggleSidebar, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ConsciaTheme.headerPaddingHorizontal(scale), vertical: 12.0 * scale),
      decoration: BoxDecoration(
        color: ConsciaTheme.surface(context),
        border: Border(bottom: BorderSide(color: ConsciaTheme.border(context))),
      ),
      child: Row(
        children: [
          if (!isSidebarVisible)
            IconButton(
              icon: Icon(LucideIcons.panelLeft, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
              onPressed: onToggleSidebar,
            ),
          CircleAvatar(
            radius: 18.0 * scale,
            backgroundColor: ConsciaTheme.border(context),
            child: Text(convo.title[0].toUpperCase(), style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: ConsciaTheme.text(context))),
          ),
          SizedBox(width: 12.0 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(convo.title, style: ConsciaTheme.subHeadingStyle(context, scale)),
                Row(
                  children: [
                    Container(width: 6.0 * scale, height: 6.0 * scale, decoration: BoxDecoration(color: ConsciaTheme.accent(context), shape: BoxShape.circle)),
                    SizedBox(width: 6.0 * scale),
                    Text("Willow Protocol Active", style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.accent(context), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.video, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
            onPressed: () => ref.read(toastProvider.notifier).show("Video call system initializing..."),
          ),
          IconButton(
            icon: Icon(LucideIcons.info, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
            onPressed: () => showDialog(context: context, builder: (_) => GroupManagerModal(conversation: convo)),
          ),
          IconButton(
            icon: Icon(LucideIcons.moreVertical, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
            onPressed: () => ref.read(toastProvider.notifier).show("Hot reload works! 🎉"),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  final List<Message> messages;
  final ScrollController scrollCtrl;
  final double scale;

  const _MessageList({required this.messages, required this.scrollCtrl, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDid = ref.watch(userProfileProvider).did;

    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.symmetric(horizontal: ConsciaTheme.headerPaddingHorizontal(scale), vertical: 30.0 * scale),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.authorDid == userDid;
        return _MessageBubble(msg: msg, isMe: isMe, scale: scale);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;
  final double scale;

  const _MessageBubble({required this.msg, required this.isMe, required this.scale});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('jm').format(DateTime.fromMillisecondsSinceEpoch(msg.timestampMs.toInt()));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0 * scale),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
        decoration: BoxDecoration(
          color: isMe ? ConsciaTheme.accent(context) : ConsciaTheme.surface(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0 * scale),
            topRight: Radius.circular(16.0 * scale),
            bottomLeft: Radius.circular(isMe ? 16.0 * scale : 4.0 * scale),
            bottomRight: Radius.circular(isMe ? 4.0 * scale : 16.0 * scale),
          ),
          border: isMe ? null : Border.all(color: ConsciaTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.content, style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: isMe ? Colors.white : ConsciaTheme.text(context), height: 1.4)),
            SizedBox(height: 4.0 * scale),
            Text(timeStr, style: ConsciaTheme.captionStyle(context, scale).copyWith(color: isMe ? Colors.white : ConsciaTheme.muted(context), fontSize: 9.0 * scale)),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends ConsumerWidget {
  final TextEditingController textCtrl;
  final Function(String) onSend;
  final double scale;

  const _ChatInput({required this.textCtrl, required this.onSend, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(ConsciaTheme.headerPaddingHorizontal(scale)),
      decoration: BoxDecoration(
        color: ConsciaTheme.surface(context),
        border: Border(top: BorderSide(color: ConsciaTheme.border(context))),
      ),
      child: Column(
        children: [
          LayoutGrid(
            columnSizes: [auto, auto, auto],
            rowSizes: const [auto],
            columnGap: 16.0 * scale,
            children: [
              _InputStubButton(icon: LucideIcons.image, label: "PHOTO", scale: scale).withGridPlacement(columnStart: 0, rowStart: 0),
              _InputStubButton(icon: LucideIcons.video, label: "VIDEO", scale: scale).withGridPlacement(columnStart: 1, rowStart: 0),
              _InputStubButton(icon: LucideIcons.sparkles, label: "AI ASSIST", color: ConsciaTheme.gold, scale: scale).withGridPlacement(columnStart: 2, rowStart: 0),
            ],
          ),
          SizedBox(height: 12.0 * scale),
          LayoutGrid(
            columnSizes: [auto, 1.fr, auto, auto],
            rowSizes: const [auto],
            columnGap: 8.0 * scale,
            children: [
              IconButton(
                icon: Icon(LucideIcons.paperclip, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
                onPressed: () => ref.read(toastProvider.notifier).show("File selector opening..."),
              ).withGridPlacement(columnStart: 0, rowStart: 0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                decoration: BoxDecoration(
                  color: ConsciaTheme.background(context),
                  borderRadius: BorderRadius.circular(16.0 * scale),
                  border: Border.all(color: ConsciaTheme.border(context)),
                ),
                child: TextField(
                  controller: textCtrl,
                  style: ConsciaTheme.bodyStyle(context, scale),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: ConsciaTheme.captionStyle(context, scale),
                    border: InputBorder.none,
                  ),
                ),
              ).withGridPlacement(columnStart: 1, rowStart: 0),
              IconButton(
                icon: Icon(LucideIcons.smile, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
                onPressed: () => ref.read(toastProvider.notifier).show("Emoji picker coming soon."),
              ).withGridPlacement(columnStart: 2, rowStart: 0),
              Material(
                color: ConsciaTheme.accent(context),
                borderRadius: BorderRadius.circular(16.0 * scale),
                child: InkWell(
                  onTap: () {
                    if (textCtrl.text.trim().isNotEmpty) {
                      onSend(textCtrl.text.trim());
                    }
                  },
                  borderRadius: BorderRadius.circular(16.0 * scale),
                  child: Container(
                    padding: EdgeInsets.all(12.0 * scale),
                    child: Icon(LucideIcons.send, color: Colors.white, size: 20.0 * scale),
                  ),
                ),
              ).withGridPlacement(columnStart: 3, rowStart: 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputStubButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double scale;
  const _InputStubButton({required this.icon, required this.label, this.color, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(right: 16.0 * scale),
      child: InkWell(
        onTap: () => ref.read(toastProvider.notifier).show("$label feature is currently in development."),
        child: Row(
          children: [
            Icon(icon, size: 14.0 * scale, color: color ?? ConsciaTheme.muted(context)),
            SizedBox(width: 6.0 * scale),
            Text(label, style: ConsciaTheme.captionStyle(context, scale).copyWith(color: color ?? ConsciaTheme.muted(context), fontWeight: FontWeight.bold, fontSize: 10.0 * scale)),
          ],
        ),
      ),
    );
  }
}
