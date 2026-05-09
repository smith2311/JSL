import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../constants/strings.dart';
import '../../../../../../providers/request_services_provider.dart';
import '../../../../../../widgets/request_service_form.dart';
class RequestServicesScreen extends ConsumerWidget {
  const RequestServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedServiceIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (selectedIndex != null) {
              ref.read(selectedServiceIndexProvider.notifier).state = null;
            } else {
              context.pop(); // works now with push()
            }
          },
        ),
        title: Text(
          selectedIndex != null
              ? AppStrings.requestServices[selectedIndex]['title']
              : 'Request Services',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: selectedIndex != null
          ? RequestServiceForm(serviceIndex: selectedIndex)
          : _buildServiceList(ref),
    );
  }

  Widget _buildServiceList(WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: AppStrings.requestServices.length,
            itemBuilder: (context, index) {
              final item = AppStrings.requestServices[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ref.read(selectedServiceIndexProvider.notifier).state = index;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xffe3f3fe),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                item['icon'],
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
