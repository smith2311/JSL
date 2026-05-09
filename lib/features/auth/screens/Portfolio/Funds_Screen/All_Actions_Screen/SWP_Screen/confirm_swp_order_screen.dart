import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/otp_provider.dart';

class SwpConfirmScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String folioNo;
  final String bseClientId;
  final String withdrawalBy;
  final double amount;
  final String frequency;
  final String swpDate;
  final int noOfInstallments;
  final bool firstOrder;
  final String fundName;
  final double availableUnits;
  final double availableAmount;
  final String bankName;
  final String accountNo;
  final int? clientId;

  const SwpConfirmScreen({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.bseClientId,
    required this.withdrawalBy,
    required this.amount,
    required this.frequency,
    required this.swpDate,
    required this.noOfInstallments,
    required this.firstOrder,
    required this.fundName,
    required this.availableUnits,
    required this.availableAmount,
    required this.bankName,
    required this.accountNo,
    this.clientId,
  });

  @override
  ConsumerState<SwpConfirmScreen> createState() => _SwpConfirmScreenState();
}

class _SwpConfirmScreenState extends ConsumerState<SwpConfirmScreen> {
  bool _hasNavigated = false;
  bool _otpSendRequested = false;

  @override
  void initState() {
    super.initState();

    // 🔥 Reset OTP provider state when entering SWP confirm screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionOtpProvider.notifier).reset();
      print('🧹 SWP Confirm Screen: Reset OTP provider');
      setState(() {
        _hasNavigated = false;
        _otpSendRequested = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final redemptionOtpState = ref.watch(redemptionOtpProvider);

    ref.listen<RedemptionOtpState>(redemptionOtpProvider, (previous, next) {
      // Prevent multiple navigations
      if (_hasNavigated) {
        print('⚠️ Already navigated, skipping...');
        return;
      }

      print('👂 SWP Listener triggered:');
      print('   Previous otpSent: ${previous?.otpSent}');
      print('   Next otpSent: ${next.otpSent}');
      print('   OTP Requested: $_otpSendRequested');
      print('   Next error: ${next.errorMessage}');

      // Navigate when OTP is successfully sent AND we requested it
      if (next.otpSent && _otpSendRequested && !_hasNavigated) {
        setState(() {
          _hasNavigated = true;
        });

        print('✅ SWP: OTP sent successfully, navigating...');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.getOtpSentMessage()),
            backgroundColor: const Color(0xFF00A651),
            duration: const Duration(seconds: 2),
          ),
        );

        // Small delay to ensure SnackBar is shown
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          final redemptionData = {
            'fundName': widget.fundName,
            'amount': widget.amount,
            'bankName': widget.bankName,
            'accountNo': widget.accountNo.length >= 4
                ? widget.accountNo.substring(widget.accountNo.length - 4)
                : widget.accountNo,
            'frequency': widget.frequency,
            'swpDate': widget.swpDate,
            'noOfInstallments': widget.noOfInstallments,
            'firstOrder': widget.firstOrder,
          };

          print('🚀 Navigating to /redemption-otp with SWP data');

          // 🔥 KEY FIX: Add .then() to detect when user returns
          context.push('/redemption-otp', extra: {
            'clientId': widget.clientId ?? 0,
            'redemptionData': redemptionData,
            'fundId': widget.fundId,
            'folioNo': widget.folioNo,
            'bseClientId': widget.bseClientId,
            'redeemType': 'SWP',
            'redeemBy': widget.withdrawalBy,
            'amount': widget.amount,
          }).then((_) {
            // User returned from OTP screen - reset everything
            if (mounted) {
              print('🔙 SWP: User returned from OTP screen - Resetting');
              ref.read(redemptionOtpProvider.notifier).reset();
              setState(() {
                _hasNavigated = false;
                _otpSendRequested = false;
              });
            }
          });
        });
      } else if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        print('❌ SWP: Error occurred: ${next.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset flags on error so user can retry
        setState(() {
          _hasNavigated = false;
          _otpSendRequested = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SWP Confirm',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                AppStrings.iconFunds_png,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.fundName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Available Units',
                          widget.availableUnits.toStringAsFixed(3),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Available Amount',
                          '₹${NumberFormat('#,##,##0.00').format(widget.availableAmount)}',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0060A6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              AppStrings.bob_icon,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'XX XXXX ${widget.accountNo.length >= 4 ? widget.accountNo.substring(widget.accountNo.length - 4) : widget.accountNo}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.bankName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888898),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SWP Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          widget.withdrawalBy == 'amount' ? 'Withdrawal Amount' : 'Withdrawal Units',
                          widget.withdrawalBy == 'amount'
                              ? '₹${NumberFormat('#,##,##0.00').format(widget.amount)}'
                              : widget.amount.toStringAsFixed(3),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Frequency',
                          widget.frequency.toUpperCase(),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'SWP Date',
                          _formatDate(widget.swpDate),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'No of Installments',
                          widget.noOfInstallments.toString(),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'BSE ID',
                          widget.bseClientId,
                        ),
                        if (widget.firstOrder) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'First Order',
                            'Yes',
                            valueColor: const Color(0xFF00A651),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: (redemptionOtpState.isLoading || _hasNavigated)
                    ? null
                    : () {
                  print('📘 SWP Continue button pressed');

                  // Validation
                  if (widget.withdrawalBy == 'amount' && widget.amount > widget.availableAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Amount cannot exceed ₹${NumberFormat('#,##,##0.00').format(widget.availableAmount)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (widget.withdrawalBy == 'units' && widget.amount > widget.availableUnits) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Units cannot exceed ${widget.availableUnits.toStringAsFixed(3)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _otpSendRequested = true;
                  });

                  print('📤 SWP: Sending OTP for clientId: ${widget.clientId}');
                  ref.read(redemptionOtpProvider.notifier).sendOtp(
                    clientId: widget.clientId ?? 0,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: (redemptionOtpState.isLoading || _hasNavigated)
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF888898),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}