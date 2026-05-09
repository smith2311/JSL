import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/portf_fund_detail_redeem_provider.dart' hide schemeConstraintProvider;
import '../../../../../../../../providers/switch_fund_detail_provider.dart';
import '../../../../../../../../widgets/custom_text_dropdown.dart';

class SwitchFundDetailScreen extends ConsumerStatefulWidget {
  final int fromFundId;
  final String fromFundName;
  final int toFundId;
  final String toFundName;
  final String toFundType;
  final String toFundSubType;
  final double availableUnits;
  final double availableAmount;
  final String folioNo;
  final String clientId;
  final String clientName; // Changed to required to ensure it's always passed

  const SwitchFundDetailScreen({
    super.key,
    required this.fromFundId,
    required this.fromFundName,
    required this.toFundId,
    required this.toFundName,
    required this.toFundType,
    required this.toFundSubType,
    required this.availableUnits,
    required this.availableAmount,
    required this.folioNo,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<SwitchFundDetailScreen> createState() => _SwitchFundDetailScreenState();
}

class _SwitchFundDetailScreenState extends ConsumerState<SwitchFundDetailScreen> {
  bool _isAmountSelected = true;
  BseAccount? selectedBseAccount;
  bool bseAccountsFetched = false;
  bool _switchAll = false;
  String _currentValue = '';
  late TextEditingController _amountController;
  late TextEditingController _unitsController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _unitsController = TextEditingController();
    Future.microtask(() {
      ref.read(redeemBseAccountProvider.notifier).fetchAccounts(widget.clientId);
      bseAccountsFetched = true;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  TextEditingController _getController() {
    return _isAmountSelected ? _amountController : _unitsController;
  }

  double _getEffectiveMax(constraint) {
    if (_isAmountSelected) {
      final apiMax = constraint.maxAmount ?? double.infinity;
      return widget.availableAmount < apiMax ? widget.availableAmount : apiMax;
    } else {
      final apiMax = constraint.maxUnits ?? double.infinity;
      return widget.availableUnits < apiMax ? widget.availableUnits : apiMax;
    }
  }

  void _navigateToConfirmScreen() {
    if (_currentValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount or units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedBseAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a BSE account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final value = double.parse(_currentValue);
    final displayValue = _isAmountSelected
        ? '₹${value.toStringAsFixed(2)}'
        : '${value.toStringAsFixed(3)} Units';

    final confirmData = {
      'clientName': widget.clientName, // Ensure clientName is passed
      'clientId': widget.clientId,
      'bseClientCode': selectedBseAccount!.bseClientId,
      'bseId': selectedBseAccount!.bseClientId,
      'fromFundId': widget.fromFundId,
      'fromFundName': widget.fromFundName,
      'availableUnits': widget.availableUnits,
      'availableAmount': widget.availableAmount,
      'toFundId': widget.toFundId,
      'toFundName': widget.toFundName,
      'toFundType': widget.toFundType,
      'toFundSubType': widget.toFundSubType,
      'isAmount': _isAmountSelected,
      'value': value,
      'displayValue': displayValue,
      'folioNo': widget.folioNo,
      'switchAll': _switchAll,
    };

    context.pushNamed('switch-confirm', extra: confirmData);
  }

  @override
  Widget build(BuildContext context) {
    final constraintState = ref.watch(schemeConstraintProvider(widget.toFundId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Switch Funds',
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
                  // Combined Fund From and Fund To Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Fund From
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
                                    child: const Icon(Icons.diamond, color: Colors.white, size: 24),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fund From',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.fromFundName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${widget.availableAmount.toStringAsFixed(2)} Amount • ${widget.availableUnits.toStringAsFixed(2)} Units',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Arrow with divider
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

                        // Fund To
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
                                    child: const Icon(Icons.diamond, color: Colors.white, size: 24),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fund To',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.toFundName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.toFundType} • ${widget.toFundSubType}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888898),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount/Units Input Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Amount/Units Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton(
                                  'Amount',
                                  _isAmountSelected,
                                      () => setState(() {
                                    _isAmountSelected = true;
                                    _switchAll = false;
                                    _currentValue = '';
                                  }),
                                ),
                              ),
                              Expanded(
                                child: _buildTabButton(
                                  'Units',
                                  !_isAmountSelected,
                                      () => setState(() {
                                    _isAmountSelected = false;
                                    _switchAll = false;
                                    _currentValue = '';
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount/Units Input Widget
                        constraintState.when(
                          data: (constraint) => _buildCenteredAmountInput(constraint),
                          loading: () => Container(
                            padding: const EdgeInsets.all(32),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0060A6),
                              ),
                            ),
                          ),
                          error: (error, stack) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Error loading constraints',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.invalidate(schemeConstraintProvider(widget.toFundId));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0060A6),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BSE Account Selection Card
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
                          'Select BSE Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
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

                                return Column(
                                  children: [
                                    CustomDropdownCard(
                                      label: '',
                                      showLabelInside: false,
                                      items: accounts.map((e) => e.displayName).toList(),
                                      selectedValue: selectedBseAccount?.displayName,
                                      hintText: 'Select',
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          selectedBseAccount = accounts.firstWhere(
                                                (acc) => acc.displayName == value,
                                          );
                                        });
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
                  onPressed: _currentValue.isEmpty || selectedBseAccount == null
                      ? null
                      : _navigateToConfirmScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredAmountInput(constraint) {
    final decimals = _isAmountSelected ? 2 : 3;
    final effectiveMax = _getEffectiveMax(constraint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _isAmountSelected ? 'Investment Amount' : 'Investment Units',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888898),
          ),
        ),
        const SizedBox(height: 16),

        // Centered Input Field
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAmountSelected)
                const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              if (_isAmountSelected) const SizedBox(width: 8),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _getController(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && _switchAll) {
                        setState(() => _switchAll = false);
                      }

                      if (value.isNotEmpty) {
                        try {
                          final inputValue = double.parse(value);
                          if (inputValue > effectiveMax) {
                            final correctedValue = effectiveMax.toStringAsFixed(decimals);
                            _getController().text = correctedValue;
                            _getController().selection = TextSelection.fromPosition(
                              TextPosition(offset: _getController().text.length),
                            );
                            setState(() => _currentValue = correctedValue);
                          } else {
                            setState(() => _currentValue = value);
                          }
                        } catch (e) {
                          setState(() => _currentValue = value);
                        }
                      } else {
                        setState(() => _currentValue = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Divider
        Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),

        const SizedBox(height: 16),

        // Min/Max Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min. ${_isAmountSelected ? '₹' : ''}${(_isAmountSelected ? constraint.minAmount ?? 0 : constraint.minUnits ?? 0).toStringAsFixed(decimals)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888898),
              ),
            ),
            Text(
              'Max. ${_isAmountSelected ? '₹' : ''}${effectiveMax.toStringAsFixed(decimals)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888898),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Centered Switch All Checkbox
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _switchAll = !_switchAll;
                if (_switchAll) {
                  final value = effectiveMax.toStringAsFixed(decimals);
                  _getController().text = value;
                  _currentValue = value;
                } else {
                  _getController().clear();
                  _currentValue = '';
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _switchAll,
                    onChanged: (value) {
                      setState(() {
                        _switchAll = value ?? false;
                        if (_switchAll) {
                          final val = effectiveMax.toStringAsFixed(decimals);
                          _getController().text = val;
                          _currentValue = val;
                        } else {
                          _getController().clear();
                          _currentValue = '';
                        }
                      });
                    },
                    activeColor: const Color(0xFF0060A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Switch all',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF888898),
            ),
          ),
        ),
      ),
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