import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../../providers/add_mandate_provider.dart';
import '../../../../../../../providers/bank_acc_operations_provider.dart';
import '../../../../../../../providers/mandates_provider.dart';

class AddMandateScreen extends ConsumerStatefulWidget {
  final String bseClientId;

  const AddMandateScreen({
    super.key,
    required this.bseClientId,
  });

  @override
  ConsumerState<AddMandateScreen> createState() => _AddMandateScreenState();
}

class _AddMandateScreenState extends ConsumerState<AddMandateScreen> {
  String? _selectedAccountNo;
  String _registrationType = 'U'; // N for eNach, U for UPI
  final _amountController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isFirstLoad = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankAccountsAsync = ref.watch(bankAccountsProvider(widget.bseClientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Mandate',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: bankAccountsAsync.when(
        data: (bankAccounts) {
          if (bankAccounts.isEmpty) {
            return _buildEmptyState();
          }

          // Set first account as default on first load
          if (_isFirstLoad && bankAccounts.isNotEmpty) {
            _isFirstLoad = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedAccountNo == null) {
                setState(() {
                  _selectedAccountNo = bankAccounts.first.accountNo;
                });
              }
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBankAccountDropdown(bankAccounts),
                      const SizedBox(height: 20),
                      _buildRegistrationType(),
                      const SizedBox(height: 20),
                      _buildAmountField(),
                      const SizedBox(height: 20),
                      _buildDateFields(),
                    ],
                  ),
                ),
              ),
              _buildAddButton(bankAccounts),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildBankAccountDropdown(List bankAccounts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Bank Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAccountNo,
                hint: const Text('Select account'),
                dropdownColor: Colors.white,
                items: bankAccounts.map<DropdownMenuItem<String>>((account) {
                  final maskedNo = _maskAccountNumber(account.accountNo);
                  return DropdownMenuItem<String>(
                    value: account.accountNo,
                    child: Text('$maskedNo - ${account.ifscCode}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountNo = value;
                  });
                },
              ),
            ),
          ),
          if (_selectedAccountNo != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Account Type: ${_getSelectedAccount(bankAccounts)?.accountType ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Account Owner: ${_getSelectedAccount(bankAccounts)?.accountOwner ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationType() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registration Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeButton('UPI', 'U'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton('Enach', 'N'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _registrationType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _registrationType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0060A6) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '200',
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
                borderSide: const BorderSide(color: Color(0xFF0060A6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFields() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // From Date
          const Text(
            'From Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectFromDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fromDate != null
                        ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                        : DateFormat('dd/MM/yyyy').format(tomorrow),
                    style: TextStyle(
                      fontSize: 16,
                      color: _fromDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // To Date
          const Text(
            'To Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _fromDate != null ? () => _selectToDate(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: _fromDate != null ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _toDate != null
                        ? DateFormat('dd/MM/yyyy').format(_toDate!)
                        : DateFormat('dd/MM/yyyy').format(dayAfterTomorrow),
                    style: TextStyle(
                      fontSize: 16,
                      color: _toDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: _fromDate != null ? Colors.grey : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(List bankAccounts) {
    final isFormValid = _isFormValid();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? const Color(0xFF0060A6) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isFormValid ? () => _handleAddMandate(bankAccounts) : null,
        child: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Bank Accounts Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add a bank account first to create a mandate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _maskAccountNumber(String accountNo) {
    if (accountNo.length >= 4) {
      final lastFour = accountNo.substring(accountNo.length - 4);
      return 'XX XXXX $lastFour';
    }
    return accountNo;
  }

  dynamic _getSelectedAccount(List bankAccounts) {
    try {
      return bankAccounts.firstWhere(
            (account) => account.accountNo == _selectedAccountNo,
      );
    } catch (e) {
      return null;
    }
  }

  bool _isFormValid() {
    return _selectedAccountNo != null &&
        _amountController.text.isNotEmpty &&
        _fromDate != null &&
        _toDate != null;
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0060A6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Reset To Date if it's before the new From Date
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    if (_fromDate == null) return;

    final initialDate = _toDate ?? _fromDate!.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _fromDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0060A6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  Future<void> _handleAddMandate(List bankAccounts) async {
    final selectedAccount = _getSelectedAccount(bankAccounts);
    if (selectedAccount == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await ref.read(addMandateProvider.notifier).addMandate(
      context: context,
      bseClientId: widget.bseClientId,
      accountNo: selectedAccount.accountNo,
      accountType: selectedAccount.accountType,
      ifscCode: selectedAccount.ifscCode,
      registrationType: _registrationType,
      mandateAmount: amount,
      mandatePeriodFrom: DateFormat('yyyy-MM-dd').format(_fromDate!),
      mandatePeriodTo: DateFormat('yyyy-MM-dd').format(_toDate!),
    );

    if (result != null && mounted) {
      // Refresh mandates list
      ref.invalidate(mandatesProvider(widget.bseClientId));

      // Navigate back after a short delay to allow user to see the browser opened
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    }
  }
}