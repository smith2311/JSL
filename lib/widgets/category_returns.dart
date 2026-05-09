import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../providers/category_returns_provider.dart';

class CategoryReturnsWidget extends ConsumerStatefulWidget {
  final int fundId;

  const CategoryReturnsWidget({super.key, required this.fundId});

  @override
  ConsumerState<CategoryReturnsWidget> createState() =>
      _CategoryReturnsWidgetState();
}

class _CategoryReturnsWidgetState
    extends ConsumerState<CategoryReturnsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryReturnsProvider.notifier).fetchCategoryReturns(widget.fundId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryReturnsProvider);

    return categoryAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(child: Text("No category return data available"));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Min Returns - Always red
              Expanded(
                child: _buildReturnCard(
                  label: "Min. Returns",
                  value: data.min,
                  valueIcon: AppStrings.down_red,
                  arrowIcon: AppStrings.down_red_arrow,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 16),
              // Max Returns - Always green
              Expanded(
                child: _buildReturnCard(
                  label: "Max. Returns",
                  value: data.max,
                  valueIcon: AppStrings.up_green,
                  arrowIcon: AppStrings.up_green_arrow,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6))),
      error: (error, _) =>
          Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildReturnCard({
    required String label,
    required double value,
    required String valueIcon,
    required String arrowIcon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value + small SVG icon
          Row(
            children: [
              Text(
                "${value.toStringAsFixed(2)}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                valueIcon,
                width: 8,
                height: 8,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Label + arrow SVG
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15,bottom: 10),
                child: SvgPicture.asset(
                  arrowIcon,
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}