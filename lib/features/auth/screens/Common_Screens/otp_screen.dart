import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../providers/otp_provider.dart';
import '../../../../../widgets/custom_otp_field.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final int clientId;
  final Map<String, dynamic> redemptionData;
  final int? fundId;
  final String? folioNo;
  final String? bseClientId;
  final String? redeemType;
  final String? redeemBy;
  final double? amount;
  final String? transactionType; // 'stp', 'switch', 'swp', 'redeem'
  final Map<String, dynamic>? switchData;
  final Map<String, dynamic>? stpData; // ✅ NEW: STP specific data

  const OtpScreen({
    super.key,
    required this.clientId,
    required this.redemptionData,
    this.fundId,
    this.folioNo,
    this.bseClientId,
    this.redeemType,
    this.redeemBy,
    this.amount,
    this.transactionType,
    this.switchData,
    this.stpData, // ✅ NEW
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _isVerifying = false;
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();

    print('========== OTP SCREEN INIT ==========');
    print('📋 Transaction Type: ${widget.transactionType}');
    print('📋 Client ID: ${widget.clientId}');
    print('📋 BSE Client ID: ${widget.bseClientId}');

    if (widget.transactionType == 'stp') {
      print('📋 STP Data received:');
      if (widget.stpData != null) {
        widget.stpData?.forEach((key, value) {
          print('   $key: $value');
        });
      } else {
        print('   ❌ stpData is NULL!');
      }
    }
    print('====================================');
  }

  Future<void> _verifyAndProceed() async {
    if (_isVerifying) return;

    final otpState = ref.read(redemptionOtpProvider);

    if (_enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    print('========== OTP VERIFICATION ==========');
    print('🔐 Verifying OTP: ${_enteredOtp.substring(0, 2)}****');
    print('🔐 Transaction Type: ${widget.transactionType}');

    // Update OTP in provider
    ref.read(redemptionOtpProvider.notifier).updateOtp(_enteredOtp);

    // Verify OTP
    await ref.read(redemptionOtpProvider.notifier).verifyOtp();

    final verifiedState = ref.read(redemptionOtpProvider);

    if (!mounted) return;

    if (verifiedState.isVerified) {
      print('✅ OTP verified successfully');
      print('=====================================');

      // Navigate based on transaction type
      if (widget.transactionType == 'stp') {
        _handleStpNavigation();
      } else if (widget.transactionType == 'switch') {
        _handleSwitchNavigation();
      } else if (widget.transactionType == 'swp') {
        _handleSwpNavigation();
      } else {
        _handleRedeemNavigation();
      }
    } else if (verifiedState.errorMessage != null) {
      print('❌ OTP verification failed: ${verifiedState.errorMessage}');
      print('=====================================');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verifiedState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _handleStpNavigation() {
    print('========== STP NAVIGATION ==========');
    print('📤 Navigating to result screen with STP data...');

    final stpData = widget.stpData;

    print('🔍 Checking stpData:');
    print('   stpData is null: ${stpData == null}');
    print('   widget.stpData is null: ${widget.stpData == null}');

    if (stpData == null) {
      print('❌ STP data is null!');
      print('❌ Available widget properties:');
      print('   clientId: ${widget.clientId}');
      print('   transactionType: ${widget.transactionType}');
      print('   fundId: ${widget.fundId}');
      print('   folioNo: ${widget.folioNo}');
      print('   bseClientId: ${widget.bseClientId}');
      _showError('STP data is missing. Please try again.');
      return;
    }

    print('✅ stpData found with ${stpData.length} keys');
    stpData.forEach((key, value) {
      print('   $key: $value (${value.runtimeType})');
    });

    // Validate all required STP fields
    final fundIdFrom = stpData['fund_id_from'];
    final fundIdTo = stpData['fund_id_to'];
    final folioNo = stpData['folio_no'];
    final amount = stpData['amount'];
    final frequency = stpData['frequency'];
    final stpDate = stpData['stp_date'];
    final noOfInstallments = stpData['no_of_installments'];
    final bseClientId = stpData['bse_client_id'];
    final firstOrder = stpData['first_order'];
    final transferBy = stpData['transfer_by'];

    print('🔍 Field Validation:');
    print('   fundIdFrom: $fundIdFrom (${fundIdFrom != null})');
    print('   fundIdTo: $fundIdTo (${fundIdTo != null})');
    print('   folioNo: $folioNo (${folioNo != null})');
    print('   amount: $amount (${amount != null})');
    print('   frequency: $frequency (${frequency != null})');
    print('   stpDate: $stpDate (${stpDate != null})');
    print('   noOfInstallments: $noOfInstallments (${noOfInstallments != null})');
    print('   bseClientId: $bseClientId (${bseClientId != null})');
    print('   firstOrder: $firstOrder (${firstOrder != null})');
    print('   transferBy: $transferBy (${transferBy != null})');

    if (fundIdFrom == null || fundIdTo == null || folioNo == null ||
        amount == null || frequency == null || stpDate == null ||
        noOfInstallments == null || bseClientId == null ||
        firstOrder == null || transferBy == null) {
      print('❌ Missing required STP fields');
      _showError('Missing required STP data. Please try again.');
      return;
    }

    // Convert types if needed
    final fundIdFromInt = fundIdFrom is int ? fundIdFrom : int.tryParse(fundIdFrom.toString());
    final fundIdToInt = fundIdTo is int ? fundIdTo : int.tryParse(fundIdTo.toString());
    final amountDouble = amount is double ? amount : double.tryParse(amount.toString());
    final installmentsInt = noOfInstallments is int ? noOfInstallments : int.tryParse(noOfInstallments.toString());

    if (fundIdFromInt == null || fundIdToInt == null || amountDouble == null || installmentsInt == null) {
      print('❌ Type conversion failed');
      _showError('Invalid data format. Please try again.');
      return;
    }

    print('✅ All validations passed. Navigating...');
    print('===================================');

    context.go('/redemption-result', extra: {
      'isLoading': true,
      'transactionType': 'stp',
      'fundIdFrom': fundIdFromInt,
      'fundIdTo': fundIdToInt,
      'folioNo': folioNo.toString(),
      'amount': amountDouble,
      'frequency': frequency.toString(),
      'stpDate': stpDate.toString(),
      'noOfInstallments': installmentsInt,
      'bseClientId': bseClientId.toString(),
      'firstOrder': firstOrder is bool ? firstOrder : (firstOrder.toString().toLowerCase() == 'true'),
      'transferBy': transferBy.toString(),
      'fromFundName': stpData['fromFundName']?.toString() ?? '',
      'toFundName': stpData['toFundName']?.toString() ?? '',
      'displayValue': stpData['displayValue']?.toString() ?? '',
      'fundName': stpData['fromFundName']?.toString() ?? '',
      'bankName': '',
      'accountNo': '',
    });
  }

  void _handleSwitchNavigation() {
    print('📤 Navigating to result screen with Switch data...');

    // ✅ CRITICAL FIX: Use 'bseClientCode' (not 'bseClientId') to match confirm screen
    final bseClientId = widget.switchData?['bseClientCode'] ?? widget.switchData?['bseClientId'] ?? '';

    print('🔍 Switch data validation:');
    print('   fundIdFrom: ${widget.switchData?['fromFundId']}');
    print('   fundIdTo: ${widget.switchData?['toFundId']}');
    print('   folioNo: ${widget.switchData?['folioNo']}');
    print('   bseClientCode: $bseClientId');

    if (widget.switchData?['fromFundId'] == null || widget.switchData?['toFundId'] == null) {
      _showError('Missing required fund IDs for switch transaction');
      return;
    }

    context.go('/redemption-result', extra: {
      'isLoading': true,
      'transactionType': 'switch',
      'fundIdFrom': widget.switchData!['fromFundId'], // fromFundId, not fundIdFrom
      'fundIdTo': widget.switchData!['toFundId'],     // toFundId, not fundIdTo
      'folioNo': widget.switchData?['folioNo'],
      'bseClientId': bseClientId, // ✅ Fixed key
      'switchBy': widget.switchData?['switchBy'],
      'switchTo': widget.switchData?['switchTo'],
      'amount': widget.switchData?['value'],
      'fromFundName': widget.switchData?['fromFundName'],
      'toFundName': widget.switchData?['toFundName'],
      'isAmount': widget.switchData?['isAmount'],
      'displayValue': widget.switchData?['displayValue'],
      'fundName': widget.switchData?['fromFundName'] ?? '',
      'bankName': '',
      'accountNo': '',
    });
  }

  void _handleSwpNavigation() {
    print('📤 Navigating to result screen with SWP data...');

    context.go('/redemption-result', extra: {
      'isLoading': true,
      'transactionType': 'swp',
      'fundId': widget.fundId,
      'folioNo': widget.folioNo,
      'bseClientId': widget.bseClientId,
      'redeemType': 'SWP',
      'redeemBy': widget.redeemBy,
      'amount': widget.amount,
      'otp': _enteredOtp,
      'redemptionData': widget.redemptionData,
      'fundName': widget.redemptionData['fundName'] ?? '',
      'bankName': widget.redemptionData['bankName'] ?? '',
      'accountNo': widget.redemptionData['accountNo'] ?? '',
      'frequency': widget.redemptionData['frequency'],
      'swpDate': widget.redemptionData['swpDate'],
      'noOfInstallments': widget.redemptionData['noOfInstallments'],
      'firstOrder': widget.redemptionData['firstOrder'],
    });
  }

  void _handleRedeemNavigation() {
    print('📤 Navigating to result screen with Redeem data...');

    context.go('/redemption-result', extra: {
      'isLoading': true,
      'fundId': widget.fundId,
      'folioNo': widget.folioNo,
      'bseClientId': widget.bseClientId,
      'redeemType': widget.redeemType,
      'redeemBy': widget.redeemBy,
      'amount': widget.amount,
      'otp': _enteredOtp,
      'redemptionData': widget.redemptionData,
      'fundName': widget.redemptionData['fundName'] ?? '',
      'bankName': widget.redemptionData['bankName'] ?? '',
      'accountNo': widget.redemptionData['accountNo'] ?? '',
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(redemptionOtpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isVerifying ? null : () => context.pop(),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                otpState.getOtpSentMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CustomOtpField(
                length: 6,
                onChanged: (otp) {
                  setState(() {
                    _enteredOtp = otp;
                  });
                },
                onCompleted: (otp) {
                  setState(() {
                    _enteredOtp = otp;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (otpState.canResend)
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(redemptionOtpProvider.notifier)
                            .resendOtp(clientId: widget.clientId);
                      },
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: Color(0xFF0060A6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend OTP in ${otpState.secondsLeft}s',
                      style: const TextStyle(
                        color: Color(0xFF888898),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_enteredOtp.length == 6 && !_isVerifying)
                      ? _verifyAndProceed
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _enteredOtp.length == 6
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}