import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../providers/action_dialog_stp_provider.dart';
import '../../../../../../../../providers/portf_fund_detail_redeem_provider.dart';
import '../../../../../../../../features/auth/data/models/switch_detail.dart' as switch_models;

class CustomTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomTabButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0060A6) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class PortfDialogStpDetailScreen extends ConsumerStatefulWidget {
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
  final String clientName;
  final String? sxpId;

  const PortfDialogStpDetailScreen({
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
    this.sxpId,
  });

  @override
  ConsumerState<PortfDialogStpDetailScreen> createState() => _PortfDialogStpDetailScreenState();
}

class _PortfDialogStpDetailScreenState extends ConsumerState<PortfDialogStpDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedFrequencyIndex = 0;
  String? _selectedFrequency;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String? _installmentsValidationMessage;
  String? _inputValidationMessage;
  BseAccount? selectedBseAccount;
  bool bseAccountsFetched = false;
  bool _isAmountMode = true;
  bool _payFirstInstallment = false;
  bool _transferAll = false;

  @override
  void initState() {
    super.initState();
    print('📋 PortfDialogStpDetailScreen initialized with:');
    print('   fromFundId: ${widget.fromFundId}');
    print('   toFundId: ${widget.toFundId}');
    print('   availableUnits: ${widget.availableUnits}');
    print('   availableAmount: ${widget.availableAmount}');
    print('   folioNo: ${widget.folioNo}');
    print('   clientId: ${widget.clientId}');
    print('   clientName: ${widget.clientName}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(redeemBseAccountProvider.notifier).fetchAccounts(widget.clientId);
      bseAccountsFetched = true;
      ref.read(stpFrequenciesProvider(widget.toFundId).notifier).fetchFrequencies();
      print('✅ STP Screen: Fetched BSE accounts and STP frequencies');
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _installmentsController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(int index, List<String> frequencies) {
    setState(() {
      _selectedFrequencyIndex = index;
      _selectedFrequency = frequencies[index];
      _dateController.clear();
      _installmentsController.clear();
      _inputController.clear();
      _transferAll = false;
      _inputValidationMessage = null;
    });

    ref.read(stpSchemeConstraintProvider(StpConstraintParams(
      fundId: widget.toFundId,
      frequency: _selectedFrequency!,
    )).notifier).fetchConstraints().then((_) {
      final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
        fundId: widget.toFundId,
        frequency: _selectedFrequency!,
      )));
      constraintAsync.whenData((constraint) {
        if (!_payFirstInstallment) {
          _installmentsController.text = (constraint.minInstallments ?? 1).toString();
        }
      });
    });
  }

  void _validateInstallments(switch_models.SchemeConstraint constraint) {
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

    final minInstallments = constraint.minInstallments ?? 1;
    final maxInstallments = constraint.maxInstallments ?? 999;

    if (value < minInstallments) {
      setState(() {
        _installmentsValidationMessage = 'Cannot be less than $minInstallments';
      });
      return;
    }

    if (value > maxInstallments) {
      setState(() {
        _installmentsValidationMessage = 'Cannot be more than $maxInstallments';
      });
      return;
    }

    setState(() {
      _installmentsValidationMessage = null;
    });
  }

  void _validateInput(String value, switch_models.SchemeConstraint constraint, bool isAmountMode, double maxValue) {
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

    final minValue = isAmountMode ? constraint.minAmount : constraint.minUnits;

    if (inputValue < minValue!) {
      setState(() {
        _inputValidationMessage = isAmountMode
            ? 'Cannot be less than ₹${NumberFormat('#,##,##0').format(minValue)}'
            : 'Cannot be less than ${minValue.toStringAsFixed(3)} units';
      });
      return;
    }

    if (inputValue > maxValue + 0.01) {
      setState(() {
        _inputValidationMessage = isAmountMode
            ? 'Cannot exceed ₹${NumberFormat('#,##,##0.00').format(maxValue)}'
            : 'Cannot exceed ${maxValue.toStringAsFixed(3)} units';
      });
      return;
    }

    setState(() {
      _inputValidationMessage = null;
    });
  }

  double _getEffectiveMax(switch_models.SchemeConstraint constraint) {
    if (_isAmountMode) {
      final apiMax = constraint.maxAmount ?? double.infinity;
      return widget.availableAmount < apiMax ? widget.availableAmount : apiMax;
    } else {
      final apiMax = constraint.maxUnits ?? double.infinity;
      return widget.availableUnits < apiMax ? widget.availableUnits : apiMax;
    }
  }

  void _proceedToConfirm() {
    if (_dateController.text.isEmpty) {
      _showError('Please select STP date');
      return;
    }

    if (_installmentsController.text.isEmpty) {
      _showError('Please enter number of installments');
      return;
    }

    if (_inputController.text.isEmpty) {
      _showError('Please enter ${_isAmountMode ? 'amount' : 'units'}');
      return;
    }

    final numValue = double.tryParse(_inputController.text.trim());
    if (numValue == null) {
      _showError('Please enter a valid number');
      return;
    }

    if (selectedBseAccount == null) {
      _showError('Please select BSE account');
      return;
    }

    final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
      fundId: widget.toFundId,
      frequency: _selectedFrequency!,
    )));
    if (constraintAsync.hasError) {
      _showError('Failed to load constraints');
      return;
    }

    constraintAsync.whenData((constraint) {
      _validateInstallments(constraint);
      _validateInput(_inputController.text, constraint, _isAmountMode, _getEffectiveMax(constraint));

      if (_installmentsValidationMessage != null || _inputValidationMessage != null) {
        return;
      }

      final dateText = _dateController.text.trim();
      String formattedDate;
      try {
        if (dateText.contains('/')) {
          final dateParts = dateText.split('/');
          final day = dateParts[0].padLeft(2, '0');
          final month = dateParts[1].padLeft(2, '0');
          final year = dateParts[2];

          if (year.length != 4) {
            throw Exception('Year must be 4 digits');
          }

          formattedDate = '$year-$month-$day';
          print('✅ Date converted successfully: $formattedDate');
        } else {
          throw Exception('Invalid date format');
        }

        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(formattedDate)) {
          throw Exception('Date does not match yyyy-MM-dd pattern');
        }
      } catch (e) {
        print('❌ Date conversion error: $e');
        _showError('Date error: $e');
        return;
      }

      print('========== NAVIGATION DATA ==========');
      print('client_id: ${widget.clientId}');  // Added for debugging
      print('fund_id_from: ${widget.fromFundId}');
      print('fund_id_to: ${widget.toFundId}');
      print('folio_no: ${widget.folioNo}');
      print('amount: ${_isAmountMode ? numValue : 0.0}');
      print('units: ${_isAmountMode ? 0.0 : numValue}');
      print('frequency: ${_selectedFrequency!.toLowerCase()}');
      print('stp_date: $formattedDate');
      print('no_of_installments: ${int.parse(_installmentsController.text.trim())}');
      print('bse_client_id: ${selectedBseAccount!.bseClientId}');
      print('first_order: $_payFirstInstallment');
      print('transfer_by: ${_isAmountMode ? 'amount' : 'units'}');
      print('====================================');

      context.pushNamed(
        'stp-confirm',
        extra: {
          'client_id': widget.clientId,  // ✅ ADDED THIS LINE
          'fund_id_from': widget.fromFundId,
          'fund_id_to': widget.toFundId,
          'folio_no': widget.folioNo,
          'amount': _isAmountMode ? numValue : 0.0,
          'units': _isAmountMode ? 0.0 : numValue,
          'frequency': _selectedFrequency!.toLowerCase(),
          'stp_date': formattedDate,
          'no_of_installments': int.parse(_installmentsController.text.trim()),
          'bse_client_id': selectedBseAccount!.bseClientId,
          'first_order': _payFirstInstallment,
          'transfer_by': _isAmountMode ? 'amount' : 'units',
          'fromFundName': widget.fromFundName,
          'toFundName': widget.toFundName,
          'displayValue': _isAmountMode
              ? '₹${NumberFormat('#,##,##0.00').format(numValue)}'
              : '${numValue.toStringAsFixed(3)} units',
          'clientName': widget.clientName,
        },
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frequenciesAsync = ref.watch(stpFrequenciesProvider(widget.toFundId));
    final bseAccountsAsync = ref.watch(redeemBseAccountProvider);

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
          'STP Funds',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: frequenciesAsync.when(
        data: (frequencies) {
          if (_selectedFrequency == null && frequencies.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedFrequency = frequencies[0];
              });
              ref.read(stpSchemeConstraintProvider(StpConstraintParams(
                fundId: widget.toFundId,
                frequency: frequencies[0],
              )).notifier).fetchConstraints().then((_) {
                final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
                  fundId: widget.toFundId,
                  frequency: frequencies[0],
                )));
                constraintAsync.whenData((constraint) {
                  if (!_payFirstInstallment) {
                    _installmentsController.text = (constraint.minInstallments ?? 1).toString();
                  }
                });
              });
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
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
                                fundName: widget.fromFundName,
                                subtitle: '${NumberFormat('#,##,##0.000').format(widget.availableAmount)} Amount • ${NumberFormat('#,##,##0.000').format(widget.availableUnits)} Units',
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
                                fundName: widget.toFundName,
                                subtitle: 'Allocation • ${widget.toFundSubType}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Amount/Units Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ref.watch(stpSchemeConstraintProvider(StpConstraintParams(
                            fundId: widget.toFundId,
                            frequency: _selectedFrequency ?? '',
                          ))).when(
                            data: (constraint) {
                              final effectiveMax = _getEffectiveMax(constraint);
                              final decimals = _isAmountMode ? 2 : 3;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Toggle Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildToggleButton(
                                          'Amount',
                                          _isAmountMode,
                                              () {
                                            setState(() {
                                              _isAmountMode = true;
                                              _inputController.clear();
                                              _transferAll = false;
                                              _inputValidationMessage = null;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildToggleButton(
                                          'Units',
                                          !_isAmountMode,
                                              () {
                                            setState(() {
                                              _isAmountMode = false;
                                              _inputController.clear();
                                              _transferAll = false;
                                              _inputValidationMessage = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Label
                                  const Text(
                                    'Investment Amount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF888898),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Input Field
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (_isAmountMode)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 70),
                                          child: Text(
                                            '₹',
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: TextField(
                                          controller: _inputController,
                                          focusNode: _inputFocusNode,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            hintText: '0',
                                            hintStyle: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFCCCCCC),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(right: 90),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textInputAction: TextInputAction.done,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _transferAll = false;
                                            });
                                            _validateInput(value, constraint, _isAmountMode, effectiveMax);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_inputValidationMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Center(
                                        child: Text(
                                          _inputValidationMessage!,
                                          style: const TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                                  const SizedBox(height: 16),

                                  // Min/Max Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Min. ${_isAmountMode ? '₹' : ''}${(_isAmountMode ? constraint.minAmount : constraint.minUnits)!.toStringAsFixed(decimals == 2 ? 2 : 0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888898),
                                        ),
                                      ),
                                      Text(
                                        'Max. ${_isAmountMode ? '₹' : ''}${effectiveMax.toStringAsFixed(decimals == 2 ? 2 : 0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888898),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Text('Error: $error'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Combined Card: Frequency, Date of STP, No of Installments, Select BSE Account
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Frequency Section
                              const Text(
                                'Frequency',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: [
                                  // First row with 3 tabs
                                  if (frequencies.isNotEmpty)
                                    Row(
                                      children: [
                                        ...frequencies.take(3).toList().asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final frequency = entry.value;
                                          return Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: index < 2 ? 8 : 0,
                                              ),
                                              child: CustomTabButton(
                                                label: frequency,
                                                isSelected: _selectedFrequencyIndex == index,
                                                onTap: () => _onFrequencyChanged(index, frequencies),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        // Add empty expanded widgets if less than 3 frequencies
                                        ...List.generate(
                                          3 - (frequencies.length > 3 ? 3 : frequencies.length),
                                              (index) => const Expanded(child: SizedBox()),
                                        ),
                                      ],
                                    ),
                                  // Fourth tab in second row (full width)
                                  if (frequencies.length > 3) ...[
                                    const SizedBox(height: 8),
                                    ...frequencies.skip(3).toList().asMap().entries.map((entry) {
                                      final index = entry.key + 3;
                                      final frequency = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: CustomTabButton(
                                            label: frequency,
                                            isSelected: _selectedFrequencyIndex == index,
                                            onTap: () => _onFrequencyChanged(index, frequencies),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Date of STP Section
                              const Text(
                                'Date of STP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: () {
                                  if (_selectedFrequency == null) return;
                                  final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
                                    fundId: widget.toFundId,
                                    frequency: _selectedFrequency!,
                                  )));
                                  constraintAsync.whenData((constraint) {
                                    _showDatePicker(context, constraint);
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'dd/mm/yyyy',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SvgPicture.asset(
                                      AppStrings.calender,
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // No of Installments Section
                              const Text(
                                'No of Installments',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _installmentsController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (_selectedFrequency == null) return;
                                  final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
                                    fundId: widget.toFundId,
                                    frequency: _selectedFrequency!,
                                  )));
                                  constraintAsync.whenData((constraint) {
                                    _validateInstallments(constraint);
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter no of installments',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  errorText: _installmentsValidationMessage,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ref.watch(stpSchemeConstraintProvider(StpConstraintParams(
                                fundId: widget.toFundId,
                                frequency: _selectedFrequency ?? '',
                              ))).when(
                                data: (constraint) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Min: ${constraint.minInstallments ?? 1}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF888898)),
                                    ),
                                    Text(
                                      'Max: ${constraint.maxInstallments ?? 999}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF888898)),
                                    ),
                                  ],
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (error, stack) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 12),

                              // Do 1st Installment Today Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _payFirstInstallment,
                                      onChanged: (value) {
                                        setState(() {
                                          _payFirstInstallment = value ?? false;
                                          _dateController.clear();
                                          if (_selectedFrequency == null) return;
                                          final constraintAsync = ref.read(stpSchemeConstraintProvider(StpConstraintParams(
                                            fundId: widget.toFundId,
                                            frequency: _selectedFrequency!,
                                          )));
                                          constraintAsync.whenData((constraint) {
                                            if (!_payFirstInstallment) {
                                              _installmentsController.text = (constraint.minInstallments ?? 1).toString();
                                            }
                                          });
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
                                    'Do 1st Installment Today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Select BSE Account Section
                              const Text(
                                'Select BSE Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              bseAccountsAsync.when(
                                data: (accounts) {
                                  final items = accounts.map((account) => account.bseClientId).toList();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedBseAccount?.bseClientId,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          hintText: 'Select',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
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
                                            borderSide: const BorderSide(color: Color(0xFF0060A6), width: 1.5),
                                          ),
                                        ),
                                        dropdownColor: Colors.white,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                        items: items.map((item) {
                                          return DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedBseAccount = accounts.firstWhere((account) => account.bseClientId == value);
                                          });
                                        },
                                      ),
                                      if (selectedBseAccount != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF4F5F8),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildDetailRow('BSE ID', selectedBseAccount!.bseClientId),
                                              const SizedBox(height: 8),
                                              _buildDetailRow('Tax Status', selectedBseAccount!.taxStatus ?? '-'),
                                              const SizedBox(height: 8),
                                              _buildDetailRow('Holding Type', selectedBseAccount!.holdingStatus ?? '-'),
                                              const SizedBox(height: 8),
                                              _buildDetailRow('Second Holder Name', selectedBseAccount!.secondHolderName ?? '-'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, stack) => Text('Error loading accounts: $error'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      onPressed: _proceedToConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0060A6))),
        error: (error, stack) => Center(child: Text('Error loading frequencies: $error')),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, switch_models.SchemeConstraint constraint) async {
    final now = DateTime.now();

    // ✅ Fix: When first installment is today, next STP starts from next valid date
    // Otherwise, STP can only start 2+ days from now
    final minSelectableDate = _payFirstInstallment
        ? now.add(const Duration(days: 1))  // Next day if doing first installment today
        : now.add(const Duration(days: 2)); // At least 2 days ahead

    // Start calendar at the month containing the minimum date
    DateTime displayMonth = DateTime(minSelectableDate.year, minSelectableDate.month, 1);

    final availableDates = (constraint.frequencyDates ?? [])
        .map((date) => int.tryParse(date) ?? 0)
        .where((date) => date != 0)
        .toList();

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
                          color: displayMonth.isAfter(DateTime(minSelectableDate.year, minSelectableDate.month, 1))
                              ? Colors.black
                              : Colors.grey.shade300,
                        ),
                        onPressed: displayMonth.isAfter(DateTime(minSelectableDate.year, minSelectableDate.month, 1))
                            ? () {
                          setDialogState(() {
                            displayMonth = DateTime(displayMonth.year, displayMonth.month - 1, 1);
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
                          final maxMonth = DateTime(minSelectableDate.year, minSelectableDate.month + 11, 1);
                          if (displayMonth.isBefore(maxMonth)) {
                            setDialogState(() {
                              displayMonth = DateTime(displayMonth.year, displayMonth.month + 1, 1);
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
                  _buildCalendarGrid(displayMonth, availableDates, minSelectableDate),
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

  Widget _buildCalendarGrid(DateTime displayMonth, List<int> availableDates, DateTime minSelectableDate) {
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
        final isAfterMinDate = currentDate.isAtSameMomentAs(minSelectableDate) || currentDate.isAfter(minSelectableDate);
        final isSelectable = isInAvailableList && isAfterMinDate;

        return InkWell(
          onTap: isSelectable ? () => Navigator.pop(context, currentDate) : null,
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

  Widget _buildFundItem({required String fundName, required String subtitle}) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            AppStrings.iconFunds_png,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
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
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fundName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888898),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
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

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0060A6) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}