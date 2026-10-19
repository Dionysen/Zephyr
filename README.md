# Zephyr

Zephyr 是本地优先的跨平台纯文本编辑器。书库存储为兼容纯纯写作的 `App/Room.db`，不是由应用管理的一组 `.txt` 文件。

- [用户指南](docs/USER_GUIDE.md)：书库、编辑、备份和恢复。
- [开发指南](docs/DEVELOPMENT.md)：运行、测试和常见改动入口。
- [架构说明](docs/ARCHITECTURE.md)：模块边界、可复用包和数据安全约束。
- [AI 协作约定](AGENTS.md)：修改代码时必须遵守的仓库规则。

## 仓库布局

| 路径 | 内容 |
| --- | --- |
| `apps/zephyr/` | Flutter 应用（`lib/`、各平台工程、`tests/`） |
| `packages/` | 可复用的 `plain_text_editor`、`text_editor_foundation`、`flutter_primitives` |
| `docs/` | 文档 |
| 根目录 `pubspec.yaml` | Pub workspace + Melos 脚本（分析、测试、bootstrap） |

## 快速开始

安装与 Dart `^3.13.4` 兼容的 Flutter SDK，在仓库根目录：

```sh
dart pub get
dart run melos bootstrap
cd apps/zephyr
flutter doctor
flutter devices
flutter run -d <device-id>
```

在仓库根目录也可以（等价于在 `apps/zephyr` 里跑）：

```sh
dart run melos run run -- -d windows
```

Windows 桌面需要 Visual Studio 的 Desktop development with C++ 工作负载；Android 需要 Android SDK；iOS 和 macOS 需要 Xcode；Linux 需要对应的 Flutter 桌面工具链。

在 IDE 中打开 Flutter 项目时，将 **`apps/zephyr`** 作为应用根目录（或打开整个 monorepo 并在该目录下运行 `flutter run`）。

## 质量检查

在仓库根目录：

```sh
dart run melos run analyze
dart run melos run test
```

或在 `apps/zephyr` 内：

```sh
flutter test tests
flutter analyze lib tests
```

纯 Dart 文本规则位于 `packages/text_editor_foundation`，Flutter 编辑引擎位于 `packages/plain_text_editor`，通用组件位于 `packages/flutter_primitives`。Zephyr 的书库、同步、主题和业务界面在 `apps/zephyr/lib/`。

## 书库安全

Zephyr 只允许写入已识别 PureWriter v27 Room 指纹的书库；未知 schema 以只读方式打开。不要同时在纯纯写作和 Zephyr 中编辑同一书库。Zephyr 的 `.zephyr-lock` 只能阻止其他 Zephyr 实例写入，纯纯写作不参与此锁协议。
