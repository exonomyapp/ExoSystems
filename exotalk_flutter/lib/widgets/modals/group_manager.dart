import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../../src/rust/api/willow.dart';
import '../../main.dart';
import '../../providers/group_provider.dart';
import '../../providers/chat_provider.dart';
import '../../src/theme.dart';
import '../../providers/toast_provider.dart';
import 'package:exoauth/exoauth.dart';

class GroupManagerModal extends ConsumerStatefulWidget {
  final Conversation conversation;
  
  const GroupManagerModal({super.key, required this.conversation});

  @override
  ConsumerState<GroupManagerModal> createState() => _GroupManagerModalState();
}

class _GroupManagerModalState extends ConsumerState<GroupManagerModal> {
  bool isEditingName = false;
  late String newName;
  String newPeerDid = "";
  String newPeerLevel = "Write";

  @override
  void initState() {
    super.initState();
    newName = widget.conversation.title;
  }

  void handleUpdateName() {
    if (newName.trim().isEmpty) return;
    ref.read(conversationListProvider.notifier).rename(widget.conversation.id, newName);
    setState(() => isEditingName = false);
    ref.read(toastProvider.notifier).show("Chat renamed to $newName.", type: ToastType.success);
  }

  void handleAddPeer() async {
    if (newPeerDid.trim().isEmpty) return;
    await ref.read(groupProvider(widget.conversation.id).notifier).invitePeer(newPeerDid.trim(), newPeerLevel);
    setState(() => newPeerDid = "");
    if (mounted) ref.read(toastProvider.notifier).show("Invitation sent! They'll see it when they come online.", type: ToastType.success);
  }

  void handleRemovePeer(String did) async {
    await ref.read(groupProvider(widget.conversation.id).notifier).revokePeer(did);
    if (mounted) ref.read(toastProvider.notifier).show("Member removed from this conversation.", type: ToastType.success);
  }

  void handleDelete() {
    ref.read(conversationListProvider.notifier).delete(widget.conversation.id);
    Navigator.pop(context);
    ref.read(toastProvider.notifier).show("Conversation deleted. All participants have been notified.", type: ToastType.success);
  }

