
import 'package:super_editor/super_editor.dart';

/// A reaction that converts Markdown-style text patterns into structured nodes.
///
/// Supported patterns (triggered by Space):
/// - `# ` to `###### `: Headers
/// - `- `, `* `: Unordered List
/// - `- [ ] `, `- [x] `, `* [ ] `, `* [x] `: Task List
/// - `1. `: Ordered List
/// - `> `: Blockquote
/// - ` ``` `: Code Block
/// - `---`: Horizontal Rule
class MarkdownInputReaction extends EditReaction {
  static final _taskListPattern = RegExp(r'^(?:\*|-|\+)\s+\[([ xX])\]\s$');
  static final _codeFencePattern = RegExp(r'^\s*```\s*([\w+-]*)\s*$');

  @override
  void react(EditContext editorContext, RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    // Copy to avoid concurrent modification when reactions dispatch edits.
    final changes = List<EditEvent>.from(changeList);
    for (final change in changes) {
      if (change is DocumentEdit && change.change is TextInsertionEvent) {
        final event = change.change as TextInsertionEvent;
        // Trigger on Space
        if (event.text.toPlainText() == ' ') {
          _handleSpaceTrigger(editorContext, requestDispatcher);
        } else if (event.text.toPlainText() == '\n') {
          _handleNewlineTrigger(editorContext, requestDispatcher);
        }
      }
    }
  }

  void _handleSpaceTrigger(EditContext context, RequestDispatcher dispatcher) {
    final selection = context.composer.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = context.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    final text = node.text.toPlainText();
    final trimmedText = text.trimRight();
    
    // Check if the paragraph contains ONLY the trigger pattern
    // (e.g. user typed "# " at the start of a new line)
    
    if (_isHeader(text) && node is ParagraphNode) {
      final level = text.trim().length;
      _convertToHeader(context, dispatcher, node, level);
    } else if (_isTaskList(text) && node is ParagraphNode) {
      _convertToTask(context, dispatcher, node, isComplete: _isTaskListChecked(text));
    } else if (_isUnorderedList(text) && node is ParagraphNode) {
      _convertToUnorderedList(context, dispatcher, node);
    } else if (_isOrderedList(text) && node is ParagraphNode) {
      _convertToOrderedList(context, dispatcher, node);
    } else if (_isBlockquote(text) && node is ParagraphNode) {
      _convertToBlockquote(context, dispatcher, node);
    } else if (_isCodeFence(trimmedText)) {
      _convertToCodeBlock(context, dispatcher, node);
    } else if (_isHr(text) && node is ParagraphNode) {
      _convertToHr(context, dispatcher, node);
    }
  }

  void _handleNewlineTrigger(EditContext context, RequestDispatcher dispatcher) {
    final selection = context.composer.selection;
    if (selection == null || !selection.isCollapsed) return;

    final currentNode = context.document.getNodeById(selection.extent.nodeId);
    if (currentNode is! TextNode) return;
    if (currentNode.text.toPlainText().trim().isNotEmpty) return;

    final previousNode = context.document.getNodeBeforeById(currentNode.id);
    if (previousNode is! TextNode) return;

    final fenceText = previousNode.text.toPlainText().trimRight();
    if (!_isCodeFence(fenceText)) return;

    final language = _extractCodeFenceLanguage(fenceText);
    final isListContext = currentNode is ListItemNode || previousNode is ListItemNode;
    final metadata = <String, dynamic>{
      'blockType': codeAttribution,
      if (isListContext) 'listItemCodeBlock': true,
    };
    if (language != null && language.isNotEmpty) {
      metadata['language'] = language;
    }

    final indent = currentNode is ListItemNode ? currentNode.indent : 0;

    dispatcher.execute([
      ReplaceNodeRequest(
        existingNodeId: currentNode.id,
        newNode: ParagraphNode(
          id: currentNode.id,
          text: AttributedText(''),
          indent: indent,
          metadata: metadata,
        ),
      ),
      DeleteNodeRequest(nodeId: previousNode.id),
    ]);
  }

