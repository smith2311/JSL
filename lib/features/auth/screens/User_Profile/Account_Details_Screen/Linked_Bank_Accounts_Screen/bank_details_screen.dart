import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../providers/bank_acc_operations_provider.dart';
import '../../../../../../../widgets/bank_acc_card.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  final String bseClientId;

  const BankDetailsScreen({
    super.key,
    required this.bseClientId,
  });

  @override
  ConsumerState<BankDetailsScreen> createState() =>
      _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    debugPrint('🗂️ Building BankDetailsScreen with bseClientId: ${widget.bseClientId}');

    final bankDetailsAsync = ref.watch(bankAccountsProvider(widget.bseClientId));

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
          'Bank Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: bankDetailsAsync.when(
        data: (bankAccounts) {
          if (bankAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bank accounts found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a bank account to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Bank Accounts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bankAccounts.length,
                  itemBuilder: (context, index) {
                    final account = bankAccounts[index];
                    return BankAccountCard(
                      accountNumber: account.accountNo,
                      ifscCode: account.ifscCode,
                      accountOwner: account.accountOwner,
                      accountType: account.accountType,
                      onDelete: () {
                        _showDeleteConfirmation(
                          context,
                          account.accountNo,
                          account.ifscCode,
                          account.accountType,
                          account.accountOwner,
                        );
                      },
                    );
                  },
                ),
              ),
              // Add Bank Account Button
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Link Bank Account screen
                      context.pushNamed(
                        'link_bank_account',
                        extra: {
                          'bseClientId': widget.bseClientId,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0060A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add Bank Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0060A6),
          ),
        ),
        error: (error, stackTrace) {
          debugPrint('❌ Error loading bank accounts: $error');

          // User-friendly error message
          String errorMessage = 'Failed to load bank accounts';
          if (error.toString().contains('Network') ||
              error.toString().contains('SocketException')) {
            errorMessage = 'Network error. Please check your internet connection.';
          } else if (error.toString().contains('TimeoutException')) {
            errorMessage = 'Request timed out. Please try again.';
          } else if (error.toString().contains('401')) {
            errorMessage = 'Session expired. Please login again.';
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the provider
                      ref.invalidate(bankAccountsProvider(widget.bseClientId));
                      debugPrint('🔄 Retrying bank accounts fetch');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0060A6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      String accountNo,
      String ifscCode,
      String accountType,
      String accountOwner,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Delete Icon with Circle Background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to '),
                    TextSpan(
                      text: 'delete',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' this bank account '),
                    TextSpan(
                      text: 'XX XXXX ${accountNo.substring(accountNo.length - 4)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _handleDeleteAccount(
                          context,
                          accountNo,
                          ifscCode,
                          accountType,
                          accountOwner,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(
      BuildContext context,
      String accountNo,
      String ifscCode,
      String accountType,
      String accountOwner,
      ) async {
    // Show loading dialog - ONLY ONE
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0060A6),
          ),
        ),
      ),
    );

    try {
      final notifier = ref.read(bankAccountsProvider(widget.bseClientId).notifier);

      // Call the delete method WITHOUT showing loader (we already have one)
      final result = await notifier.deleteBankAccountWithoutLoader(
        bseClientId: widget.bseClientId,
        ifscCode: ifscCode,
        accountNo: accountNo,
        accountType: accountType,
        accountOwner: accountOwner,
      );

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        if (result['status'] == 1) {
          // Success - Refresh the list
          await notifier.fetchBankDetails(widget.bseClientId);

          final message = result['message'] ?? 'Bank account deleted successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $message'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Status is 0 - Show API error message
          final errorMessage = result['message'] ?? 'Error while processing your request';
          debugPrint('❌ Delete failed - Status: ${result['status']}, Message: $errorMessage');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMessage'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      // Close loading dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('❌ Exception during delete: $error');

      if (mounted) {
        String errorMessage = 'Error while processing your request';
        if (error.toString().contains('Network') ||
            error.toString().contains('SocketException')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (error.toString().contains('TimeoutException')) {
          errorMessage = 'Request timed out. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}