  String getPeerName(String did) {
    if (did.startsWith('did:peer')) return 'Peer ${did.substring(9, 15)}';
    return 'Peer ${did.substring(0, 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final rosterData = ref.watch(groupProvider(widget.conversation.id));
    final verifiedParticipants = rosterData.allowedPeers.entries.toList();
    final scale = ref.watch(uiScaleProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(400.0, 650.0 * scale),
          maxHeight: 750.0 * scale,
        ),
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          children: [
            _ModalHeader(scale: scale),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopicBanner(
                      newName: newName,
                      isEditing: isEditingName,
                      convoId: widget.conversation.id,
                      onEditToggle: () => setState(() => isEditingName = !isEditingName),
                      onNameChanged: (v) => newName = v,
                      onSave: handleUpdateName,
                      scale: scale,
                    ),
                    SizedBox(height: 32.0 * scale),
                    Text("Verified Participants (${verifiedParticipants.length})", style: ConsciaTheme.subHeadingStyle(context, scale)),
                    SizedBox(height: 16.0 * scale),
                    _AddPeerRow(
                      onDidChanged: (v) => newPeerDid = v,
                      onLevelChanged: (v) => setState(() => newPeerLevel = v!),
                      onAdd: handleAddPeer,
                      level: newPeerLevel,
                      scale: scale,
                    ),
                    SizedBox(height: 24.0 * scale),
                    if (rosterData.isLoading && verifiedParticipants.isEmpty)
                      Center(child: CircularProgressIndicator())
                    else
                      ...verifiedParticipants.map((e) => _ParticipantTile(name: getPeerName(e.key), did: e.key, level: e.value, onRemove: () => handleRemovePeer(e.key), scale: scale)),
                    SizedBox(height: 40.0 * scale),
                    DangerZone(
                      scale: scale,
                      items: [
                        DangerZoneItem(
                          title: "Delete Conversation",
                          description: "Removes this conversation from your device and broadcasts a tombstone to stop synchronization with peers.",
                          buttonLabel: "Delete Conversation",
                          onPressed: handleDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _ModalFooter(onClose: () => Navigator.pop(context), scale: scale),
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
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ConsciaTheme.border(context)))),
      child: LayoutGrid(
        columnSizes: [auto, 1.fr],
        rowSizes: [auto],
        columnGap: 16.0 * scale,
        children: [
          Icon(LucideIcons.users, color: ConsciaTheme.accent(context), size: 28.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Chat Management", style: ConsciaTheme.headingStyle(context, scale)),
              Text("Control membership and metadata", style: ConsciaTheme.captionStyle(context, scale)),
            ],
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    );
  }
}

class _TopicBanner extends StatelessWidget {
  final String newName;
  final bool isEditing;
  final String convoId;
  final VoidCallback onEditToggle;
  final Function(String) onNameChanged;
  final VoidCallback onSave;
  final double scale;

  const _TopicBanner({required this.newName, required this.isEditing, required this.convoId, required this.onEditToggle, required this.onNameChanged, required this.onSave, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0 * scale),
      decoration: ConsciaTheme.solidDecoration(context, radius: 20.0 * scale),
      child: LayoutGrid(
        columnSizes: [auto, 1.fr],
        rowSizes: [auto],
        columnGap: 16.0 * scale,
        children: [
          CircleAvatar(radius: 28.0 * scale, backgroundColor: ConsciaTheme.accentDark(context), child: Text(newName[0].toUpperCase(), style: ConsciaTheme.headingStyle(context, scale).copyWith(color: ConsciaTheme.accent(context)))).withGridPlacement(columnStart: 0, rowStart: 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing)
                LayoutGrid(
                  columnSizes: [1.fr, auto],
                  rowSizes: [auto],
                  children: [
                    TextField(onChanged: onNameChanged, style: ConsciaTheme.bodyStyle(context, scale), decoration: InputDecoration(isDense: true)).withGridPlacement(columnStart: 0, rowStart: 0),
                    IconButton(icon: Icon(LucideIcons.check, size: 18.0 * scale), onPressed: onSave).withGridPlacement(columnStart: 1, rowStart: 0),
                  ],
                )
              else
                LayoutGrid(
                  columnSizes: [1.fr, auto],
                  rowSizes: [auto],
                  children: [
                    Text(newName, style: ConsciaTheme.subHeadingStyle(context, scale)).withGridPlacement(columnStart: 0, rowStart: 0),
                    IconButton(icon: Icon(LucideIcons.edit3, size: 16.0 * scale, color: ConsciaTheme.accent(context)), onPressed: onEditToggle).withGridPlacement(columnStart: 1, rowStart: 0),
                  ],
                ),
              Text("ID: $convoId", style: ConsciaTheme.captionStyle(context, scale), overflow: TextOverflow.ellipsis),
            ],
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    );
  }
}

class _AddPeerRow extends StatelessWidget {
  final Function(String) onDidChanged;
  final Function(String?) onLevelChanged;
  final VoidCallback onAdd;
  final String level;
  final double scale;

  const _AddPeerRow({required this.onDidChanged, required this.onLevelChanged, required this.onAdd, required this.level, required this.scale});

  @override
  Widget build(BuildContext context) {
    return LayoutGrid(
      columnSizes: [1.fr, auto, auto],
      rowSizes: [auto],
      columnGap: 8.0 * scale,
      children: [
        TextField(
          onChanged: onDidChanged,
          style: ConsciaTheme.bodyStyle(context, scale),
          decoration: InputDecoration(hintText: "did:peer...", hintStyle: ConsciaTheme.captionStyle(context, scale), filled: true, fillColor: ConsciaTheme.background(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide.none)),
        ).withGridPlacement(columnStart: 0, rowStart: 0),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
          decoration: BoxDecoration(color: ConsciaTheme.background(context), borderRadius: BorderRadius.circular(12.0 * scale)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: level,
              items: ["Read", "Write", "Admin"].map((l) => DropdownMenuItem(value: l, child: Text(l, style: ConsciaTheme.captionStyle(context, scale)))).toList(),
              onChanged: onLevelChanged,
            ),
          ),
        ).withGridPlacement(columnStart: 1, rowStart: 0),
        IconButton.filled(onPressed: onAdd, icon: Icon(LucideIcons.plus, size: 20.0 * scale)).withGridPlacement(columnStart: 2, rowStart: 0),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String name;
  final String did;
  final String level;
  final VoidCallback onRemove;
  final double scale;

  const _ParticipantTile({required this.name, required this.did, required this.level, required this.onRemove, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0 * scale),
      padding: EdgeInsets.all(12.0 * scale),
      decoration: ConsciaTheme.solidDecoration(context, radius: 12.0 * scale),
      child: LayoutGrid(
        columnSizes: [auto, 1.fr, auto],
        rowSizes: [auto],
        columnGap: 12.0 * scale,
        children: [
          CircleAvatar(radius: 16.0 * scale, backgroundColor: ConsciaTheme.background(context), child: Text(name[0], style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold))).withGridPlacement(columnStart: 0, rowStart: 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutGrid(
                columnSizes: [auto, 1.fr],
                rowSizes: [auto],
                columnGap: 8.0 * scale,
                children: [
                  Text(name, style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold)).withGridPlacement(columnStart: 0, rowStart: 0),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), 
                    decoration: BoxDecoration(color: ConsciaTheme.accentDark(context), borderRadius: BorderRadius.circular(4)), 
                    child: Text(level, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontSize: 8, color: ConsciaTheme.accent(context), fontWeight: FontWeight.bold))
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                ],
              ),
              Text(did, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontSize: 9), overflow: TextOverflow.ellipsis),
            ],
          ).withGridPlacement(columnStart: 1, rowStart: 0),
          IconButton(icon: Icon(LucideIcons.trash2, size: 16.0 * scale, color: ConsciaTheme.error(context)), onPressed: onRemove).withGridPlacement(columnStart: 2, rowStart: 0),
        ],
      ),
    );
  }
}

class _ModalFooter extends StatelessWidget {
  final VoidCallback onClose;
  final double scale;

  const _ModalFooter({required this.onClose, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.0 * scale),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: ConsciaTheme.border(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ConsciaTheme.accent(context), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 32.0 * scale, vertical: 16.0 * scale), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale))),
            onPressed: onClose,
            child: Text("Done", style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
