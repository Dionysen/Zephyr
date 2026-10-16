import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/ai_chat_session.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';

/// Returns the selected session id, or null when dismissed without a change.
Future<String?> showWorkspaceAiSessionsSheet(
  BuildContext context, {
  required WritingLibraryRepository repository,
  required String articleId,
  String? activeSessionId,
}) {
  return showZephyrModalSheet<String>(
    context: context,
    builder: (context) => _WorkspaceAiSessionsSheet(
      repository: repository,
      articleId: articleId,
      activeSessionId: activeSessionId,
    ),
  );
}

class _WorkspaceAiSessionsSheet extends StatefulWidget {
  const _WorkspaceAiSessionsSheet({
    required this.repository,
    required this.articleId,
    required this.activeSessionId,
  });

  final WritingLibraryRepository repository;
  final String articleId;
  final String? activeSessionId;

  @override
  State<_WorkspaceAiSessionsSheet> createState() =>
      _WorkspaceAiSessionsSheetState();
}

class _WorkspaceAiSessionsSheetState extends State<_WorkspaceAiSessionsSheet> {
  var _showArchived = false;
  var _loading = true;
  List<AiChatSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final sessions = await widget.repository.listAiChatSessions(
      widget.articleId,
      includeArchived: _showArchived,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sessions = sessions;
    });
  }

  Future<void> _createSession() async {
    if (!mounted) return;
    Navigator.of(context).pop(kAiChatNewConversation);
  }

  Future<void> _archive(AiChatSession session, bool archived) async {
    await widget.repository.archiveAiChatSession(
      session.id,
      archived: archived,
    );
    await _reload();
  }

  Future<void> _delete(AiChatSession session) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiChatDeleteSessionTitle),
        content: Text(l10n.aiChatDeleteSessionBody(session.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deleteAiChatSession(session.id);
    if (!mounted) return;
    if (session.id == widget.activeSessionId) {
      final remaining = await widget.repository.listAiChatSessions(
        widget.articleId,
      );
      if (!mounted) return;
      if (remaining.isEmpty) {
        await widget.repository.beginNewAiChatConversation(widget.articleId);
        Navigator.of(context).pop(kAiChatNewConversation);
      } else {
        Navigator.of(context).pop(remaining.first.id);
      }
      return;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.aiChatSessionsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _createSession,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.aiChatNewSession),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.aiChatShowArchivedSessions),
              value: _showArchived,
              onChanged: (value) {
                setState(() => _showArchived = value);
                unawaited(_reload());
              },
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.aiChatNoSessions,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final active =
                        widget.activeSessionId != null &&
                        session.id == widget.activeSessionId;
                    return ListTile(
                      leading: Icon(
                        session.archived
                            ? Icons.inventory_2_outlined
                            : Icons.chat_bubble_outline,
                      ),
                      title: Text(session.title),
                      subtitle: Text(
                        l10n.aiChatSessionUpdated(
                          _formatTime(session.updatedAt),
                        ),
                      ),
                      trailing: active
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : PopupMenuButton<String>(
                              onSelected: (value) async {
                                switch (value) {
                                  case 'open':
                                    Navigator.of(context).pop(session.id);
                                  case 'archive':
                                    await _archive(session, !session.archived);
                                  case 'delete':
                                    await _delete(session);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Text(l10n.aiChatOpenSession),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text(
                                    session.archived
                                        ? l10n.aiChatUnarchiveSession
                                        : l10n.aiChatArchiveSession,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.aiChatDeleteSession),
                                ),
                              ],
                            ),
                      onTap: active
                          ? null
                          : () => Navigator.of(context).pop(session.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
