
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_editor/super_editor.dart';
import 'syntax_highlighting.dart';

TextStyle lumiWriteInlineTextStyler(Set<Attribution> attributions, TextStyle existing) {
  TextStyle style = existing;

  for (final attribution in attributions) {
    if (attribution == syntaxKeywordAttribution) {
      style = style.copyWith(
        color: const Color(0xFFD73A49),
        fontWeight: FontWeight.bold,
      );
    } else if (attribution == syntaxStringAttribution) {
      style = style.copyWith(color: const Color(0xFF22863A));
    } else if (attribution == syntaxCommentAttribution) {
      style = style.copyWith(
        color: const Color(0xFF6A737D),
        fontStyle: FontStyle.italic,
      );
    } else if (attribution == syntaxNumberAttribution) {
      style = style.copyWith(color: const Color(0xFF005CC5));
    } else if (attribution == syntaxTypeAttribution) {
      style = style.copyWith(color: const Color(0xFF6F42C1));
    } else if (attribution == syntaxFunctionAttribution) {
      style = style.copyWith(color: const Color(0xFF005CC5));
    } else if (attribution == syntaxBuiltInAttribution) {
      style = style.copyWith(color: const Color(0xFFE36209));
    } else if (attribution == syntaxLiteralAttribution) {
      style = style.copyWith(color: const Color(0xFF005CC5));
    } else if (attribution == syntaxVariableAttribution) {
      style = style.copyWith(color: const Color(0xFF24292E));
    } else if (attribution == syntaxTagAttribution) {
      style = style.copyWith(color: const Color(0xFF22863A));
    } else if (attribution == syntaxAttrAttribution) {
      style = style.copyWith(color: const Color(0xFF6F42C1));
    } else if (attribution == syntaxMetaAttribution) {
      style = style.copyWith(color: const Color(0xFF005CC5));
    } else if (attribution == syntaxRegexpAttribution) {
      style = style.copyWith(color: const Color(0xFF032F62));
    } else if (attribution == syntaxSymbolAttribution) {
      style = style.copyWith(color: const Color(0xFFE36209));
    } else if (attribution == syntaxSectionAttribution) {
      style = style.copyWith(color: const Color(0xFF005CC5), fontWeight: FontWeight.bold);
    } else if (attribution == syntaxAdditionAttribution) {
      style = style.copyWith(backgroundColor: const Color(0xFFE6FFED));
    } else if (attribution == syntaxDeletionAttribution) {
      style = style.copyWith(backgroundColor: const Color(0xFFFFEEF0));
    }
  }

  return defaultInlineTextStyler(attributions, style);
}

/// Creates the custom stylesheet for LumiWrite
Stylesheet lumiWriteStylesheet(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  final isLight = brightness == Brightness.light;

  final baseTextColor = isLight ? const Color(0xFF1E1E1E) : const Color(0xFFE1E1E1);
  final mutedTextColor = isLight ? const Color(0xFF757575) : const Color(0xFF9E9E9E);

  return Stylesheet(
    documentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    inlineTextStyler: lumiWriteInlineTextStyler,
    rules: [

      // Headers
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header1')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: baseTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 24, bottom: 12),
          };
        },
      ),
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header2')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: baseTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 20, bottom: 10),
          };
        },
      ),
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header3')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: baseTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 16, bottom: 8),
          };
        },
      ),
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header4')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: baseTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 12, bottom: 8),
          };
        },
      ),
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header5')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: baseTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 10, bottom: 8),
          };
        },
      ),
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'header6')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: mutedTextColor,
              height: 1.4,
              backgroundColor: Colors.transparent,
            ),
            'padding': const CascadingPadding.only(top: 10, bottom: 8),
          };
        },
      ),

      // Blockquote
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'blockquote')) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: mutedTextColor,
              height: 1.6,
            ),
            'padding': const CascadingPadding.all(0),
          };
        },
      ),

      // Code Block
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (!_isBlockType(node, 'code')) return {};
          return {
            'textStyle': GoogleFonts.firaCode(
              fontSize: 14,
              color: baseTextColor,
              height: 1.6,
            ),
            'padding': const CascadingPadding.all(0),
          };
        },
      ),

      // Tables
      StyleRule(
        BlockSelector(tableBlockAttribution.name),
        (Document doc, DocumentNode node) {
          if (node is! TableBlockNode) return {};

          final borderColor = isLight ? const Color(0xFFE0E0E0) : const Color(0xFF3A3A3A);
          final headerBg = isLight ? const Color(0xFFF2F2F2) : const Color(0xFF2A2A2A);
          final stripeBg = isLight ? const Color(0xFFFAFAFA) : const Color(0xFF242424);

          return {
            Styles.padding: const CascadingPadding.only(top: 12, bottom: 12),
            Styles.textStyle: GoogleFonts.merriweather(
              fontSize: 15,
              color: baseTextColor,
              height: 1.5,
            ),
            TableStyles.headerTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: baseTextColor,
            ),
            TableStyles.cellPadding: const CascadingPadding.all(8),
            TableStyles.border: TableBorder.all(color: borderColor, width: 1),
            TableStyles.cellDecorator: ({
              required int rowIndex,
              required int columnIndex,
              required AttributedText cellText,
              required Map<String, dynamic> cellMetadata,
            }) {
              if (rowIndex == 0) {
                return BoxDecoration(color: headerBg);
              }
              if (rowIndex.isEven) {
                return BoxDecoration(color: stripeBg);
              }
              return const BoxDecoration();
            },
          };
        },
      ),

      // List Items (Unordered & Ordered)
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (node is! ListItemNode) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 16,
              color: baseTextColor,
              height: 1.6,
            ),
            'padding': const CascadingPadding.only(top: 4, bottom: 4),
          };
        },
      ),

      // Tasks
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (node is! TaskNode) return {};
          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 16,
              color: baseTextColor,
              height: 1.6,
              decoration: node.isComplete ? TextDecoration.lineThrough : TextDecoration.none,
            ),
            'padding': const CascadingPadding.only(top: 4, bottom: 4),
          };
        },
      ),

      // Default Paragraph (Catch-all for ParagraphNode without special blockType)
      StyleRule(
        BlockSelector.all,
        (Document doc, DocumentNode node) {
          if (node is! ParagraphNode) return {};
          
          // Don't override headers, blockquotes, or code blocks
          if (_isBlockType(node, 'header1') ||
              _isBlockType(node, 'header2') ||
              _isBlockType(node, 'header3') ||
              _isBlockType(node, 'header4') ||
              _isBlockType(node, 'header5') ||
              _isBlockType(node, 'header6') ||
              _isBlockType(node, 'blockquote') ||
              _isBlockType(node, 'code')) {
            return {};
          }

          return {
            'textStyle': GoogleFonts.merriweather(
              fontSize: 16,
              color: baseTextColor,
              height: 1.6,
            ),
            'padding': const CascadingPadding.only(top: 8, bottom: 8),
          };
        },
      ),
    ],
  );
}

bool _isBlockType(DocumentNode node, String type) {
  if (node is! ParagraphNode) return false;
  final blockType = node.getMetadataValue('blockType');
  if (blockType == null) return false;
  if (blockType is NamedAttribution) return blockType.id == type;
  return blockType.toString() == type;
}
