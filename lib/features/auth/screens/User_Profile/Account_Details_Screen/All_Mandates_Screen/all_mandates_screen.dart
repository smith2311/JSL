import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../providers/mandates_provider.dart';
import '../../../../../../../widgets/mandate_card.dart';

class AllMandatesScreen extends ConsumerWidget {
  final String bseClientId;

  const AllMandatesScreen({
    super.key,
    required this.bseClientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mandatesAsync = ref.watch(mandatesProvider(bseClientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'All Mandate Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              ref.read(mandatesProvider(bseClientId).notifier).refresh();
            },
          ),
        ],
      ),

      // ✅ Body + Fixed Bottom Button
      body: mandatesAsync.when(
        data: (mandates) {
          if (mandates.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Scrollable List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mandates.length,
                  itemBuilder: (context, index) {
                    final mandate = mandates[index];
                    return MandateCard(
                      mandate: mandate,
                      onTap: () {
                        debugPrint("🔥 Tapped on mandate: ${mandate.mandateId}");
                      },
                    );
                  },
                ),
              ),

              // Fixed Bottom Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    debugPrint("✅ Navigating to Add Mandate with clientId: $bseClientId");
                    context.pushNamed(
                      'add_mandate',
                      extra: {'bseClientId': bseClientId},
                    );
                  },
                  child: const Text(
                    "Add Mandate",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG Image
            SvgPicture.asset(
              AppStrings.add_nom, // Update with your actual SVG path
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 32),
            const Text(
              'You haven\'t added mandate Yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.pushNamed(
                  'add_mandate',
                  extra: {'bseClientId': bseClientId},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0060A6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Mandate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String errorMessage = 'Failed to load mandates';
    if (error.toString().contains('Network') ||
        error.toString().contains('SocketException')) {
      errorMessage = 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      errorMessage = 'Request timed out. Please try again.';
    } else if (error.toString().contains('AUTH_ERROR')) {
      errorMessage = 'Session expired. Please login again.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(mandatesProvider(bseClientId).notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0060A6),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}