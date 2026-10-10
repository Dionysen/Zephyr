import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../../l10n/app_localizations.dart';

extension ShortcutLabels on AppLocalizations {
  String shortcutGroupTitle(ShortcutGroup group) => switch (group) {
    ShortcutGroup.clipboard => shortcutGroupClipboard,
    ShortcutGroup.history => shortcutGroupHistory,
    ShortcutGroup.delete => shortcutGroupDelete,
    ShortcutGroup.indent => shortcutGroupIndent,
    ShortcutGroup.newline => shortcutGroupNewline,
    ShortcutGroup.navigate => shortcutGroupNavigate,
    ShortcutGroup.select => shortcutGroupSelect,
    ShortcutGroup.workspace => shortcutGroupWorkspace,
  };

  String shortcutActionTitle(ShortcutActionId id) => switch (id) {
    ShortcutActionId.copy => shortcutActionCopy,
    ShortcutActionId.cut => shortcutActionCut,
    ShortcutActionId.paste => shortcutActionPaste,
    ShortcutActionId.selectAll => shortcutActionSelectAll,
    ShortcutActionId.undo => shortcutActionUndo,
    ShortcutActionId.redo => shortcutActionRedo,
    ShortcutActionId.deleteBackward => shortcutActionDeleteBackward,
    ShortcutActionId.deleteForward => shortcutActionDeleteForward,
    ShortcutActionId.deleteWordBackward => shortcutActionDeleteWordBackward,
    ShortcutActionId.deleteWordForward => shortcutActionDeleteWordForward,
    ShortcutActionId.indent => shortcutActionIndent,
    ShortcutActionId.outdent => shortcutActionOutdent,
    ShortcutActionId.newline => shortcutActionNewline,
    ShortcutActionId.moveLeft => shortcutActionMoveLeft,
    ShortcutActionId.moveRight => shortcutActionMoveRight,
    ShortcutActionId.moveUp => shortcutActionMoveUp,
    ShortcutActionId.moveDown => shortcutActionMoveDown,
    ShortcutActionId.moveWordLeft => shortcutActionMoveWordLeft,
    ShortcutActionId.moveWordRight => shortcutActionMoveWordRight,
    ShortcutActionId.moveLineStart => shortcutActionMoveLineStart,
    ShortcutActionId.moveLineEnd => shortcutActionMoveLineEnd,
    ShortcutActionId.movePageUp => shortcutActionMovePageUp,
    ShortcutActionId.movePageDown => shortcutActionMovePageDown,
    ShortcutActionId.moveDocumentStart => shortcutActionMoveDocumentStart,
    ShortcutActionId.moveDocumentEnd => shortcutActionMoveDocumentEnd,
    ShortcutActionId.selectLeft => shortcutActionSelectLeft,
    ShortcutActionId.selectRight => shortcutActionSelectRight,
    ShortcutActionId.selectUp => shortcutActionSelectUp,
    ShortcutActionId.selectDown => shortcutActionSelectDown,
    ShortcutActionId.selectWordLeft => shortcutActionSelectWordLeft,
    ShortcutActionId.selectWordRight => shortcutActionSelectWordRight,
    ShortcutActionId.selectLineStart => shortcutActionSelectLineStart,
    ShortcutActionId.selectLineEnd => shortcutActionSelectLineEnd,
    ShortcutActionId.selectPageUp => shortcutActionSelectPageUp,
    ShortcutActionId.selectPageDown => shortcutActionSelectPageDown,
    ShortcutActionId.selectDocumentStart => shortcutActionSelectDocumentStart,
    ShortcutActionId.selectDocumentEnd => shortcutActionSelectDocumentEnd,
    ShortcutActionId.closeSettings => shortcutActionCloseSettings,
  };
}

List<ShortcutActionId> actionsInGroup(ShortcutGroup group) => [
  for (final id in ShortcutActionId.values)
    if (id.group == group) id,
];
