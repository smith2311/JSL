import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../providers/sip_sip_detail_screen_provider.dart';

class PauseSipScreen extends ConsumerWidget {
  final String sxpId;
  final dynamic sipDetail;

  const PauseSipScreen({
    super.key,
    required this.sxpId,
    required this.sipDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pauseState = ref.watch(pauseSipStateProvider);
    final maxAllowed = sipDetail.remainingPauseCount;

    // ✅ Validate SIP status before allowing pause
    final sipStatus = sipDetail.status?.toString().toLowerCase().trim() ?? '';
    final canPause = sipStatus == 'active';

    print('[DEBUG] SIP Status: $sipStatus, Can Pause: $canPause');

    // ✅ Show error state if cannot pause
    if (!canPause) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            AppStrings.pau_sip,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Color(0xFFE53935)),
              const SizedBox(height: 24),
              const Text(
                'Cannot Pause SIP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This SIP cannot be paused because it is ${sipStatus == 'cancelled' ? 'cancelled' : sipStatus == 'paused' ? 'already paused' : 'not active'}.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888898),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => !pauseState.isProcessing,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.only(top: 38),
            child: AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: pauseState.isProcessing
                    ? null
                    : () {
                  ref.read(pauseSipStateProvider.notifier).reset();
                  context.pop();
                },
              ),
              title: const Text(
                AppStrings.pau_sip,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------ CARD 1 ------------------
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6EAF8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      AppStrings.nextInstallment,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                    Text(
                                      sipDetail.nextInstallmentDate,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      AppStrings.iconFunds_png,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sipDetail.fundName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            _buildChip(
                                                sipDetail.fundCategory),
                                            const SizedBox(width: 6),
                                            _buildChip(
                                                sipDetail.fundSubCategory),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Color(0xFFBDBDBD)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          AppStrings.amt,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF888898)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${NumberFormat('#,##,##0').format(sipDetail.amount)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          AppStrings.freq,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF888898)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sipDetail.frequency,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          AppStrings.curr_amt,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF888898)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${NumberFormat('#,##,##0').format(sipDetail.currentAmount)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFE0E0E0)),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                  'SIP Date', sipDetail.sipDate),
                              const SizedBox(height: 12),
                              _buildDetailRow('Successful Installment',
                                  '${sipDetail.successfulInvestments}'),
                              const SizedBox(height: 12),
                              _buildDetailRow('SIP ID', sipDetail.sipId),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                  'Registration Date', sipDetail.regDate),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                  'SIP End Date', sipDetail.sipEndDate),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ------------------ CARD 2 ------------------
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: pauseState.isProcessing
                                    ? null
                                    : () => _selectDate(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        pauseState.selectedDate != null
                                            ? DateFormat('dd/MM/yyyy').format(
                                            pauseState.selectedDate!)
                                            : DateFormat('dd/MM/yyyy')
                                            .format(DateTime.now()),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF888898), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No of Installments',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: TextEditingController(
                                  text: pauseState.noOfInstallments
                                      .toString(),
                                )..selection = TextSelection.collapsed(
                                  offset: pauseState.noOfInstallments
                                      .toString()
                                      .length,
                                ),
                                keyboardType: TextInputType.number,
                                enabled: !pauseState.isProcessing,
                                onChanged: (value) {
                                  final number = int.tryParse(value);
                                  if (number != null) {
                                    ref
                                        .read(pauseSipStateProvider.notifier)
                                        .updateInstallments(number);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '1',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0060A6)),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Min: 1',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Max: $maxAllowed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (pauseState.errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  pauseState.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pauseState.isProcessing
                              ? null
                              : () {
                            ref
                                .read(pauseSipStateProvider.notifier)
                                .reset();
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            side:
                            const BorderSide(color: Color(0xFF0060A6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Back',
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
                              : () => _handlePause(
                              context, ref, maxAllowed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0060A6),
                            disabledBackgroundColor:
                            Colors.grey.shade300,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Pause',
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
                ),
              ),
            ),
            // ✅ FIXED: Single loader overlay
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
                              'Please wait',
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
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F3FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF0060A6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(fontSize: 13, color: Color(0xFF888898)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initialDate =
        ref.read(pauseSipStateProvider).selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
            const ColorScheme.light(primary: Color(0xFF0060A6)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(pauseSipStateProvider.notifier).selectDate(picked);
    }
  }

  void _handlePause(
      BuildContext context, WidgetRef ref, int maxAllowed) {
    if (!ref
        .read(pauseSipStateProvider.notifier)
        .validate(maxAllowed)) return;
    _showPauseConfirmation(context, ref);
  }

  void _showPauseConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
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
                color: const Color(0xFFE3F3FE),
                border: Border.all(
                  color: const Color(0xFF0060A6),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.pause_circle_outline,
                color: Color(0xFF0060A6),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to Pause this SIP?',
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
                    onPressed: () => Navigator.pop(modalContext),
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
                      Navigator.pop(modalContext);
                      _processPause(context, ref);
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

  /// ✅ FIXED: Better error handling with user-friendly messages
  Future<void> _processPause(BuildContext context, WidgetRef ref) async {
    print('[DEBUG] ========== PAUSE SIP PROCESS STARTED ==========');
    try {
      final pauseState = ref.read(pauseSipStateProvider);

      print('[DEBUG] Calling pauseSip API...');
      final startTime = DateTime.now();

      await ref.read(pauseSipStateProvider.notifier).pauseSip(
        regNo: sipDetail.sipId,
        pausedFrom: pauseState.selectedDate!,
        noOfInstallments: pauseState.noOfInstallments,
      );

      final apiDuration = DateTime.now().difference(startTime);
      print('[DEBUG] API call completed successfully in ${apiDuration.inSeconds} seconds');

      if (!context.mounted) {
        print('[DEBUG] Context not mounted after API call');
        return;
      }

      print('[DEBUG] Starting 6 second wait for status update...');
      await Future.delayed(const Duration(seconds: 6));

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

      print('[DEBUG] Closing pause screen...');
      context.pop();

      print('[DEBUG] Showing success message...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SIP paused successfully'),
          backgroundColor: Color(0xFF00A651),
          duration: Duration(seconds: 2),
        ),
      );

      print('[DEBUG] ========== PAUSE SIP PROCESS COMPLETED ==========');
    } catch (e, stackTrace) {
      print('[DEBUG] ========== PAUSE SIP ERROR ==========');
      print('[DEBUG] Error: $e');
      print('[DEBUG] Stack trace: $stackTrace');

      if (context.mounted) {
        print('[DEBUG] Setting processing to false due to error');
        ref.read(pauseSipStateProvider.notifier).setProcessing(false);

        // ✅ Parse error message for better user experience
        String errorMessage = 'Failed to pause SIP';
        final errorString = e.toString();

        if (errorString.contains('Invalid Status') ||
            errorString.contains('cancelled') ||
            errorString.contains('inactive')) {
          errorMessage = 'This SIP cannot be paused. It may be cancelled or inactive.';
        } else if (errorString.contains('Exception:')) {
          errorMessage = errorString.replaceAll('Exception:', '').trim();
        }

        print('[DEBUG] Showing error message to user: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}