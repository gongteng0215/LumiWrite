# LumiWrite 任务清单 (Task List)

> 基于 需求文档 与 MVP_PLAN 更新。

## Phase 1: Core Editor
- [x] 集成 super_editor
- [x] Markdown 解析与序列化
- [x] 基础块级样式（标题/段落/引用/列表/任务）
- [x] 行内样式（加粗/斜体/删除线/高亮）
- [x] 代码块语法高亮 + 语言选择
- [x] 引用块背景与内边距优化
- [x] 代码块背景与语言选择 UI
- [x] 列表内 fenced code 解析修复
- [x] 表格渲染与编辑（多行、行列增删）
- [ ] 混合编辑（源码/预览切换）
- [ ] 表格列宽拖拽
- [ ] 图片粘贴

## Phase 2: File System
- [x] 打开/保存文件
- [x] 侧边栏文件树（Flutter）
- [x] 目录大纲（Outline）
- [ ] Rust 目录树读取
- [ ] Rust notify 文件监听
- [ ] 侧边栏自动刷新

## Phase 3: Hotkeys & UX
- [x] 撤销/重做
- [x] 热键配置（hotkeys.json）
- [x] 主题跟随系统
- [ ] 自定义标题栏
- [ ] 命令面板 (Ctrl/Cmd+P)
- [ ] Zen/专注模式

## Phase 4: Images
- [ ] Ctrl+V 粘贴图片
- [ ] Rust 保存与去重
- [ ] 生成相对路径

## Phase 5: Release
- [ ] Windows/macOS 打包
- [ ] CI/CD
