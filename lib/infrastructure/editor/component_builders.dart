import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

const _autoLanguageKey = 'auto';
const _codeLanguageOptions = <String>[
  _autoLanguageKey,
  'plaintext',
  'dart',
  'javascript',
  'typescript',
  'json',
  'yaml',
  'markdown',
  'bash',
  'python',
  'rust',
  'go',
  'java',
  'kotlin',
  'swift',
  'c',
  'cpp',
  'cs',
  'sql',
  'html',
  'css',
  'xml',
];

const _codeLanguageLabels = <String, String>{
  _autoLanguageKey: 'Auto',
  'plaintext': 'Plain Text',
  'dart': 'Dart',
  'javascript': 'JavaScript',
  'typescript': 'TypeScript',
  'json': 'JSON',
  'yaml': 'YAML',
  'markdown': 'Markdown',
  'bash': 'Shell',
  'python': 'Python',
  'rust': 'Rust',
  'go': 'Go',
  'java': 'Java',
  'kotlin': 'Kotlin',
  'swift': 'Swift',
  'c': 'C',
  'cpp': 'C++',
  'cs': 'C#',
  'sql': 'SQL',
  'html': 'HTML',
  'css': 'CSS',
  'xml': 'XML',
};

bool _isBlockType(dynamic blockType, NamedAttribution expectedType) {
  if (blockType == null) return false;
  if (blockType is NamedAttribution) return blockType.id == expectedType.id;
  return blockType.toString() == expectedType.id;
}

/// Wraps the standard paragraph builder to add a background decoration
/// for blockquotes.
class LumiBlockquoteComponentBuilder extends ParagraphComponentBuilder {
  final Editor editor;

  const LumiBlockquoteComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode) return null;
    final blockType = node.getMetadataValue('blockType');
    if (!_isBlockType(blockType, blockquoteAttribution)) return null;

    return super.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ParagraphComponentViewModel) return null;
    if (!_isBlockType(componentViewModel.blockType, blockquoteAttribution)) return null;

    final component = super.createComponent(componentContext, componentViewModel);
    if (component == null) return null;

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isLight = colorScheme.brightness == Brightness.light;
        final bgColor = isLight ? const Color(0xFFF0F0F0) : const Color(0xFF2A2A2A);
        final borderColor = isLight ? const Color(0xFFBDBDBD) : const Color(0xFF555555);

        return _buildBackground(
          backgroundColor: bgColor,
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: component,
        );
      },
    );
  }
}

/// Wraps the standard paragraph builder to add a background decoration
/// for code blocks.
class LumiCodeBlockComponentBuilder extends ParagraphComponentBuilder {
  final Editor editor;

  const LumiCodeBlockComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode) return null;
    final blockType = node.getMetadataValue('blockType');
    // Check for 'code' attribution (string or NamedAttribution)
    if (!_isBlockType(blockType, codeAttribution)) return null;

    return super.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ParagraphComponentViewModel) return null;
    if (!_isBlockType(componentViewModel.blockType, codeAttribution)) return null;
    
    final document = editor.context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(componentViewModel.nodeId);
    final currentLanguage = node is ParagraphNode ? node.getMetadataValue('language') as String? : null;
    final normalizedLanguage = _normalizeLanguage(currentLanguage);
    final languageOptions = List<String>.from(_codeLanguageOptions);
    if (normalizedLanguage != _autoLanguageKey && !languageOptions.contains(normalizedLanguage)) {
      languageOptions.insert(1, normalizedLanguage);
    }
    final dropdownValue = languageOptions.contains(normalizedLanguage)
        ? normalizedLanguage
        : _autoLanguageKey;

    final component = super.createComponent(componentContext, componentViewModel);
    if (component == null) return null;

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isLight = colorScheme.brightness == Brightness.light;
        final bgColor = isLight ? const Color(0xFFEEF1F5) : const Color(0xFF1F232A);
        final borderColor = isLight ? const Color(0xFFD2D8E0) : const Color(0xFF3A414C);

        return _buildBackground(
          backgroundColor: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CodeBlockLanguagePicker(
                value: dropdownValue,
                options: languageOptions,
                onChanged: (language) {
                  if (node is! ParagraphNode) return;
                  _updateCodeBlockLanguage(
                    editor: editor,
                    node: node,
                    language: language,
                  );
                },
              ),
              const SizedBox(height: 8),
              component,
            ],
          ),
        );
      },
    );
  }
}

