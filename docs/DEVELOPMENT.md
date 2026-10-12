# 开发指南

## 环境与命令

在仓库根目录运行 `flutter pub get`，然后用 `flutter devices` 查找目标设备，运行 `flutter run -d <device-id>`。修改 `pubspec.yaml` 后重新运行 `flutter pub get`。Windows、macOS、Linux、Android 和 iOS 的原生工程分别在同名目录；iOS 构建需要 macOS。

应用根目录的 `pubspec.lock` 提交到仓库，以固定可复现的依赖版本；它由 `flutter pub get` 生成，不要手工编辑。两个本地包只通过根应用的 path 依赖接入。

```sh
flutter test tests
flutter test tests/ui/plain_text_layout_engine_test.dart
flutter analyze lib packages tests
dart format lib packages tests
```

`flutter analyze` 可检查全仓库；本项目的本地包也可通过 `flutter analyze lib packages tests` 单独检查。新代码不要引入 analyzer 错误。测试统一放在 `tests/domain`、`tests/data`、`tests/ui`，使用 `package:flutter_test/flutter_test.dart`。布局测试先初始化 binding；有 `dispose` 的对象与临时目录使用 `addTearDown` 清理。

## 代码入口

| 任务 | 入口 |
| --- | --- |
| 应用组装、启动 | `lib/main.dart`、`lib/app/zephyr_app.dart` |
| 书库规则与仓储协议 | `lib/domain/` |
| PureWriter SQLite、备份、云服务 | `lib/data/` |
| 工作区与设置 | `lib/ui/features/workspace/`、`lib/ui/features/settings/` |
| Zephyr 编辑器外壳 | `lib/ui/features/editor/plain_text/zephyr_plain_text_editor.dart` |
| 纯 Dart 文本规则 | `packages/text_editor_foundation/lib/` |
| 可复用 Flutter 编辑内核 | `packages/plain_text_editor/lib/` |
| 通用 Flutter 组件 | `packages/flutter_primitives/lib/` |
| Zephyr 设计组件 | `lib/ui/core/` |

先把 Zephyr 业务规则放在 `domain`，I/O 放在 `data`，可观察 UI 状态放在 ViewModel。跨产品纯 Dart 文本规则进入基础包；跨产品 Flutter 编辑或 Widget 逻辑进入相应 Flutter 包。包内不能导入 Zephyr。保留兼容导出以免破坏调用方，新增调用直接使用包入口。

## 提交前验证

运行受影响测试文件、`flutter test tests`、`flutter analyze lib packages tests` 与 `git diff --check`。不要通过削弱断言、跳过用例或改产品行为来使结构重构通过。涉及 `Room.db` 时，同时检查读写、只读 schema、锁、备份恢复及启动回退路径。
