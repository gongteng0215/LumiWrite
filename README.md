# LumiWrite ✨

<p align="center">
  <img src="app.jpg" alt="LumiWrite Logo" width="160">
</p>

LumiWrite is a local-first, lightweight, high-performance Markdown editor. 📝⚡

> This project is currently in MVP development.

## Implemented Features (2026-02-04) ✅
- Markdown basics (H1-H6, paragraphs, blockquotes, lists, tasks)
- Inline styles (bold, italic, strikethrough, highlight)
- Code blocks with syntax highlighting + language selection
- Tables: render + edit (multi-line cells, insert/delete rows/cols)
- Sidebar file tree + document outline (click to jump)
- Open/save files (Ctrl+S)
- Undo/redo + configurable hotkeys (hotkeys.json)
- Theme follows system (Light/Dark)

## Not Yet Implemented ⏳
- Hybrid editing (source/preview switching)
- Paste images + assets management
- Rust notify file watching
- Custom title bar
- Export (HTML/PDF/long image)
- Windows/macOS packaging

## Tech Stack 🧰
- Flutter
- super_editor
- Rust
- flutter_rust_bridge
- highlight

## Quick Start 🚀

### Prerequisites
- Flutter SDK (stable)
- Rust toolchain

### Install & Run
1. Clone the repo
   ```bash
   git clone https://github.com/yourusername/lumiwrite.git
   cd lumiwrite
   ```
2. Install Flutter dependencies
   ```bash
   flutter pub get
   ```
3. Generate Rust bindings (when needed)
   If you modify or rebuild `native/`, regenerate Dart bindings:
   ```bash
   flutter_rust_bridge_codegen generate
   ```
4. Run
   ```bash
   flutter run
   ```

### App Icon 🎨
Place your icon PNG at the project root as `app.png`, and make sure
`flutter_launcher_icons.image_path` in `pubspec.yaml` points to it.

Generate icons:
```bash
flutter pub get
dart run flutter_launcher_icons
```

Rebuild Windows:
```bash
flutter build windows --release
```

### Portable Package (Recommended) 📦
The portable build output is located at `build/windows/x64/runner/Release/`.
Zip the whole directory for distribution.

One-click packaging script:
```bash
powershell -ExecutionPolicy Bypass -File installer\package_portable.ps1
```

Outputs:
- `dist/LumiWrite_Portable/` (ready to run)
- `dist/LumiWrite_Portable.zip` (ready to share)

### File Association Scripts (.md / .markdown) 🧷
The portable package includes two scripts:
- `register_md.ps1`: associate `.md/.markdown` with `LumiWrite.exe`
- `unregister_md.ps1`: remove the association

Run from the same folder as `LumiWrite.exe`:
```bash
powershell -ExecutionPolicy Bypass -File .\register_md.ps1
powershell -ExecutionPolicy Bypass -File .\unregister_md.ps1
```

## Hotkey Configuration ⌨️
Default hotkeys:
- Ctrl+Z: Undo
- Ctrl+Y: Redo
- Ctrl+S: Save
- Ctrl+O: Open file
- Ctrl+Shift+O: Open folder

You can edit `hotkeys.json` in the project root, for example:
```json
{
  "undo": "Ctrl+Z",
  "redo": "Ctrl+Y",
  "save": "Ctrl+S",
  "openFile": "Ctrl+O",
  "openFolder": "Ctrl+Shift+O"
}
```
Leave a value empty to disable that hotkey.

## Roadmap 🗺️
- [x] Basic Markdown input and rendering
- [x] File open/save
- [x] Sidebar file tree + outline
- [x] Code blocks + syntax highlighting + language selection
- [x] Table render + edit
- [x] Undo/redo + hotkey configuration
- [ ] Image paste + local storage
- [ ] Hybrid editing (source/preview switch)
- [ ] File watching (Rust notify)
- [ ] Custom title bar
- [ ] Export (HTML/PDF/long image)
- [ ] Packaging (Windows/macOS)

## License 📄
MIT
