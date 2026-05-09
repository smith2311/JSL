import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/widgets/perfromance_chart.dart';
import '../features/funds/data/models/investment_return.dart';
import '../providers/investment_returns_service_provider.dart';
import 'investment_chart.dart';

class InvestmentReturnsCard extends ConsumerWidget {
  const InvestmentReturnsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Outer Tabs: Returns / Performance
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab(context, ref, AppStrings.returns, 0),
                  _buildTab(context, ref, AppStrings.performance, 1),
                ],
              ),
            ),
            const SizedBox(height: 19),

            // Tab content
            SizedBox(
              height: 390,
              child: selectedTab == 0
                  ? _buildReturnsContent(context, ref)
                  : _buildPerformanceContent(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, String label, int index) {
    final selectedTab = ref.watch(selectedTabProvider);
    final bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(selectedTabProvider.notifier).state = index,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0060A6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReturnsContent(BuildContext context, WidgetRef ref) {
    final selectedReturnType = ref.watch(selectedReturnTypeProvider);
    final fundId = ref.watch(selectedFundIdProvider);

    // ✅ FIXED: Log fund ID for debugging
    print('🔍 Building returns content for fundId: $fundId, type: $selectedReturnType');

    final returnsAsync = ref.watch(currentReturnsProvider);

    return Column(
      children: [
        // Inner tabs for ABS/CAGR with connected indicator line
        Padding(
          padding: const EdgeInsets.only(left: 80, right: 80),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInnerTab(context, ref, AppStrings.abs, ReturnType.abs),
                  _buildInnerTab(context, ref, AppStrings.cagr, ReturnType.cagr),
                ],
              ),
              const SizedBox(height: 7),
              // Connected indicator line
              Stack(
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  Align(
                    alignment: selectedReturnType == ReturnType.abs
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      height: 2,
                      width: 100,
                      color: const Color(0xFF0060A6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chart content
        Expanded(
          child: returnsAsync.when(
            data: (response) {
              print('✅ Data loaded successfully: ${response.returns.length} items for fundId: $fundId');
              return InvestmentChart(
                returns: response.returns,
                type: selectedReturnType,
              );
            },
            loading: () {
              print('⏳ Loading data for fundId: $fundId...');
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
                ),
              );
            },
            error: (error, stack) {
              print('❌ Error loading data for fundId: $fundId');
              print('Error: $error');
              print('Stack trace: $stack');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load data',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fund ID: $fundId',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('🔄 Retry clicked for fundId: $fundId');
                        // ref.refresh(currentReturnsProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Center(
          child: TextButton(
            onPressed: () {
              print("View All clicked");
              // Add navigation or action here
            },
            child: const Text(
              AppStrings.view_all_funds,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerTab(BuildContext context, WidgetRef ref, String label, ReturnType type) {
    final selectedType = ref.watch(selectedReturnTypeProvider);
    final bool isSelected = selectedType == type;

    return GestureDetector(
      onTap: () {
        // Update selected type
        ref.read(selectedReturnTypeProvider.notifier).state = type;

        // Log which API type is being requested
        final fundId = ref.read(selectedFundIdProvider);
        if (type == ReturnType.abs) {
          print("📊 API for ABS called - fundId: $fundId");
        } else if (type == ReturnType.cagr) {
          print("📊 API for CAGR called - fundId: $fundId");

          // Optionally, you can force-fetch CAGR explicitly by refreshing the provider:
          // ref.refresh(investmentReturnsProvider((fundId: fundId, type: ReturnType.cagr)));
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0060A6) : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPerformanceContent(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(performanceAmountProvider);
    final fundId = ref.watch(selectedFundIdProvider);
    final performanceAsync = ref.watch(currentPerformanceProvider);

    print('📈 Building performance content for fundId: $fundId, amount: $amount');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Amount input field with proper validation
        _buildAmountInputField(context, ref, amount),

        // Error messages
        _buildErrorMessages(amount),

        // Simple divider instead of dashed line
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 100),
          child: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ),

        // "Would have given return of" text with proper spacing
        const Text(
          AppStrings.would_return,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888898),
          ),
        ),

        const SizedBox(height: 24),

        // Performance Chart
        Expanded(
          child: performanceAsync.when(
            data: (response) {
              print('✅ Performance data loaded for fundId: $fundId');
              return PerformanceChart(
                performance: response.performance,
              );
            },
            error: (e, stack) {
              print('❌ Error loading performance for fundId: $fundId');
              print('Error: $e');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Error loading performance",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fund ID: $fundId',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('🔄 Retry performance for fundId: $fundId');
                        // ref.refresh(currentPerformanceProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
            loading: () {
              print('⏳ Loading performance for fundId: $fundId...');
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // View All button
        Center(
          child: TextButton(
            onPressed: () {
              print("View All clicked");
            },
            child: const Text(
              AppStrings.view_all_funds,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInputField(BuildContext context, WidgetRef ref, double amount) {
    final controller = TextEditingController();

    // Format the display value with ₹ symbol together
    if (amount > 0) {
      controller.text = "₹${amount.toStringAsFixed(0)}";
    } else {
      controller.text = "₹"; // Show just ₹ when empty
    }

    // Set cursor position to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          // Custom formatter that allows clearing but maintains ₹
          TextInputFormatter.withFunction((oldValue, newValue) {
            String text = newValue.text;

            // If user is trying to delete the ₹ symbol, keep it
            if (!text.startsWith('₹')) {
              text = '₹$text';
            }

            // Remove all non-digits except ₹
            String digitsOnly = text.substring(1).replaceAll(RegExp(r'[^\d]'), '');

            // Limit to 6 digits max (500000)
            if (digitsOnly.length > 6) {
              digitsOnly = digitsOnly.substring(0, 6);
            }

            // Format with ₹ prefix
            String formatted = '₹$digitsOnly';

            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          // Extract only digits from the value
          final digitsOnly = value.replaceAll('₹', '').replaceAll(RegExp(r'[^\d]'), '');
          final entered = double.tryParse(digitsOnly) ?? 0;

          // Update provider for real-time validation
          ref.read(performanceAmountProvider.notifier).state = entered;

          // Make API call only if valid amount
          if (entered >= 100 && entered <= 500000) {
            _callPerformanceAPI(ref, entered);
          }
        },
        onEditingComplete: () {
          // Extract digits for validation
          final digitsOnly = controller.text.replaceAll('₹', '').replaceAll(RegExp(r'[^\d]'), '');
          final currentAmount = double.tryParse(digitsOnly) ?? 0;
          _handleEditingComplete(ref, currentAmount, controller, context);
        },
      ),
    );
  }

  void _handleEditingComplete(WidgetRef ref, double amount, TextEditingController controller, BuildContext context) {
    // Final validation on editing complete
    if (amount == 0) {
      ref.read(performanceAmountProvider.notifier).state = 100;
      controller.text = "₹100";
      _showError(context, 'Please enter a value of ₹100 or greater');
      _callPerformanceAPI(ref, 100);
      return;
    }

    if (amount < 100) {
      ref.read(performanceAmountProvider.notifier).state = 100;
      controller.text = "₹100";
      _showError(context, 'Minimum value is ₹100');
      _callPerformanceAPI(ref, 100);
      return;
    }

    if (amount > 500000) {
      ref.read(performanceAmountProvider.notifier).state = 500000;
      controller.text = "₹500000";
      _showError(context, 'You have reached the maximum limit of adding funds (₹5,00,000)');
      _callPerformanceAPI(ref, 500000);
      return;
    }

    // Valid amount - make API call
    _callPerformanceAPI(ref, amount);

    // Set cursor position to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  void _callPerformanceAPI(WidgetRef ref, double amount) {
    final fundId = ref.read(selectedFundIdProvider);
    print('💰 Performance API called - fundId: $fundId, amount: ₹$amount');
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorMessages(double amount) {
    if (amount == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "⚠ Amount cannot be empty",
          style: TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    } else if (amount > 0 && amount < 100) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "⚠ Minimum investment is ₹100",
          style: TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    } else if (amount > 500000) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "⚠ You have reached the maximum limit of adding funds",
          style: TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink(); // No error
  }
}