import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../constants/strings.dart';
import '../core/token_helper.dart';
import '../core/config/env.dart';
import '../providers/watchlist_provider.dart';
import 'package:http/http.dart' as http;

class AnimatedSaveButton extends ConsumerStatefulWidget {
  final String fundName;
  final int fundId;
  final double size;

  const AnimatedSaveButton({
    super.key,
    required this.fundName,
    required this.fundId,
    this.size = 24,
  });

  @override
  ConsumerState<AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends ConsumerState<AnimatedSaveButton> {
  bool isSaved = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize from Riverpod state
    final watchlist = ref.read(watchlistProvider);
    isSaved = watchlist.contains(widget.fundId);
  }

  Future<void> _toggleSave() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please login to save funds."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final body = {
        "action": isSaved ? "remove" : "add",
        "fund_id": widget.fundId,
      };

      debugPrint("=== Watchlist API Call ===");
      debugPrint("Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/funds/watchlist/add-remove'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final data = jsonDecode(response.body);
      final success = data['status'] == 1;

      if (success) {
        setState(() {
          isSaved = !isSaved;
        });

        final notifier = ref.read(watchlistProvider.notifier);
        if (isSaved) {
          // Add fund to watchlist
          final currentList = [...ref.read(watchlistProvider)];
          if (!currentList.contains(widget.fundId)) {
            currentList.add(widget.fundId);
          }
          notifier.setWatchlist(currentList);
        } else {
          // Remove fund from watchlist
          notifier.removeFund(widget.fundId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSaved
                  ? "Added '${widget.fundName}' to watchlist"
                  : "Removed '${widget.fundName}' from watchlist",
            ),
            duration: const Duration(seconds: 2),
            backgroundColor:
            isSaved ? Colors.green.shade600 : Colors.red.shade600,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to update watchlist"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving/removing fund: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSave,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: SvgPicture.asset(
          AppStrings.save,
          key: ValueKey(isSaved),
          width: widget.size,
          height: widget.size,
          colorFilter: ColorFilter.mode(
            isSaved ? const Color(0xFF0060A6) : Colors.grey,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}