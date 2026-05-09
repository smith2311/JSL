import 'package:flutter/material.dart';
import '../providers/onetime_startsip_provider.dart';

class BseAccountSelectorWidget extends StatelessWidget {
  final List<BseAccount> accounts;
  final BseAccount? selectedAccount;
  final Function(BseAccount?) onChanged;
  final bool isLoading;

  const BseAccountSelectorWidget({
    Key? key,
    required this.accounts,
    required this.selectedAccount,
    required this.onChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            'Select BSE Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                isExpanded: true,
                value: selectedAccount?.bseClientId,
                hint: Text(
                  isLoading ? 'Loading...' : 'Select BSE Account',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                padding:
                const EdgeInsets.symmetric(horizontal: 16,vertical: 2),
                items: accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account.bseClientId,
                    child: Text(
                      account.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                  if (value != null) {
                    final selected = accounts.firstWhere(
                          (acc) => acc.bseClientId == value,
                    );
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),

          // BSE ID display (only when account selected)
          if (selectedAccount != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'BSE ID: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF818990),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: (selectedAccount!.bseClientId.isNotEmpty)
                          ? selectedAccount!.bseClientId
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: (selectedAccount!.bseClientId.isNotEmpty)
                            ? Colors.black87
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}