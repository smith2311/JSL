import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../providers/nominee_list_provider.dart';
import '../../../../../../../widgets/nominee_card.dart';

class NomineeCentreScreen extends ConsumerStatefulWidget {
  final String bseClientId;

  const NomineeCentreScreen({
    super.key,
    required this.bseClientId,
  });

  @override
  ConsumerState<NomineeCentreScreen> createState() => _NomineeCentreScreenState();
}

class _NomineeCentreScreenState extends ConsumerState<NomineeCentreScreen> {

  @override
  void initState() {
    super.initState();
    // ✅ Load nominees when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nomineeListProvider(widget.bseClientId).notifier).refresh(widget.bseClientId);
    });
  }

  void _handleEdit(int index) async {
    // ✅ Get the CURRENT state of nominees before navigating
    final nomineesAsync = ref.read(nomineeListProvider(widget.bseClientId));
    final nominees = nomineesAsync.value ?? [];

    // Navigate to edit screen
    await context.pushNamed(
      'add_nominee',
      extra: {
        'bseClientId': widget.bseClientId,
        'existingNominees': nominees,
        'initialTab': index,
      },
    );

    // ✅ CRITICAL: Refresh the list when returning from edit screen
    if (mounted) {
      ref.read(nomineeListProvider(widget.bseClientId).notifier).refresh(widget.bseClientId);
    }
  }

  void _handleAddNominee() async {
    // ✅ Get current nominees to pass to add screen
    final nomineesAsync = ref.read(nomineeListProvider(widget.bseClientId));
    final nominees = nomineesAsync.value ?? [];

    await context.pushNamed(
      'add_nominee',
      extra: {
        'bseClientId': widget.bseClientId,
        'existingNominees': nominees,
      },
    );

    // ✅ Refresh after returning
    if (mounted) {
      ref.read(nomineeListProvider(widget.bseClientId).notifier).refresh(widget.bseClientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomineesAsync = ref.watch(nomineeListProvider(widget.bseClientId));

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
          'Nominee Centre',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: nomineesAsync.when(
        data: (nominees) {
          if (nominees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No nominees added yet'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleAddNominee,
                    child: const Text('Add Nominee'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: nominees.length,
                  itemBuilder: (context, index) {
                    return NomineeCard(
                      nominee: nominees[index],
                      index: index,
                      onEdit: () => _handleEdit(index),
                    );
                  },
                ),
              ),
              if (nominees.length < 3)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _handleAddNominee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066A6),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add Another Nominee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(nomineeListProvider(widget.bseClientId).notifier)
                      .refresh(widget.bseClientId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}