import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../constants/strings.dart';
import '../../../../../../providers/user_orders.dart';
import '../../../../../../providers/family_members_provider.dart';
import '../../../../../../widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Fetch initial orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedMemberState = ref.read(selectedMemberProvider);
      final clientIds = selectedMemberState.isMeSelected
          ? <int>[]
          : selectedMemberState.clientIds.cast<int>();

      ref.read(ordersProvider.notifier).fetchOrders(
        clientIds: clientIds,
        refresh: true,
      );
    });
  }

  void _onScroll() {
    // Check if user is near the bottom (100 pixels before the end)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final ordersState = ref.read(ordersProvider);

      // Only load more if not already loading and has more data
      if (!ordersState.isLoadingMore && ordersState.hasMore) {
        final selectedMemberState = ref.read(selectedMemberProvider);
        final clientIds = selectedMemberState.isMeSelected
            ? <int>[]
            : selectedMemberState.clientIds.cast<int>();

        print('🔄 Loading more orders...');
        ref.read(ordersProvider.notifier).fetchOrders(clientIds: clientIds);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final ordersNotifier = ref.read(ordersProvider.notifier);
    final selectedMemberState = ref.watch(selectedMemberProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 16, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/user_profile'),
                    child: SvgPicture.asset(
                      AppStrings.back_icon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    AppStrings.orders_title_lbl,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: ordersState.isLoading && ordersState.orders.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              )
                  : ordersState.error != null && ordersState.orders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        ordersState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final clientIds = selectedMemberState.isMeSelected
                            ? <int>[]
                            : selectedMemberState.clientIds.cast<int>();
                        ordersNotifier.fetchOrders(
                          clientIds: clientIds,
                          refresh: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
                  : ordersState.orders.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () {
                  final clientIds = selectedMemberState.isMeSelected
                      ? <int>[]
                      : selectedMemberState.clientIds.cast<int>();
                  return ordersNotifier.fetchOrders(
                    clientIds: clientIds,
                    refresh: true,
                  );
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ordersState.orders.length +
                      (ordersState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom
                    if (index >= ordersState.orders.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ordersState.isLoadingMore
                              ? const CircularProgressIndicator(
                            color: Color(0xFF0060A6),
                          )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final order = ordersState.orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to order details
                          final orderId = order["order_id"];
                          if (orderId != null) {
                            context.push('/order-details/$orderId');
                          }
                        },
                        child: OrderCard(
                          logoPath: AppStrings.iconFunds_png,
                          fundName: order["fund_name"] ?? "",
                          clientName: order["client_name"] ?? "",
                          orderStatus: order["order_status"] ?? "",
                          investedAmount:
                          (order["invested_amount"] as num?)
                              ?.toDouble() ??
                              0,
                          investmentDate: order["investment_date"] ?? "",
                          bseId: order["bse_id"] ?? "",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}