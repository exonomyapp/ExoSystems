// new_chat_dialog.dart — Create Conversation Modal
// =============================================================================
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../../providers/chat_provider.dart';
import '../../main.dart';
import '../../src/theme.dart';
import '../../providers/toast_provider.dart';

class NewChatDialogModal extends ConsumerStatefulWidget {
  const NewChatDialogModal({super.key});

  @override
  ConsumerState<NewChatDialogModal> createState() => _NewChatDialogModalState();
}

class _NewChatDialogModalState extends ConsumerState<NewChatDialogModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String peerId = "";
  String chatName = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void handleCreate(bool isGroup) {
    if (isGroup) {
      if (chatName.trim().isEmpty) {
        ref.read(toastProvider.notifier).show("Please enter a group name.", type: ToastType.error);
        return;
      }
    } else {
      if (peerId.trim().isEmpty) {
        ref.read(toastProvider.notifier).show("Please enter the contact's address to start a direct chat.", type: ToastType.error);
        return;
      }
    }

    final name = isGroup ? chatName : peerId;
    ref.read(conversationListProvider.notifier).createNew(
      name,
      peerDid: isGroup ? null : peerId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(400.0, 550.0 * scale),
          maxHeight: 600.0 * scale,
        ),
        decoration: AppTheme.premiumCardDecoration(context, scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModalHeader(scale: scale),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0 * scale),
                child: Column(
                  children: [
                    _TabSelector(controller: _tabController, scale: scale),
                    SizedBox(height: 32.0 * scale),
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _DirectTab(
                                onChanged: (v) => peerId = v,
                                onSubmit: () => handleCreate(false),
                                scale: scale,
                              )
                            : _GroupTab(
                                onChanged: (v) => chatName = v,
                                onSubmit: () => handleCreate(true),
                                scale: scale,
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final double scale;
  const _ModalHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.0 * scale),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: LayoutGrid(
        columnSizes: [auto, 1.fr],
        rowSizes: [auto],
        columnGap: 16.0 * scale,
        children: [
          Container(
            padding: EdgeInsets.all(12.0 * scale),
            decoration: BoxDecoration(color: AppTheme.accentDark(context), borderRadius: BorderRadius.circular(16.0 * scale)),
            child: Icon(LucideIcons.plus, color: AppTheme.accent(context), size: 24.0 * scale),
          ).withGridPlacement(columnStart: 0, rowStart: 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Secure chat", style: AppTheme.subHeadingStyle(context, scale).copyWith(fontSize: 18.0 * scale)),
              Text("Create a direct or group channel", style: AppTheme.captionStyle(context, scale)),
            ],
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final TabController controller;
  final double scale;
  const _TabSelector({required this.controller, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.0 * scale),
      decoration: BoxDecoration(color: AppTheme.background(context), borderRadius: BorderRadius.circular(12.0 * scale)),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(8.0 * scale), border: Border.all(color: AppTheme.border(context))),
        labelColor: AppTheme.text(context),
        unselectedLabelColor: AppTheme.muted(context),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(child: Text("Direct", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold))),
          Tab(child: Text("Group", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _DirectTab extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback onSubmit;
  final double scale;

  const _DirectTab({required this.onChanged, required this.onSubmit, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Peer Identifier", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 12.0 * scale),
        TextField(
          onChanged: onChanged,
          style: AppTheme.bodyStyle(context, scale),
          decoration: InputDecoration(
            hintText: "did:peer:2... or +peername",
            hintStyle: AppTheme.captionStyle(context, scale),
            filled: true,
            fillColor: AppTheme.background(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide(color: AppTheme.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide(color: AppTheme.border(context))),
          ),
        ),
        SizedBox(height: 40.0 * scale),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent(context),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50.0 * scale),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
          ),
          onPressed: onSubmit,
          child: Text("Start Chat", style: AppTheme.subHeadingStyle(context, scale).copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback onSubmit;
  final double scale;

  const _GroupTab({required this.onChanged, required this.onSubmit, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Group Name", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 12.0 * scale),
        TextField(
          onChanged: onChanged,
          style: AppTheme.bodyStyle(context, scale),
          decoration: InputDecoration(
            hintText: "e.g. Project Willow Core",
            hintStyle: AppTheme.captionStyle(context, scale),
            filled: true,
            fillColor: AppTheme.background(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide(color: AppTheme.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide(color: AppTheme.border(context))),
          ),
        ),
        SizedBox(height: 24.0 * scale),
        Container(
          padding: EdgeInsets.all(16.0 * scale),
          decoration: BoxDecoration(color: AppTheme.accentDark(context), borderRadius: BorderRadius.circular(16.0 * scale), border: Border.all(color: AppTheme.accent(context))),
          child: LayoutGrid(
            columnSizes: [auto, 1.fr],
            rowSizes: [auto],
            columnGap: 12.0 * scale,
            children: [
              Icon(LucideIcons.shieldCheck, color: AppTheme.accent(context), size: 20.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
              Text("Multi-peer groups use Willow protocol for decentralized sync.", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context))).withGridPlacement(columnStart: 1, rowStart: 0),
            ],
          ),
        ),
        SizedBox(height: 40.0 * scale),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent(context),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50.0 * scale),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
          ),
          onPressed: onSubmit,
          child: Text("Create Group", style: AppTheme.subHeadingStyle(context, scale).copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