/// Custom list item builder that keeps ordered list numbering
/// continuous across inline code blocks that originated from list items.
class LumiListItemComponentBuilder implements ComponentBuilder {
  final Editor editor;

  const LumiListItemComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ListItemNode) {
      return null;
    }

    int? ordinalValue;
    if (node.type == ListItemType.ordered) {
      ordinalValue = _computeOrderedListOrdinalValue(node, document);
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());
    final textAlignment = textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right;

    return switch (node.type) {
      ListItemType.unordered => UnorderedListItemComponentViewModel(
          nodeId: node.id,
          createdAt: node.metadata[NodeMetadata.createdAt],
          indent: node.indent,
          text: node.text,
          textDirection: textDirection,
          textAlignment: textAlignment,
          textStyleBuilder: noStyleBuilder,
          selectionColor: const Color(0x00000000),
        ),
      ListItemType.ordered => OrderedListItemComponentViewModel(
          nodeId: node.id,
          createdAt: node.metadata[NodeMetadata.createdAt],
          indent: node.indent,
          ordinalValue: ordinalValue,
          text: node.text,
          textDirection: textDirection,
          textAlignment: textAlignment,
          textStyleBuilder: noStyleBuilder,
          selectionColor: const Color(0x00000000),
        ),
    };
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! UnorderedListItemComponentViewModel &&
        componentViewModel is! OrderedListItemComponentViewModel) {
      return null;
    }

    if (componentViewModel is UnorderedListItemComponentViewModel) {
      return UnorderedListItemComponent(
        componentKey: componentContext.componentKey,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        indent: componentViewModel.indent,
        dotStyle: componentViewModel.dotStyle,
        textSelection: componentViewModel.selection,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }

    final orderedViewModel = componentViewModel as OrderedListItemComponentViewModel;
    return OrderedListItemComponent(
      componentKey: componentContext.componentKey,
      indent: orderedViewModel.indent,
      listIndex: orderedViewModel.ordinalValue ?? 1,
      text: orderedViewModel.text,
      textDirection: orderedViewModel.textDirection,
      textAlignment: orderedViewModel.textAlignment,
      styleBuilder: orderedViewModel.textStyleBuilder,
      numeralStyle: orderedViewModel.numeralStyle,
      textSelection: orderedViewModel.selection,
      selectionColor: orderedViewModel.selectionColor,
      highlightWhenEmpty: orderedViewModel.highlightWhenEmpty,
      underlines: orderedViewModel.createUnderlines(),
      inlineWidgetBuilders: orderedViewModel.inlineWidgetBuilders,
    );
  }

  int _computeOrderedListOrdinalValue(ListItemNode listItem, Document document) {
    if (listItem.type != ListItemType.ordered) {
      return 0;
    }

    int ordinalValue = 1;
    DocumentNode? nodeAbove = document.getNodeBeforeById(listItem.id);
    while (nodeAbove != null) {
      if (_isListItemCodeBlock(nodeAbove)) {
        nodeAbove = document.getNodeBeforeById(nodeAbove.id);
        continue;
      }

      if (nodeAbove is! ListItemNode || nodeAbove.indent < listItem.indent) {
        break;
      }

      if (nodeAbove.indent == listItem.indent) {
        if (nodeAbove.type != ListItemType.ordered) {
          break;
        }
        ordinalValue += 1;
      }

      nodeAbove = document.getNodeBeforeById(nodeAbove.id);
    }

    return ordinalValue;
  }
}

