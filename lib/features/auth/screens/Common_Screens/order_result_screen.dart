import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../providers/otp_provider.dart';
import '../../../../../providers/redeem_confirmed_provider.dart';
import '../../../../../providers/switch_order_provider.dart';
import '../../../../../providers/stp_order_provider.dart';

class OrderResultScreen extends ConsumerStatefulWidget {
  final bool? isLoading;
  final bool? isSuccess;
  final String? orderId;
  final String? bseClientId;
  final String fundName;
  final double amount;
  final String bankName;
  final String accountNo;
  final String? errorMessage;
  final String? transactionType;
  final String? frequency;
  final int? noOfInstallments;
  final bool? firstOrder;
  final String? swpDate;
  final String? stpDate;
  final String? fromFundName;
  final String? toFundName;
  final bool? isAmount;
  final String? displayValue;
  final int? fundIdFrom;
  final int? fundIdTo;
  final String? switchBy;
  final String? switchTo;
  final String? transferBy;
  final int? fundId;
  final String? folioNo;
  final String? redeemType;
  final String? redeemBy;
  final String? otp;
  final Map<String, dynamic>? redemptionData;

  const OrderResultScreen({
    super.key,
    this.isLoading,
    this.isSuccess,
    this.orderId,
    this.bseClientId,
    required this.fundName,
    required this.amount,
    required this.bankName,
    required this.accountNo,
    this.errorMessage,
    this.transactionType,
    this.frequency,
    this.noOfInstallments,
    this.firstOrder,
    this.swpDate,
    this.stpDate,
    this.fundId,
    this.folioNo,
    this.redeemType,
    this.redeemBy,
    this.otp,
    this.redemptionData,
    this.fromFundName,
    this.toFundName,
    this.isAmount,
    this.displayValue,
    this.fundIdFrom,
    this.fundIdTo,
    this.switchBy,
    this.switchTo,
    this.transferBy,
  });

  @override
  ConsumerState<OrderResultScreen> createState() => _OrderResultScreenState();
}

