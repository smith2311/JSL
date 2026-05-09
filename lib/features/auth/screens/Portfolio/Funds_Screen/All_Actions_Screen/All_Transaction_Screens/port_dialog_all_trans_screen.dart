import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../../providers/all_trans_provider.dart';
import '../../../../../../../../widgets/all_transaction_card.dart';

class PortDialogAllTrans extends ConsumerStatefulWidget {
  final int fundId;
  final String folioNo;
  final String fundName;

  const PortDialogAllTrans({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.fundName,
  });

  @override
  ConsumerState<PortDialogAllTrans> createState() => _PortDialogAllTransState();
}

class _PortDialogAllTransState extends ConsumerState<PortDialogAllTrans> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final params = AllTransactionsParams(
        fundId: widget.fundId,
        folioNo: widget.folioNo,
      );
      final state = ref.read(allTransactionsProvider(params));

      state.whenData((data) {
        if (data.hasMore && !data.isLoadingMore) {
          ref.read(allTransactionsProvider(params).notifier).fetchTransactions();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = AllTransactionsParams(
      fundId: widget.fundId,
      folioNo: widget.folioNo,
    );
    final transactionsAsync = ref.watch(allTransactionsProvider(params));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Transaction',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (state) {
          if (state.transactions.isEmpty) {
            return const EmptyTransactionsState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(allTransactionsProvider(params).notifier).fetchTransactions(refresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.transactions.length) {
                  return const LoadingIndicatorWidget();
                }

                final transaction = state.transactions[index];
                return TransactionCard(transaction: transaction);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0060A6),
          ),
        ),
        error: (error, stack) => ErrorTransactionsState(
          error: error.toString(),
          params: params,
        ),
      ),
    );
  }
}

class EmptyTransactionsState extends StatelessWidget {
  const EmptyTransactionsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888898),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorTransactionsState extends ConsumerWidget {
  final String error;
  final AllTransactionsParams params;

  const ErrorTransactionsState({
    super.key,
    required this.error,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(allTransactionsProvider(params).notifier).reset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060A6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicatorWidget extends StatelessWidget {
  const LoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0060A6),
        ),
      ),
    );
  }
}