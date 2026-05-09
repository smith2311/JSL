import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../providers/sip_tab_provider.dart';

// -------------------
// SIP Header Widget
// -------------------
class SipHeader extends ConsumerWidget {
  final int subTab; // 0=SIP, 1=SWP, 2=STP

  const SipHeader({
    super.key,
    required this.subTab,
  });

  String _getAmountLabel() {
    switch (subTab) {
      case 0:
        return AppStrings.totalSIPAmount;
      case 1:
        return AppStrings.totalSWPAmount;
      default:
        return AppStrings.totalSTPAmount;
    }
  }

  String _getActiveLabel() {
    switch (subTab) {
      case 0:
        return AppStrings.activeSIP;
      case 1:
        return AppStrings.activeSWP;
      default:
        return AppStrings.activeSTP;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sipState = ref.watch(sipDetailsProvider);

    return sipState.when(
      data: (sip) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Amount (Dynamic based on subTab)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAmountLabel(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₹${sip.totalSipAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const TextSpan(
                        text: ' approx.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Active Count (Dynamic based on subTab)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getActiveLabel(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sip.activeSips}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Error loading details',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}