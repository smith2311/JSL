import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../features/auth/data/models/swp_detail.dart';
import '../providers/cancel_provider.dart';
import '../providers/sip_sip_detail_screen_provider.dart';
import '../providers/swp_detail_screen_provider.dart';
import '../providers/stp_detail_screen_provider.dart';

class CancelSipReasonBottomSheet extends ConsumerWidget {
  final String sxpId;
  final String regNo;
  final String sxpType;

  const CancelSipReasonBottomSheet({
    super.key,
    required this.sxpId,
    required this.regNo,
    required this.sxpType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[DEBUG] CancelSipReasonBottomSheet - build() called');
    print('[DEBUG] sxpId: $sxpId, regNo: $regNo, sxpType: $sxpType');

    final cancelReasonsState = ref.watch(cancelReasonsProvider);
    final cancelState = ref.watch(cancelSipStateProvider);

    print('[DEBUG] cancelState.isProcessing: ${cancelState.isProcessing}');
    print('[DEBUG] cancelState.selectedReasonId: ${cancelState.selectedReasonId}');
    print('[DEBUG] cancelState.errorMessage: ${cancelState.errorMessage}');

    return WillPopScope(
      onWillPop: () async {
        print('[DEBUG] WillPopScope - onWillPop called, isProcessing: ${cancelState.isProcessing}');
        if (cancelState.isProcessing) {
          print('[DEBUG] Blocking back navigation - processing in progress');
          return false;
        }
        print('[DEBUG] Allowing back navigation');
        return true;
      },
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 35, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: cancelState.isProcessing
                              ? () {
                            print('[DEBUG] Back button pressed while processing - ignoring');
                          }
                              : () {
                            print('[DEBUG] Back button pressed - closing bottom sheet');
                            ref.read(cancelSipStateProvider.notifier).reset();
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Choose your reason to cancel ${sxpType.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: cancelReasonsState.when(
                      data: (reasons) {
                        print('[DEBUG] Reasons loaded: ${reasons.length} items');
                        return _buildReasonsList(context, ref, reasons, cancelState);
                      },
                      loading: () {
                        print('[DEBUG] Loading reasons...');
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: CircularProgressIndicator(color: Color(0xFF0060A6)),
                          ),
                        );
                      },
                      error: (error, stack) {
                        print('[DEBUG] Error loading reasons: $error');
                        print('[DEBUG] Stack trace: $stack');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text('Error loading reasons'),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    print('[DEBUG] Retry button pressed - invalidating provider');
                                    ref.invalidate(cancelReasonsProvider);
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Full screen blocking loader overlay
          if (cancelState.isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: WillPopScope(
                  onWillPop: () async {
                    print('[DEBUG] Blocking all navigation during processing');
                    return false;
                  },
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

  Widget _buildReasonsList(
      BuildContext context,
      WidgetRef ref,
      List<CancelReason> reasons,
      CancelSipState cancelState,
      ) {
    print('[DEBUG] Building reasons list');
    CancelReason? otherReason;
    try {
      otherReason = reasons.firstWhere(
            (r) => r.id == 13 || r.reason.toLowerCase().trim() == 'others',
      );
      print('[DEBUG] Found "Others" option with ID: ${otherReason.id}');
    } catch (e) {
      print('[DEBUG] "Others" option not found in reasons list');
    }

    final bool showOtherTextField = otherReason != null &&
        cancelState.selectedReasonId == otherReason.id;
    print('[DEBUG] showOtherTextField: $showOtherTextField');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...reasons.map((reason) => _buildReasonOption(
                    context, ref, reason, cancelState, otherReason?.id)),
                if (showOtherTextField) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: cancelState.otherReasonText)
                      ..selection = TextSelection.collapsed(
                        offset: cancelState.otherReasonText.length,
                      ),
                    maxLines: 3,
                    autofocus: true,
                    enabled: !cancelState.isProcessing,
                    onChanged: (value) {
                      print('[DEBUG] Other reason text changed: $value');
                      ref.read(cancelSipStateProvider.notifier).updateOtherReasonText(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Reason',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cancelState.errorMessage != null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cancelState.errorMessage != null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cancelState.errorMessage != null
                              ? Colors.red
                              : const Color(0xFF0060A6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (cancelState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      cancelState.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cancelState.selectedReasonId != null && !cancelState.isProcessing
                    ? () {
                  print('[DEBUG] Continue button pressed');
                  _handleContinue(context, ref, cancelState);
                }
                    : null,
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
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonOption(
      BuildContext context,
      WidgetRef ref,
      CancelReason reason,
      CancelSipState cancelState,
      int? othersReasonId,
      ) {
    final bool isSelected = cancelState.selectedReasonId == reason.id;
    final bool isOthersOption = reason.id == othersReasonId;

    return InkWell(
      onTap: cancelState.isProcessing
          ? null
          : () {
        print('[DEBUG] Reason selected: ${reason.reason} (ID: ${reason.id})');
        print('[DEBUG] Is others option: $isOthersOption');
        ref.read(cancelSipStateProvider.notifier).selectReason(reason.id, isOthersOption);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0060A6) : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason.reason,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0060A6),
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0060A6),
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue(BuildContext context, WidgetRef ref, CancelSipState cancelState) {
    print('[DEBUG] _handleContinue called');
    final cancelReasonsState = ref.read(cancelReasonsProvider);

    cancelReasonsState.whenData((reasons) {
      print('[DEBUG] Validating selection...');
      CancelReason? otherReason;
      try {
        otherReason = reasons.firstWhere(
              (r) => r.id == 13 || r.reason.toLowerCase().trim() == 'others',
        );
      } catch (e) {
        print('[DEBUG] Others option not found during validation');
      }

      if (!ref.read(cancelSipStateProvider.notifier).validate(otherReason?.id)) {
        print('[DEBUG] Validation failed');
        return;
      }

      print('[DEBUG] Validation passed - showing confirmation');
      _showConfirmationModal(context, ref, cancelState, reasons);
    });
  }

  void _showConfirmationModal(
      BuildContext context,
      WidgetRef ref,
      CancelSipState cancelState,
      List<CancelReason> reasons,
      ) {
    print('[DEBUG] ========== SHOWING CONFIRMATION MODAL ==========');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (modalContext) => Container(
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
                color: const Color(0xFFFFEBEE),
                border: Border.all(
                  color: const Color(0xFFE53935),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFE53935),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Are you sure you want to Cancel this ${sxpType.toUpperCase()}?',
              style: const TextStyle(
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
                    onPressed: () {
                      print('[DEBUG] Cancel button clicked in confirmation modal');
                      Navigator.pop(modalContext);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF0060A6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
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
                    onPressed: () {
                      print('[DEBUG] Confirm button clicked in confirmation modal');
                      Navigator.pop(modalContext);
                      _processCancellation(context, ref, cancelState, reasons);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0060A6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
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
    );
  }
  /// ✅ FIXED: Polls API until status changes to cancelled
  Future<void> _processCancellation(
      BuildContext context,
      WidgetRef ref,
      CancelSipState cancelState,
      List<CancelReason> reasons,
      ) async {
    print('[DEBUG] ========== CANCELLATION PROCESS STARTED ==========');
    print('[DEBUG] sxpType: $sxpType');

    try {
      final selectedReason = reasons.firstWhere(
            (r) => r.id == cancelState.selectedReasonId,
      );
      print('[DEBUG] Selected reason: ${selectedReason.reason} (ID: ${selectedReason.id})');

      final reasonMsg = cancelState.selectedReasonId == 13
          ? cancelState.otherReasonText
          : selectedReason.reason;
      print('[DEBUG] Reason message to send: $reasonMsg');

      print('[DEBUG] Calling cancelSxp API...');
      final startTime = DateTime.now();

      await ref.read(cancelSipStateProvider.notifier).cancelSxp(
        regNo: regNo,
        reasonCode: cancelState.selectedReasonId!,
        reasonMsg: reasonMsg,
        sxpType: sxpType,
      );

      final apiDuration = DateTime.now().difference(startTime);
      print('[DEBUG] API call completed successfully in ${apiDuration.inSeconds} seconds');

      if (!context.mounted) {
        print('[DEBUG] Context not mounted after API call');
        return;
      }

      // ✅ FIXED: Poll the API until status changes or timeout
      final sxpTypeLower = sxpType.toLowerCase().trim();
      print('[DEBUG] Starting status polling for sxpType: $sxpTypeLower');

      bool statusChanged = false;
      int pollAttempts = 0;
      const maxPollAttempts = 12; // Poll for up to 24 seconds (12 attempts x 2 seconds)

      while (!statusChanged && pollAttempts < maxPollAttempts) {
        pollAttempts++;
        print('[DEBUG] Poll attempt $pollAttempts/$maxPollAttempts');

        await Future.delayed(const Duration(seconds: 2));

        // Invalidate and fetch fresh data
        if (sxpTypeLower == 'sip') {
          ref.invalidate(sipDetailProvider(sxpId));
          try {
            final detail = await ref.read(sipDetailProvider(sxpId).future);
            final status = detail.status.toLowerCase().trim();
            print('[DEBUG] Current SIP status: $status');
            if (status == 'cancelled' || status == 'inactive') {
              statusChanged = true;
              print('[DEBUG] ✅ Status changed to $status');
            }
          } catch (e) {
            print('[DEBUG] Error fetching SIP detail: $e');
          }
        } else if (sxpTypeLower == 'swp') {
          ref.invalidate(swpDetailProvider(sxpId));
          try {
            final detail = await ref.read(swpDetailProvider(sxpId).future);
            final status = detail.status.toLowerCase().trim();
            print('[DEBUG] Current SWP status: $status');
            if (status == 'cancelled' || status == 'inactive') {
              statusChanged = true;
              print('[DEBUG] ✅ Status changed to $status');
            }
          } catch (e) {
            print('[DEBUG] Error fetching SWP detail: $e');
          }
        } else if (sxpTypeLower == 'stp') {
          ref.invalidate(stpDetailProvider(sxpId));
          try {
            final detail = await ref.read(stpDetailProvider(sxpId).future);
            final status = detail.status.toLowerCase().trim();
            print('[DEBUG] Current STP status: $status');
            if (status == 'cancelled' || status == 'inactive') {
              statusChanged = true;
              print('[DEBUG] ✅ Status changed to $status');
            }
          } catch (e) {
            print('[DEBUG] Error fetching STP detail: $e');
          }
        }

        if (!statusChanged) {
          print('[DEBUG] Status not changed yet, continuing polling...');
        }
      }

      if (!statusChanged) {
        print('[DEBUG] ⚠️ Polling timeout - status may not have updated yet');
      }

      // Also invalidate transaction history
      if (sxpTypeLower == 'sip') {
        ref.invalidate(sipTransactionHistoryProvider(sxpId));
      } else if (sxpTypeLower == 'swp') {
        ref.invalidate(swpTransactionHistoryProvider(sxpId));
      } else if (sxpTypeLower == 'stp') {
        ref.invalidate(stpTransactionHistoryProvider(sxpId));
      }

      print('[DEBUG] Resetting cancellation state...');
      ref.read(cancelSipStateProvider.notifier).reset();

      if (!context.mounted) {
        print('[DEBUG] Context not mounted before navigation');
        return;
      }

      print('[DEBUG] Closing bottom sheet...');
      Navigator.pop(context);

      print('[DEBUG] Showing success message...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              statusChanged
                  ? '${sxpType.toUpperCase()} cancelled successfully'
                  : '${sxpType.toUpperCase()} cancellation initiated. Please refresh to see updated status.'
          ),
          backgroundColor: const Color(0xFF00A651),
          duration: const Duration(seconds: 3),
        ),
      );

      print('[DEBUG] ========== CANCELLATION PROCESS COMPLETED ==========');
    } catch (e, stackTrace) {
      print('[DEBUG] ========== CANCELLATION ERROR ==========');
      print('[DEBUG] Error: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      if (context.mounted) {
        print('[DEBUG] Setting processing to false due to error');
        ref.read(cancelSipStateProvider.notifier).setProcessing(false);

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