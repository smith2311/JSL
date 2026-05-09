import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../features/market/data/repo/market_repo.dart';

class MarketMarqueeList extends StatefulWidget {
  const MarketMarqueeList({super.key});

  @override
  State<MarketMarqueeList> createState() => _MarketMarqueeListState();
}

class _MarketMarqueeListState extends State<MarketMarqueeList> {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;
  Timer? _retryTimer;

  List<Map<String, dynamic>> _tickers = [];
  bool _loading = true;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _retryInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startScrolling();
  }

  String _capitalizeWords(String text) {
    return text.toUpperCase();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    try {
      final repo = MarketRepo();
      final data = await repo.fetchIndices();

      if (mounted) {
        setState(() {
          _tickers = data;
          _loading = false;
          _hasError = false;
          _retryCount = 0;
        });
      }
    } on SocketException catch (_) {
      // Network error - schedule retry
      _handleConnectionError();
    } on TimeoutException catch (_) {
      // Timeout error - schedule retry
      _handleConnectionError();
    } catch (e) {
      // Other errors - schedule retry
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _loading = false;
    });

    // Auto-retry with exponential backoff
    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = _retryInterval * _retryCount;

      debugPrint('📡 Market data fetch failed. Retrying in ${delay.inSeconds}s (Attempt $_retryCount/$_maxRetries)');

      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        if (mounted) {
          setState(() {
            _loading = true;
            _hasError = false;
          });
          _fetchData();
        }
      });
    } else {
      debugPrint('❌ Market data fetch failed after $_maxRetries attempts');
    }
  }

  void _manualRetry() {
    _retryCount = 0;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _fetchData();
  }

  void _startScrolling() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients || _tickers.isEmpty) return;

      final maxExtent = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset + 1;

      if (current >= maxExtent) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(current);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _retryTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always show shimmer when loading or error - keep UI professional
    if (_loading || _hasError || _tickers.isEmpty) {
      return _buildShimmer();
    }

    // Repeat tickers so scrolling feels continuous
    final items = List.generate(50, (i) => _tickers[i % _tickers.length]);

    return Container(
      height: 44,
      width: double.infinity,
      color: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final t = items[i];
          final name = _capitalizeWords(t["name"]?.toString() ?? "");
          final value = t["value"]?.toString() ?? "";
          final difference = (t["difference"] ?? 0).toString();
          final percentage = (t["percentage"] ?? 0).toString();
          final changeText = "$difference ($percentage%)";
          final isNegative = changeText.contains("-");

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  changeText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 44,
      width: double.infinity,
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 10,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}