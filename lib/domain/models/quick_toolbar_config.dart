/// Built-in and user-defined tools for the IME quick toolbar.
enum QuickToolKind { tools, undo, paste, indent, format, phrase }

/// A single toolbar tool. Built-ins use stable [id]s matching [kind].name;
/// phrases use generated ids with [label] / [payload].
class QuickTool {
  const QuickTool({
    required this.id,
    required this.kind,
    this.label,
    this.payload,
  });

  static const toolsId = 'tools';
  static const undoId = 'undo';
  static const pasteId = 'paste';
  static const indentId = 'indent';
  static const formatId = 'format';

  static const tools = QuickTool(id: toolsId, kind: QuickToolKind.tools);
  static const undo = QuickTool(id: undoId, kind: QuickToolKind.undo);
  static const paste = QuickTool(id: pasteId, kind: QuickToolKind.paste);
  static const indent = QuickTool(id: indentId, kind: QuickToolKind.indent);
  static const format = QuickTool(id: formatId, kind: QuickToolKind.format);

  static const builtins = [tools, undo, paste, indent, format];

  final String id;
  final QuickToolKind kind;
  final String? label;
  final String? payload;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    if (label != null) 'label': label,
    if (payload != null) 'payload': payload,
  };

  factory QuickTool.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    final kind = QuickToolKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => QuickToolKind.phrase,
    );
    return QuickTool(
      id: json['id'] as String? ?? '',
      kind: kind,
      label: json['label'] as String?,
      payload: json['payload'] as String?,
    );
  }

  QuickTool copyWith({String? label, String? payload}) => QuickTool(
    id: id,
    kind: kind,
    label: label ?? this.label,
    payload: payload ?? this.payload,
  );

  @override
  bool operator ==(Object other) =>
      other is QuickTool &&
      other.id == id &&
      other.kind == kind &&
      other.label == label &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, kind, label, payload);
}

/// Persisted layout of the IME quick toolbar.
///
/// [pinnedIds] are configurable fixed-zone slots (not including the reserved
/// tools button). [customIds] are the horizontally scrollable zone.
class QuickToolbarConfig {
  const QuickToolbarConfig({
    required this.pinnedIds,
    required this.customIds,
    required this.catalog,
  });

  /// Max configurable pinned slots (tools button is always first → 5 total).
  static const maxPinned = 4;

  static final defaults = QuickToolbarConfig(
    pinnedIds: const [QuickTool.undoId, QuickTool.pasteId],
    customIds: const [QuickTool.indentId],
    catalog: List<QuickTool>.from(QuickTool.builtins),
  );

  final List<String> pinnedIds;
  final List<String> customIds;
  final List<QuickTool> catalog;

  /// Fixed zone ids including the reserved tools button at index 0.
  List<String> get fixedZoneIds => [QuickTool.toolsId, ...pinnedIds];

  QuickTool? toolById(String id) {
    for (final tool in catalog) {
      if (tool.id == id) return tool;
    }
    for (final tool in QuickTool.builtins) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  List<QuickTool> get pinnedTools =>
      pinnedIds.map(toolById).whereType<QuickTool>().toList(growable: false);

  List<QuickTool> get customTools =>
      customIds.map(toolById).whereType<QuickTool>().toList(growable: false);

  Set<String> get placedIds => {...pinnedIds, ...customIds, QuickTool.toolsId};

  /// Built-in tools not currently placed (phrases are always "add new").
  List<QuickTool> get availableBuiltins => QuickTool.builtins
      .where(
        (t) =>
            t.kind != QuickToolKind.tools &&
            t.kind != QuickToolKind.phrase &&
            !placedIds.contains(t.id),
      )
      .toList(growable: false);

  QuickToolbarConfig copyWith({
    List<String>? pinnedIds,
    List<String>? customIds,
    List<QuickTool>? catalog,
  }) => QuickToolbarConfig(
    pinnedIds: pinnedIds ?? this.pinnedIds,
    customIds: customIds ?? this.customIds,
    catalog: catalog ?? this.catalog,
  );

  /// Drops unknown ids, enforces uniqueness, caps pinned length, keeps tools out
  /// of both lists.
  QuickToolbarConfig normalized() {
    final known = <String>{
      for (final t in [...QuickTool.builtins, ...catalog]) t.id,
    };
    final seen = <String>{QuickTool.toolsId};
    List<String> clean(List<String> ids, {required int? max}) {
      final out = <String>[];
      for (final id in ids) {
        if (id == QuickTool.toolsId) continue;
        if (!known.contains(id) || seen.contains(id)) continue;
        seen.add(id);
        out.add(id);
        if (max != null && out.length >= max) break;
      }
      return out;
    }

    final phrases = catalog
        .where((t) => t.kind == QuickToolKind.phrase && t.id.isNotEmpty)
        .toList();
    final mergedCatalog = [...QuickTool.builtins, ...phrases];
    return QuickToolbarConfig(
      pinnedIds: clean(pinnedIds, max: maxPinned),
      customIds: clean(customIds, max: null),
      catalog: mergedCatalog,
    );
  }

  Map<String, Object?> toJson() => {
    'pinnedIds': pinnedIds,
    'customIds': customIds,
    'catalog': catalog
        .where((t) => t.kind == QuickToolKind.phrase)
        .map((t) => t.toJson())
        .toList(),
  };

  factory QuickToolbarConfig.fromJson(Map<String, Object?> json) {
    List<String> stringList(Object? value) {
      if (value is! List) return const [];
      return value.whereType<String>().toList();
    }

    final catalogRaw = json['catalog'];
    final phrases = <QuickTool>[];
    if (catalogRaw is List) {
      for (final item in catalogRaw) {
        if (item is Map) {
          final tool = QuickTool.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
          if (tool.kind == QuickToolKind.phrase && tool.id.isNotEmpty) {
            phrases.add(tool);
          }
        }
      }
    }

    return QuickToolbarConfig(
      pinnedIds: stringList(json['pinnedIds']),
      customIds: stringList(json['customIds']),
      catalog: [...QuickTool.builtins, ...phrases],
    ).normalized();
  }
}