bool _isListItemCodeBlock(DocumentNode node) {
  if (node is! ParagraphNode) return false;
  final flag = node.getMetadataValue('listItemCodeBlock');
  return flag == true;
}

/// Explicitly handles headers to ensure they do NOT have any background decoration.
class LumiHeaderComponentBuilder extends ParagraphComponentBuilder {
  final Editor editor;
  const LumiHeaderComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode) return null;
    final blockType = node.getMetadataValue('blockType');
    if (blockType == null) return null;
    
    // Check for header attributions
    if (_isBlockType(blockType, header1Attribution) ||
        _isBlockType(blockType, header2Attribution) ||
        _isBlockType(blockType, header3Attribution) ||
        _isBlockType(blockType, header4Attribution) ||
        _isBlockType(blockType, header5Attribution) ||
        _isBlockType(blockType, header6Attribution)) {
      return super.createViewModel(document, node);
    }
    
    return null;
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ParagraphComponentViewModel) return null;
    final blockType = componentViewModel.blockType;
    if (!_isBlockType(blockType, header1Attribution) &&
        !_isBlockType(blockType, header2Attribution) &&
        !_isBlockType(blockType, header3Attribution) &&
        !_isBlockType(blockType, header4Attribution) &&
        !_isBlockType(blockType, header5Attribution) &&
        !_isBlockType(blockType, header6Attribution)) {
      return null;
    }
    // Just render the text component without any wrapping decoration/background.
    return super.createComponent(componentContext, componentViewModel);
  }
}

Widget _buildBackground({
  required Color backgroundColor,
  required Widget child,
  required EdgeInsets padding,
  Border? border,
  BorderRadius? borderRadius,
}) {
  return Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: border,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
      Padding(
        padding: padding,
        child: child,
      ),
    ],
  );
}

String _normalizeLanguage(String? language) {
  if (language == null) return _autoLanguageKey;
  final trimmed = language.trim().toLowerCase();
  return trimmed.isEmpty ? _autoLanguageKey : trimmed;
}

void _updateCodeBlockLanguage({
  required Editor editor,
  required ParagraphNode node,
  required String? language,
}) {
  final normalized = _normalizeLanguage(language);
  final metadata = Map<String, dynamic>.from(node.metadata);
  if (normalized == _autoLanguageKey) {
    metadata.remove('language');
  } else {
    metadata['language'] = normalized;
  }

  final newNode = ParagraphNode(
    id: node.id,
    text: node.text,
    indent: node.indent,
    metadata: metadata,
  );

  editor.execute([
    ReplaceNodeRequest(
      existingNodeId: node.id,
      newNode: newNode,
    ),
  ]);
}

