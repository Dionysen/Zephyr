# 在新产品中复用模块

`packages/` 下的包不导入 Zephyr 应用代码。按需要复制整个包目录，并在新产品的 `pubspec.yaml` 中以 path 依赖它们：

- `text_editor_foundation`：纯 Dart 文本规则、字数、边距；不需要 Flutter。
- `plain_text_editor`：Flutter 文本编辑内核；同时复制相邻的 `text_editor_foundation`。
- `flutter_primitives`：跨平台抽屉、双页滑动、浮层、导航、分栏与统一控件样式。
- `local_json_store`：纯 Dart JSON 配置文件读写；由新产品注入目录与文件名。

这些包目前使用 Melos/Dart workspace。新产品若也是 workspace，把复制的目录加入根 `workspace:` 列表；若不是 workspace，删除各包 `pubspec.yaml` 中的 `resolution: workspace`，并把 `plain_text_editor` 对基础包的相对 path 保持为有效路径。运行 `dart pub get` 或 `flutter pub get` 解析依赖。

新产品从包的公共入口导入 API，例如 `package:flutter_primitives/flutter_primitives.dart`、`package:local_json_store/local_json_store.dart`。应用自行提供主题颜色、业务数据、平台目录与编辑器外壳；Zephyr 的兼容导出路径仅供旧代码使用。统一的控件尺寸、浮层阴影、滚动条和工具栏样式位于 `flutter_primitives`，可直接用在新产品的主题组合中。

设置页可直接传入条目，页面按可用宽度选择桌面或移动布局，无需平台判断：

```dart
AdaptiveSettingsPage(
  title: 'Settings',
  groups: [
    SettingsGroup(
      title: 'Editor',
      icon: Icons.edit,
      items: [
        SettingsToggleItem(
          title: 'Auto save',
          icon: Icons.save,
          value: autoSave,
          onChanged: (value) => setState(() => autoSave = value),
        ),
        SettingsChoiceItem<String>(
          title: 'Format',
          icon: Icons.description,
          value: format,
          choices: const [
            SettingsChoice(value: 'plain', label: 'Plain'),
            SettingsChoice(value: 'markdown', label: 'Markdown'),
          ],
          onChanged: (value) => setState(() => format = value),
        ),
      ],
    ),
  ],
)
```

`SettingsNumberItem` 自动使用宽屏行内滑杆或窄屏数值对话框；`SettingsActionItem` 用于操作或子页面。只需要提供状态与保存回调。应用已有 `Scaffold` 时使用 `AdaptiveSettingsView`。

产品级风格在应用根节点选择一次：`DesignStyleScope(style: DesignStyle.cupertino, child: app)`。可用 `material`、`cupertino` 或 `custom`；前两种设置项有独立的 Material / Cupertino 控件实现，`custom` 由宿主的主题和扩展组件实现。风格与窗口宽度独立，修改风格不需要改变设置项列表。Zephyr 的实现及尚待迁移的应用专用页面见 [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)。
