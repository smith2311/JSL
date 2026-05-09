import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/portf_fund_detail_redeem_provider.dart';
import '../../../../../../../../providers/otp_provider.dart';
import '../../../../../../../../widgets/custom_text_dropdown.dart';
import '../../../../../../../constants/messages.dart';

class RedeemScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String folioNo;
  final String clientId;

  const RedeemScreen({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.clientId,
  });

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  BseAccount? selectedBseAccount;
  bool bseAccountsFetched = false;
  String? _inputValidationMessage;

  @override
  void initState() {
    super.initState();

    // Reset OTP provider when entering redeem screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redemptionOtpProvider.notifier).reset();
      print('🧹 Redeem Screen: Reset OTP provider');
    });

    Future.microtask(() {
      ref.read(redeemBseAccountProvider.notifier).fetchAccounts(widget.clientId);
      bseAccountsFetched = true;
    });
  }

  void _validateInput(String value, SchemeConstraint? constraint, bool isAmountMode, double maxValue) {
    if (constraint == null) {
      setState(() {
        _inputValidationMessage = 'Constraints not loaded';
      });
      return;
    }

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

    if (isAmountMode) {
      // Units mode
      if (inputValue < constraint.minUnits) {
        setState(() {
          _inputValidationMessage = 'Cannot be less than ${constraint.minUnits.toStringAsFixed(3)} units';
        });
        return;
      }
    } else {
      // Amount mode
      if (inputValue < constraint.minAmount) {
        setState(() {
          _inputValidationMessage = 'Cannot be less than ₹${NumberFormat('#,##,##0').format(constraint.minAmount)}';
        });
        return;
      }
    }

    if (inputValue > maxValue) {
      setState(() {
        _inputValidationMessage = isAmountMode
            ? 'Cannot exceed ${maxValue.toStringAsFixed(3)} units'
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

    final constraintState = ref.watch(schemeConstraintProvider(widget.fundId));

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
          AppStrings.red,
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
          return constraintState.when(
            data: (constraint) => _buildContent(context, ref, fundDetail, constraint),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0060A6)),
            ),
            error: (error, stack) => _buildContent(context, ref, fundDetail, null),
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
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
      SchemeConstraint? constraint,
      ) {
    final formState = ref.watch(redeemFormProvider);
    final availableAmount = (fundDetail.current is int)
        ? (fundDetail.current as int).toDouble()
        : fundDetail.current as double;

    // Calculate effective max values (minimum of available and constraint max)
    final effectiveMaxAmount = constraint != null
        ? (availableAmount < constraint.maxAmount ? availableAmount : constraint.maxAmount)
        : availableAmount;

    final effectiveMaxUnits = constraint != null
        ? (fundDetail.balanceUnits < constraint.maxUnits ? fundDetail.balanceUnits : constraint.maxUnits)
        : fundDetail.balanceUnits;

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
                      const SizedBox(height: 16),
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

                // Toggle Buttons and Input Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Connected Toggle Buttons
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
                      Text(
                        formState.isAmountMode ? AppStrings.units : AppStrings.amt,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888898),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Input Field
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
                            child: TextField(
                              controller: TextEditingController(text: formState.inputValue)
                                ..selection = TextSelection.collapsed(
                                  offset: formState.inputValue.length,
                                ),
                              onChanged: (value) {
                                final maxValue = formState.isAmountMode
                                    ? effectiveMaxUnits
                                    : effectiveMaxAmount;
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
                      // Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: _inputValidationMessage != null || formState.errorMessage != null
                            ? Colors.red
                            : const Color(0xFFF1F3F5),
                      ),

                      // Min/Max Constraints Display
                      if (constraint != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formState.isAmountMode
                                  ? 'Min: ${constraint.minUnits.toStringAsFixed(3)}'
                                  : 'Min: ₹${NumberFormat('#,##,##0').format(constraint.minAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888898),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formState.isAmountMode
                                  ? 'Max: ${effectiveMaxUnits.toStringAsFixed(3)}'
                                  : 'Max: ₹${NumberFormat('#,##,##0').format(effectiveMaxAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888898),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

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

                      const SizedBox(height: 16),
                      // Checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: formState.isRedeemAll,
                            onChanged: (value) {
                              ref.read(redeemFormProvider.notifier).toggleRedeemAll(
                                value ?? false,
                                maxValue: formState.isAmountMode
                                    ? effectiveMaxUnits
                                    : effectiveMaxAmount,
                              );
                              setState(() {
                                _inputValidationMessage = null;
                              });
                            },
                            activeColor: const Color(0xFF0060A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            formState.isAmountMode
                                ? AppStrings.red_all_uni
                                : AppStrings.red_tot_amt,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                      const SizedBox(height: 24),
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
                if (constraint == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading constraints, please wait...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (selectedBseAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a BSE account'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (_inputValidationMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_inputValidationMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final maxValue = formState.isAmountMode
                    ? effectiveMaxUnits
                    : effectiveMaxAmount;

                ref.read(redeemFormProvider.notifier).validateInput(
                  maxValue,
                  !formState.isAmountMode,
                  constraint,
                );

                if (formState.inputValue.isNotEmpty &&
                    double.tryParse(formState.inputValue) != maxValue) {
                  ref.read(redeemFormProvider.notifier).toggleRedeemAll(false);
                }

                if (formState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(formState.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (formState.inputValue.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a redemption value'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final inputValue = double.parse(formState.inputValue);
                final redeemType = formState.isRedeemAll ? 'full' : 'partial';
                final redeemBy = formState.isAmountMode ? 'units' : 'amount';

                print('🚀 Navigating to redeem-confirm with data:');
                print('   Fund ID: ${widget.fundId}');
                print('   Folio No: ${widget.folioNo}');
                print('   BSE Client ID: ${selectedBseAccount!.bseClientId}');
                print('   Redeem Type: $redeemType');
                print('   Redeem By: $redeemBy');
                print('   Value: $inputValue');
                print('   Client ID: ${int.tryParse(widget.clientId) ?? 0}');

                context.push(
                  '/redeem-confirm',
                  extra: {
                    'fundId': widget.fundId,
                    'folioNo': widget.folioNo,
                    'bseClientId': selectedBseAccount!.bseClientId,
                    'redeemType': redeemType,
                    'redeemBy': redeemBy,
                    'value': inputValue,
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