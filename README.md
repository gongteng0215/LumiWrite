# LumiWrite

LumiWrite 是一款本地优先、轻量、高性能的 Markdown 编辑器。

> 当前处于 MVP 开发阶段。

## 已实现功能（2026-02-04）
- Markdown 基础格式渲染（H1-H6、段落、引用、列表、任务）
- 行内样式（加粗/斜体/删除线/高亮）
- 代码块语法高亮 + 语言选择
- 表格渲染与编辑（多行单元格、行列插入/删除）
- 侧边栏文件树 + 目录大纲（可点击跳转）
- 文件打开/保存（Ctrl+S）
- 撤销/重做 + 热键配置（hotkeys.json）
- 主题跟随系统（Light/Dark）

## 待实现功能
- 混合编辑（源码/预览切换）
- 图片粘贴与 assets 管理
- Rust notify 文件监听
- 自定义标题栏
- 导出（HTML/PDF/长图）
- Windows/macOS 打包发布

## 技术栈
- Flutter
- super_editor
- Rust
- flutter_rust_bridge
- highlight

## 快速开始

### 前置要求
- Flutter SDK（稳定版）
- Rust 工具链

### 安装与运行
1. 克隆仓库
   ```bash
   git clone https://github.com/yourusername/lumiwrite.git
   cd lumiwrite
   ```
2. 安装 Flutter 依赖
   ```bash
   flutter pub get
   ```
3. 生成 Rust 绑定（如需）
   如果修改了 `native/` 目录代码，需要重新生成 Dart 绑定：
   ```bash
   flutter_rust_bridge_codegen generate
   ```
4. 运行应用
   ```bash
   flutter run
   ```

### 应用图标
将图标 PNG 放在项目根目录的 `app.png`，并确保 `pubspec.yaml` 中 `flutter_launcher_icons.image_path` 指向该文件。

生成图标：
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

Windows 重新构建：
```bash
flutter build windows --release
```

### 便携包打包与分发（推荐）
Windows 便携版打包目录在 `build/windows/x64/runner/Release/`。建议将整个目录打包成 zip 分发。

项目内已提供一键打包脚本：
```bash
powershell -ExecutionPolicy Bypass -File installer\package_portable.ps1
```

输出产物：
- `dist/LumiWrite_Portable/`（可直接运行）
- `dist/LumiWrite_Portable.zip`（可直接分发）

### 文件关联脚本（.md / .markdown）
便携包内包含两个脚本：
- `register_md.ps1`：关联 `.md/.markdown` 到 `LumiWrite.exe`
- `unregister_md.ps1`：解除关联

使用方法（放在 `LumiWrite.exe` 同目录运行）：
```bash
powershell -ExecutionPolicy Bypass -File .\register_md.ps1
powershell -ExecutionPolicy Bypass -File .\unregister_md.ps1
```

## 热键配置
默认热键：
- Ctrl+Z：撤销
- Ctrl+Y：重做
- Ctrl+S：保存
- Ctrl+O：打开文件
- Ctrl+Shift+O：打开文件夹

你可以在项目根目录的 `hotkeys.json` 配置热键，例如：
```json
{
  "undo": "Ctrl+Z",
  "redo": "Ctrl+Y",
  "save": "Ctrl+S",
  "openFile": "Ctrl+O",
  "openFolder": "Ctrl+Shift+O"
}
```
留空表示禁用该热键。

## 路线图
- [x] 基础 Markdown 输入与渲染
- [x] 文件打开 / 保存
- [x] 侧边栏文件树 + 目录大纲
- [x] 代码块语法高亮 + 语言选择
- [x] 表格渲染与编辑
- [x] 撤销/重做 + 热键配置
- [ ] 图片粘贴与本地存储
- [ ] 混合编辑（源码/预览切换）
- [ ] 文件监听（Rust notify）
- [ ] 自定义标题栏
- [ ] 导出（HTML/PDF/长图）
- [ ] 打包发布（Windows/macOS）

## License
MIT
