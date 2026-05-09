import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../constants/messages.dart';
import '../providers/sip_sip_detail_screen_provider.dart';

class ResumeSipConfirmation extends ConsumerWidget {
  final String sxpId;
  final dynamic sipDetail;

  const ResumeSipConfirmation({
    super.key,
    required this.sxpId,
    required this.sipDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pauseState = ref.watch(pauseSipStateProvider);

    return WillPopScope(
      onWillPop: () async => !pauseState.isProcessing,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE3F3FE),
                    border: Border.all(
                      color: const Color(0xFF0060A6),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.timer,
                    color: Color(0xFF0060A6),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.cnf_res_sip,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: pauseState.isProcessing
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF0060A6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0060A6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: pauseState.isProcessing
                            ? null
                            : () => _processResume(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0060A6),
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          AppStrings.confirm,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (pauseState.isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: WillPopScope(
                  onWillPop: () async => false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                            color: Color(0xFF0060A6),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 24),
                          Text(
                            AppStrings.pls_wait,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processResume(BuildContext context, WidgetRef ref) async {
    print('[DEBUG] ========== RESUME SIP PROCESS STARTED ==========');
    try {
      print('[DEBUG] Calling resumeSip API...');
      final startTime = DateTime.now();

      await ref.read(pauseSipStateProvider.notifier).resumeSip(
        regNo: sipDetail.sipId,
      );

      final apiDuration = DateTime.now().difference(startTime);
      print('[DEBUG] API call completed successfully in ${apiDuration.inSeconds} seconds');

      if (!context.mounted) {
        print('[DEBUG] Context not mounted after API call');
        return;
      }

      // Wait 6 seconds for backend to process
      print('[DEBUG] Starting 6 second wait for status update...');
      final waitStartTime = DateTime.now();
      await Future.delayed(const Duration(seconds: 6));
      final waitDuration = DateTime.now().difference(waitStartTime);
      print('[DEBUG] Wait completed in ${waitDuration.inSeconds} seconds');

      // Invalidate providers to refresh data
      print('[DEBUG] Invalidating SIP providers to refresh data...');
      ref.invalidate(sipDetailProvider(sxpId));
      ref.invalidate(sipTransactionHistoryProvider(sxpId));

      print('[DEBUG] Waiting 500ms for providers to start fetching...');
      await Future.delayed(const Duration(milliseconds: 500));

      print('[DEBUG] Resetting pause state...');
      ref.read(pauseSipStateProvider.notifier).reset();

      if (!context.mounted) {
        print('[DEBUG] Context not mounted before navigation');
        return;
      }

      print('[DEBUG] Closing confirmation modal...');
      Navigator.pop(context);

      print('[DEBUG] Showing success message...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SuccessMessages.sip_res),
          backgroundColor: Color(0xFF00A651),
          duration: Duration(seconds: 2),
        ),
      );

      print('[DEBUG] ========== RESUME SIP PROCESS COMPLETED ==========');
    } catch (e, stackTrace) {
      print('[DEBUG] ========== RESUME SIP ERROR ==========');
      print('[DEBUG] Error: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      if (context.mounted) {
        print('[DEBUG] Setting processing to false due to error');
        ref.read(pauseSipStateProvider.notifier).setProcessing(false);

        print('[DEBUG] Showing error message to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }
}