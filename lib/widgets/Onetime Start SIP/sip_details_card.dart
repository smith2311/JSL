import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../providers/onetime_startsip_provider.dart';
import '../../../../../widgets/custom_tab_button.dart';

class SipDetailsCard extends ConsumerWidget {
  final int fundId;
  final int selectedFrequencyIndex;
  final String? selectedFrequency;
  final TextEditingController dateController;
  final TextEditingController installmentsController;
  final String? installmentsValidationMessage;
  final bool payFirstInstallment;
  final Function(int, String) onFrequencyChanged;
  final Function(String?) onInstallmentsValidationChanged;
  final Function(bool) onPayFirstInstallmentChanged;

  const SipDetailsCard({
    super.key,
    required this.fundId,
    required this.selectedFrequencyIndex,
    required this.selectedFrequency,
    required this.dateController,
    required this.installmentsController,
    required this.installmentsValidationMessage,
    required this.payFirstInstallment,
    required this.onFrequencyChanged,
    required this.onInstallmentsValidationChanged,
    required this.onPayFirstInstallmentChanged,
  });

  void _validateInstallments(SipConstraint constraint) {
    final text = installmentsController.text.trim();

    if (text.isEmpty) {
      onInstallmentsValidationChanged('Number of installments cannot be empty');
      return;
    }

    final value = int.tryParse(text);
    if (value == null) {
      onInstallmentsValidationChanged('Invalid number');
      return;
    }

    if (value < constraint.minInstallments) {
      onInstallmentsValidationChanged('Cannot be less than ${constraint.minInstallments}');
      return;
    }

    if (value > constraint.maxInstallments) {
      onInstallmentsValidationChanged('Cannot be more than ${constraint.maxInstallments}');
      return;
    }

    onInstallmentsValidationChanged(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequenciesAsync = ref.watch(sipFrequencyProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: frequenciesAsync.when(
          data: (frequencies) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    frequencies.length,
                        (index) => CustomTabButton(
                      label: frequencies[index],
                      isSelected: selectedFrequencyIndex == index,
                      unselectedColor: const Color(0xFFF4F5F8),
                      onTap: () => onFrequencyChanged(index, frequencies[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDatePicker(context, ref),
                const SizedBox(height: 20),
                _buildInstallmentsInput(ref),
                const SizedBox(height: 16),
                _buildFirstInstallmentCheckbox(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, st) => const Center(
            child: Text('Failed to load frequencies', style: TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Investment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final sipConstraint = ref.watch(sipConstraintProvider);

            return sipConstraint.when(
              data: (constraint) => _buildDateTextField(context, constraint),
              loading: () => _buildDateTextField(context, null, isLoading: true),
              error: (e, st) => _buildDateTextField(context, null, hasError: true),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateTextField(BuildContext context, SipConstraint? constraint, {bool isLoading = false, bool hasError = false}) {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: isLoading ? 'Loading dates...' : hasError ? 'Error loading dates' : 'Select Date',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(AppStrings.calender, width: 20, height: 20),
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
      onTap: constraint != null ? () => _selectDate(context, constraint) : null,
    );
  }

  Future<void> _selectDate(BuildContext context, SipConstraint constraint) async {
    final now = DateTime.now();
    late DateTime minSelectableDate;
    late DateTime initialDisplayDate;

    if (payFirstInstallment) {
      minSelectableDate = DateTime(now.year, now.month + 1, 1);
      initialDisplayDate = minSelectableDate;
    } else {
      minSelectableDate = DateTime(now.year, now.month, now.day + 2);
      initialDisplayDate = minSelectableDate;
    }

    final maxSelectableDate = DateTime(
      minSelectableDate.year,
      minSelectableDate.month + 12,
      0,
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDisplayDate,
      firstDate: minSelectableDate,
      lastDate: maxSelectableDate,
      selectableDayPredicate: (DateTime date) {
        return constraint.frequencyDates.contains(date.day);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0060A6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0060A6)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      dateController.text = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    }
  }

  Widget _buildInstallmentsInput(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final sipConstraint = ref.watch(sipConstraintProvider);

        return sipConstraint.when(
          data: (constraint) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No of Installments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: installmentsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter no of installments',
                  filled: true,
                  fillColor: payFirstInstallment ? Colors.grey.shade100 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  disabledBorder: OutlineInputBorder(
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
              if (installmentsValidationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    installmentsValidationMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Min: ${constraint.minInstallments}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Max: ${constraint.maxInstallments}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Number of Installments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: installmentsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Loading...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          error: (e, st) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildFirstInstallmentCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: payFirstInstallment,
            onChanged: (value) => onPayFirstInstallmentChanged(value ?? false),
            activeColor: const Color(0xFF0060A6),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Pay 1st Installment Now',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}