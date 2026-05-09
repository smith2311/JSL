import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service that automatically retries failed operations with exponential backoff
/// No external dependencies required - uses pure Dart
class AutoRetryService {
  static const Duration _initialDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(seconds: 30);

  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _retryCounts = {};
  final Map<String, _RetryOperation> _operations = {};

  static final AutoRetryService _instance = AutoRetryService._internal();
  factory AutoRetryService() => _instance;
  AutoRetryService._internal();

  /// Execute a function with automatic retry logic
  /// Returns null on failure (continues retrying in background)
  Future<T?> executeWithRetry<T>({
    required String key,
    required Future<T> Function() operation,
    VoidCallback? onSuccess,
    VoidCallback? onRetrying,
  }) async {
    // Store operation for potential retries
    _operations[key] = _RetryOperation(
      operation: () async => await operation(),
      onSuccess: onSuccess,
      onRetrying: onRetrying,
    );

    try {
      final result = await operation();
      _resetRetryCount(key);
      onSuccess?.call();
      return result;
    } on SocketException catch (e) {
      debugPrint('🔴 [AutoRetry] Socket error for $key: $e');
      _scheduleRetry(key);
      return null;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [AutoRetry] Timeout error for $key: $e');
      _scheduleRetry(key);
      return null;
    } on HttpException catch (e) {
      debugPrint('🔴 [AutoRetry] HTTP error for $key: $e');
      _scheduleRetry(key);
      return null;
    } catch (e) {
      debugPrint('🔴 [AutoRetry] Error for $key: $e');
      _scheduleRetry(key);
      return null;
    }
  }

  /// Schedule a retry with exponential backoff
  void _scheduleRetry(String key) {
    // Cancel existing timer if any
    _activeTimers[key]?.cancel();

    // Increment retry count
    _retryCounts[key] = (_retryCounts[key] ?? 0) + 1;
    final retryCount = _retryCounts[key]!;

    // Calculate delay with exponential backoff (capped at max)
    final delaySeconds = (_initialDelay.inSeconds * (1 << (retryCount - 1))).clamp(
      _initialDelay.inSeconds,
      _maxDelay.inSeconds,
    );
    final delay = Duration(seconds: delaySeconds);

    debugPrint('🔄 [AutoRetry] Scheduling retry #$retryCount for $key in ${delay.inSeconds}s');

    final storedOp = _operations[key];
    if (storedOp != null) {
      storedOp.onRetrying?.call();

      _activeTimers[key] = Timer(delay, () async {
        debugPrint('🔁 [AutoRetry] Executing retry #$retryCount for $key');
        await executeWithRetry(
          key: key,
          operation: () async => await storedOp.operation(),
          onSuccess: storedOp.onSuccess,
          onRetrying: storedOp.onRetrying,
        );
      });
    }
  }

  /// Reset retry count for a specific key
  void _resetRetryCount(String key) {
    _retryCounts.remove(key);
    _activeTimers[key]?.cancel();
    _activeTimers.remove(key);
    _operations.remove(key);
  }

  /// Cancel retry for a specific key
  void cancelRetry(String key) {
    _activeTimers[key]?.cancel();
    _activeTimers.remove(key);
    _retryCounts.remove(key);
    _operations.remove(key);
  }

  /// Cancel all pending retries
  void cancelAllRetries() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _retryCounts.clear();
    _operations.clear();
  }

  /// Get current retry count for a key
  int getRetryCount(String key) => _retryCounts[key] ?? 0;

  /// Check if a key is currently retrying
  bool isRetrying(String key) => _activeTimers.containsKey(key);

  /// Dispose the service
  void dispose() {
    cancelAllRetries();
  }
}

/// Internal class to store retry operation details
class _RetryOperation {
  final Future<dynamic> Function() operation;
  final VoidCallback? onSuccess;
  final VoidCallback? onRetrying;

  _RetryOperation({
    required this.operation,
    this.onSuccess,
    this.onRetrying,
  });
}