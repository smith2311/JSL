import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../providers/bank_acc_operations_provider.dart';

/// ✅ Provider for managing link bank account state
final linkBankAccountProvider = StateNotifierProvider.autoDispose<
    LinkBankAccountNotifier, LinkBankAccountState>(
      (ref) => LinkBankAccountNotifier(),
);

/// ✅ State class
class LinkBankAccountState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, String>> accountTypes;
  final List<Map<String, String>> accountOwners;

  LinkBankAccountState({
    this.isLoading = false,
    this.errorMessage,
    this.accountTypes = const [],
    this.accountOwners = const [],
  });

  LinkBankAccountState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, String>>? accountTypes,
    List<Map<String, String>>? accountOwners,
  }) {
    return LinkBankAccountState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      accountTypes: accountTypes ?? this.accountTypes,
      accountOwners: accountOwners ?? this.accountOwners,
    );
  }
}

/// ✅ State Notifier
class LinkBankAccountNotifier extends StateNotifier<LinkBankAccountState> {
  LinkBankAccountNotifier() : super(LinkBankAccountState()) {
    _loadDropdownData();
  }

  void _loadDropdownData() {
    // Load constants (replace with API later if needed)
    state = state.copyWith(
      accountTypes: DropdownConstants.accountTypes,
      accountOwners: DropdownConstants.accountOwners,
    );
    debugPrint("[LinkBankAccount] Dropdown data loaded");
  }

  Future<void> fetchDropdownDataFromAPI() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulated call
      state = state.copyWith(
        isLoading: false,
        accountTypes: DropdownConstants.accountTypes,
        accountOwners: DropdownConstants.accountOwners,
      );
    } catch (e) {
      debugPrint("[LinkBankAccount] Error fetching dropdown data: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dropdown options',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// ✅ Main Screen
class LinkBankAccScreen extends ConsumerStatefulWidget {
  final String bseClientId;

  const LinkBankAccScreen({
    super.key,
    required this.bseClientId,
  });

  @override
  ConsumerState<LinkBankAccScreen> createState() =>
      _LinkBankAccScreenState();
}

class _LinkBankAccScreenState extends ConsumerState<LinkBankAccScreen> {
  bool _showForm = false;

  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  String? _selectedAccountType;
  String? _selectedAccountOwner;

  @override
  void dispose() {
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkState = ref.watch(linkBankAccountProvider);

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
          'Link Bank Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showForm
              ? _buildBankForm(context, linkState)
              : _buildInitialContent(context, linkState),
        ),
      ),
    );
  }

  /// 🌟 Initial Content (Before Proceed)
  Widget _buildInitialContent(
      BuildContext context, LinkBankAccountState linkState) {
    return Container(
      key: const ValueKey('initialContainer'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.black, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.govt_rules,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SvgPicture.asset(AppStrings.one_rs, height: 100),
          const SizedBox(height: 32),
          const Text(
            AppStrings.ban_lin_desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: linkState.isLoading
                    ? null
                    : () {
                  setState(() {
                    _showForm = true;
                  });
                  debugPrint("[LinkBankAccScreen] Showing bank form");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor:
                  const Color(0xFF0060A6).withOpacity(0.6),
                ),
                child: linkState.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Proceed to Link A/c',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 🌟 Form Content (After Proceed)
  Widget _buildBankForm(
      BuildContext context, LinkBankAccountState linkState) {
    return Container(
      key: const ValueKey('formContainer'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Bank Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          /// Account No
          const Text('Bank Account Number',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _accountNoController,
            keyboardType: TextInputType.number,
            maxLength: 18,
            decoration: const InputDecoration(
              hintText: 'Enter bank account number',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          /// IFSC
          const Text('IFSC Code',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _ifscController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            decoration: const InputDecoration(
              hintText: 'Enter IFSC Code',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          /// Account Type
          const Text('Account Type',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedAccountType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Select account type'),
            items: linkState.accountTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Text(type['label'] ?? ''),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedAccountType = value),
          ),
          const SizedBox(height: 16),

          /// Account Owner
          const Text('Account Owner',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedAccountOwner,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Select account owner'),
            items: linkState.accountOwners.map((owner) {
              return DropdownMenuItem<String>(
                value: owner['value'],
                child: Text(owner['label'] ?? ''),
              );
            }).toList(),
            onChanged: (value) =>
                setState(() => _selectedAccountOwner = value),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _submitBankDetails(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0060A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Submit Bank Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Submit Bank Details
  Future<void> _submitBankDetails(BuildContext context) async {
    final accountNo = _accountNoController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final type = _selectedAccountType;
    final owner = _selectedAccountOwner;

    if (accountNo.isEmpty || ifsc.isEmpty || type == null || owner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    debugPrint('🧾 Adding bank account...');
    debugPrint('➡️ BSE ID: ${widget.bseClientId}');
    debugPrint('➡️ Account No: $accountNo');
    debugPrint('➡️ IFSC: $ifsc');
    debugPrint('➡️ Type: $type');
    debugPrint('➡️ Owner: $owner');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
      ),
    );

    try {
      final notifier =
      ref.read(bankAccountsProvider(widget.bseClientId).notifier);

      // ✅ Use the new method that returns status
      final result = await notifier.addBankAccountWithoutLoader(
        bseClientId: widget.bseClientId,
        ifscCode: ifsc,
        accountNo: accountNo,
        accountType: type,
        accountOwner: owner,
      );

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      debugPrint('📊 Add Bank Response - Status: ${result['status']}, Message: ${result['message']}');

      // ✅ Check the status field from response
      if (result['status'] == 1) {
        // Success - Refresh the list
        await notifier.fetchBankDetails(widget.bseClientId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message'] ?? 'Bank account added successfully!'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Invalidate and wait before going back
        ref.invalidate(bankAccountsProvider(widget.bseClientId));
        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) context.pop();
      } else {
        // ❌ Status is 0 - Show error from API
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Failed to add account'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitBankDetails(context),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('❌ Error adding bank account: $e');

      if (!mounted) return;

      String errorMessage = 'Failed to add account';
      if (e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Session expired. Please login again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _submitBankDetails(context),
          ),
        ),
      );
    }
  }
}