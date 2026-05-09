import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../constants/strings.dart';
import '../../../../../../providers/family_members_provider.dart';
import '../../../data/repo/portfolio_vs_repo.dart';

// State providers for form fields
final portfolioValuationGroupProvider = StateProvider<String?>((ref) => null);
final transactionUptoDateProvider = StateProvider<DateTime?>((ref) => null);

// Repository provider
final portfolioValuationRepositoryProvider = Provider<PortfolioValuationRepository>((ref) {
  return PortfolioValuationRepository();
});

// Download state provider
final isPortfolioValuationDownloadingProvider = StateProvider<bool>((ref) => false);

class PortfolioValuationSummaryScreen extends ConsumerStatefulWidget {
  const PortfolioValuationSummaryScreen({super.key});

  @override
  ConsumerState<PortfolioValuationSummaryScreen> createState() =>
      _PortfolioValuationSummaryScreenState();
}

class _PortfolioValuationSummaryScreenState
    extends ConsumerState<PortfolioValuationSummaryScreen> {

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          await OpenFile.open(response.payload);
        }
      },
    );
  }

  Future<void> _showDownloadNotification(String filePath) async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'download_channel',
      'Download Notifications',
      channelDescription: 'Notifications for downloaded reports',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Portfolio Valuation Report Downloaded',
      'Tap to open the report',
      notificationDetails,
      payload: filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroup = ref.watch(portfolioValuationGroupProvider);
    final transactionDate = ref.watch(transactionUptoDateProvider);
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final isDownloading = ref.watch(isPortfolioValuationDownloadingProvider);

    // Form validation
    final isFormValid = selectedGroup != null && transactionDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/reports'),
        ),
        title: const Text(
          'MF Portfolio Valuation Summary',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Group Dropdown
                    const Text(
                      'Select Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    familyMembersAsync.when(
                      data: (familyMembersState) {
                        final groupOptions = [
                          {
                            'id': 'all',
                            'name': 'All Family Members',
                          },
                          ...familyMembersState.allMembers.map((member) => {
                            'id': member.clientId.toString(),
                            'name': member.clientName,
                          }),
                        ];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedGroup,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Select',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.keyboard_arrow_down),
                              ),
                              items: groupOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option['id']?.toString(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      option['name']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                ref.read(portfolioValuationGroupProvider.notifier).state = value;
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0060A6)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading family members...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Failed to load family members',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(familyMembersProvider.notifier)
                                  .fetchFamilyMembers(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Consider Transactions upto Date Picker
                    const Text(
                      'Consider Transactions upto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTransactionDate(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: transactionDate == null
                                ? Colors.grey.shade300
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transactionDate != null
                                  ? DateFormat('dd/MM/yyyy').format(transactionDate)
                                  : 'Select',
                              style: TextStyle(
                                fontSize: 16,
                                color: transactionDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                            SvgPicture.asset(
                              AppStrings.calender,
                              color: const Color(0xFF0060A6),
                              height: 25,
                              width: 25,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isFormValid && !isDownloading)
                                ? () => _handleDownload(context, ref)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0060A6),
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: isDownloading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (isFormValid && !isDownloading)
                                ? () => _handleEmail(context, ref)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: (isFormValid && !isDownloading)
                                    ? const Color(0xFF0060A6)
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Email',
                              style: TextStyle(
                                color: (isFormValid && !isDownloading)
                                    ? const Color(0xFF0060A6)
                                    : Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isDownloading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectTransactionDate(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    final transactionDate = ref.read(transactionUptoDateProvider);

    DateTime initialDate = transactionDate ?? now;
    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0060A6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(transactionUptoDateProvider.notifier).state = picked;
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final permissionStatus = await _requestStoragePermission();

    if (!permissionStatus) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download the report.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final selectedGroup = ref.read(portfolioValuationGroupProvider);
    final transactionDate = ref.read(transactionUptoDateProvider);
    final familyMembersState = ref.read(familyMembersProvider).value;

    if (familyMembersState == null) return;

    // 🧾 Prepare client IDs
    List<int> clientIds = [];
    if (selectedGroup == 'all') {
      clientIds = familyMembersState.allMembers
          .map((member) => member.clientId)
          .toList();
    } else {
      clientIds = [int.parse(selectedGroup!)];
    }

    // 📅 Format date for API (yyyy-MM-dd)
    final formattedDate = transactionDate != null
        ? DateFormat('yyyy-MM-dd').format(transactionDate)
        : '';

    // 🔄 Set loading state
    ref.read(isPortfolioValuationDownloadingProvider.notifier).state = true;

    try {
      final repository = ref.read(portfolioValuationRepositoryProvider);
      final result = await repository.downloadPortfolioValuationReport(
        clientIds: clientIds,
        transactionUptoDate: formattedDate,
      );

      if (context.mounted) {
        if (result['success']) {
          if (result['filePath'] != null) {
            await _showDownloadNotification(result['filePath']);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Report downloaded successfully.'),
              backgroundColor: const Color(0xFF0060A6),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'No data available.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.read(isPortfolioValuationDownloadingProvider.notifier).state = false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    if (await Permission.photos.isGranted ||
        await Permission.mediaLibrary.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  void _handleEmail(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.read(portfolioValuationGroupProvider);
    final transactionDate = ref.read(transactionUptoDateProvider);

    print('Email Report:');
    print('  Group: $selectedGroup');
    print('  Transaction Date: ${transactionDate != null ? DateFormat('dd/MM/yyyy').format(transactionDate) : 'N/A'}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending report via email...'),
        backgroundColor: Color(0xFF0060A6),
      ),
    );

    // TODO: Implement actual email logic
  }
}