class _OrderResultScreenState extends ConsumerState<OrderResultScreen> {
  bool _isProcessing = false;
  bool _orderPlaced = false;
  String? _finalOrderId;
  String? _finalBseClientId;
  bool? _finalSuccess;
  String? _finalErrorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.isLoading == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _placeOrder();
      });
    } else {
      _orderPlaced = true;
      _finalSuccess = widget.isSuccess;
      _finalOrderId = widget.orderId;
      _finalBseClientId = widget.bseClientId;
      _finalErrorMessage = widget.errorMessage;
    }
  }

  Future<void> _placeOrder() async {
    try {
      print('========== PLACE ORDER ==========');
      print('📦 Transaction Type: ${widget.transactionType}');
      print('📦 Redeem Type: ${widget.redeemType}');
      print('=================================');

      final transType = widget.transactionType?.toLowerCase();

      if (transType == 'stp') {
        print('✅ Detected STP transaction - calling _placeStpOrder');
        await _placeStpOrder();
      } else if (transType == 'switch') {
        print('✅ Detected Switch transaction - calling _placeSwitchOrder');
        await _placeSwitchOrder();
      } else if (widget.redeemType == 'SWP') {
        print('✅ Detected SWP transaction - calling _placeSwpOrder');
        await _placeSwpOrder();
      } else {
        print('✅ Detected Redeem transaction - calling _placeRedeemOrder');
        await _placeRedeemOrder();
      }
    } catch (e, st) {
      print('❌ Order placement error: $e');
      print('Stack trace: $st');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _orderPlaced = true;
          _finalSuccess = false;
          _finalErrorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _placeStpOrder() async {
    print('========== PLACING STP ORDER ==========');

    if (widget.fundIdFrom == null ||
        widget.fundIdTo == null ||
        widget.folioNo == null ||
        widget.folioNo!.isEmpty ||
        widget.frequency == null ||
        widget.stpDate == null ||
        widget.noOfInstallments == null ||
        widget.bseClientId == null ||
        widget.firstOrder == null ||
        widget.transferBy == null) {
      throw Exception('Missing required STP parameters');
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(widget.stpDate!)) {
      throw Exception('Invalid date format. Expected yyyy-MM-dd');
    }

    await ref.read(stpOrderProvider.notifier).placeStpOrder(
      fundIdFrom: widget.fundIdFrom!,
      fundIdTo: widget.fundIdTo!,
      folioNo: widget.folioNo!,
      amount: widget.amount,
      frequency: widget.frequency!.toLowerCase(),
      stpDate: widget.stpDate!,
      noOfInstallments: widget.noOfInstallments!,
      bseClientId: widget.bseClientId!,
      firstOrder: widget.firstOrder!,
      transferBy: widget.transferBy!,
    );

    final orderState = ref.read(stpOrderProvider);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
      _finalSuccess = orderState.isSuccess;
      _finalOrderId = orderState.orderId;
      _finalBseClientId = widget.bseClientId;
      _finalErrorMessage = orderState.errorMessage;
    });

    print('🔥 STP Order Result: Success=${orderState.isSuccess}, OrderID=${orderState.orderId}');
  }

  Future<void> _placeSwitchOrder() async {
    print('========== PLACING SWITCH ORDER ==========');

    final otpState = ref.read(redemptionOtpProvider);
    final verifiedToken = otpState.verifiedAccessToken;

    if (verifiedToken == null) {
      throw Exception('Verified token not found');
    }

    await ref.read(switchOrderProvider.notifier).placeSwitchOrder(
      fundIdFrom: widget.fundIdFrom!,
      fundIdTo: widget.fundIdTo!,
      folioNo: widget.folioNo!,
      bseClientId: widget.bseClientId ?? '',
      switchBy: widget.switchBy!,
      switchTo: widget.switchTo!,
      value: widget.amount,
      verifiedToken: verifiedToken,
    );

    final orderState = ref.read(switchOrderProvider);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
      _finalSuccess = orderState.isSuccess;
      _finalOrderId = orderState.orderId;
      _finalBseClientId = widget.bseClientId;
      _finalErrorMessage = orderState.errorMessage;
    });
  }

  Future<void> _placeSwpOrder() async {
    print('========== PLACING SWP ORDER ==========');

    final frequency = widget.redemptionData?['frequency'] as String? ?? '';
    final swpDate = widget.redemptionData?['swpDate'] as String? ?? '';
    final noOfInstallments = widget.redemptionData?['noOfInstallments'] as int? ?? 0;
    final firstOrder = widget.redemptionData?['firstOrder'] as bool? ?? false;

    final otpState = ref.read(redemptionOtpProvider);
    final otpToUse = widget.otp ?? otpState.otp;

    if (otpToUse == null || otpToUse.isEmpty) {
      throw Exception('OTP not found');
    }

    await ref.read(redeemOrderProvider.notifier).placeRedeemOrder(
      fundId: widget.fundId!,
      folioNo: widget.folioNo!,
      bseClientId: widget.bseClientId ?? '',
      redeem: 'SWP',
      redeemBy: widget.redeemBy!,
      amount: widget.amount,
      otp: otpToUse,
      redemptionData: {
        'frequency': frequency,
        'swpDate': swpDate,
        'noOfInstallments': noOfInstallments,
        'firstOrder': firstOrder,
      },
      verifiedToken: otpState.verifiedAccessToken,
    );

    final orderState = ref.read(redeemOrderProvider);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
      _finalSuccess = orderState.isSuccess;
      _finalOrderId = orderState.orderId;
      _finalBseClientId = orderState.bseClientId;
      _finalErrorMessage = orderState.errorMessage;
    });
  }

  Future<void> _placeRedeemOrder() async {
    print('========== PLACING REDEEM ORDER ==========');

    final otpState = ref.read(redemptionOtpProvider);
    final verifiedToken = otpState.verifiedAccessToken;

    await ref.read(redeemOrderProvider.notifier).placeRedeemOrder(
      fundId: widget.fundId!,
      folioNo: widget.folioNo!,
      bseClientId: widget.bseClientId ?? '',
      redeem: widget.redeemType!,
      redeemBy: widget.redeemBy!,
      amount: widget.amount,
      otp: widget.otp!,
      redemptionData: widget.redemptionData,
      verifiedToken: verifiedToken,
    );

    final orderState = ref.read(redeemOrderProvider);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
      _finalSuccess = orderState.isSuccess;
      _finalOrderId = orderState.orderId;
      _finalBseClientId = orderState.bseClientId;
      _finalErrorMessage = orderState.errorMessage;
    });
  }

  bool get _isSwp => widget.transactionType?.toLowerCase() == 'swp';
  bool get _isSwitch => widget.transactionType?.toLowerCase() == 'switch';
  bool get _isStp => widget.transactionType?.toLowerCase() == 'stp';

  String get _successTitle {
    if (_isStp) return 'STP order has been placed';
    if (_isSwitch) return 'Switch Order Placed';
    if (_isSwp) return 'SWP request has been placed';
    return 'Redemption request has been placed';
  }

  String get _errorTitle {
    if (_isStp) return 'STP order cannot be placed';
    if (_isSwitch) return 'Order Failed';
    if (_isSwp) return 'SWP order cannot be placed';
    return 'Redemption request cannot be placed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/portfolio');
            }
          },
        ),
        title: Text(
          _finalSuccess == false ? 'Order Failed' : 'Order Summary',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isProcessing || !_orderPlaced
                    ? _buildLoadingState()
                    : _buildContent(),
              ),
            ),
            if (_orderPlaced) _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Main Result Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Status Icon
              SvgPicture.asset(
                _finalSuccess == true
                    ? AppStrings.success_icon
                    : AppStrings.error_icon,
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _finalSuccess == true ? _successTitle : _errorTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              // Error Message (only for failed orders)
              if (_finalSuccess == false && _finalErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _finalErrorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Fund Display Section (show for both success and failure)
              const SizedBox(height: 24),
              if (_isSwitch || _isStp)
                _buildTransferFundSection()
              else
                _buildSingleFundSection(),
            ],
          ),
        ),

        // Details Card (show for both success and failure)
        const SizedBox(height: 16),
        _buildDetailsCard(),
      ],
    );
  }

  Widget _buildTransferFundSection() {
    return Column(
      children: [
        // From Fund
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isStp ? 'STP out from' : 'Switch out from',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888898),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.fromFundName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Arrow Divider
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
                  color: Colors.white,
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

        // To Fund
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isStp ? 'STP in to' : 'Switch in to',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888898),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.toFundName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleFundSection() {
    final displayFundName = _isSwp
        ? (widget.redemptionData?['fundName'] ?? widget.fundName)
        : widget.fundName;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,

          child: Image.asset(
            AppStrings.iconFunds_png,
            color: Colors.white,
            width: 24,height: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayFundName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Amount/Units
          _buildDetailRow(
            _isSwitch
                ? (widget.isAmount == true ? 'Amount' : 'Units')
                : 'Amount',
            _isSwitch
                ? (widget.displayValue ?? _formatCurrency(widget.amount))
                : _formatCurrency(widget.amount),
          ),

          // STP/SWP Specific Fields
          if (_isStp || _isSwp) ...[
            if (widget.frequency != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Frequency', _capitalizeFirst(widget.frequency!)),
            ],
            if (_isStp && widget.stpDate != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('STP Date', _formatDate(widget.stpDate!)),
            ],
            if (_isSwp && widget.swpDate != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('SWP Date', _formatDate(widget.swpDate!)),
            ],
            if (widget.noOfInstallments != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Number of Installments', widget.noOfInstallments.toString()),
            ],
            if (widget.firstOrder != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('First Order Today', widget.firstOrder! ? 'Yes' : 'No'),
            ],
          ],

          // BSE Client ID
          if (_finalBseClientId != null && _finalBseClientId!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow('BSE Client ID', _finalBseClientId!),
          ],

          // Bank details (not for switch/stp)
          if (!_isSwitch && !_isStp) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Bank', widget.bankName),
            const SizedBox(height: 16),
            _buildDetailRow('Account No.', _formatAccountNumber(widget.accountNo)),
          ],

          // Order ID (only show on success)
          if (_finalSuccess == true && _finalOrderId != null && _finalOrderId!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Order ID', _finalOrderId!),
          ],
        ],
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

  Widget _buildBottomButtons() {
    return Container(
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
        child: _finalSuccess == true
            ? Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/orders'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0060A6), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Order Details',
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
                onPressed: () => context.go('/portfolio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        )
            : SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/portfolio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060A6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Back to Portfolio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${NumberFormat('#,##,##0.##').format(amount)}';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      if (date.contains('-')) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _formatAccountNumber(String accountNo) {
    if (accountNo.length <= 4) return accountNo;
    return 'XX XXXX ${accountNo.substring(accountNo.length - 4)}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}