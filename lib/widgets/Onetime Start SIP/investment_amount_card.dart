import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../providers/onetime_startsip_provider.dart';
import '../../../../../widgets/custom_tab_button.dart';

class InvestmentAmountCard extends ConsumerWidget {
  final int fundId;
  final int selectedTab;
  final Function(int) onTabChanged;
  final TextEditingController investmentController;
  final TextEditingController sipAmountController;
  final String? validationMessage;
  final String? sipValidationMessage;
  final Function(String?) onValidationMessageChanged;
  final Function(String?) onSipValidationMessageChanged;
  final String? selectedFolio;
  final double? originalMinAmount;
  final double? originalSipMinAmount;
  final Function(double?) onOriginalMinAmountChanged;
  final Function(double?) onOriginalSipMinAmountChanged;

  static const String NEW_FOLIO = "New Folio";
  static const double NEW_FOLIO_MIN_AMOUNT = 5000.0;

  const InvestmentAmountCard({
    super.key,
    required this.fundId,
    required this.selectedTab,
    required this.onTabChanged,
    required this.investmentController,
    required this.sipAmountController,
    required this.validationMessage,
    required this.sipValidationMessage,
    required this.onValidationMessageChanged,
    required this.onSipValidationMessageChanged,
    required this.selectedFolio,
    required this.originalMinAmount,
    required this.originalSipMinAmount,
    required this.onOriginalMinAmountChanged,
    required this.onOriginalSipMinAmountChanged,
  });

  void _validateAmount(OnetimeStartsipConstraint constraint, WidgetRef ref) {
    final text = investmentController.text.trim();
    if (text.isEmpty) {
      onValidationMessageChanged('Amount cannot be empty');
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      onValidationMessageChanged('Invalid amount');
      return;
    }

    if (value < constraint.minAmount) {
      onValidationMessageChanged('Amount cannot be less than ₹${constraint.minAmount.toInt()}');
      return;
    }

    if (value > constraint.maxAmount) {
      onValidationMessageChanged('Amount cannot be more than ₹${constraint.maxAmount.toInt()}');
      return;
    }

    onValidationMessageChanged(null);
  }

  void _validateSipAmount(SipConstraint constraint, WidgetRef ref) {
    final text = sipAmountController.text.trim();
    if (text.isEmpty) {
      onSipValidationMessageChanged('Amount cannot be empty');
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      onSipValidationMessageChanged('Invalid amount');
      return;
    }

    if (value < constraint.minAmount) {
      onSipValidationMessageChanged('Amount cannot be less than ₹${constraint.minAmount.toInt()}');
      return;
    }

    if (value > constraint.maxAmount) {
      onSipValidationMessageChanged('Amount cannot be more than ₹${constraint.maxAmount.toInt()}');
      return;
    }

    onSipValidationMessageChanged(null);
  }

  Widget _amountButton(int amount, WidgetRef ref, {bool isSip = false}) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      onPressed: () {
        if (isSip) {
          final currentText = sipAmountController.text.trim();
          final currentAmount = double.tryParse(currentText) ?? 0;
          final newAmount = currentAmount + amount;
          sipAmountController.text = newAmount.toInt().toString();
          final constraintAsync = ref.read(sipConstraintProvider);
          constraintAsync.whenData((constraint) => _validateSipAmount(constraint, ref));
        } else {
          final currentText = investmentController.text.trim();
          final currentAmount = double.tryParse(currentText) ?? 0;
          final newAmount = currentAmount + amount;
          investmentController.text = newAmount.toInt().toString();
          final constraintAsync = ref.read(fundConstraintProvider);
          constraintAsync.whenData((constraint) => _validateAmount(constraint, ref));
        }
      },
      child: Text('+₹$amount', style: const TextStyle(fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constraintAsync = ref.watch(fundConstraintProvider);
    final sipConstraintAsync = ref.watch(sipConstraintProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomTabButton(
                    label: 'One-Time',
                    isSelected: selectedTab == 0,
                    unselectedColor: const Color(0xFFF4F5F8),
                    onTap: () => onTabChanged(0),
                  ),
                  CustomTabButton(
                    label: 'SIP',
                    isSelected: selectedTab == 1,
                    unselectedColor: const Color(0xFFF4F5F8),
                    onTap: () => onTabChanged(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (selectedTab == 0)
              constraintAsync.when(
                data: (constraint) => _buildAmountInput(
                  ref,
                  constraint: constraint,
                  controller: investmentController,
                  validationMessage: validationMessage,
                  onChanged: (_) => _validateAmount(constraint, ref),
                  isSip: false,
                ),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, st) => const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text('Failed to load min/max', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),

            if (selectedTab == 1)
              sipConstraintAsync.when(
                data: (constraint) => _buildAmountInput(
                  ref,
                  constraint: constraint,
                  controller: sipAmountController,
                  validationMessage: sipValidationMessage,
                  onChanged: (_) => _validateSipAmount(constraint, ref),
                  isSip: true,
                ),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, st) => const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text('Failed to load min/max', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(
      WidgetRef ref, {
        required dynamic constraint,
        required TextEditingController controller,
        required String? validationMessage,
        required Function(String) onChanged,
        required bool isSip,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Investment Amount',
            style: TextStyle(fontSize: 16, color: Color(0xFF8F969C)),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
          ),
          onChanged: onChanged,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Divider(thickness: 1, color: Colors.grey),
        ),
        if (validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 80, top: 10, bottom: 10),
            child: Text(
              validationMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min ₹${constraint.minAmount.toInt()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Max ₹${constraint.maxAmount.toInt()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final amount in AppStrings.amt_txtbtns)
              _amountButton(amount, ref, isSip: isSip),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}