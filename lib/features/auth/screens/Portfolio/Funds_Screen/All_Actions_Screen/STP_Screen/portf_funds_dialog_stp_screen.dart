import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../../providers/switch_funds_provider.dart';
import 'dart:async';

class StpDialogFundsScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String fundName;
  final double availableUnits;
  final double availableAmount;
  final String folioNo;
  final String clientId;
  final String clientName;

  const StpDialogFundsScreen({
    super.key,
    required this.fundId,
    required this.fundName,
    required this.availableUnits,
    required this.availableAmount,
    required this.folioNo,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<StpDialogFundsScreen> createState() => _StpDialogFundsScreenState();
}

class _StpDialogFundsScreenState extends ConsumerState<StpDialogFundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    print('🔍 StpDialogFundsScreen initialized with:');
    print('   fundId: ${widget.fundId}');
    print('   fundName: ${widget.fundName}');
    print('   availableUnits: ${widget.availableUnits}');
    print('   availableAmount: ${widget.availableAmount}');
    print('   folioNo: ${widget.folioNo}');
    print('   clientId: ${widget.clientId}');
    print('   clientName: ${widget.clientName}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(
        switchFundsProvider(SwitchFundsParams(fundId: widget.fundId)).notifier,
      );
      final state = ref.read(
        switchFundsProvider(SwitchFundsParams(fundId: widget.fundId)),
      );

      state.whenData((data) {
        if (data.hasMore) {
          notifier.fetchFunds();
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isEmpty) {
        ref
            .read(switchFundsProvider(
            SwitchFundsParams(fundId: widget.fundId))
            .notifier)
            .clearSearch();
      } else {
        ref
            .read(switchFundsProvider(
            SwitchFundsParams(fundId: widget.fundId))
            .notifier)
            .searchFunds(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final switchFundsState = ref.watch(
      switchFundsProvider(SwitchFundsParams(fundId: widget.fundId)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'STP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // STPFrom Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STP out from',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888898),
                  ),
                ),
                const SizedBox(height: 12),
                // Fund Icon and Name
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        AppStrings.iconFunds_png,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.fundName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Units',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888898),
                          ),
                        ),
                        Text(
                          widget.availableUnits.toStringAsFixed(3),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888898),
                          ),
                        ),
                        Text(
                          '₹${widget.availableAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'STP to',
                  hintStyle: const TextStyle(
                    color: Color(0xFF888898),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF888898),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xFF888898),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fund List
          Expanded(
            child: switchFundsState.when(
              data: (data) {
                if (data.funds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.searchTerm.isNotEmpty
                              ? 'No funds found for "${data.searchTerm}"'
                              : 'No funds available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888898),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.funds.length + (data.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == data.funds.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0060A6),
                          ),
                        ),
                      );
                    }

                    final fund = data.funds[index];
                    return _buildFundCard(fund);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading funds',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(switchFundsProvider(
                            SwitchFundsParams(fundId: widget.fundId))
                            .notifier)
                            .fetchFunds(refresh: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                      ),
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

  Widget _buildFundCard(fund) {
    final isPositiveReturn = fund.returnPercentage >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Validate fund data
            if (fund.fundId == null || fund.fundName == null) {
              print('❌ Invalid fund data: $fund');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid fund data')),
              );
              return;
            }

            // Validate widget data
            if (widget.fundId == 0 || widget.folioNo.isEmpty || widget.clientId.isEmpty) {
              print('❌ Invalid widget data: fundId=${widget.fundId}, folioNo=${widget.folioNo}, clientId=${widget.clientId}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid fund or client details')),
              );
              return;
            }

            print('🔍 Selected fund: ${fund.fundId}');
            print('   fundName: ${fund.fundName}');
            print('   fundType: ${fund.fundType}');
            print('   fundSubType: ${fund.fundSubType}');
            print('🚀 Navigating to STP-fund-detail...');

            context.pushNamed(
              'stp-fund-detail',
              extra: {
                'fromFundId': widget.fundId,
                'fromFundName': widget.fundName,
                'toFundId': fund.fundId,
                'toFundName': fund.fundName,
                'toFundType': fund.fundType ?? '',
                'toFundSubType': fund.fundSubType ?? '',
                'availableUnits': widget.availableUnits,
                'availableAmount': widget.availableAmount,
                'folioNo': widget.folioNo,
                'clientId': widget.clientId,
                'clientName': widget.clientName,
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    AppStrings.iconFunds_png,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fund.fundName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fund.fundType} • ${fund.fundSubType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888898),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isPositiveReturn ? '+' : ''}${fund.returnPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositiveReturn
                        ? const Color(0xFF00A651)
                        : const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}