class _CodeBlockLanguagePicker extends StatelessWidget {
  const _CodeBlockLanguagePicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          iconSize: 18,
          style: textStyle,
          onChanged: (next) {
            if (next == null) return;
            onChanged(next);
          },
          items: options.map((lang) {
            return DropdownMenuItem<String>(
              value: lang,
              child: Text(_codeLanguageLabels[lang] ?? lang),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Editable table builder for Markdown tables.
class LumiMarkdownTableComponentBuilder implements ComponentBuilder {
  LumiMarkdownTableComponentBuilder(
    this.editor, {
    this.columnWidth = const IntrinsicColumnWidth(),
    this.fit = TableComponentFit.scroll,
  }) : _delegate = MarkdownTableComponentBuilder(
          columnWidth: columnWidth,
          fit: fit,
        );

  final Editor editor;
  final TableColumnWidth columnWidth;
  final TableComponentFit fit;
  final MarkdownTableComponentBuilder _delegate;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    return _delegate.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! MarkdownTableViewModel) return null;

    return LumiEditableTableComponent(
      componentKey: componentContext.componentKey,
      viewModel: componentViewModel,
      editor: editor,
    );
  }
}

class LumiEditableTableComponent extends StatefulWidget {
  const LumiEditableTableComponent({
    super.key,
    required this.componentKey,
    required this.viewModel,
    required this.editor,
  });

  final GlobalKey componentKey;
  final MarkdownTableViewModel viewModel;
  final Editor editor;

  @override
  State<LumiEditableTableComponent> createState() => _LumiEditableTableComponentState();
}

class _LumiEditableTableComponentState extends State<LumiEditableTableComponent> {
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _cellIndexById = <String, _TableCellIndex>{};
  final _scrollController = ScrollController();
  int? _activeRow;
  int? _activeColumn;
  String? _pendingFocusCellId;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LumiEditableTableComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    _cellIndexById.clear();
    final activeIds = <String>{};
    for (int rowIndex = 0; rowIndex < widget.viewModel.cells.length; rowIndex++) {
      final row = widget.viewModel.cells[rowIndex];
      for (int colIndex = 0; colIndex < row.length; colIndex++) {
        final cell = row[colIndex];
        activeIds.add(cell.nodeId);
        _cellIndexById[cell.nodeId] = _TableCellIndex(rowIndex, colIndex);
        final controller = _controllers.putIfAbsent(
          cell.nodeId,
          () => TextEditingController(text: cell.text.toPlainText()),
        );
        final focus = _focusNodes.putIfAbsent(cell.nodeId, () {
          final node = FocusNode();
          node.addListener(() {
            if (!mounted || !node.hasFocus) return;
            final index = _cellIndexById[cell.nodeId];
            if (index == null) return;
            if (_activeRow == index.row && _activeColumn == index.column) return;
            setState(() {
              _activeRow = index.row;
              _activeColumn = index.column;
            });
          });
          return node;
        });
        final cellText = cell.text.toPlainText();
        if (!focus.hasFocus && controller.text != cellText) {
          controller.text = cellText;
        }
      }
    }

    final idsToRemove = _controllers.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in idsToRemove) {
      _controllers.remove(id)?.dispose();
      _focusNodes.remove(id)?.dispose();
      _cellIndexById.remove(id);
    }
  }

  void _applyPendingFocus() {
    final cellId = _pendingFocusCellId;
    if (cellId == null) return;
    final focusNode = _focusNodes[cellId];
    if (focusNode == null) return;
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    _pendingFocusCellId = null;
  }

  TableBlockNode? _getTableNode() {
    final document = widget.editor.context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(widget.viewModel.nodeId);
    if (node is TableBlockNode) return node;
    return null;
  }

