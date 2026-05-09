import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class ActionBottomSheet extends StatelessWidget {
  final int fundId;
  final String folioNo;
  final String clientId;
  final String fundName;
  final double availableUnits;
  final double availableAmount;
  final String clientName;

  const ActionBottomSheet({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.clientId,
    required this.fundName,
    required this.availableUnits,
    required this.availableAmount,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionTile(
                context,
                icon: Icons.file_present,
                title: AppStrings.all_trans,
                onTap: () {
                  Navigator.pop(context);
                  print('📋 Navigating to All Transactions with:');
                  print('   fundId: $fundId');
                  print('   folioNo: $folioNo');
                  print('   fundName: $fundName');

                  context.pushNamed(
                    'all-transactions',
                    extra: {
                      'fundId': fundId,
                      'folioNo': folioNo,
                      'fundName': fundName,
                    },
                  );
                },
              ),

              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.autorenew,
                title: AppStrings.swi,
                onTap: () {
                  Navigator.pop(context);
                  print('🔍 Navigating to switch with:');
                  print('   fundId: $fundId');
                  print('   fundName: $fundName');
                  print('   availableUnits: $availableUnits');
                  print('   availableAmount: $availableAmount');
                  print('   folioNo: $folioNo');
                  print('   clientId: $clientId');
                  print('   clientName: $clientName');

                  context.pushNamed(
                    'switch-funds',
                    extra: {
                      'fundId': fundId,
                      'folioNo': folioNo,
                      'clientId': clientId,
                      'fundName': fundName,
                      'availableUnits': availableUnits,
                      'availableAmount': availableAmount,
                      'clientName': clientName,
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.monetization_on_outlined,
                title: AppStrings.red,
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    'redeem',
                    extra: {
                      'fundId': fundId,
                      'folioNo': folioNo,
                      'client_id': clientId,
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.swap_horiz,
                title: AppStrings.stp,
                  onTap: () {
                    Navigator.pop(context);
                    print('🔍 Navigating to switch with:');
                    print('   fundId: $fundId');
                    print('   fundName: $fundName');
                    print('   availableUnits: $availableUnits');
                    print('   availableAmount: $availableAmount');
                    print('   folioNo: $folioNo');
                    print('   clientId: $clientId');
                    print('   clientName: $clientName');

                    context.pushNamed(
                      'stp-dialog-funds',
                      extra: {
                        'fundId': fundId,
                        'folioNo': folioNo,
                        'clientId': clientId,
                        'fundName': fundName,
                        'availableUnits': availableUnits,
                        'availableAmount': availableAmount,
                        'clientName': clientName,
                      },
                    );
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.trending_down,
                title: AppStrings.swp,
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    'portfolio-funds-swp',
                    extra: {
                      'fundId': fundId,
                      'folioNo': folioNo,
                      'clientId': clientId,
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F3FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0060A6),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF888898),
        ),
      ),
    );
  }
}