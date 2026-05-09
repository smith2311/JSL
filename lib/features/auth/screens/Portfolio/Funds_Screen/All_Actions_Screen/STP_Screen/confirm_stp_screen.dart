import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/otp_provider.dart';

class StpConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> confirmData;

  const StpConfirmScreen({
    super.key,
    required this.confirmData,
  });

  @override
  ConsumerState<StpConfirmScreen> createState() => _StpConfirmScreenState();
}

class _StpConfirmScreenState extends ConsumerState<StpConfirmScreen> {
  bool _agreeToTerms = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionOtpProvider.notifier).reset();
      print('🧹 STP Confirm Screen: Initial OTP reset');
    });

    print('========== STP CONFIRM SCREEN INIT ==========');
    print('📋 Received confirmData:');
    widget.confirmData.forEach((key, value) {
      print('   $key: $value (${value.runtimeType})');
    });
    print('============================================');

    _validateRequiredFields();
  }

  void _validateRequiredFields() {
    final requiredFields = [
      'fund_id_from',
      'fund_id_to',
      'folio_no',
      'amount',
      'frequency',
      'stp_date',
      'no_of_installments',
      'bse_client_id',
      'first_order',
      'transfer_by',
      'client_id', // For OTP
    ];

    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (!widget.confirmData.containsKey(field) ||
          widget.confirmData[field] == null ||
          (widget.confirmData[field] is String && (widget.confirmData[field] as String).isEmpty)) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      print('❌ MISSING REQUIRED FIELDS: ${missingFields.join(", ")}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog('Missing required data: ${missingFields.join(", ")}');
      });
    } else {
      print('✅ All required fields present');
    }
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

    // Extract client_id for OTP
    final clientId = widget.confirmData['client_id'] as String?;
    final bseClientId = widget.confirmData['bse_client_id'] as String?;

    print('🔍 STP: Extracted IDs - client_id: $clientId, bse_client_id: $bseClientId');

    if (clientId == null || clientId.isEmpty) {
      _showError('Client ID is missing');
      return;
    }

    if (bseClientId == null || bseClientId.isEmpty) {
      _showError('BSE Client ID is missing');
      return;
    }

    final clientIdInt = int.tryParse(clientId);
    if (clientIdInt == null) {
      _showError('Invalid Client ID');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    print('📤 STP: Sending OTP for clientId: $clientIdInt');

    // Send OTP
    await ref.read(redemptionOtpProvider.notifier).sendOtp(clientId: clientIdInt);

    final otpState = ref.read(redemptionOtpProvider);

    if (!mounted) return;

    if (otpState.otpSent) {
      print('✅ STP: OTP sent successfully, navigating to OTP screen...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpState.getOtpSentMessage()),
          backgroundColor: const Color(0xFF00A651),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Prepare complete STP data
      final stpDataToPass = {
        'fund_id_from': widget.confirmData['fund_id_from'],
        'fund_id_to': widget.confirmData['fund_id_to'],
        'folio_no': widget.confirmData['folio_no'],
        'amount': widget.confirmData['amount'],
        'frequency': widget.confirmData['frequency'],
        'stp_date': widget.confirmData['stp_date'],
        'no_of_installments': widget.confirmData['no_of_installments'],
        'bse_client_id': bseClientId,
        'first_order': widget.confirmData['first_order'],
        'transfer_by': widget.confirmData['transfer_by'],
        'fromFundName': widget.confirmData['fromFundName'],
        'toFundName': widget.confirmData['toFundName'],
        'displayValue': widget.confirmData['displayValue'],
      };

      print('📦 STP Data to pass to OTP screen:');
      stpDataToPass.forEach((key, value) {
        print('   $key: $value');
      });

      // Navigate to OTP screen with STP-specific data
      print('📤 ABOUT TO NAVIGATE - Extra map:');
      final extraMap = {
        'clientId': clientIdInt,
        'redemptionData': {
          'fundName': widget.confirmData['fromFundName'] ?? '',
        },
        'transactionType': 'stp',
        'stpData': stpDataToPass,
      };
      extraMap.forEach((key, value) {
        if (value is Map) {
          print('   $key: {Map with ${(value as Map).length} keys}');
        } else {
          print('   $key: $value');
        }
      });
      await context.push('/redemption-otp', extra: extraMap);

      // User returned from OTP screen
      if (mounted) {
        print('🔙 STP: User returned from OTP screen - Resetting');
        ref.read(redemptionOtpProvider.notifier).reset();
        setState(() {
          _isProcessing = false;
        });
      }
    } else if (otpState.errorMessage != null) {
      print('❌ STP: Error sending OTP: ${otpState.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final redemptionOtpState = ref.watch(redemptionOtpProvider);
    final fromFundName = widget.confirmData['fromFundName'] ?? '';
    final toFundName = widget.confirmData['toFundName'] ?? '';
    final displayValue = widget.confirmData['displayValue'] ?? '';
    final transferBy = widget.confirmData['transfer_by'] ?? 'amount';
    final frequency = widget.confirmData['frequency'] ?? '';
    final stpDate = widget.confirmData['stp_date'] ?? '';
    final noOfInstallments = widget.confirmData['no_of_installments'] ?? 0;
    final firstOrder = widget.confirmData['first_order'] ?? false;
    final bseClientId = widget.confirmData['bse_client_id'] ?? '';
    final clientName = widget.confirmData['clientName'] ?? '';

    // Format date from yyyy-MM-dd to dd/MM/yyyy
    String formattedDate = stpDate;
    if (stpDate.contains('-')) {
      final parts = stpDate.split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    // Capitalize frequency
    String capitalizedFrequency = frequency.isNotEmpty
        ? frequency[0].toUpperCase() + frequency.substring(1)
        : '';

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
          'STP Funds',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fund Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildFundItem(
                          label: 'STP out from',
                          fundName: fromFundName,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildFundItem(
                          label: 'STP in to',
                          fundName: toFundName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STP Details Card
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
                          'STP Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          transferBy == 'amount' ? 'Amount' : 'Units',
                          displayValue,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Frequency', capitalizedFrequency),
                        const SizedBox(height: 16),
                        _buildDetailRow('STP Date', formattedDate),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Number of Installments',
                          noOfInstallments.toString(),
                        ),
                        if (firstOrder) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('First Order Today', 'Yes'),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailRow('BSE Client ID', bseClientId),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms Checkbox
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
                            onChanged: _isProcessing
                                ? null
                                : (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF0060A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isProcessing
                                ? null
                                : () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to '),
                                  TextSpan(
                                    text: 'terms and conditions',
                                    style: TextStyle(
                                      color: Color(0xFF0060A6),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                    ' and I have read all scheme related documents',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.black54,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Systematic Transfer of ',
                                ),
                                TextSpan(
                                  text: clientName.isNotEmpty
                                      ? clientName
                                      : 'Client',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' investment will be withdrawn from ',
                                ),
                                TextSpan(
                                  text: fromFundName.split(' ').take(3).join(' '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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

          // Confirm Button
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
                  onPressed: (_agreeToTerms && !_isProcessing)
                      ? _proceedToOtp
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing || redemptionOtpState.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _agreeToTerms
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888898),
          ),
        ),
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
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fundName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(width: 16),
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
}