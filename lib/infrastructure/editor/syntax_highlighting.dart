import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:highlight/highlight.dart' as hl;

// Attributions
const syntaxKeywordAttribution = NamedAttribution('syntax-keyword');
const syntaxStringAttribution = NamedAttribution('syntax-string');
const syntaxCommentAttribution = NamedAttribution('syntax-comment');
const syntaxNumberAttribution = NamedAttribution('syntax-number');
const syntaxTypeAttribution = NamedAttribution('syntax-type'); // class, title, type
const syntaxFunctionAttribution = NamedAttribution('syntax-function');
const syntaxBuiltInAttribution = NamedAttribution('syntax-built-in');
const syntaxLiteralAttribution = NamedAttribution('syntax-literal');
const syntaxVariableAttribution = NamedAttribution('syntax-variable');
const syntaxTagAttribution = NamedAttribution('syntax-tag');
const syntaxAttrAttribution = NamedAttribution('syntax-attr');
const syntaxMetaAttribution = NamedAttribution('syntax-meta');
const syntaxRegexpAttribution = NamedAttribution('syntax-regexp');
const syntaxSymbolAttribution = NamedAttribution('syntax-symbol');
const syntaxSectionAttribution = NamedAttribution('syntax-section');
const syntaxAdditionAttribution = NamedAttribution('syntax-addition');
const syntaxDeletionAttribution = NamedAttribution('syntax-deletion');

/// Highlights all code blocks in the document.
/// Call this after loading a document to apply initial syntax highlighting.
void highlightAllCodeBlocks(Editor editor, Document doc) {
  final codeBlockNodeIds = <String>[];
  
  for (int i = 0; i < doc.nodeCount; i++) {
    final node = doc.getNodeAt(i);
    if (node is ParagraphNode) {
      final blockType = node.getMetadataValue('blockType');
      bool isCodeBlock = false;
      if (blockType is NamedAttribution && blockType.id == 'code') isCodeBlock = true;
      if (blockType == codeAttribution) isCodeBlock = true;
      
      if (isCodeBlock) {
        codeBlockNodeIds.add(node.id);
      }
    }
  }
  
  if (codeBlockNodeIds.isEmpty) return;
  
  // Use a post-frame callback to ensure the editor is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final nodeId in codeBlockNodeIds) {
      final node = doc.getNodeById(nodeId);
      if (node is ParagraphNode) {
        _applySyntaxHighlighting(editor, node);
      }
    }
  });
}

void _applySyntaxHighlighting(Editor editor, ParagraphNode node) {
  String? language = node.getMetadataValue('language') as String?;
  final text = node.text.toPlainText();
  
  if (text.isEmpty) return;
  
  hl.Result result;
  try {
    if (language != null && language.isNotEmpty) {
      result = hl.highlight.parse(text, language: language);
    } else {
      // Auto-detect language
      result = hl.highlight.parse(text, autoDetection: true);
    }
  } catch (e) {
    return;
  }

  final allSyntaxAttributions = {
      syntaxKeywordAttribution,
      syntaxStringAttribution,
      syntaxCommentAttribution,
      syntaxNumberAttribution,
      syntaxTypeAttribution,
      syntaxFunctionAttribution,
      syntaxBuiltInAttribution,
      syntaxLiteralAttribution,
      syntaxVariableAttribution,
  };

  // Remove all existing syntax attributions
  editor.execute([
    RemoveTextAttributionsRequest(
      documentRange: DocumentSelection(
        base: DocumentPosition(
          nodeId: node.id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
        extent: DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: text.length),
        ),
      ),
      attributions: allSyntaxAttributions,
    )
  ]);

  // Add new attributions based on highlight result
  _traverseNodesStatic(result.nodes, (start, end, className) {
     NamedAttribution? attr = _mapClassNameToAttributionStatic(className);
     if (attr != null && end > start) {
        editor.execute([
          AddTextAttributionsRequest(
            documentRange: DocumentSelection(
              base: DocumentPosition(
                nodeId: node.id,
                nodePosition: TextNodePosition(offset: start),
              ),
              extent: DocumentPosition(
                nodeId: node.id,
                nodePosition: TextNodePosition(offset: end),
              ),
            ),
            attributions: {attr},
          )
        ]);
     }
  }, 0);
}

int _traverseNodesStatic(List<hl.Node>? nodes, void Function(int start, int end, String? className) onSpan, int currentOffset) {
  if (nodes == null) return currentOffset;

  for (final node in nodes) {
    if (node.children != null) {
      int start = currentOffset;
      int end = _traverseNodesStatic(node.children, onSpan, currentOffset);
      
      if (node.className != null) {
         onSpan(start, end, node.className);
      }
      currentOffset = end;
    } else if (node.value != null) {
       int length = node.value!.length;
       if (node.className != null) {
          onSpan(currentOffset, currentOffset + length, node.className);
       }
       currentOffset += length;
    }
  }
  return currentOffset;
}