  bool _isHeader(String text) => RegExp(r'^#{1,6} $').hasMatch(text);
  bool _isTaskList(String text) => _taskListPattern.hasMatch(text);
  bool _isTaskListChecked(String text) {
    final match = _taskListPattern.firstMatch(text);
    if (match == null) return false;
    return match.group(1)?.toLowerCase() == 'x';
  }
  bool _isUnorderedList(String text) => RegExp(r'^(\*|-) $').hasMatch(text);
  bool _isOrderedList(String text) => RegExp(r'^1\. $').hasMatch(text);
  bool _isBlockquote(String text) => RegExp(r'^> $').hasMatch(text);
  bool _isCodeBlock(String text) => _isCodeFence(text);
  bool _isHr(String text) => RegExp(r'^--- $').hasMatch(text);
  bool _isCodeFence(String text) => _codeFencePattern.hasMatch(text);
  String? _extractCodeFenceLanguage(String text) {
    final match = _codeFencePattern.firstMatch(text.trimRight());
    if (match == null) return null;
    final language = match.group(1);
    if (language == null || language.trim().isEmpty) return null;
    return language.trim().toLowerCase();
  }

  void _convertToHeader(EditContext context, RequestDispatcher dispatcher, ParagraphNode node, int level) {
    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: ParagraphNode(
          id: node.id,
          text: AttributedText(''),
          metadata: {
            'blockType': NamedAttribution('header$level'),
          },
        ),
      ),
    ]);
  }

  void _convertToUnorderedList(EditContext context, RequestDispatcher dispatcher, ParagraphNode node) {
    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: ListItemNode(
          id: node.id,
          itemType: ListItemType.unordered,
          text: AttributedText(''),
        ),
      ),
    ]);
  }

  void _convertToTask(
    EditContext context,
    RequestDispatcher dispatcher,
    ParagraphNode node, {
    required bool isComplete,
  }) {
    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: TaskNode(
          id: node.id,
          text: AttributedText(''),
          isComplete: isComplete,
        ),
      ),
    ]);
  }

  void _convertToOrderedList(EditContext context, RequestDispatcher dispatcher, ParagraphNode node) {
    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: ListItemNode(
          id: node.id,
          itemType: ListItemType.ordered,
          text: AttributedText(''),
        ),
      ),
    ]);
  }

  void _convertToBlockquote(EditContext context, RequestDispatcher dispatcher, ParagraphNode node) {
    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: ParagraphNode(
          id: node.id,
          text: AttributedText(''),
          metadata: const {
            'blockType': blockquoteAttribution,
          },
        ),
      ),
    ]);
  }

  void _convertToCodeBlock(EditContext context, RequestDispatcher dispatcher, TextNode node) {
    final text = node.text.toPlainText().trimRight();
    final language = _extractCodeFenceLanguage(text);

    final metadata = <String, dynamic>{
      'blockType': codeAttribution,
    };
    if (node is ListItemNode) {
      metadata['listItemCodeBlock'] = true;
    }
    if (language != null && language.isNotEmpty) {
      metadata['language'] = language;
    }
    final indent = node is ParagraphNode
        ? node.indent
        : node is ListItemNode
            ? node.indent
            : 0;

    dispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: ParagraphNode(
          id: node.id,
          text: AttributedText(''),
          indent: indent,
          metadata: metadata,
        ),
      ),
    ]);
  }

  void _convertToHr(EditContext context, RequestDispatcher dispatcher, ParagraphNode node) {
    final newNodeId = Editor.createNodeId();
    dispatcher.execute([
      ReplaceNodeRequest(
        existingNodeId: node.id,
        newNode: HorizontalRuleNode(
          id: node.id,
        ),
      ),
      InsertNodeAfterNodeRequest(
        existingNodeId: node.id,
        newNode: ParagraphNode(
          id: newNodeId,
          text: AttributedText(''),
        ),
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }
}
