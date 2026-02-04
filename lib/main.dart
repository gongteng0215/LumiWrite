import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
// ignore: implementation_imports
import 'package:super_editor/src/undo_redo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/rust/frb_generated.dart';
import 'src/rust/api/simple.dart';
import 'infrastructure/editor/markdown_reactions.dart';
import 'infrastructure/editor/syntax_highlighting.dart';
import 'infrastructure/editor/styles.dart';
import 'infrastructure/editor/component_builders.dart';
import 'infrastructure/editor/markdown_parser.dart';
import 'infrastructure/editor/hotkeys.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final initialFilePath = _extractInitialFilePath(args);
  runApp(LumiWriteApp(initialFilePath: initialFilePath));
}

String? _extractInitialFilePath(List<String> args) {
  if (args.isEmpty) return null;
  for (final raw in args) {
    final candidate = raw.trim().replaceAll('"', '');
    if (candidate.isEmpty) continue;
    if (candidate.startsWith('-')) continue;
    final file = File(candidate);
    if (file.existsSync()) {
      return file.path;
    }
  }
  return null;
}

class LumiWriteApp extends StatelessWidget {
  const LumiWriteApp({super.key, this.initialFilePath});

  final String? initialFilePath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumiWrite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.merriweatherTextTheme(ThemeData.dark().textTheme),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      themeMode: ThemeMode.system,
      home: EditorPage(initialFilePath: initialFilePath),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.initialFilePath});

  final String? initialFilePath;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late MutableDocument _doc;
  late MutableDocumentComposer _composer;
  late Editor _docEditor;
  late HotkeyConfig _hotkeys;
  String? _currentFilePath;
  String? _currentFolderPath;
  String? _selectedFilePath;
  List<FileTreeNode> _fileTree = [];
  List<OutlineEntry> _outlineItems = [];
  DocumentChangeListener? _docChangeListener;
  VoidCallback? _composerListener;
  String? _activeHeadingId;
  final GlobalKey _docLayoutKey = GlobalKey();
  bool _isLoading = false;
  bool _isLoadingTree = false;
  int _editorKeyIndex = 0;
  SidebarSection _sidebarSection = SidebarSection.files;

  @override
  void initState() {
    super.initState();
    // Load a demo document by default
    const demoContent = '''
# Welcome to LumiWrite

This is a **demo** of the supported Markdown features.

## Headers
### Header 3
#### Header 4
##### Header 5
###### Header 6

## Lists
- Unordered item 1
- Unordered item 2

1. Ordered item 1
2. Ordered item 2

## Blockquotes
> This is a blockquote.
> It can span multiple lines.

## Code Blocks
```dart
void main() {
  print('Hello World');
}
```

## Horizontal Rule
---

Enjoy writing!
''';
    final hasInitialFile = widget.initialFilePath != null;
    _doc = parseMarkdownWithLanguage(hasInitialFile ? '' : demoContent);
    _composer = MutableDocumentComposer();
    _docEditor = Editor(
      editables: {
        Editor.documentKey: _doc,
        Editor.composerKey: _composer,
      },
      requestHandlers: List.from(defaultRequestHandlers),
      reactionPipeline: [
        ...defaultEditorReactions,
        MarkdownInputReaction(),
        SyntaxHighlightingReaction(),
      ],
      isHistoryEnabled: true,
    );
    // Apply initial syntax highlighting after editor is ready
    highlightAllCodeBlocks(_docEditor, _doc);
    _attachDocumentListener();
    _attachComposerListener();
    _outlineItems = _buildOutline();
    _updateActiveHeading();

    _hotkeys = HotkeyConfig();
    _hotkeys.addListener(_onHotkeysChanged);
    _hotkeys.load();

    if (hasInitialFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadFile(widget.initialFilePath!);
      });
    }
  }

  @override
  void dispose() {
    _detachDocumentListener();
    _detachComposerListener();
    _docEditor.dispose();
    _hotkeys.removeListener(_onHotkeysChanged);
    _hotkeys.dispose();
    super.dispose();
  }

  Future<void> _openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      await _loadFile(result.files.single.path!);
    }
  }

  Future<void> _loadFile(String path) async {
    try {
      final content = readFile(path: path);
      setState(() {
        _isLoading = true;
      });

      // Simulate async parsing or just quick switch
      await Future.delayed(const Duration(milliseconds: 50));

      setState(() {
        _detachDocumentListener();
        _detachComposerListener();
        _currentFilePath = path;
        _selectedFilePath = path;

        _doc = parseMarkdownWithLanguage(content);
        _composer = MutableDocumentComposer();
        _docEditor = Editor(
          editables: {
            Editor.documentKey: _doc,
            Editor.composerKey: _composer,
          },
          requestHandlers: List.from(defaultRequestHandlers),
          reactionPipeline: [
            ...defaultEditorReactions,
            MarkdownInputReaction(),
            SyntaxHighlightingReaction(),
          ],
          isHistoryEnabled: true,
        );
        _editorKeyIndex++;
        _isLoading = false;
        _attachDocumentListener();
        _attachComposerListener();
        _outlineItems = _buildOutline();
        _updateActiveHeading();
      });
      // Apply initial syntax highlighting after editor is ready
      highlightAllCodeBlocks(_docEditor, _doc);
    } catch (e) {
      if (mounted) {
        _showError('Failed to read file: $e');
      }
    }
  }

  void _onHotkeysChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleHotkey(LumiHotkeyAction action) {
    switch (action) {
      case LumiHotkeyAction.undo:
        _docEditor.undo();
        break;
      case LumiHotkeyAction.redo:
        _docEditor.redo();
        break;
      case LumiHotkeyAction.save:
        _saveFile();
        break;
      case LumiHotkeyAction.openFile:
        _openFile();
        break;
      case LumiHotkeyAction.openFolder:
        _openFolder();
        break;
    }
  }

  List<SuperEditorKeyboardAction> _buildKeyboardActions() {
    final actions = <SuperEditorKeyboardAction>[];
    final undoBinding = _hotkeys.bindingFor(LumiHotkeyAction.undo);
    if (undoBinding != null) {
      actions.add(_hotkeyToEditorAction(undoBinding, () => _docEditor.undo()));
    }
    final redoBinding = _hotkeys.bindingFor(LumiHotkeyAction.redo);
    if (redoBinding != null) {
      actions.add(_hotkeyToEditorAction(redoBinding, () => _docEditor.redo()));
    }
    actions.addAll(defaultKeyboardActions.where((action) {
      return action != undoWhenCmdZOrCtrlZIsPressed && action != redoWhenCmdShiftZOrCtrlShiftZIsPressed;
    }));
    return actions;
  }

  SuperEditorKeyboardAction _hotkeyToEditorAction(HotkeyBinding binding, VoidCallback action) {
    final activator = binding.toActivator();
    return ({
      required SuperEditorContext editContext,
      required KeyEvent keyEvent,
    }) {
      if (!activator.accepts(keyEvent, HardwareKeyboard.instance)) {
        return ExecutionInstruction.continueExecution;
      }
      action();
      return ExecutionInstruction.haltExecution;
    };
  }

  Future<void> _showHotkeySettings() async {
    final controllers = <LumiHotkeyAction, TextEditingController>{};
    for (final action in LumiHotkeyAction.values) {
      controllers[action] = TextEditingController(text: _hotkeys.displayFor(action));
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hotkey Settings'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final action in LumiHotkeyAction.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_hotkeys.labelFor(action)),
                          ),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: controllers[action],
                              decoration: const InputDecoration(
                                hintText: 'Ctrl+S',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Leave blank to disable. Config: ${_hotkeys.configPath}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updated = <LumiHotkeyAction, HotkeyBinding?>{};
                for (final action in LumiHotkeyAction.values) {
                  final raw = controllers[action]?.text ?? '';
                  final trimmed = raw.trim();
                  if (trimmed.isEmpty) {
                    continue;
                  }
                  final parsed = HotkeyBinding.parse(trimmed);
                  if (parsed == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid hotkey: $trimmed')),
                    );
                    return;
                  }
                  updated[action] = parsed;
                }

                _hotkeys.replaceAll(updated);
                await _hotkeys.save();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _openFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;

    setState(() {
      _currentFolderPath = path;
      _isLoadingTree = true;
      _fileTree = [];
    });

    try {
      final nodes = await _buildFileTree(path);
      if (!mounted) return;
      setState(() {
        _fileTree = nodes;
        _isLoadingTree = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTree = false;
        });
        _showError('Failed to read folder: $e');
      }
    }
  }

  Future<List<FileTreeNode>> _buildFileTree(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return [];

    final entities = await rootDir.list(followLinks: false).toList();
    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) {
        return aIsDir ? -1 : 1;
      }
      return _basename(a.path).toLowerCase().compareTo(_basename(b.path).toLowerCase());
    });

    final nodes = <FileTreeNode>[];
    for (final entity in entities) {
      final name = _basename(entity.path);
      if (_isIgnoredName(name)) continue;

      if (entity is Directory) {
        final children = await _buildFileTree(entity.path);
        nodes.add(FileTreeNode.directory(
          path: entity.path,
          name: name,
          children: children,
        ));
      } else if (entity is File) {
        if (!_isSupportedFile(entity.path)) continue;
        nodes.add(FileTreeNode.file(
          path: entity.path,
          name: name,
        ));
      }
    }
    return nodes;
  }

  void _attachDocumentListener() {
    _docChangeListener = (changeLog) {
      if (!mounted) return;
      setState(() {
        _outlineItems = _buildOutline();
        _updateActiveHeading(updateState: false);
      });
    };
    _doc.addListener(_docChangeListener!);
  }

  void _detachDocumentListener() {
    if (_docChangeListener != null) {
      _doc.removeListener(_docChangeListener!);
      _docChangeListener = null;
    }
  }

  void _attachComposerListener() {
    _composerListener = () {
      if (!mounted) return;
      _updateActiveHeading();
    };
    _composer.addListener(_composerListener!);
  }

  void _detachComposerListener() {
    if (_composerListener != null) {
      _composer.removeListener(_composerListener!);
      _composerListener = null;
    }
  }

  List<OutlineEntry> _buildOutline() {
    final items = <OutlineEntry>[];
    for (final node in _doc) {
      final level = _headerLevelForNode(node);
      if (level == null) continue;
      if (node is! ParagraphNode) continue;
      final title = node.text
          .toPlainText()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      items.add(OutlineEntry(
        nodeId: node.id,
        title: title.isEmpty ? 'Untitled Heading' : title,
        level: level,
      ));
    }
    return items;
  }

  int? _headerLevelForNode(DocumentNode node) {
    if (node is! ParagraphNode) return null;
    final blockType = node.getMetadataValue('blockType');
    String? id;
    if (blockType is NamedAttribution) {
      id = blockType.id;
    } else if (blockType != null) {
      id = blockType.toString();
    }
    if (id == null) return null;
    if (!id.startsWith('header')) return null;
    final levelText = id.replaceFirst('header', '');
    final level = int.tryParse(levelText);
    if (level == null || level < 1 || level > 6) return null;
    return level;
  }

  void _updateActiveHeading({bool updateState = true}) {
    final selection = _composer.selection;
    if (selection == null) {
      if (updateState) {
        setState(() {
          _activeHeadingId = null;
        });
      } else {
        _activeHeadingId = null;
      }
      return;
    }

    final nodeIndex = _doc.getNodeIndexById(selection.extent.nodeId);
    if (nodeIndex < 0) return;

    String? headingId;
    for (int i = nodeIndex; i >= 0; i--) {
      final node = _doc.getNodeAt(i);
      if (node == null) continue;
      if (_headerLevelForNode(node) != null) {
        headingId = node.id;
        break;
      }
    }

    if (headingId == _activeHeadingId) return;
    if (updateState) {
      setState(() {
        _activeHeadingId = headingId;
      });
    } else {
      _activeHeadingId = headingId;
    }
  }

  Future<void> _saveFile() async {
    String? path = _currentFilePath;
    path ??= await FilePicker.platform.saveFile(
      dialogTitle: 'Save Markdown',
      fileName: 'untitled.md',
      allowedExtensions: ['md'],
    );

    if (path != null) {
      try {
        final content = serializeDocumentToMarkdown(_doc);
        saveFile(path: path, content: content);
        setState(() {
          _currentFilePath = path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('Failed to save file: $e');
        }
      }
    }
  }

  bool _isSupportedFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.markdown') || lower.endsWith('.txt');
  }

  bool _isIgnoredName(String name) {
    const ignored = {
      '.git',
      '.dart_tool',
      '.idea',
      '.vscode',
      'build',
      'target',
      'node_modules',
    };
    if (ignored.contains(name)) return true;
    return name.startsWith('.');
  }

  String _basename(String path) {
    final separator = Platform.pathSeparator;
    final parts = path.split(separator);
    return parts.isEmpty ? path : parts.last;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF7F7F7) : const Color(0xFF1E1E1E);
    final borderColor = isLight ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A);
    final folderName = _currentFolderPath == null ? 'No Folder' : _basename(_currentFolderPath!);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _openFolder,
                  tooltip: 'Open Folder',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SegmentedButton<SidebarSection>(
              segments: const [
                ButtonSegment(
                  value: SidebarSection.files,
                  icon: Icon(Icons.folder),
                  label: Text('Files'),
                ),
                ButtonSegment(
                  value: SidebarSection.outline,
                  icon: Icon(Icons.view_list),
                  label: Text('Outline'),
                ),
              ],
              selected: {_sidebarSection},
              onSelectionChanged: (selection) {
                setState(() {
                  _sidebarSection = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: _sidebarSection == SidebarSection.files
                ? _buildFileTreePanel(context)
                : _buildOutlinePanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTreePanel(BuildContext context) {
    if (_isLoadingTree) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentFolderPath == null) {
      return Center(
        child: Text(
          'Open a folder to browse files',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: _fileTree.map((node) => _buildTreeNode(node, depth: 0)).toList(),
    );
  }

  Widget _buildOutlinePanel(BuildContext context) {
    if (_outlineItems.isEmpty) {
      return Center(
        child: Text(
          'No headings in this file',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: _outlineItems.map((entry) => _buildOutlineItem(context, entry)).toList(),
    );
  }

  Widget _buildTreeNode(FileTreeNode node, {required int depth}) {
    final indent = depth * 12.0;
    if (node.isDirectory) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>(node.path),
            leading: const Icon(Icons.folder),
            title: Text(
              node.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: node.children
                .map((child) => _buildTreeNode(child, depth: depth + 1))
                .toList(),
          ),
        ),
      );
    }

    final isSelected = node.path == _selectedFilePath;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.description),
        title: Text(
          node.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        onTap: () => _loadFile(node.path),
      ),
    );
  }

  Widget _buildOutlineItem(BuildContext context, OutlineEntry entry) {
    final indent = (entry.level - 1) * 8.0;
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = entry.nodeId == _activeHeadingId;
    final bgColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final textColor = isActive ? colorScheme.primary : colorScheme.onSurface;
    final levelScale = switch (entry.level) {
      1 => 1.15,
      2 => 1.08,
      3 => 1.02,
      4 => 0.98,
      5 => 0.94,
      _ => 0.9,
    };

    return InkWell(
      onTap: () => _jumpToNode(entry.nodeId),
      child: Container(
        padding: EdgeInsets.only(left: 8 + indent, right: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * levelScale,
                      fontWeight: entry.level <= 2 ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToNode(String nodeId) {
    _docEditor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);

    final layoutState = _docLayoutKey.currentState;
    final DocumentLayout? layout = layoutState is DocumentLayout ? layoutState as DocumentLayout : null;
    if (layout == null) {
      return;
    }

    final component = layout.getComponentByNodeId(nodeId);
    if (component == null) {
      return;
    }

    Scrollable.ensureVisible(
      component.context,
      duration: const Duration(milliseconds: 200),
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = _hotkeys.buildShortcuts({
      LumiHotkeyAction.save,
      LumiHotkeyAction.openFile,
      LumiHotkeyAction.openFolder,
    });
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          LumiHotkeyIntent: CallbackAction<LumiHotkeyIntent>(
            onInvoke: (intent) {
              _handleHotkey(intent.action);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_currentFilePath ?? 'Untitled'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bolt),
                  tooltip: 'Test Rust',
                  onPressed: () {
                    final message = greet(name: "LumiWrite User");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _openFolder,
                  tooltip: 'Open Folder',
                ),
                IconButton(
                  icon: const Icon(Icons.file_open),
                  onPressed: _openFile,
                  tooltip: 'Open',
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveFile,
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard),
                  onPressed: _showHotkeySettings,
                  tooltip: 'Hotkeys',
                ),
              ],
            ),
            body: Row(
              children: [
                _buildSidebar(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SuperEditor(
                          key: ValueKey(_editorKeyIndex),
                          editor: _docEditor,
                          documentLayoutKey: _docLayoutKey,
                          stylesheet: lumiWriteStylesheet(context),
                          keyboardActions: _buildKeyboardActions(),
                          componentBuilders: [
                            LumiHeaderComponentBuilder(_docEditor),
                            LumiBlockquoteComponentBuilder(_docEditor),
                            LumiCodeBlockComponentBuilder(_docEditor),
                            LumiListItemComponentBuilder(_docEditor),
                            LumiMarkdownTableComponentBuilder(
                              _docEditor,
                              fit: TableComponentFit.scroll,
                            ),
                            ...defaultComponentBuilders,
                            TaskComponentBuilder(_docEditor),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileTreeNode {
  FileTreeNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.children = const [],
  });

  factory FileTreeNode.directory({
    required String path,
    required String name,
    List<FileTreeNode> children = const [],
  }) {
    return FileTreeNode(
      path: path,
      name: name,
      isDirectory: true,
      children: children,
    );
  }

  factory FileTreeNode.file({
    required String path,
    required String name,
  }) {
    return FileTreeNode(
      path: path,
      name: name,
      isDirectory: false,
    );
  }

  final String path;
  final String name;
  final bool isDirectory;
  final List<FileTreeNode> children;
}

class OutlineEntry {
  OutlineEntry({
    required this.nodeId,
    required this.title,
    required this.level,
  });

  final String nodeId;
  final String title;
  final int level;
}

enum SidebarSection { files, outline }
