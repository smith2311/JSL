import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/portf_fund_detail_redeem_provider.dart';
import '../../../../../../../../providers/redeem_confirmed_provider.dart';
import '../../../../../../../../widgets/custom_text_dropdown.dart';
import '../../../../../../../../widgets/custom_tab_button.dart';
import '../../../../../../../../features/auth/data/models/swp_constraint.dart';
import '../../../../../../../../features/auth/data/models/swp_frequency.dart';
import '../../../../../../../constants/messages.dart';

class PortfolioFundsDialogSwpScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String folioNo;
  final String clientId;

  const PortfolioFundsDialogSwpScreen({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.clientId,
  });

  @override
  ConsumerState<PortfolioFundsDialogSwpScreen> createState() => _PortfolioFundsDialogSwpScreenState();
}

class _PortfolioFundsDialogSwpScreenState extends ConsumerState<PortfolioFundsDialogSwpScreen> {
  BseAccount? selectedBseAccount;
  bool bseAccountsFetched = false;

  int _selectedFrequencyIndex = 0;
  String? _selectedFrequency;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();
  bool _payFirstInstallment = false;
  String? _installmentsValidationMessage;
  String? _inputValidationMessage;

  @override
  void initState() {
    super.initState();

    // 🔥 CRITICAL FIX: Reset providers to prevent state interference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidate both form and details providers to clear redemption state
      ref.invalidate(redeemFormProvider);
      ref.invalidate(redeemDetailsProvider);

      print('🧹 SWP Screen: Cleared redemption state');
    });

    Future.microtask(() {
      // Only fetch what's needed for SWP
      ref.read(redeemBseAccountProvider.notifier).fetchAccounts(widget.clientId);
      ref.read(swpFrequencyProvider.notifier).fetchFrequencies(widget.fundId);
      bseAccountsFetched = true;

      print('✅ SWP Screen: Fetched BSE accounts and SWP frequencies');
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(int index, List<String> frequencies) {
    setState(() {
      _selectedFrequencyIndex = index;
      _selectedFrequency = frequencies[index];
      _dateController.clear();
      _installmentsController.clear();
      _inputValidationMessage = null;
    });

    ref.read(swpConstraintProvider.notifier)
        .fetchSwpConstraint(widget.fundId, _selectedFrequency!).then((_) {
      final constraintAsync = ref.read(swpConstraintProvider);
      constraintAsync.whenData((constraint) {
        if (!_payFirstInstallment) {
          _installmentsController.text = constraint.minInstallments.toString();
        }
      });
    });
  }

  void _validateInstallments(SwpConstraint constraint) {
    final text = _installmentsController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _installmentsValidationMessage = 'Number of installments cannot be empty';
      });
      return;
    }

    final value = int.tryParse(text);
    if (value == null) {
      setState(() {
        _installmentsValidationMessage = 'Invalid number';
      });
      return;
    }

    if (value < constraint.minInstallments) {
      setState(() {
        _installmentsValidationMessage = 'Cannot be less than ${constraint.minInstallments}';
      });
      return;
    }

    if (value > constraint.maxInstallments) {
      setState(() {
        _installmentsValidationMessage = 'Cannot be more than ${constraint.maxInstallments}';
      });
      return;
    }

    setState(() {
      _installmentsValidationMessage = null;
    });
  }

  void _validateInput(String value, SwpConstraint constraint, bool isAmountMode, double maxValue) {
    final text = value.trim();

    if (text.isEmpty) {
      setState(() {
        _inputValidationMessage = 'Please enter a value';
      });
      return;
    }

    final inputValue = double.tryParse(text);
    if (inputValue == null) {
      setState(() {
        _inputValidationMessage = 'Invalid number';
      });
      return;
    }

    if (inputValue < constraint.minAmount) {
      setState(() {
        _inputValidationMessage = isAmountMode
            ? 'Cannot be less than ${constraint.minAmount.toStringAsFixed(0)} units'
            : 'Cannot be less than ₹${NumberFormat('#,##,##0').format(constraint.minAmount)}';
      });
      return;
    }

    if (inputValue > maxValue) {
      setState(() {
        _inputValidationMessage = isAmountMode
            ? 'Cannot exceed ${maxValue.toStringAsFixed(0)} units'
            : 'Cannot exceed ₹${NumberFormat('#,##,##0').format(maxValue)}';
      });
      return;
    }

    setState(() {
      _inputValidationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fundDetailState = ref.watch(
      portfolioFundDetailProvider(
        FundDetailParams(fundId: widget.fundId, folioNo: widget.folioNo),
      ),
    );

    final frequenciesAsync = ref.watch(swpFrequencyProvider);

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
          'SWP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: fundDetailState.when(
        data: (fundDetail) {
          print('📊 SWP Screen: Fund details loaded - ${fundDetail.fundName}');
          return frequenciesAsync.when(
            data: (frequencies) {
              if (_selectedFrequency == null && frequencies.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _selectedFrequency = frequencies[0];
                  });
                  ref.read(swpConstraintProvider.notifier)
                      .fetchSwpConstraint(widget.fundId, frequencies[0])
                      .then((_) {
                    final constraintAsync = ref.read(swpConstraintProvider);
                    constraintAsync.whenData((constraint) {
                      if (!_payFirstInstallment) {
                        _installmentsController.text = constraint.minInstallments.toString();
                      }
                    });
                  });
                });
              }

              return _buildContent(context, ref, fundDetail, frequencies);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0060A6)),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading frequencies: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                ErrorMessages.errorLoadingFundDetails,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      fundDetail,
      List<String> frequencies) {
    final formState = ref.watch(redeemFormProvider);
    final swpConstraintAsync = ref.watch(swpConstraintProvider);
    final availableAmount = (fundDetail.current is int)
        ? (fundDetail.current as int).toDouble()
        : fundDetail.current as double;

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
                              fundDetail.fundName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.avl_units,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888898),
                            ),
                          ),
                          Text(
                            fundDetail.balanceUnits.toStringAsFixed(3),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.avl_amt,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888898),
                            ),
                          ),
                          Text(
                            '₹${NumberFormat('#,##,##0.00').format(availableAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bank Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        AppStrings.bob_icon,
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'XX XXXX ${fundDetail.accountNo.length >= 4 ? fundDetail.accountNo.substring(fundDetail.accountNo.length - 4) : fundDetail.accountNo}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fundDetail.bankName,
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

                // Amount Input Container
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
                      // Toggle Buttons (Amount/Units)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (formState.isAmountMode) {
                                    ref.read(redeemFormProvider.notifier).toggleMode();
                                    setState(() {
                                      _inputValidationMessage = null;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: !formState.isAmountMode
                                        ? const Color(0xFF0060A6)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.amt,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !formState.isAmountMode
                                            ? Colors.white
                                            : const Color(0xFF888898),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!formState.isAmountMode) {
                                    ref.read(redeemFormProvider.notifier).toggleMode();
                                    setState(() {
                                      _inputValidationMessage = null;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: formState.isAmountMode
                                        ? const Color(0xFF0060A6)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.units,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: formState.isAmountMode
                                            ? Colors.white
                                            : const Color(0xFF888898),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Amount/Units Input
                      Text(
                        formState.isAmountMode ? AppStrings.units : AppStrings.amt,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888898),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!formState.isAmountMode)
                            const Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          IntrinsicWidth(
                            child: swpConstraintAsync.when(
                              data: (constraint) {
                                double maxValue;
                                if (formState.isAmountMode) {
                                  maxValue = fundDetail.balanceUnits < constraint.maxAmount
                                      ? fundDetail.balanceUnits
                                      : constraint.maxAmount;
                                } else {
                                  maxValue = availableAmount < constraint.maxAmount
                                      ? availableAmount
                                      : constraint.maxAmount;
                                }
                                return TextField(
                                  controller: TextEditingController(text: formState.inputValue)
                                    ..selection = TextSelection.collapsed(
                                        offset: formState.inputValue.length),
                                  onChanged: (value) {
                                    ref.read(redeemFormProvider.notifier).updateInputValue(
                                      value,
                                      maxValue: maxValue,
                                    );
                                    _validateInput(value, constraint, formState.isAmountMode, maxValue);
                                  },
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,3}'),
                                    ),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: !formState.isAmountMode ? AppStrings.amt_hint : AppStrings.units_hint,
                                    hintStyle: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                );
                              },
                              loading: () => const CircularProgressIndicator(strokeWidth: 2),
                              error: (e, st) => const Text('Error'),
                            ),
                          ),
                          if (formState.isAmountMode && formState.inputValue.isNotEmpty)
                            Container(
                              width: 2,
                              height: 32,
                              color: Colors.black,
                              margin: const EdgeInsets.only(left: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: _inputValidationMessage != null || formState.errorMessage != null
                            ? Colors.red
                            : const Color(0xFFF1F3F5),
                      ),

                      // Min/Max Constraints Display
                      swpConstraintAsync.when(
                        data: (constraint) {
                          double displayMaxValue;
                          if (formState.isAmountMode) {
                            displayMaxValue = fundDetail.balanceUnits < constraint.maxAmount
                                ? fundDetail.balanceUnits
                                : constraint.maxAmount;
                          } else {
                            displayMaxValue = availableAmount < constraint.maxAmount
                                ? availableAmount
                                : constraint.maxAmount;
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formState.isAmountMode
                                        ? 'Min: ${constraint.minAmount.toStringAsFixed(0)}'
                                        : 'Min: ₹${NumberFormat('#,##,##0').format(constraint.minAmount)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    formState.isAmountMode
                                        ? 'Max: ${displayMaxValue.toStringAsFixed(0)}'
                                        : 'Max: ₹${NumberFormat('#,##,##0').format(displayMaxValue)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                      // Input Error Message
                      if (_inputValidationMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _inputValidationMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // Existing Form Error Message
                      if (formState.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          formState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SWP Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: swpConstraintAsync.when(
                    data: (constraint) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            frequencies.length,
                                (index) => CustomTabButton(
                              label: frequencies[index],
                              isSelected: _selectedFrequencyIndex == index,
                              onTap: () => _onFrequencyChanged(index, frequencies),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Date of SWP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Select Date',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                AppStrings.calender,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onTap: () => _showDatePicker(context, constraint),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No of Installments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _installmentsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter no of installments',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (_) => _validateInstallments(constraint),
                        ),
                        const SizedBox(height: 8),
                        if (_installmentsValidationMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _installmentsValidationMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Min: ${constraint.minInstallments}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'Max: ${constraint.maxInstallments}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _payFirstInstallment,
                                onChanged: (value) {
                                  setState(() {
                                    _payFirstInstallment = value ?? false;
                                    _dateController.clear();
                                    if (!_payFirstInstallment) {
                                      _installmentsController.text = constraint.minInstallments.toString();
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF0060A6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pay 1st Order Now',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, st) => const Center(
                      child: Text('Failed to load constraints', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // BSE Account Selection Card
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
                        'Select BSE Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, _) {
                          final bseAccountsAsync = ref.watch(redeemBseAccountProvider);

                          return bseAccountsAsync.when(
                            data: (accounts) {
                              if (accounts.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3CD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Color(0xFF856404)),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No BSE accounts found',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF856404),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (selectedBseAccount == null && accounts.isNotEmpty) {
                                Future.microtask(() {
                                  setState(() {
                                    selectedBseAccount = accounts[0];
                                  });
                                });
                              }

                              return CustomDropdownCard(
                                label: '',
                                showLabelInside: false,
                                items: accounts.map((e) => e.displayName).toList(),
                                selectedValue: selectedBseAccount?.displayName,
                                hintText: 'Select BSE Account',
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    selectedBseAccount = accounts.firstWhere(
                                          (acc) => acc.displayName == value,
                                    );
                                  });
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0060A6),
                                ),
                              ),
                            ),
                            error: (e, st) => Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8D7DA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFF721C24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Failed to load BSE accounts: ${e.toString()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF721C24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (selectedBseAccount != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('BSE ID', selectedBseAccount!.bseClientId),
                              const SizedBox(height: 8),
                              _buildDetailRow('Tax Status', selectedBseAccount!.taxStatus),
                              const SizedBox(height: 8),
                              _buildDetailRow('Holding Type', selectedBseAccount!.holdingStatus),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Second Holder Name',
                                selectedBseAccount!.secondHolderName ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Continue Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () {
                print('========== SWP VALIDATION START ==========');

                // Validation 1: BSE Account
                if (selectedBseAccount == null) {
                  print('❌ Validation failed: No BSE account selected');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a BSE account'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validation 2: Date
                if (_dateController.text.trim().isEmpty) {
                  print('❌ Validation failed: No date selected');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select SWP date'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validation 3: Installments
                if (_installmentsController.text.trim().isEmpty) {
                  print('❌ Validation failed: No installments entered');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter number of installments'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validation 4: Input validation message
                if (_inputValidationMessage != null) {
                  print('❌ Validation failed: $_inputValidationMessage');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_inputValidationMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validation 5: Form error message
                if (formState.errorMessage != null) {
                  print('❌ Validation failed: ${formState.errorMessage}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(formState.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validation 6: Installments validation message
                if (_installmentsValidationMessage != null) {
                  print('❌ Validation failed: $_installmentsValidationMessage');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_installmentsValidationMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validation 7: Input value
                if (formState.inputValue.isEmpty) {
                  print('❌ Validation failed: No withdrawal amount');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter withdrawal amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                print('✅ All validations passed');

                // Parse values
                final inputValue = double.parse(formState.inputValue);
                final withdrawalBy = formState.isAmountMode ? 'units' : 'amount';

                // Date conversion: dd/MM/yyyy -> yyyy-MM-dd
                final dateText = _dateController.text.trim();
                String formattedDate;

                try {
                  print('📅 Converting date: $dateText');

                  if (dateText.contains('/')) {
                    // Date is in dd/MM/yyyy format
                    final dateParts = dateText.split('/');

                    if (dateParts.length != 3) {
                      throw Exception('Date must have 3 parts (dd/MM/yyyy)');
                    }

                    final day = dateParts[0].padLeft(2, '0');
                    final month = dateParts[1].padLeft(2, '0');
                    final year = dateParts[2];

                    // Validate year is 4 digits
                    if (year.length != 4) {
                      throw Exception('Year must be 4 digits');
                    }

                    formattedDate = '$year-$month-$day';

                    print('   Day: $day');
                    print('   Month: $month');
                    print('   Year: $year');
                    print('   Result: $formattedDate');
                  } else if (dateText.contains('-')) {
                    // Already in yyyy-MM-dd format
                    formattedDate = dateText;
                    print('   Already in correct format: $formattedDate');
                  } else {
                    throw Exception('Unknown date format');
                  }

                  // Final validation
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(formattedDate)) {
                    throw Exception('Date does not match yyyy-MM-dd pattern');
                  }

                  print('✅ Date converted successfully: $formattedDate');

                } catch (e) {
                  print('❌ Date conversion error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Date error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                print('========== NAVIGATION DATA ==========');
                print('fundId: ${widget.fundId}');
                print('folioNo: ${widget.folioNo}');
                print('bseClientId: ${selectedBseAccount!.bseClientId}');
                print('withdrawalBy: $withdrawalBy');
                print('amount: $inputValue');
                print('frequency: $_selectedFrequency');
                print('swpDate: $formattedDate');
                print('noOfInstallments: ${int.parse(_installmentsController.text.trim())}');
                print('firstOrder: $_payFirstInstallment');
                print('clientId: ${int.tryParse(widget.clientId) ?? 0}');
                print('====================================');

                context.push(
                  '/swp-confirm',
                  extra: {
                    'fundId': widget.fundId,
                    'folioNo': widget.folioNo,
                    'bseClientId': selectedBseAccount!.bseClientId,
                    'withdrawalBy': withdrawalBy,
                    'amount': inputValue,
                    'frequency': _selectedFrequency!,
                    'swpDate': formattedDate,
                    'noOfInstallments': int.parse(_installmentsController.text.trim()),
                    'firstOrder': _payFirstInstallment,
                    'fundName': fundDetail.fundName,
                    'availableUnits': fundDetail.balanceUnits,
                    'availableAmount': availableAmount,
                    'bankName': fundDetail.bankName,
                    'accountNo': fundDetail.accountNo,
                    'clientId': int.tryParse(widget.clientId) ?? 0,
                  },
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0060A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                AppStrings.continue_btn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context, SwpConstraint constraint) async {
    final now = DateTime.now();
    late DateTime minSelectableDate;
    late DateTime displayMonth;

    if (_payFirstInstallment) {
      minSelectableDate = DateTime(now.year, now.month + 1, now.day);
      displayMonth = DateTime(now.year, now.month + 1, 1);
    } else {
      minSelectableDate = DateTime(now.year, now.month, now.day + 2);
      displayMonth = DateTime(now.year, now.month, 1);
    }

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: displayMonth.isAfter(DateTime(
                              minSelectableDate.year, minSelectableDate.month, 1))
                              ? Colors.black
                              : Colors.grey.shade300,
                        ),
                        onPressed: displayMonth.isAfter(DateTime(
                            minSelectableDate.year, minSelectableDate.month, 1))
                            ? () {
                          setDialogState(() {
                            displayMonth = DateTime(
                                displayMonth.year, displayMonth.month - 1, 1);
                          });
                        }
                            : null,
                      ),
                      Text(
                        '${_getMonthName(displayMonth)} ${displayMonth.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0060A6),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.black),
                        onPressed: () {
                          final maxMonth = DateTime(
                              minSelectableDate.year, minSelectableDate.month + 11, 1);
                          if (displayMonth.isBefore(maxMonth)) {
                            setDialogState(() {
                              displayMonth = DateTime(
                                  displayMonth.year, displayMonth.month + 1, 1);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(displayMonth, constraint.frequencyDates, minSelectableDate),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem(color: const Color(0xFF0060A6), label: 'Available'),
                      _buildLegendItem(color: Colors.grey.shade300, label: 'Not Available'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (selectedDate != null) {
      setState(() {
        _dateController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
      });
    }
  }

  Widget _buildCalendarGrid(
      DateTime displayMonth, List<int> availableDates, DateTime minSelectableDate) {
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDayOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: startWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < startWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - startWeekday + 1;
        final currentDate = DateTime(displayMonth.year, displayMonth.month, day);

        final isInAvailableList = availableDates.contains(day);
        final isAfterMinDate = currentDate.isAtSameMomentAs(minSelectableDate) ||
            currentDate.isAfter(minSelectableDate);
        final isSelectable = isInAvailableList && isAfterMinDate;

        return InkWell(
          onTap: isSelectable
              ? () {
            Navigator.pop(context, currentDate);
          }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelectable ? const Color(0xFF0060A6) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelectable ? const Color(0xFF0060A6) : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelectable ? FontWeight.bold : FontWeight.normal,
                  color: isSelectable ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value ?? '-',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}