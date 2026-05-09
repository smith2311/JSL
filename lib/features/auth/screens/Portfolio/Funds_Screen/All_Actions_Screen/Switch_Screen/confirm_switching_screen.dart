import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/otp_provider.dart';

class SwitchConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> confirmData;

  const SwitchConfirmScreen({
    super.key,
    required this.confirmData,
  });

  @override
  ConsumerState<SwitchConfirmScreen> createState() => _SwitchConfirmScreenState();
}

class _SwitchConfirmScreenState extends ConsumerState<SwitchConfirmScreen> {
  bool _agreeToTerms = false;
  bool _hasNavigatedToOtp = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionOtpProvider.notifier).reset();
      print('🧹 Switch Confirm Screen: Initial OTP reset');
    });

    print('📋 SwitchConfirmScreen received data:');
    widget.confirmData.forEach((key, value) {
      print('   $key: $value');
    });
  }

  void _proceedToOtp() async {
    if (_isProcessing) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clientId = widget.confirmData['clientId'] as String? ?? '';
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clientIdInt = int.tryParse(clientId);
    if (clientIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Client ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasNavigatedToOtp = true;
    });

    print('📤 Switch: Sending OTP for clientId: $clientIdInt');

    // Send OTP
    await ref.read(redemptionOtpProvider.notifier).sendOtp(clientId: clientIdInt);

    // Check if OTP was sent successfully
    final otpState = ref.read(redemptionOtpProvider);

    if (!mounted) return;

    if (otpState.otpSent) {
      print('✅ Switch: OTP sent successfully, navigating...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpState.getOtpSentMessage()),
          backgroundColor: const Color(0xFF00A651),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      final switchData = {
        'fromFundId': widget.confirmData['fromFundId'] as int,
        'fromFundName': widget.confirmData['fromFundName'] as String,
        'toFundId': widget.confirmData['toFundId'] as int,
        'toFundName': widget.confirmData['toFundName'] as String,
        'folioNo': widget.confirmData['folioNo'] as String,
        'bseClientCode': widget.confirmData['bseClientCode'] as String, // ✅ Keep this key
        'bseClientId': widget.confirmData['bseClientCode'] as String,   // ✅ Also add this for compatibility
        'isAmount': widget.confirmData['isAmount'] as bool,
        'value': widget.confirmData['value'] as double,
        'displayValue': widget.confirmData['displayValue'] as String,
        'switchBy': widget.confirmData['isAmount'] == true ? 'amount' : 'units',
        'switchTo': widget.confirmData['switchAll'] == true ? 'full' : 'partial',
      };

      print('📦 Switch data being passed to OTP:');
      switchData.forEach((key, value) {
        print('   $key: $value');
      });

      // Navigate and handle return
      await context.push('/redemption-otp', extra: {
        'clientId': clientIdInt,
        'redemptionData': {
          'fundName': widget.confirmData['fromFundName'] ?? '',
          'bankName': '',
          'accountNo': '',
        },
        'fundId': widget.confirmData['fromFundId'] ?? 0,
        'folioNo': widget.confirmData['folioNo'] ?? '',
        'bseClientId': widget.confirmData['bseClientCode'] ?? '',
        'redeemType': 'SWITCH',
        'redeemBy': widget.confirmData['isAmount'] == true ? 'amount' : 'units',
        'amount': widget.confirmData['value'] ?? 0.0,
        'transactionType': 'switch',
        'switchData': switchData,
      });

      // User returned from OTP screen - reset everything
      if (mounted) {
        print('🔙 Switch: User returned from OTP screen - Resetting');
        ref.read(redemptionOtpProvider.notifier).reset();
        setState(() {
          _hasNavigatedToOtp = false;
          _isProcessing = false;
        });
      }
    } else if (otpState.errorMessage != null) {
      print('❌ Switch: Error sending OTP: ${otpState.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _hasNavigatedToOtp = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final redemptionOtpState = ref.watch(redemptionOtpProvider);
    final fromFundName = widget.confirmData['fromFundName'] ?? '';
    final toFundName = widget.confirmData['toFundName'] ?? '';
    final isAmount = widget.confirmData['isAmount'] as bool? ?? true;
    final displayValue = widget.confirmData['displayValue'] ?? '';
    final bseId = widget.confirmData['bseId'] ?? '';
    final clientName = widget.confirmData['clientName'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isProcessing ? null : () => context.pop(),
        ),
        title: const Text(
          'Confirm Switch',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fund Switch Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildFundItem(label: 'Switch out from', fundName: fromFundName),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                ),
                                child: const Icon(Icons.arrow_downward, color: Colors.black, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                            ],
                          ),
                        ),
                        _buildFundItem(label: 'Switch in to', fundName: toFundName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(isAmount ? 'Amount' : 'Units', displayValue),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                        _buildDetailRow('BSE ID', bseId),
                        const SizedBox(height: 16),
                        _buildDetailRow('Client Name', clientName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The switch order will be processed and the units will be transferred to the new fund.',
                            style: TextStyle(fontSize: 14, color: Color(0xFF856404), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: _isProcessing ? null : (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF0060A6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isProcessing ? null : () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 14, color: Colors.black, height: 1.5),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: Color(0xFF0060A6),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' for switching funds'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Continue Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreeToTerms && !_isProcessing) ? _proceedToOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing || redemptionOtpState.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _agreeToTerms ? Colors.white : Colors.grey[600],
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

  Widget _buildFundItem({required String label, required String fundName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888898))),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppStrings.iconFunds_png,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.diamond, color: Colors.white, size: 16),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fundName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}