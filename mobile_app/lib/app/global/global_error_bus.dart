import 'dart:async';

import 'package:flutter/material.dart';

enum GlobalMessageSeverity { info, warning, error }

class GlobalUiMessage {
  const GlobalUiMessage({
    required this.text,
    this.severity = GlobalMessageSeverity.info,
  });

  final String text;
  final GlobalMessageSeverity severity;
}

class GlobalErrorBus {
  final StreamController<GlobalUiMessage> _controller = StreamController.broadcast();

  Stream<GlobalUiMessage> get stream => _controller.stream;

  void info(String message) => _emit(GlobalUiMessage(text: message));

  void warning(String message) =>
      _emit(GlobalUiMessage(text: message, severity: GlobalMessageSeverity.warning));

  void error(String message) =>
      _emit(GlobalUiMessage(text: message, severity: GlobalMessageSeverity.error));

  void _emit(GlobalUiMessage message) {
    if (_controller.isClosed) return;
    _controller.add(message);
  }

  Future<void> dispose() => _controller.close();

  Color backgroundColor(GlobalUiMessage message) {
    return switch (message.severity) {
      GlobalMessageSeverity.info => const Color(0xFF0EA5E9),
      GlobalMessageSeverity.warning => const Color(0xFFF59E0B),
      GlobalMessageSeverity.error => const Color(0xFFDC2626),
    };
  }
}
