import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../providers/onetime_startsip_provider.dart';
import '../../../../../widgets/custom_text_dropdown.dart';
import '../../constants/messages.dart';
import '../../features/auth/data/models/family_member.dart';

class AccountSelectionCard extends ConsumerWidget {
  final int fundId;
  final int selectedTab;
  final FutureProvider<List<FamilyMember>> familyMembersProvider;
  final FamilyMember? selectedClient;
  final BseAccount? selectedBseAccount;
  final String? selectedFolio;
  final Mandate? selectedMandate;
  final bool bseAccountsFetched;
  final bool foliosFetched;
  final bool mandatesFetched;
  final Function(FamilyMember?, bool, bool, bool) onClientChanged;
  final Function(BseAccount?, bool) onBseAccountChanged;
  final Function(String?) onFolioChanged;
  final Function(Mandate?) onMandateChanged;
  final VoidCallback onResetMinAmounts;

  static const double NEW_FOLIO_MIN_AMOUNT = 5000.0;

  const AccountSelectionCard({
    super.key,
    required this.fundId,
    required this.selectedTab,
    required this.familyMembersProvider,
    required this.selectedClient,
    required this.selectedBseAccount,
    required this.selectedFolio,
    required this.selectedMandate,
    required this.bseAccountsFetched,
    required this.foliosFetched,
    required this.mandatesFetched,
    required this.onClientChanged,
    required this.onBseAccountChanged,
    required this.onFolioChanged,
    required this.onMandateChanged,
    required this.onResetMinAmounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);

    return membersAsync.when(
      data: (familyMembers) {
        // Initialize selected client
        final currentClient = selectedClient ?? familyMembers.firstWhere(
              (member) => member.isCurrentUser,
          orElse: () => familyMembers[0],
        );

        // Check if there's only one member
        final bool isSingleMember = familyMembers.length <= 1;

        // Fetch BSE accounts and folios if not yet fetched
        Future.microtask(() {
          if (!bseAccountsFetched) {
            ref.read(bseAccountProvider.notifier).fetchAccounts(currentClient.clientId);
            ref.read(folioProvider.notifier).fetchFolios(currentClient.clientId);
            onClientChanged(currentClient, true, true, false);
          }
        });

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Only show client dropdown if there are multiple members
                if (!isSingleMember) ...[
                  _buildClientDropdown(familyMembers, currentClient, ref),
                  const SizedBox(height: 8),
                ],
                _buildBseAccountDropdown(ref),
                if (selectedBseAccount != null) ...[
                  const SizedBox(height: 12),
                  _buildBseAccountDetails(),
                  if (selectedTab == 1) ...[
                    const SizedBox(height: 8),
                    _buildMandateSection(ref),
                  ],
                  const SizedBox(height: 8),
                  _buildFolioDropdown(ref),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildClientDropdown(List<FamilyMember> familyMembers,
      FamilyMember currentClient, WidgetRef ref) {
    return CustomDropdownCard(
      label: AppStrings.sel_acc,
      items: familyMembers.map((e) => e.clientName).toList(),
      selectedValue: currentClient.clientName,
      hintText: AppStrings.select,
      isEnabled: true,
      onChanged: (value) {
        final newClient = familyMembers.firstWhere((e) => e.clientName == value);
        onClientChanged(newClient, false, false, false);
        onBseAccountChanged(null, false);
        onFolioChanged(null);
        onMandateChanged(null);
        onResetMinAmounts();

        ref.read(bseAccountProvider.notifier).fetchAccounts(newClient.clientId);
        ref.read(folioProvider.notifier).fetchFolios(newClient.clientId);
      },
    );
  }

  Widget _buildBseAccountDropdown(WidgetRef ref) {
    final bseAccountsAsync = ref.watch(bseAccountProvider);

    return bseAccountsAsync.when(
      data: (accounts) {
        if (accounts.isNotEmpty && selectedBseAccount == null) {
          Future.microtask(() {
            onBseAccountChanged(accounts[0], selectedTab == 1);
            if (selectedTab == 1) {
              ref.read(mandateProvider.notifier).fetchMandates(accounts[0].bseClientId);
            }
          });
        }

        return CustomDropdownCard(
          label: AppStrings.selc_bse_acc,
          items: accounts.map((e) => e.displayName).toList(),
          selectedValue: selectedBseAccount?.displayName,
          hintText: AppStrings.select,
          onChanged: (value) {
            if (value == null) return;
            final account = accounts.firstWhere((acc) => acc.displayName == value);
            onBseAccountChanged(account, false);
            onMandateChanged(null);

            if (selectedTab == 1) {
              ref.read(mandateProvider.notifier).fetchMandates(account.bseClientId);
              onBseAccountChanged(account, true);
            }
          },
        );
      },
      loading: () => CustomDropdownCard(
        label: AppStrings.selc_bse_acc,
        items: const [],
        hintText: AppStrings.loading,
        onChanged: (_) {},
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildBseAccountDetails() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(AppStrings.orders_bseid_lbl, selectedBseAccount!.bseClientId),
            const SizedBox(height: 4),
            _buildDetailRow(AppStrings.tax_status, selectedBseAccount!.taxStatus),
            const SizedBox(height: 4),
            _buildDetailRow(AppStrings.hol_pat, selectedBseAccount!.holdingStatus),
            const SizedBox(height: 4),
            _buildDetailRow(
              AppStrings.second_holder_name,
              selectedBseAccount!.secondHolderName.isNotEmpty ? selectedBseAccount!.secondHolderName : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Color(0xFF818990))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black)),
      ],
    );
  }

  Widget _buildMandateSection(WidgetRef ref) {
    final mandatesAsync = ref.watch(mandateProvider);

    return mandatesAsync.when(
      data: (mandates) {
        if (mandates.isEmpty) {
          return _buildNoMandatesWarning();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdownCard(
              label: AppStrings.select_mandate,
              items: mandates,
              selectedValue: selectedMandate?.mandateId.toString(),
              hintText: AppStrings.select,
              onChanged: (value) {
                if (value == null) return;
                final selected = mandates.firstWhere((m) => m.mandateId.toString() == value);
                onMandateChanged(selected);
              },
              isMandateDropdown: true,
            ),
            if (selectedMandate != null) ...[
              const SizedBox(height: 12),
              _buildMandateDetails(),
            ],
          ],
        );
      },
      loading: () => CustomDropdownCard(
        label: AppStrings.select_mandate,
        items: const [],
        hintText: AppStrings.loading,
        onChanged: (_) {},
      ),
      error: (e, st) => _buildNoMandatesWarning(),
    );
  }

  Widget _buildNoMandatesWarning() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                ValidationMessages.no_mandate_warning,
                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandateDetails() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(AppStrings.mandate_id, selectedMandate!.mandateId.toString()),
            const SizedBox(height: 4),
            _buildDetailRow(AppStrings.bank_name, selectedMandate!.bankName),
            const SizedBox(height: 4),
            _buildDetailRow(
              AppStrings.account_number,
              selectedMandate!.accountNo.length > 4
                  ? '*' * (selectedMandate!.accountNo.length - 4) + selectedMandate!.accountNo.substring(selectedMandate!.accountNo.length - 4)
                  : selectedMandate!.accountNo,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(AppStrings.ifsc, selectedMandate!.ifsc),
            const SizedBox(height: 4),
            _buildDetailRow(AppStrings.orders_amt_lbl, '₹${selectedMandate!.amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFolioDropdown(WidgetRef ref) {
    final foliosAsync = ref.watch(folioProvider);

    return foliosAsync.when(
      data: (folios) {
        final folioItems = [AppStrings.new_folio, ...folios];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdownCard(
              label: AppStrings.sel_fol,
              items: folioItems,
              selectedValue: selectedFolio,
              hintText: AppStrings.select,
              onChanged: onFolioChanged,
            ),
            if (selectedFolio == AppStrings.new_folio && selectedTab == 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${AppStrings.note_min_investment_new_folio}${NEW_FOLIO_MIN_AMOUNT.toInt()}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5AD8F4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => CustomDropdownCard(
        label: AppStrings.sel_fol,
        items: const [],
        hintText: AppStrings.loading,
        onChanged: (_) {},
      ),
      error: (e, st) => CustomDropdownCard(
        label: AppStrings.sel_fol,
        items: const [AppStrings.new_folio],
        selectedValue: selectedFolio,
        hintText: AppStrings.select,
        onChanged: onFolioChanged,
      ),
    );
  }
}
