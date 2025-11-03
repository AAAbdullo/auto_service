import 'dart:async';
import 'package:flutter/material.dart';

/// Утилита для дебаунсинга функций (задержка выполнения)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Вызвать функцию с задержкой
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Отменить ожидающий вызов
  void cancel() {
    _timer?.cancel();
  }

  /// Уничтожить дебаунсер
  void dispose() {
    _timer?.cancel();
  }
}
