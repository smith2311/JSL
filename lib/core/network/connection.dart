import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Simple helper to wrap any async operation with automatic retry
class ConnectionHelper {
  /// Execute an operation with automatic retry on network errors
  /// Shows shimmer/loading state and retries in background
  static Future<T?> executeWithAutoRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 10,
    Duration initialDelay = const Duration(seconds: 2),
    Duration maxDelay = const Duration(seconds: 30),
    VoidCallback? onRetrying,
    VoidCallback? onSuccess,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        final result = await operation();
        onSuccess?.call();
        return result;
      } on SocketException catch (e) {
        retryCount++;
        debugPrint('🔴 Network error (attempt $retryCount): $e');
        if (retryCount >= maxRetries) {
          debugPrint('⚠️ Max retries reached, will keep trying in background');
        }
        onRetrying?.call();
        await _waitBeforeRetry(retryCount, initialDelay, maxDelay);
      } on TimeoutException catch (e) {
        retryCount++;
        debugPrint('🔴 Timeout error (attempt $retryCount): $e');
        if (retryCount >= maxRetries) {
          debugPrint('⚠️ Max retries reached, will keep trying in background');
        }
        onRetrying?.call();
        await _waitBeforeRetry(retryCount, initialDelay, maxDelay);
      } catch (e) {
        retryCount++;
        debugPrint('🔴 Error (attempt $retryCount): $e');
        if (retryCount >= maxRetries) {
          debugPrint('⚠️ Max retries reached, will keep trying in background');
        }
        onRetrying?.call();
        await _waitBeforeRetry(retryCount, initialDelay, maxDelay);
      }
    }
  }

  static Future<void> _waitBeforeRetry(
      int retryCount,
      Duration initialDelay,
      Duration maxDelay,
      ) async {
    // Exponential backoff with cap
    final delaySeconds = (initialDelay.inSeconds * (1 << (retryCount - 1))).clamp(
      initialDelay.inSeconds,
      maxDelay.inSeconds,
    );
    final delay = Duration(seconds: delaySeconds);

    debugPrint('🔄 Retrying in ${delay.inSeconds} seconds...');
    await Future.delayed(delay);
  }
}

/// Mixin to add auto-retry capabilities to any widget
mixin AutoRetryMixin<T extends StatefulWidget> on State<T> {
  final Map<String, bool> _retryingOperations = {};

  bool isRetrying(String operationKey) => _retryingOperations[operationKey] ?? false;

  Future<R?> executeWithRetry<R>({
    required String operationKey,
    required Future<R> Function() operation,
    VoidCallback? onSuccess,
  }) async {
    return ConnectionHelper.executeWithAutoRetry<R>(
      operation: operation,
      onRetrying: () {
        if (mounted) {
          setState(() {
            _retryingOperations[operationKey] = true;
          });
        }
      },
      onSuccess: () {
        if (mounted) {
          setState(() {
            _retryingOperations[operationKey] = false;
          });
          onSuccess?.call();
        }
      },
    );
  }
}