import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../providers/acc_det_mf_provider.dart';
import '../../../../../../providers/account_details_provider.dart';
import '../../../../../../providers/family_members_provider.dart';
import '../../../../../../providers/onetime_startsip_provider.dart';
import '../../../../../../widgets/bse_acc_selector.dart';
import '../../../../../../widgets/tile_widget.dart';
import '../../../data/models/account_details.dart';
import '../../../data/repo/acc_det_mf_tab_repo.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  int _selectedTab = 0;
  int? _selectedClientId;
  BseAccount? selectedBseAccount;
  bool _hasInitializedBseAccount = false;
  bool _hasInitializedMember = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyMembersProvider.notifier).fetchFamilyMembers();
    });
  }

  void _showMemberSelector() {
    final familyMembersState = ref.read(familyMembersProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title - LEFT ALIGNED
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.fam_lbl,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: familyMembersState.when(
                        data: (familyData) {
                          return ListView(
                            controller: scrollController,
                            children: [
                              // Individual family members with background and radio button
                              ...familyData.allMembers.map((member) {
                                final isSelected = _selectedClientId == member.clientId;
                                return Container(
                                  color: isSelected ? Colors.grey[300] : Colors.transparent,
                                  child: ListTile(
                                    leading: SvgPicture.asset(
                                      AppStrings.curr_user,
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF0060A6),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    title: Text(member.clientName),
                                    trailing: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0060A6),
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF0060A6)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Center(
                                        child: Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      )
                                          : null,
                                    ),
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      setState(() {
                                        _selectedClientId = member.clientId;
                                        selectedBseAccount = null;
                                        _hasInitializedBseAccount = false;
                                      });
                                      ref.read(AccountProfileProvider.notifier)
                                          .fetchProfile(member.clientId);
                                      ref.read(bseAccountProvider.notifier)
                                          .fetchAccounts(member.clientId);
                                      ref.read(mutualFundDetailsProvider.notifier).reset();
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: Color(0xFF0060A6)),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text('Error: ${err.toString()}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(familyMembersProvider.notifier).fetchFamilyMembers();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyMembersProvider);
    final profileState = ref.watch(AccountProfileProvider);
    final bseAccountsAsync = ref.watch(bseAccountProvider);

    // Initialize with current user when family members are loaded
    familyState.whenData((state) {
      if (!_hasInitializedMember && state.currentUser != null && _selectedClientId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedClientId = state.currentUser!.clientId;
            _hasInitializedMember = true;
          });

          // Fetch profile and BSE accounts for the current user
          ref.read(AccountProfileProvider.notifier).fetchProfile(state.currentUser!.clientId);
          ref.read(bseAccountProvider.notifier).fetchAccounts(state.currentUser!.clientId);
        });
      }
    });

    // Auto-select first BSE account when accounts are loaded
    bseAccountsAsync.whenData((accounts) {
      if (!_hasInitializedBseAccount && accounts.isNotEmpty && selectedBseAccount == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedBseAccount = accounts.first;
            _hasInitializedBseAccount = true;
          });
          // Fetch mutual fund details for the first account
          ref.read(mutualFundDetailsProvider.notifier)
              .fetchDetails(accounts.first.bseClientId);
        });
      }
    });

    String selectedMemberName = '';
    familyState.whenData((state) {
      if (state.allMembers.isNotEmpty && _selectedClientId != null) {
        final member = state.allMembers.firstWhere(
              (m) => m.clientId == _selectedClientId,
          orElse: () => state.allMembers.first,
        );
        selectedMemberName = member.clientName;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F3F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/user_profile'),
        ),
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          familyState.maybeWhen(
            data: (familyData) {
              if (familyData.allMembers.length <= 1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: _showMemberSelector,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Color(0xFF0060A6), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          selectedMemberName.isNotEmpty
                              ? (selectedMemberName.length > 15
                              ? '${selectedMemberName.substring(0, 15)}...'
                              : selectedMemberName)
                              : 'Select',
                          style: const TextStyle(
                            color: Color(0xFF0060A6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF0060A6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTab('My Profile', 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTab('Mutual Fund', 1)),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: profileState.when(
              data: (profile) {
                if (_selectedTab == 0) {
                  return _buildMyProfileTab(profile);
                } else {
                  return _buildMutualFundTab(profile);
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedClientId != null) {
                          ref.read(AccountProfileProvider.notifier).fetchProfile(_selectedClientId!);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyProfileTab(AccountDetails profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combined Name and Details Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name section with blue background
                Padding(
                  padding: const EdgeInsets.only(top: 3.0,right: 3.0,left: 3.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0060A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Details section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow('Gender', profile.gender ?? '-'),
                      _buildDetailRow('Group Code', profile.groupCode ?? '-'),
                      _buildDetailRow('Customer Type', profile.customerType ?? '-'),
                      _buildDetailRow('PAN Number', profile.panNumber ?? '-'),
                      _buildDetailRow('Mobile', profile.mobile ?? '-'),
                      _buildDetailRow('Email ID', profile.emailId ?? '-', isLast: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Family Members Card using DetailTile
          DetailTile(
            icon: Icons.people,
            iconColor: const Color(0xFF0060A6),
            iconBgColor: const Color(0xFFE3F2FD),
            title: 'Family Members',
            onTap: () {
              context.push('/family-members');

            },
          ),

          const SizedBox(height: 24),

          // RM Details Section
          const Text(
            'RM Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('RM Name', profile.rmName ?? '-'),
                _buildDetailRow('RM Email', profile.rmEmail ?? '-', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualFundTab(AccountDetails profile) {
    return Consumer(
      builder: (context, ref, _) {
        final bseAccountsAsync = ref.watch(bseAccountProvider);
        final mutualFundDetailsAsync = ref.watch(mutualFundDetailsProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // BSE Account Selector
              bseAccountsAsync.when(
                data: (accounts) {
                  return BseAccountSelectorWidget(
                    accounts: accounts,
                    selectedAccount: selectedBseAccount,
                    onChanged: (account) {
                      setState(() {
                        selectedBseAccount = account;
                      });

                      if (account != null) {
                        // Fetch mutual fund details when account is selected
                        ref.read(mutualFundDetailsProvider.notifier)
                            .fetchDetails(account.bseClientId);
                      } else {
                        // Reset if no account selected
                        ref.read(mutualFundDetailsProvider.notifier).reset();
                      }
                    },
                    isLoading: false,
                  );
                },
                loading: () => Container(
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0060A6),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading accounts...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                error: (e, st) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Error loading BSE accounts: ${e.toString()}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedClientId != null) {
                            ref.read(bseAccountProvider.notifier)
                                .fetchAccounts(_selectedClientId!);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

              // Client Details Card (shown only when BSE account is selected)
              if (selectedBseAccount != null) ...[
                const SizedBox(height: 16),
                mutualFundDetailsAsync.when(
                  data: (details) => _buildClientDetailsCard(details),
                  loading: () => Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0060A6),
                      ),
                    ),
                  ),
                  error: (e, st) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error: ${e.toString()}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedBseAccount != null) {
                              ref.read(mutualFundDetailsProvider.notifier)
                                  .fetchDetails(selectedBseAccount!.bseClientId);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Linked Bank Accounts using DetailTile
                DetailTile(
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFF0060A6),
                  iconBgColor: const Color(0xFFE3F2FD),
                  title: 'Linked Bank Accounts',
                  onTap: () {
                   if(selectedBseAccount != null){
                     context.pushNamed('bank_detail_screen',extra: {
                       'bseClientId': selectedBseAccount!.bseClientId,

                     });
                   }
                   else{
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                       content: Text('Please Select a BSE Account'),
                     backgroundColor: Colors.red,
                     ),);
                   }
                   },
                ),

                const SizedBox(height: 16),

                // Nominee Center using DetailTile
                DetailTile(
                  iconColor: const Color(0xFF0060A6),
                  svgAsset: AppStrings.contact,
                  iconBgColor: const Color(0xFFE3F2FD),
                  title: 'Nominee Center',
                  onTap: () {
                    if (selectedBseAccount != null) {
                      context.pushNamed('nominee_centre', extra: {'bseClientId': selectedBseAccount!.bseClientId});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please Select a BSE Account'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // All Mandates using DetailTile
                DetailTile(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF0060A6),
                  iconBgColor: const Color(0xFFE3F2FD),
                  title: 'All Mandates',
                  onTap: () {
                    if(selectedBseAccount != null){
                      context.pushNamed('all_mandates',
                          extra: {
                        'bseClientId': selectedBseAccount!.bseClientId,
                      });
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please Select a BSE Account'),
                        backgroundColor: Colors.red,
                      ),);
                    }
                  },
                ),

                SizedBox(height: 70,),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientDetailsCard(MutualFundDetails details) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name section with blue background
          Padding(
            padding: const EdgeInsets.only(left: 3.0, right: 3.0, top: 4.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Client Name',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0060A6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Holding Pattern', details.holdingPattern),
                _buildDetailRow('PAN No', details.panNo),
                _buildDetailRow('Tax Status', details.taxStatus),
                _buildDetailRow('Date of Birth', details.dateOfBirth),
                _buildDetailRow('Email', details.email),
                _buildDetailRow('Mobile', details.mobile, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // if (!isLast)
        //   Divider(
        //     height: 1,
        //     color: Colors.grey[300],
        //   ),
      ],
    );
  }
}