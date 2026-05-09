import 'package:flutter/material.dart';

class BankAccountCard extends StatefulWidget {
  final String accountNumber;
  final String ifscCode;
  final String accountOwner;
  final String accountType;
  final VoidCallback? onDelete;

  const BankAccountCard({
    super.key,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountOwner,
    required this.accountType,
    this.onDelete,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  bool _isDeleting = false;

  String _maskAccountNumber(String accountNo) {
    if (accountNo.length <= 4) return accountNo;
    final lastFour = accountNo.substring(accountNo.length - 4);
    return 'XX XXXX $lastFour';
  }

  void _handleDelete() async {
    if (_isDeleting || widget.onDelete == null) return;
    debugPrint('Delete button pressed for account: ${widget.accountNumber}');
    setState(() {
      _isDeleting = true;
    });
    await Future.delayed(const Duration(milliseconds: 300)); // simulate delay
    widget.onDelete!();
    if (mounted) {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, // subtle tap feedback, no action
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row: Icon, Account Number, Delete Button
              Row(
                children: [
                  // Bank Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0060A6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Account Number and IFSC
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _maskAccountNumber(widget.accountNumber),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.ifscCode,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete Icon Button or Loading Indicator
                  IconButton(
                    onPressed: _isDeleting ? null : _handleDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 26,
                          ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom Row: Account Owner and Account Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Account Owner
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Owner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.accountOwner,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Account Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Account Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.accountType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}