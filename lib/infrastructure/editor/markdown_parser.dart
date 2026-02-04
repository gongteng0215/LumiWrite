import 'dart:convert';

import 'package:super_editor/super_editor.dart';

/// Custom markdown parser that preserves code block language metadata.
///
/// This parser wraps the standard deserializeMarkdownToDocument but
/// post-processes code blocks to extract and store language information.
MutableDocument parseMarkdownWithLanguage(String markdown) {
  // First, use the standard parser
  final doc = deserializeMarkdownToDocument(markdown);
  
  // Then extract language info from the original markdown and apply to nodes
  _applyListItemCodeBlocks(doc, markdown);
  _applyCodeBlockLanguages(doc, markdown);
  
  return doc;
}

/// Extracts language identifiers from fenced code blocks in the original markdown
/// and applies them to the corresponding code block nodes in the document.
void _applyCodeBlockLanguages(MutableDocument doc, String markdown) {
  // Extract all code block languages from the markdown
  final languages = _extractCodeBlockLanguages(markdown);
  
  if (languages.isEmpty) return;
  
  // Find all code block nodes and apply languages in order
  int langIndex = 0;
  for (int i = 0; i < doc.nodeCount; i++) {
    final node = doc.getNodeAt(i);
    if (node is ParagraphNode) {
      final blockType = node.getMetadataValue('blockType');
      bool isCodeBlock = false;
      if (blockType is NamedAttribution && blockType.id == 'code') isCodeBlock = true;
      if (blockType == codeAttribution) isCodeBlock = true;
      
      if (isCodeBlock && langIndex < languages.length) {
        final lang = languages[langIndex];
        if (lang != null && lang.isNotEmpty) {
          // We need to replace the node to add metadata since ParagraphNode
          // metadata might be immutable after creation
          final newNode = ParagraphNode(
            id: node.id,
            text: node.text,
            metadata: {
              ...node.metadata,
              'language': lang,
            },
          );
          doc.replaceNodeById(node.id, newNode);
        }
        langIndex++;
      }
    }
  }
}

/// Parses the markdown to extract language identifiers from fenced code blocks.
/// Returns a list of languages in order of appearance (null for blocks without language).
List<String?> _extractCodeBlockLanguages(String markdown) {
  final languages = <String?>[];
  
  // Match fenced code blocks: ```language or ``` (no language)
  // Only capture opening fences to avoid double counting.
  final fencePattern = RegExp(r'^\\s*```\\s*([\\w+-]*)\\s*$');
  bool inFence = false;

  for (final line in const LineSplitter().convert(markdown)) {
    final match = fencePattern.firstMatch(line);
    if (match == null) continue;

    if (!inFence) {
      final lang = match.group(1);
      if (lang != null && lang.isNotEmpty) {
        languages.add(lang.toLowerCase());
      } else {
        languages.add(null);
      }
      inFence = true;
    } else {
      inFence = false;
    }
  }
  
  return languages;
}

class _ListItemCodeBlock {
  _ListItemCodeBlock({
    required this.lines,
    this.language,
  });

  final List<String> lines;
  final String? language;

  String get text => lines.join('\n');
}

void _applyListItemCodeBlocks(MutableDocument doc, String markdown) {
  final codeBlocks = _extractListItemCodeBlocks(markdown);
  if (codeBlocks.isEmpty) return;

  int searchStartIndex = 0;
  for (final codeBlock in codeBlocks) {
    if (codeBlock.lines.isEmpty) continue;

    final matchIndex = _findListItemRun(doc, searchStartIndex, codeBlock.lines);
    if (matchIndex == null) continue;

    final firstNode = doc.getNodeAt(matchIndex);
    if (firstNode is! ListItemNode) {
      searchStartIndex = matchIndex + 1;
      continue;
    }

    final metadata = <String, dynamic>{
      ...firstNode.metadata,
      'blockType': codeAttribution,
      'listItemCodeBlock': true,
    };
    if (codeBlock.language != null && codeBlock.language!.isNotEmpty) {
      metadata['language'] = codeBlock.language!;
    }

    final newNode = ParagraphNode(
      id: firstNode.id,
      text: AttributedText(codeBlock.text),
      indent: firstNode.indent,
      metadata: metadata,
    );
    doc.replaceNodeById(firstNode.id, newNode);

    final idsToDelete = <String>[];
    for (int offset = 1; offset < codeBlock.lines.length; offset++) {
      final nextNode = doc.getNodeAt(matchIndex + 1);
      if (nextNode is! ListItemNode) {
        break;
      }
      idsToDelete.add(nextNode.id);
    }

    for (final nodeId in idsToDelete) {
      doc.deleteNode(nodeId);
    }

    searchStartIndex = matchIndex + 1;
  }
}

List<_ListItemCodeBlock> _extractListItemCodeBlocks(String markdown) {
  final lines = const LineSplitter().convert(markdown);
  final codeBlocks = <_ListItemCodeBlock>[];
  final listItemPattern = RegExp(r'^\\s*(?:\\d+\\.|[*+-])\\s+(?:\\[[ xX]\\]\\s+)?');
  final fencePattern = RegExp(r'^(\s*)```\\s*([\\w+-]*)\\s*$');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fenceMatch = fencePattern.firstMatch(line);
    if (fenceMatch == null) continue;

    final indent = fenceMatch.group(1) ?? '';
    if (indent.isEmpty) {
      continue;
    }

    int prev = i - 1;
    while (prev >= 0 && lines[prev].trim().isEmpty) {
      prev--;
    }
    if (prev < 0 || !listItemPattern.hasMatch(lines[prev])) {
      continue;
    }

    final language = fenceMatch.group(2)?.trim();
    final codeLines = <String>[];

    i++;
    while (i < lines.length) {
      final current = lines[i];
      final closeMatch = fencePattern.firstMatch(current);
      if (closeMatch != null && (closeMatch.group(1) ?? '') == indent) {
        break;
      }

      var stripped = current;
      if (indent.isNotEmpty && stripped.startsWith(indent)) {
        stripped = stripped.substring(indent.length);
      }
      codeLines.add(stripped);
      i++;
    }

    final cleanedLines = codeLines.map((line) => line.trimRight()).toList();
    while (cleanedLines.isNotEmpty && cleanedLines.last.isEmpty) {
      cleanedLines.removeLast();
    }
    codeBlocks.add(_ListItemCodeBlock(
      lines: cleanedLines,
      language: language != null && language.isNotEmpty ? language.toLowerCase() : null,
    ));
  }

  return codeBlocks;
}

int? _findListItemRun(MutableDocument doc, int startIndex, List<String> lines) {
  if (lines.isEmpty) return null;

  final maxStart = doc.nodeCount - lines.length;
  for (int i = startIndex; i <= maxStart; i++) {
    final firstNode = doc.getNodeAt(i);
    if (firstNode is! ListItemNode) continue;
    if (!_linesMatch(firstNode.text.toPlainText(), lines[0])) continue;

    bool matches = true;
    for (int offset = 1; offset < lines.length; offset++) {
      final node = doc.getNodeAt(i + offset);
      if (node is! ListItemNode) {
        matches = false;
        break;
      }
      if (!_linesMatch(node.text.toPlainText(), lines[offset])) {
        matches = false;
        break;
      }
    }

    if (matches) return i;
  }

  return null;
}

bool _linesMatch(String nodeText, String line) {
  if (nodeText.trimRight() == line.trimRight()) return true;
  return nodeText.trim() == line.trim();
}
