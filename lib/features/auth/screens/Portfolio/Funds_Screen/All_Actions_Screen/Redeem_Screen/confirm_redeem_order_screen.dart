import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/otp_provider.dart';
import '../../../../../../../../providers/redeem_confirmed_provider.dart';
import '../../../../../data/models/redeem_confirm.dart';

class RedeemConfirmScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String folioNo;
  final String bseClientId;
  final String redeemType;
  final String redeemBy;
  final double value;
  final String fundName;
  final double availableUnits;
  final double availableAmount;
  final String bankName;
  final String accountNo;
  final int? clientId;

  const RedeemConfirmScreen({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.bseClientId,
    required this.redeemType,
    required this.redeemBy,
    required this.value,
    required this.fundName,
    required this.availableUnits,
    required this.availableAmount,
    required this.bankName,
    required this.accountNo,
    this.clientId,
  });

  @override
  ConsumerState<RedeemConfirmScreen> createState() => _RedeemConfirmScreenState();
}

class _RedeemConfirmScreenState extends ConsumerState<RedeemConfirmScreen> {
  bool _hasNavigated = false;
  bool _otpSendRequested = false;
  bool _isTaxesExpanded = false;

  @override
  void initState() {
    super.initState();

    // Reset OTP provider and fetch redemption details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionOtpProvider.notifier).reset();
      print('🧹 Redeem Confirm Screen: Reset OTP provider');

      // Fetch redemption details from API for taxes and exit load
      ref.read(redeemDetailsProvider.notifier).fetchRedeemDetails(
        fundId: widget.fundId,
        folioNo: widget.folioNo,
        bseClientId: widget.bseClientId,
        redeem: widget.redeemType,
        redeemBy: widget.redeemBy,
        amount: widget.value,
      );

      setState(() {
        _hasNavigated = false;
        _otpSendRequested = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final redemptionOtpState = ref.watch(redemptionOtpProvider);
    final redeemDetailsState = ref.watch(redeemDetailsProvider);

    ref.listen<RedemptionOtpState>(redemptionOtpProvider, (previous, next) {
      if (_hasNavigated) {
        print('⚠️ Already navigated, skipping...');
        return;
      }

      print('👂 Redeem Listener triggered:');
      print('   Previous otpSent: ${previous?.otpSent}');
      print('   Next otpSent: ${next.otpSent}');
      print('   OTP Requested: $_otpSendRequested');
      print('   Next error: ${next.errorMessage}');

      if (next.otpSent && _otpSendRequested && !_hasNavigated) {
        setState(() {
          _hasNavigated = true;
        });

        print('✅ Redeem: OTP sent successfully, navigating...');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.getOtpSentMessage()),
            backgroundColor: const Color(0xFF00A651),
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          final redemptionData = {
            'fundName': widget.fundName,
            'amount': widget.value,
            'bankName': widget.bankName,
            'accountNo': widget.accountNo.length >= 4
                ? widget.accountNo.substring(widget.accountNo.length - 4)
                : widget.accountNo,
          };

          print('🚀 Navigating to /redemption-otp with Redeem data');

          // 🔥 KEY FIX: Add .then() to detect when user returns
          context.push('/redemption-otp', extra: {
            'clientId': widget.clientId ?? 0,
            'redemptionData': redemptionData,
            'fundId': widget.fundId,
            'folioNo': widget.folioNo,
            'bseClientId': widget.bseClientId,
            'redeemType': widget.redeemType,
            'redeemBy': widget.redeemBy,
            'amount': widget.value,
          }).then((_) {
            // User returned from OTP screen - reset everything
            if (mounted) {
              print('🔙 Redeem: User returned from OTP screen - Resetting');
              ref.read(redemptionOtpProvider.notifier).reset();
              setState(() {
                _hasNavigated = false;
                _otpSendRequested = false;
              });
            }
          });
        });
      } else if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        print('❌ Redeem: Error occurred: ${next.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          'Redeem Confirm',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildContent(context, redemptionOtpState, redeemDetailsState),
    );
  }

  Widget _buildContent(
      BuildContext context,
      RedemptionOtpState redemptionOtpState,
      AsyncValue<ConfirmRedeemDetails> redeemDetailsState,
      ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Fund Info Card
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

                // Bank Card
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

                // Redemption Details Card
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
                        'Redeem Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show Units or Amount based on redeemBy
                      _buildInfoRow(
                        widget.redeemBy == 'units' ? 'Units' : 'Amount',
                        widget.redeemBy == 'units'
                            ? widget.value.toStringAsFixed(3)
                            : '₹${NumberFormat('#,##,##0.00').format(widget.value)}',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'BSE ID',
                        widget.bseClientId,
                      ),
                      const SizedBox(height: 16),

                      // Taxes & Exit Load - Expandable (from API)
                      redeemDetailsState.when(
                        data: (details) => Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isTaxesExpanded = !_isTaxesExpanded;
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Taxes & Exit Load',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF888898),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${details.taxesAndExitLoad.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _isTaxesExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF0060A6),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Expanded Tax Details
                            if (_isTaxesExpanded) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    _buildTaxDetailRow('Exit Load', details.exitLoad),
                                    const SizedBox(height: 8),
                                    _buildTaxDetailRow('LTCG', details.ltcg),
                                    const SizedBox(height: 8),
                                    _buildTaxDetailRow('Tax on LTCG', details.taxOnLtcg),
                                    const SizedBox(height: 8),
                                    _buildTaxDetailRow('STCG', details.stcg),
                                    const SizedBox(height: 8),
                                    _buildTaxDetailRow('Tax on STCG', details.taxOnStcg),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        loading: () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Taxes & Exit Load',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888898),
                              ),
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0060A6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isTaxesExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        error: (error, stack) => GestureDetector(
                          onTap: () {
                            // Retry fetching
                            ref.read(redeemDetailsProvider.notifier).fetchRedeemDetails(
                              fundId: widget.fundId,
                              folioNo: widget.folioNo,
                              bseClientId: widget.bseClientId,
                              redeem: widget.redeemType,
                              redeemBy: widget.redeemBy,
                              amount: widget.value,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Taxes & Exit Load',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF888898),
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Tap to retry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Continue Button
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
                print('📘 Redeem Continue button pressed');

                // Validation
                if (widget.redeemBy == 'amount' && widget.value > widget.availableAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Amount cannot exceed ₹${NumberFormat('#,##,##0.00').format(widget.availableAmount)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (widget.redeemBy == 'units' && widget.value > widget.availableUnits) {
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

                print('📤 Redeem: Sending OTP for clientId: ${widget.clientId}');
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

  Widget _buildTaxDetailRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6C757D),
          ),
        ),
        Text(
          '₹${NumberFormat('#,##,##0.00').format(value)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}