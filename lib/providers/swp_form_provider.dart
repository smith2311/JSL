import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwpFormState {
  final bool isAmountMode;
  final String inputValue;
  final String? errorMessage;

  SwpFormState({
    this.isAmountMode = false,
    this.inputValue = '',
    this.errorMessage,
  });

  SwpFormState copyWith({
    bool? isAmountMode,
    String? inputValue,
    String? errorMessage,
  }) {
    return SwpFormState(
      isAmountMode: isAmountMode ?? this.isAmountMode,
      inputValue: inputValue ?? this.inputValue,
      errorMessage: errorMessage,
    );
  }
}

class SwpFormNotifier extends StateNotifier<SwpFormState> {
  SwpFormNotifier() : super(SwpFormState());

  void toggleMode() {
    state = state.copyWith(
      isAmountMode: !state.isAmountMode,
      inputValue: '',
      errorMessage: null,
    );
  }

  void updateInputValue(String value, {double? maxValue}) {
    state = state.copyWith(
      inputValue: value,
      errorMessage: null,
    );
  }

  void validateInput(double maxValue, bool isAmount, {double? minValue}) {
    if (state.inputValue.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter ${isAmount ? 'amount' : 'units'}',
      );
      return;
    }

    final value = double.tryParse(state.inputValue);
    if (value == null) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid number',
      );
      return;
    }

    if (minValue != null && value < minValue) {
      state = state.copyWith(
        errorMessage: isAmount
            ? 'Minimum amount is ₹${minValue.toStringAsFixed(0)}'
            : 'Minimum units is ${minValue.toStringAsFixed(3)}',
      );
      return;
    }

    if (value > maxValue) {
      state = state.copyWith(
        errorMessage: isAmount
            ? 'Amount cannot exceed ₹${maxValue.toStringAsFixed(2)}'
            : 'Units cannot exceed ${maxValue.toStringAsFixed(3)}',
      );
      return;
    }

    state = state.copyWith(errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = SwpFormState();
  }
}

final swpFormProvider = StateNotifierProvider.autoDispose<SwpFormNotifier, SwpFormState>(
      (ref) => SwpFormNotifier(),
);