NamedAttribution? _mapClassNameToAttributionStatic(String? className) {
  if (className == null) return null;
  switch (className) {
    case 'keyword': return syntaxKeywordAttribution;
    case 'string': return syntaxStringAttribution;
    case 'comment': return syntaxCommentAttribution;
    case 'number': return syntaxNumberAttribution;
    case 'type': 
    case 'class':
    case 'title':
      return syntaxTypeAttribution;
    case 'function': return syntaxFunctionAttribution;
    case 'built_in': return syntaxBuiltInAttribution;
    case 'literal': return syntaxLiteralAttribution;
    case 'variable': return syntaxVariableAttribution;
    case 'tag': 
    case 'name':
      return syntaxTagAttribution;
    case 'attr': return syntaxAttrAttribution;
    case 'meta': return syntaxMetaAttribution;
    case 'regexp': return syntaxRegexpAttribution;
    case 'symbol': return syntaxSymbolAttribution;
    case 'section': return syntaxSectionAttribution;
    case 'addition': return syntaxAdditionAttribution;
    case 'deletion': return syntaxDeletionAttribution;
    default: return null;
  }
}

// Reaction
class SyntaxHighlightingReaction extends EditReaction {
  @override
  void react(EditContext editorContext, RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    final modifiedCodeBlockIds = <String>{};
    
    for (final change in changeList) {
      if (change is DocumentEdit) {
        final event = change.change;
        if (event is TextInsertionEvent) {
          modifiedCodeBlockIds.add(event.nodeId);
        } else if (event is TextDeletedEvent) {
          modifiedCodeBlockIds.add(event.nodeId);
        } else if (event is NodeChangeEvent) {
          modifiedCodeBlockIds.add(event.nodeId);
        } else if (event is NodeInsertedEvent) {
          modifiedCodeBlockIds.add(event.nodeId);
        }
      }
    }

    for (final nodeId in modifiedCodeBlockIds) {
      final node = editorContext.document.getNodeById(nodeId);
      if (node is ParagraphNode) {
        final blockType = node.getMetadataValue('blockType');
        bool isCodeBlock = false;
        if (blockType is NamedAttribution && blockType.id == 'code') isCodeBlock = true;
        if (blockType == codeAttribution) isCodeBlock = true;
        
        if (isCodeBlock) {
          _highlightNode(editorContext, requestDispatcher, node);
        }
      }
    }
  }

  void _highlightNode(EditContext context, RequestDispatcher dispatcher, ParagraphNode node) {
    final language = node.getMetadataValue('language') as String?;

    final text = node.text.toPlainText();
    hl.Result result;
    try {
      if (language != null && language.isNotEmpty) {
        result = hl.highlight.parse(text, language: language);
      } else {
        result = hl.highlight.parse(text, autoDetection: true);
      }
    } catch (e) {
      return;
    }

    final allSyntaxAttributions = {
        syntaxKeywordAttribution,
        syntaxStringAttribution,
        syntaxCommentAttribution,
        syntaxNumberAttribution,
        syntaxTypeAttribution,
        syntaxFunctionAttribution,
        syntaxBuiltInAttribution,
        syntaxLiteralAttribution,
        syntaxVariableAttribution,
    };

    // Remove all existing syntax attributions
    if (text.isNotEmpty) {
      dispatcher.execute([
        RemoveTextAttributionsRequest(
          documentRange: DocumentSelection(
            base: DocumentPosition(
              nodeId: node.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            extent: DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: text.length),
            ),
          ),
          attributions: allSyntaxAttributions,
        )
      ]);
    }

    // Add new attributions based on highlight result
    _traverseNodes(result.nodes, (start, end, className) {
       NamedAttribution? attr = _mapClassNameToAttribution(className);
       if (attr != null && end > start) {
          dispatcher.execute([
            AddTextAttributionsRequest(
              documentRange: DocumentSelection(
                base: DocumentPosition(
                  nodeId: node.id,
                  nodePosition: TextNodePosition(offset: start),
                ),
                extent: DocumentPosition(
                  nodeId: node.id,
                  nodePosition: TextNodePosition(offset: end),
                ),
              ),
              attributions: {attr},
            )
          ]);
       }
    }, 0);
  }

  int _traverseNodes(List<hl.Node>? nodes, void Function(int start, int end, String? className) onSpan, int currentOffset) {
    if (nodes == null) return currentOffset;

    for (final node in nodes) {
      if (node.children != null) {
        int start = currentOffset;
        int end = _traverseNodes(node.children, onSpan, currentOffset);
        
        if (node.className != null) {
           onSpan(start, end, node.className);
        }
        currentOffset = end;
      } else if (node.value != null) {
         int length = node.value!.length;
         if (node.className != null) {
            onSpan(currentOffset, currentOffset + length, node.className);
         }
         currentOffset += length;
      }
    }
    return currentOffset;
  }

  NamedAttribution? _mapClassNameToAttribution(String? className) {
    if (className == null) return null;
    switch (className) {
      case 'keyword': return syntaxKeywordAttribution;
      case 'string': return syntaxStringAttribution;
      case 'comment': return syntaxCommentAttribution;
      case 'number': return syntaxNumberAttribution;
      case 'type': 
      case 'class':
      case 'title':
        return syntaxTypeAttribution;
      case 'function': return syntaxFunctionAttribution;
      case 'built_in': return syntaxBuiltInAttribution;
      case 'literal': return syntaxLiteralAttribution;
      case 'variable': return syntaxVariableAttribution;
      case 'tag': 
      case 'name': // XML tag name
        return syntaxTagAttribution;
      case 'attr': return syntaxAttrAttribution;
      case 'meta': return syntaxMetaAttribution;
      case 'regexp': return syntaxRegexpAttribution;
      case 'symbol': return syntaxSymbolAttribution;
      case 'section': return syntaxSectionAttribution;
      case 'addition': return syntaxAdditionAttribution;
      case 'deletion': return syntaxDeletionAttribution;
      default: return null;
    }
  }
}
