import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum LumiHotkeyAction {
  undo,
  redo,
  save,
  openFile,
  openFolder,
}

class LumiHotkeyIntent extends Intent {
  const LumiHotkeyIntent(this.action);

  final LumiHotkeyAction action;
}

class HotkeyBinding {
  HotkeyBinding({
    required this.key,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final LogicalKeyboardKey key;
  final bool control;
  final bool shift;
  final bool alt;
  final bool meta;

  SingleActivator toActivator() {
    return SingleActivator(
      key,
      control: control,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  String format() {
    final parts = <String>[];
    if (control) parts.add('Ctrl');
    if (meta) parts.add('Cmd');
    if (alt) parts.add('Alt');
    if (shift) parts.add('Shift');
    parts.add(_keyToLabel(key));
    return parts.join('+');
  }

  static HotkeyBinding? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final tokens = value.split('+').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    bool control = false;
    bool shift = false;
    bool alt = false;
    bool meta = false;
    LogicalKeyboardKey? key;

    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (lower == 'ctrl' || lower == 'control') {
        control = true;
        continue;
      }
      if (lower == 'cmd' || lower == 'command' || lower == 'meta') {
        meta = true;
        continue;
      }
      if (lower == 'alt' || lower == 'option') {
        alt = true;
        continue;
      }
      if (lower == 'shift') {
        shift = true;
        continue;
      }

      final parsedKey = _parseKeyToken(token);
      if (parsedKey == null) {
        return null;
      }
      if (key != null) {
        return null;
      }
      key = parsedKey;
    }

    if (key == null) return null;

    return HotkeyBinding(
      key: key,
      control: control,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }
}

class HotkeyConfig extends ChangeNotifier {
  HotkeyConfig({String? path}) : _path = path ?? File('hotkeys.json').absolute.path {
    _bindings = Map<LumiHotkeyAction, HotkeyBinding>.from(_defaultBindings);
  }

  final String _path;
  late Map<LumiHotkeyAction, HotkeyBinding> _bindings;

  Map<LumiHotkeyAction, HotkeyBinding> get bindings => Map.unmodifiable(_bindings);
  String get configPath => _path;
  HotkeyBinding? bindingFor(LumiHotkeyAction action) => _bindings[action];

  String labelFor(LumiHotkeyAction action) => _actionLabels[action] ?? action.name;
  String idFor(LumiHotkeyAction action) => _actionIds[action] ?? action.name;

  String displayFor(LumiHotkeyAction action) => _bindings[action]?.format() ?? '';

  Map<ShortcutActivator, Intent> buildShortcuts([Set<LumiHotkeyAction>? actions]) {
    final shortcuts = <ShortcutActivator, Intent>{};
    for (final entry in _bindings.entries) {
      if (actions != null && !actions.contains(entry.key)) {
        continue;
      }
      shortcuts[entry.value.toActivator()] = LumiHotkeyIntent(entry.key);
    }
    return shortcuts;
  }

  Future<void> load() async {
    final file = File(_path);
    if (!await file.exists()) return;

    try {
      final jsonText = await file.readAsString();
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return;

      _bindings = Map<LumiHotkeyAction, HotkeyBinding>.from(_defaultBindings);
      for (final entry in decoded.entries) {
        final action = _actionFromId(entry.key);
        if (action == null) continue;
        if (entry.value is! String) continue;
        final raw = (entry.value as String).trim();
        if (raw.isEmpty) {
          _bindings.remove(action);
          continue;
        }
        final binding = HotkeyBinding.parse(raw);
        if (binding != null) {
          _bindings[action] = binding;
        }
      }

      notifyListeners();
    } catch (_) {
      // Ignore invalid config.
    }
  }

  Future<void> save() async {
    final data = <String, String>{};
    for (final action in LumiHotkeyAction.values) {
      final binding = _bindings[action];
      data[idFor(action)] = binding?.format() ?? '';
    }
    final file = File(_path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  void replaceAll(Map<LumiHotkeyAction, HotkeyBinding?> updated) {
    final next = <LumiHotkeyAction, HotkeyBinding>{};
    for (final action in LumiHotkeyAction.values) {
      final binding = updated[action];
      if (binding != null) {
        next[action] = binding;
      }
    }
    _bindings = next;
    notifyListeners();
  }
}

const Map<LumiHotkeyAction, String> _actionLabels = {
  LumiHotkeyAction.undo: 'Undo',
  LumiHotkeyAction.redo: 'Redo',
  LumiHotkeyAction.save: 'Save File',
  LumiHotkeyAction.openFile: 'Open File',
  LumiHotkeyAction.openFolder: 'Open Folder',
};

const Map<LumiHotkeyAction, String> _actionIds = {
  LumiHotkeyAction.undo: 'undo',
  LumiHotkeyAction.redo: 'redo',
  LumiHotkeyAction.save: 'save',
  LumiHotkeyAction.openFile: 'openFile',
  LumiHotkeyAction.openFolder: 'openFolder',
};

final Map<LumiHotkeyAction, HotkeyBinding> _defaultBindings = {
  LumiHotkeyAction.undo: HotkeyBinding(
    key: LogicalKeyboardKey.keyZ,
    control: true,
  ),
  LumiHotkeyAction.redo: HotkeyBinding(
    key: LogicalKeyboardKey.keyY,
    control: true,
  ),
  LumiHotkeyAction.save: HotkeyBinding(
    key: LogicalKeyboardKey.keyS,
    control: true,
  ),
  LumiHotkeyAction.openFile: HotkeyBinding(
    key: LogicalKeyboardKey.keyO,
    control: true,
  ),
  LumiHotkeyAction.openFolder: HotkeyBinding(
    key: LogicalKeyboardKey.keyO,
    control: true,
    shift: true,
  ),
};

LumiHotkeyAction? _actionFromId(String id) {
  for (final entry in _actionIds.entries) {
    if (entry.value == id) return entry.key;
  }
  return null;
}

LogicalKeyboardKey? _parseKeyToken(String token) {
  final normalized = token.trim();
  if (normalized.isEmpty) return null;

  final lower = normalized.toLowerCase();
  if (lower.length == 1) {
    final char = lower.codeUnitAt(0);
    if (char >= 97 && char <= 122) {
      final index = char - 97;
      return LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + index);
    }
    if (char >= 48 && char <= 57) {
      final index = char - 48;
      return LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + index);
    }
  }

  if (_namedKeys.containsKey(lower)) {
    return _namedKeys[lower];
  }

  if (lower.startsWith('f')) {
    final number = int.tryParse(lower.substring(1));
    if (number != null && number >= 1 && number <= 12) {
      return LogicalKeyboardKey(LogicalKeyboardKey.f1.keyId + (number - 1));
    }
  }

  return null;
}

String _keyToLabel(LogicalKeyboardKey key) {
  for (final entry in _namedKeys.entries) {
    if (entry.value == key) {
      return entry.key.toUpperCase();
    }
  }

  final label = key.keyLabel;
  if (label.isNotEmpty) {
    if (label.length == 1) return label.toUpperCase();
    return label;
  }

  if (key == LogicalKeyboardKey.backquote) return '`';
  if (key == LogicalKeyboardKey.bracketLeft) return '[';
  if (key == LogicalKeyboardKey.bracketRight) return ']';

  return key.debugName ?? key.keyId.toString();
}

const Map<String, LogicalKeyboardKey> _namedKeys = {
  'enter': LogicalKeyboardKey.enter,
  'tab': LogicalKeyboardKey.tab,
  'space': LogicalKeyboardKey.space,
  'esc': LogicalKeyboardKey.escape,
  'escape': LogicalKeyboardKey.escape,
  'backspace': LogicalKeyboardKey.backspace,
  'delete': LogicalKeyboardKey.delete,
  'home': LogicalKeyboardKey.home,
  'end': LogicalKeyboardKey.end,
  'pageup': LogicalKeyboardKey.pageUp,
  'pagedown': LogicalKeyboardKey.pageDown,
  'insert': LogicalKeyboardKey.insert,
  'up': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
  'comma': LogicalKeyboardKey.comma,
  'period': LogicalKeyboardKey.period,
  'dot': LogicalKeyboardKey.period,
  'minus': LogicalKeyboardKey.minus,
  'dash': LogicalKeyboardKey.minus,
  'equal': LogicalKeyboardKey.equal,
  'slash': LogicalKeyboardKey.slash,
  'backslash': LogicalKeyboardKey.backslash,
  'semicolon': LogicalKeyboardKey.semicolon,
  'quote': LogicalKeyboardKey.quote,
  'backquote': LogicalKeyboardKey.backquote,
  'bracketleft': LogicalKeyboardKey.bracketLeft,
  'bracketright': LogicalKeyboardKey.bracketRight,
};