  void _updateCellValue({
    required int rowIndex,
    required int columnIndex,
    required String value,
  }) {
    final node = _getTableNode();
    if (node == null) return;

    final currentCell = node.getCell(rowIndex: rowIndex, columnIndex: columnIndex);
    if (currentCell.text.toPlainText() == value) return;

    final newCells = <List<TextNode>>[];
    for (int row = 0; row < node.rowCount; row++) {
      final cells = <TextNode>[];
      for (int col = 0; col < node.columnCount; col++) {
        final oldCell = node.getCell(rowIndex: row, columnIndex: col);
        final newText = (row == rowIndex && col == columnIndex)
            ? AttributedText(value)
            : oldCell.text;
        cells.add(TextNode(
          id: oldCell.id,
          text: newText,
          metadata: Map<String, dynamic>.from(oldCell.metadata),
        ));
      }
      newCells.add(cells);
    }

    final newNode = TableBlockNode(
      id: node.id,
      cells: newCells,
      metadata: node.metadata,
    );

    widget.editor.execute([
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: newNode,
      ),
    ]);
  }

  void _replaceTableCells(TableBlockNode node, List<List<TextNode>> newCells, {String? focusCellId}) {
    final newNode = TableBlockNode(
      id: node.id,
      cells: newCells,
      metadata: node.metadata,
    );

    if (focusCellId != null) {
      _pendingFocusCellId = focusCellId;
    }

    widget.editor.execute([
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: newNode,
      ),
    ]);
  }

  Map<String, dynamic> _dataCellMetadata(TableBlockNode node, int columnIndex) {
    if (node.rowCount > 1) {
      return Map<String, dynamic>.from(node.getCell(rowIndex: 1, columnIndex: columnIndex).metadata);
    }
    final headerMeta = Map<String, dynamic>.from(node.getCell(rowIndex: 0, columnIndex: columnIndex).metadata);
    headerMeta.remove(NodeMetadata.blockType);
    return headerMeta;
  }

  void _insertRow({required bool below}) {
    final node = _getTableNode();
    if (node == null) return;

    final columnCount = node.columnCount;
    if (columnCount == 0) return;

    final activeRow = _activeRow ?? node.rowCount - 1;
    final baseRow = activeRow <= 0 ? 1 : activeRow;
    final insertIndex = (below ? baseRow + 1 : baseRow).clamp(1, node.rowCount);

    final newCells = <List<TextNode>>[];
    String? focusId;
    for (int row = 0; row <= node.rowCount; row++) {
      if (row == insertIndex) {
        final newRow = <TextNode>[];
        for (int col = 0; col < columnCount; col++) {
          final meta = _dataCellMetadata(node, col);
          final newCell = TextNode(
            id: Editor.createNodeId(),
            text: AttributedText(''),
            metadata: meta,
          );
          newRow.add(newCell);
          focusId ??= newCell.id;
        }
        newCells.add(newRow);
      }

      if (row < node.rowCount) {
        newCells.add(node.getRow(row).map((cell) {
          return TextNode(
            id: cell.id,
            text: cell.text,
            metadata: Map<String, dynamic>.from(cell.metadata),
          );
        }).toList());
      }
    }

    _replaceTableCells(node, newCells, focusCellId: focusId);
  }

  void _deleteRow() {
    final node = _getTableNode();
    if (node == null) return;
    if (node.rowCount <= 1) return;

    final activeRow = _activeRow;
    if (activeRow == null || activeRow <= 0 || activeRow >= node.rowCount) {
      return;
    }

    final newCells = <List<TextNode>>[];
    for (int row = 0; row < node.rowCount; row++) {
      if (row == activeRow) continue;
      newCells.add(node.getRow(row).map((cell) {
        return TextNode(
          id: cell.id,
          text: cell.text,
          metadata: Map<String, dynamic>.from(cell.metadata),
        );
      }).toList());
    }

    _replaceTableCells(node, newCells);
  }

  void _insertColumn({required bool right}) {
    final node = _getTableNode();
    if (node == null) return;

    final columnCount = node.columnCount;
    final activeColumn = _activeColumn ?? columnCount - 1;
    final baseColumn = activeColumn.clamp(0, columnCount - 1);
    final insertIndex = (right ? baseColumn + 1 : baseColumn).clamp(0, columnCount);

    final newCells = <List<TextNode>>[];
    String? focusId;
    for (int row = 0; row < node.rowCount; row++) {
      final existingRow = node.getRow(row);
      final newRow = <TextNode>[];
      for (int col = 0; col <= columnCount; col++) {
        if (col == insertIndex) {
          final meta = Map<String, dynamic>.from(
            row == 0
                ? existingRow[(insertIndex == columnCount ? columnCount - 1 : insertIndex)].metadata
                : existingRow[(insertIndex == columnCount ? columnCount - 1 : insertIndex)].metadata,
          );
          if (row != 0) {
            meta.remove(NodeMetadata.blockType);
          } else {
            meta[NodeMetadata.blockType] = tableHeaderAttribution;
          }
          final newCell = TextNode(
            id: Editor.createNodeId(),
            text: AttributedText(''),
            metadata: meta,
          );
          newRow.add(newCell);
          focusId ??= newCell.id;
        }
        if (col < columnCount) {
          final cell = existingRow[col];
          newRow.add(TextNode(
            id: cell.id,
            text: cell.text,
            metadata: Map<String, dynamic>.from(cell.metadata),
          ));
        }
      }
      newCells.add(newRow);
    }

    _replaceTableCells(node, newCells, focusCellId: focusId);
  }

  void _deleteColumn() {
    final node = _getTableNode();
    if (node == null) return;
    if (node.columnCount <= 1) return;

    final activeColumn = _activeColumn;
    if (activeColumn == null || activeColumn < 0 || activeColumn >= node.columnCount) {
      return;
    }

    final newCells = <List<TextNode>>[];
    for (int row = 0; row < node.rowCount; row++) {
      final existingRow = node.getRow(row);
      final newRow = <TextNode>[];
      for (int col = 0; col < existingRow.length; col++) {
        if (col == activeColumn) continue;
        final cell = existingRow[col];
        newRow.add(TextNode(
          id: cell.id,
          text: cell.text,
          metadata: Map<String, dynamic>.from(cell.metadata),
        ));
      }
      newCells.add(newRow);
    }

    _replaceTableCells(node, newCells);
  }

  Widget _buildToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canDeleteRow = _activeRow != null && _activeRow! > 0;
    final canDeleteColumn = _activeColumn != null && _activeColumn! >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _insertRow(below: true),
            icon: const Icon(Icons.add),
            label: const Text('插入行'),
          ),
          FilledButton.tonalIcon(
            onPressed: canDeleteRow ? _deleteRow : null,
            icon: const Icon(Icons.remove),
            label: const Text('删除行'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _insertColumn(right: true),
            icon: const Icon(Icons.add),
            label: const Text('插入列'),
          ),
          FilledButton.tonalIcon(
            onPressed: canDeleteColumn ? _deleteColumn : null,
            icon: const Icon(Icons.remove),
            label: const Text('删除列'),
          ),
          if (_activeRow != null && _activeColumn != null)
            Text(
              '当前单元格: ${_activeRow! + 1} × ${_activeColumn! + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(int rowIndex, int columnIndex, MarkdownTableCellViewModel cell) {
    final controller = _controllers.putIfAbsent(
      cell.nodeId,
      () => TextEditingController(text: cell.text.toPlainText()),
    );
    final focusNode = _focusNodes.putIfAbsent(cell.nodeId, FocusNode.new);
    final textStyle = cell.textStyleBuilder({});

    return DecoratedBox(
      decoration: cell.decoration ?? const BoxDecoration(),
      child: Padding(
        padding: cell.padding,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          textAlign: cell.textAlign,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            _updateCellValue(
              rowIndex: rowIndex,
              columnIndex: columnIndex,
              value: value,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Table(
      border: widget.viewModel.border ?? TableBorder.all(),
      defaultColumnWidth: widget.viewModel.columnWidth,
      children: [
        for (int row = 0; row < widget.viewModel.cells.length; row++)
          TableRow(
            children: [
              for (int col = 0; col < widget.viewModel.cells[row].length; col++)
                _buildCell(row, col, widget.viewModel.cells[row][col]),
            ],
          ),
      ],
    );
  }

  Widget _buildTableToScaleDown({required Widget table}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        );
      },
    );
  }

  Widget _buildTableContent(BuildContext context) {
    final table = _buildTable(context);
    return switch (widget.viewModel.fit) {
      TableComponentFit.scroll => Scrollbar(
          controller: _scrollController,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: table,
          ),
        ),
      TableComponentFit.scale => _buildTableToScaleDown(table: table),
    };
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    _applyPendingFocus();
    return BoxComponent(
      key: widget.componentKey,
      isVisuallySelectable: false,
      opacity: widget.viewModel.opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(context),
          _buildTableContent(context),
        ],
      ),
    );
  }
}

class _TableCellIndex {
  const _TableCellIndex(this.row, this.column);

  final int row;
  final int column;
}
