import 'dart:async';

import 'package:flutter/material.dart';

import 'global_error_bus.dart';

class GlobalUiWrapper extends StatefulWidget {
  const GlobalUiWrapper({
    super.key,
    required this.errorBus,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalErrorBus errorBus;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<GlobalUiWrapper> createState() => _GlobalUiWrapperState();
}

class _GlobalUiWrapperState extends State<GlobalUiWrapper> {
  StreamSubscription<GlobalUiMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.errorBus.stream.listen(_showMessage);
  }

  void _showMessage(GlobalUiMessage message) {
    final messenger = widget.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: widget.errorBus.backgroundColor(message),
          content: Text(message.text),
        ),
      );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
