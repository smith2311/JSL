import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/widgets/notification_filter_row.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String selectedFilter = AppStrings.notificationFilters.first; // default "All"

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "icon": Icons.check_circle,
        "title": "Mutual Fund autopay was Successful",
        "subtitle": "₹4000 for your SIP was Successful",
        "time": "11 hour ago",
        "type": "SIPs",
      },
      {
        "icon": Icons.account_balance_wallet,
        "title": "MF Weekly Portfolio Update",
        "subtitle":
        "Current Value: ₹34,000.45\nInvested Value: ₹18,000.45\nReturns: ₹14000.45 • 85.55%",
        "time": "11 hour ago",
        "type": "Investments",
      },
      {
        "icon": Icons.notifications,
        "title": "New Updates",
        "subtitle":
        "Lorem ipsum dolor sit amet consectetur. At eget vitae pretium facilisi aliquam.",
        "time": "11 hour ago",
        "type": "Portfolio Updates",
      },
    ];

    // filter notifications based on selection
    final filteredNotifications = selectedFilter == "All"
        ? notifications
        : notifications
        .where((n) => n["type"] == selectedFilter)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-18, 0),
          child: const Text(
            "Notifications",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            AppStrings.back_icon,
            height: 26,
            width: 26,
          ),
        ),
      ),
      body: Column(
        children: [
          // ✅ Custom filter row widget
          NotificationFilterRow(
            selectedFilter: selectedFilter,
            onFilterSelected: (filter) {
              setState(() {
                selectedFilter = filter;
              });
            },
          ),

          // Notifications list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16,8,16,16),
              itemCount: filteredNotifications.length,
              separatorBuilder: (_, __) =>

              const SizedBox(height: 12),

              itemBuilder: (context, index) {
                final item = filteredNotifications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item["icon"] as IconData,
                          color: Color(0xFF0060A6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["time"] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item["title"] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item["subtitle"] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}