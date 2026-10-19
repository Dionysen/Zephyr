# 开发指南

## 环境与命令

本仓库是 **Melos monorepo**：Flutter 应用在 `apps/zephyr/`，共享包在 `packages/`。

在仓库根目录：

```sh
dart pub get
dart run melos bootstrap
```

日常运行与调试在 `apps/zephyr` 下执行（`flutter devices`、`flutter run -d <device-id>`）。修改任意 `pubspec.yaml` 后重新 `dart run melos bootstrap` 或在该包目录执行 `flutter pub get`。Windows、macOS、Linux、Android 和 iOS 的原生工程在 `apps/zephyr/` 下同名目录；iOS 构建需要 macOS。

产品 UI 风格默认是现有 Zephyr 外观。可在运行或构建命令中加 `--dart-define=ZEPHYR_DESIGN_STYLE=material` 或 `cupertino`，也可在 `apps/zephyr/lib/app/zephyr_design_config.dart` 改唯一默认值。当前覆盖范围和迁移边界见 [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)。

根目录 `pubspec.lock` 锁定整个 workspace（应用 + 本地包），由 `dart pub get` / `dart run melos bootstrap` 生成，不要手工编辑。

```sh
dart run melos run test
dart run melos run analyze
# 或仅应用：
cd apps/zephyr && flutter test tests/ui/plain_text_layout_engine_test.dart
dart run melos run format
```

`melos run analyze` 会分析应用（`lib`、`tests`）与各 `packages/*/lib`。新代码不要引入 analyzer 错误。测试在 `apps/zephyr/tests/domain`、`tests/data`、`tests/ui`，使用 `package:flutter_test/flutter_test.dart`。布局测试先初始化 binding；有 `dispose` 的对象与临时目录使用 `addTearDown` 清理。

## 发版

正式发版由 **Git tag** 触发 [`.github/workflows/release.yml`](../.github/workflows/release.yml)：推送 `v*` 标签后，CI 会构建 Linux / Windows / macOS / Android / iOS（未签名）并创建 GitHub Release。

发版前建议：

1. 在 `main` 上，工作区已提交，且与 `origin/main` 同步（不要落后远程）。
2. 视需要更新 `CHANGELOG.md`（将 `Unreleased` 挪到新版本小节）。
3. 确认仓库 Secrets 已配置（可选）：`ANDROID_KEYSTORE_BASE64` 等，否则 APK 为 debug 签名。

一键脚本（只需版本号，可带或不带前缀 `v`）：

```powershell
# Windows（仓库根目录）
.\tool\release.ps1 1.0.4
```

```sh
# macOS / Linux
chmod +x tool/release.sh
./tool/release.sh 1.0.4
```

脚本会：把 `apps/zephyr/pubspec.yaml` 的 `version` 设为 `X.Y.Z+N`（同版本号时递增 `+N`）、提交、`git tag -a vX.Y.Z`、`git push origin main` 与 `git push origin vX.Y.Z`。加 `-DryRun` / `--dry-run` 只预览不执行。若不想改 pubspec，仅对当前 HEAD 打 tag：`-TagOnly` / `--tag-only`。

手动等价步骤：

```sh
git checkout main && git pull
# 编辑 apps/zephyr/pubspec.yaml 与 CHANGELOG.md，提交
git tag -a v1.0.4 -m "Zephyr v1.0.4"
git push origin main
git push origin v1.0.4
```

已有标签：`v1.0.1`、`v1.0.2`、`v1.0.3`。下一版请使用未占用的版本号（例如 `1.0.4`）。

## 代码入口

| 任务 | 入口 |
| --- | --- |
| 应用组装、启动 | `apps/zephyr/lib/main.dart`、`apps/zephyr/lib/app/zephyr_app.dart` |
| 书库规则与仓储协议 | `apps/zephyr/lib/domain/` |
| PureWriter SQLite、备份、云服务 | `apps/zephyr/lib/data/` |
| 工作区与设置 | `apps/zephyr/lib/ui/features/workspace/`、`apps/zephyr/lib/ui/features/settings/` |
| Zephyr 编辑器外壳 | `apps/zephyr/lib/ui/features/editor/plain_text/zephyr_plain_text_editor.dart` |
| 纯 Dart 文本规则 | `packages/text_editor_foundation/lib/` |
| 可复用 Flutter 编辑内核 | `packages/plain_text_editor/lib/` |
| 通用 Flutter 组件 | `packages/flutter_primitives/lib/` |
| 通用 JSON 文件存储 | `packages/local_json_store/lib/` |
| Zephyr 设计组件 | `apps/zephyr/lib/ui/core/` |

先把 Zephyr 业务规则放在 `domain`，I/O 放在 `data`，可观察 UI 状态放在 ViewModel。跨产品纯 Dart 文本规则进入基础包；跨产品 Flutter 编辑或 Widget 逻辑进入相应 Flutter 包。包内不能导入 Zephyr。保留兼容导出以免破坏调用方，新增调用直接使用包入口。

## 提交前验证

运行受影响测试、`dart run melos run test`、`dart run melos run analyze` 与 `git diff --check`。不要通过削弱断言、跳过用例或改产品行为来使结构重构通过。涉及 `Room.db` 时，同时检查读写、只读 schema、锁、备份恢复及启动回退路径。
