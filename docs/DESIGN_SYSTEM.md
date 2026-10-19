# 产品级 UI 风格

风格由产品组装层选择，与用户的颜色主题、操作系统和窗口宽度分别管理。Zephyr 的唯一入口是 `apps/zephyr/lib/app/zephyr_design_config.dart`：默认 `custom` 维持现有 Zephyr 外观；构建时可用 `--dart-define=ZEPHYR_DESIGN_STYLE=material` 或 `cupertino` 选择另一套呈现。配置不写入用户设置，也不影响 `Room.db`、备份或同步。

## 分层

1. `domain`、`data` 和 ViewModel 只提供状态、命令与持久化，不认识设计风格。
2. `packages/flutter_primitives/lib/design/` 定义 `DesignStyle`、`DesignStyleScope`、`DesignSwitch` 和 `DesignSlider`。新产品在应用根节点选择一次；语义控件读取作用域。窗口宽度仍由组件独立决定。
3. 共享设置条目（toggle、choice、number、action）描述设置的语义。`AdaptiveSettingsPage` 和底层设置控件根据作用域选择 Material 或 Cupertino 页面、控件和选择器；`custom` 使用宿主主题定制的 Material 组件。
4. Zephyr 的 `productTheme` 为仍使用 Material 的旧页面提供三套全局控件默认值。`zephyrTheme` 是 `custom` 的实现，保持原有外观。Zephyr 设置页导航、常用选择器、列表弹层与简单确认对话框读取同一个风格作用域；特殊样式或复杂表单对话框继续由各功能拥有。

共享包不导入 Zephyr。新产品可以复用 `DesignStyleScope` 和设置组件，并由自己的应用组装层提供 `ThemeData`、业务数据、文案及需要的自定义组件。

## 边界和继续迁移

Flutter 的 Material 控件不会因切换 `ThemeData` 自动变为 Cupertino 控件。当前 Zephyr 的工作区、编辑器外壳、部分功能弹窗和复杂设置控件仍直接构建 Material Widget；它们在 `material` / `cupertino` 模式下通过全局主题获得相应颜色、形状和页面过渡，但尚未全部拥有独立的 Cupertino 交互实现。迁移一个页面时，应先复用共享语义组件，再为需要改变交互的控件增加风格实现，并分别验证窄屏、宽屏、键盘与返回行为。不要把颜色主题的切换当作设计风格切换。

该边界也是 API 扩展点：新风格先为语义组件添加呈现实现，再在产品层加入主题组装；业务模型无需改动。`custom` 表示宿主提供的设计系统，Zephyr 的具体实现只是其中一个例子。
