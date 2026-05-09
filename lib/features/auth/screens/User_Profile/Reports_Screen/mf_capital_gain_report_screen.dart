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
import '../../../../../constants/messages.dart';
import '../../../data/repo/capital_gain_repo.dart';

// State providers for form fields
final selectedGroupProvider = StateProvider<String?>((ref) => null);
final selectedPeriodProvider = StateProvider<String?>((ref) => null);
final fromDateProvider = StateProvider<DateTime?>((ref) => null);
final toDateProvider = StateProvider<DateTime?>((ref) => null);

final periodOptionsProvider = Provider<List<String>>((ref) {
  return AppStrings.capitalGainPeriods;
});

// Repository provider
final capitalGainRepositoryProvider = Provider<CapitalGainRepository>((ref) {
  return CapitalGainRepository();
});

// Download state provider
final isDownloadingProvider = StateProvider<bool>((ref) => false);

class MfCapitalGainReportScreen extends ConsumerStatefulWidget {
  const MfCapitalGainReportScreen({super.key});

  @override
  ConsumerState<MfCapitalGainReportScreen> createState() =>
      _MfCapitalGainReportScreenState();
}

class _MfCapitalGainReportScreenState
    extends ConsumerState<MfCapitalGainReportScreen> {

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
        // Handle notification tap - open the PDF file
        if (response.payload != null && response.payload!.isNotEmpty) {
          await OpenFile.open(response.payload);
        }
      },
    );
  }

  Future<void> _showDownloadNotification(String filePath) async {
    // Request notification permission for Android 13+
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
      'Capital Gain Report Downloaded',
      'Tap to open the report',
      notificationDetails,
      payload: filePath,
    );
  }

  // Helper function to calculate dates based on period
  Map<String, String> _calculateDatesForPeriod(String period) {
    // Extract the year from period (e.g., "2024-25" -> 2024)
    if (period.toLowerCase() == 'custom') {
      return {'from_date': '', 'to_date': ''};
    }

    // Parse period like "2024-25" or "2023-24"
    final parts = period.split('-');
    if (parts.length == 2) {
      final startYear = int.tryParse(parts[0]);
      final endYearShort = int.tryParse(parts[1]);

      if (startYear != null && endYearShort != null) {
        final endYear = startYear + 1; // 2024-25 means 2024 to 2025

        // Financial year: April 1, startYear to March 31, endYear
        // Format: yyyy-MM-dd
        final fromDate = '$startYear-04-01';
        final toDate = '$endYear-03-31';

        return {'from_date': fromDate, 'to_date': toDate};
      }
    }

    return {'from_date': '', 'to_date': ''};
  }

  // Validation method to check if from date is after to date
  String? _validateDates() {
    final fromDate = ref.read(fromDateProvider);
    final toDate = ref.read(toDateProvider);

    if (fromDate != null && toDate != null) {
      if (fromDate.isAfter(toDate)) {
        return 'From date cannot be after To date';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroup = ref.watch(selectedGroupProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final fromDate = ref.watch(fromDateProvider);
    final toDate = ref.watch(toDateProvider);
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final periodOptions = ref.watch(periodOptionsProvider);
    final isDownloading = ref.watch(isDownloadingProvider);

    // Check if Custom period is selected
    final isCustomPeriod = selectedPeriod == AppStrings.custom;

    // Enhanced form validation
    final dateValidationError = isCustomPeriod ? _validateDates() : null;
    final isFormValid = selectedGroup != null &&
        selectedPeriod != null &&
        (!isCustomPeriod || (fromDate != null && toDate != null && dateValidationError == null));

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
          AppStrings.cap_gain,
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
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
                      AppStrings.sel_grou,
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
                            'name': AppStrings.allFamily['name'],
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
                                  AppStrings.select,
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
                                ref.read(selectedGroupProvider.notifier).state = value;
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
                              AppStrings.load_fam_mem,
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
                                ErrorMessages.fail_fam_mem,
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

                    // Period Dropdown
                    const Text(
                      AppStrings.period,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppStrings.select,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(Icons.keyboard_arrow_down),
                          ),
                          items: periodOptions.map((period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  period,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            ref.read(selectedPeriodProvider.notifier).state = value;
                            // Reset dates when period changes
                            ref.read(fromDateProvider.notifier).state = null;
                            ref.read(toDateProvider.notifier).state = null;
                          },
                        ),
                      ),
                    ),

                    // Show date pickers only when Custom is selected
                    if (isCustomPeriod) ...[
                      const SizedBox(height: 24),

                      // From Date
                      const Text(
                        AppStrings.from_date,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, ref, true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: (fromDate == null && toDate != null)
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fromDate != null
                                    ? DateFormat('dd/MM/yyyy').format(fromDate)
                                    : AppStrings.select,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: fromDate != null
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
                      if (fromDate == null && toDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'From date is required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // To Date
                      const Text(
                        AppStrings.to_date,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, ref, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: (toDate == null && fromDate != null) || dateValidationError != null
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                toDate != null
                                    ? DateFormat('dd/MM/yyyy').format(toDate)
                                    : AppStrings.select,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: toDate != null
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
                      if (toDate == null && fromDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'To date is required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      if (dateValidationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            dateValidationError,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],

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
                              AppStrings.download,
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
                              AppStrings.email,
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

  Future<void> _selectDate(
      BuildContext context, WidgetRef ref, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final fromDate = ref.read(fromDateProvider);
    final toDate = ref.read(toDateProvider);

    // Set initial date based on context
    DateTime initialDate = now;
    if (isFromDate && fromDate != null) {
      initialDate = fromDate;
    } else if (!isFromDate && toDate != null) {
      initialDate = toDate;
    } else if (!isFromDate && fromDate != null) {
      // For to date, default to from date if it's set
      initialDate = fromDate;
    }

    // Ensure initialDate is not in the future
    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now, // Only allow dates up to today (prevents future dates)
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
      if (isFromDate) {
        ref.read(fromDateProvider.notifier).state = picked;
        // If to date is set and is before the new from date, clear it
        final currentToDate = ref.read(toDateProvider);
        if (currentToDate != null && picked.isAfter(currentToDate)) {
          ref.read(toDateProvider.notifier).state = null;
        }
      } else {
        // Only set to date if it's not before from date
        final currentFromDate = ref.read(fromDateProvider);
        if (currentFromDate == null || !picked.isBefore(currentFromDate)) {
          ref.read(toDateProvider.notifier).state = picked;
        } else {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('To date cannot be before From date'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    // Request storage permission first
    final permissionStatus = await _requestStoragePermission();

    if (!permissionStatus) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download the report'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final selectedGroup = ref.read(selectedGroupProvider);
    final selectedPeriod = ref.read(selectedPeriodProvider);
    final fromDate = ref.read(fromDateProvider);
    final toDate = ref.read(toDateProvider);
    final familyMembersState = ref.read(familyMembersProvider).value;

    if (familyMembersState == null) return;

    // Prepare client IDs
    List<int> clientIds = [];
    if (selectedGroup == 'all') {
      clientIds = familyMembersState.allMembers
          .map((member) => member.clientId)
          .toList();
    } else {
      clientIds = [int.parse(selectedGroup!)];
    }

    // Format dates for API (yyyy-MM-dd format)
    String formattedFromDate = '';
    String formattedToDate = '';
    String? periodToSend;

    if (selectedPeriod == AppStrings.custom) {
      // For custom period, use user-selected dates and don't send period
      formattedFromDate = fromDate != null
          ? DateFormat('yyyy-MM-dd').format(fromDate)
          : '';
      formattedToDate = toDate != null
          ? DateFormat('yyyy-MM-dd').format(toDate)
          : '';
      periodToSend = null; // Don't send period for custom
    } else {
      // For predefined periods, calculate dates automatically
      final calculatedDates = _calculateDatesForPeriod(selectedPeriod!);
      formattedFromDate = calculatedDates['from_date']!;
      formattedToDate = calculatedDates['to_date']!;
      periodToSend = selectedPeriod; // Send period for predefined periods
    }

    // Set loading state
    ref.read(isDownloadingProvider.notifier).state = true;

    try {
      final repository = ref.read(capitalGainRepositoryProvider);
      final result = await repository.downloadCapitalGainReport(
        clientIds: clientIds,
        period: periodToSend,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
      );

      if (context.mounted) {
        if (result['success']) {
          // Show notification if file path is available
          if (result['filePath'] != null) {
            await _showDownloadNotification(result['filePath']);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Report downloaded successfully'),
              backgroundColor: const Color(0xFF0060A6),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to download report'),
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
      ref.read(isDownloadingProvider.notifier).state = false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    // Check if permission is already granted
    if (await Permission.storage.isGranted) {
      return true;
    }

    // For Android 13+ (API 33+), use photos/media permissions
    if (await Permission.photos.isGranted ||
        await Permission.mediaLibrary.isGranted) {
      return true;
    }

    // Request storage permission
    final status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Try requesting photos permission for Android 13+
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    } else if (status.isPermanentlyDenied) {
      // User permanently denied; open app settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  Future<void> _handleEmail(BuildContext context, WidgetRef ref) async {
    final selectedGroup = ref.read(selectedGroupProvider);
    final selectedPeriod = ref.read(selectedPeriodProvider);
    final fromDate = ref.read(fromDateProvider);
    final toDate = ref.read(toDateProvider);
    final familyMembersState = ref.read(familyMembersProvider).value;

    if (familyMembersState == null) return;

    // Prepare client IDs
    List<int> clientIds = [];
    if (selectedGroup == 'all') {
      clientIds = familyMembersState.allMembers
          .map((member) => member.clientId)
          .toList();
    } else {
      clientIds = [int.parse(selectedGroup!)];
    }

    // Format dates for API (yyyy-MM-dd format)
    String formattedFromDate = '';
    String formattedToDate = '';
    String? periodToSend;

    if (selectedPeriod == AppStrings.custom) {
      // For custom period, use user-selected dates and don't send period
      formattedFromDate = fromDate != null
          ? DateFormat('yyyy-MM-dd').format(fromDate)
          : '';
      formattedToDate = toDate != null
          ? DateFormat('yyyy-MM-dd').format(toDate)
          : '';
      periodToSend = null; // Don't send period for custom
    } else {
      // For predefined periods
      final calculatedDates = _calculateDatesForPeriod(selectedPeriod!);
      formattedFromDate = calculatedDates['from_date']!;
      formattedToDate = calculatedDates['to_date']!;
      periodToSend = selectedPeriod; // Send period for predefined periods
    }

    // Set loading state
    ref.read(isDownloadingProvider.notifier).state = true;

    try {
      final repository = ref.read(capitalGainRepositoryProvider);
      final result = await repository.emailCapitalGainReport(
        clientIds: clientIds,
        period: periodToSend,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                (result['success']
                    ? 'Report sent via email successfully'
                    : 'Failed to send report via email')),
            backgroundColor: result['success']
                ? const Color(0xFF0060A6)
                : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
      ref.read(isDownloadingProvider.notifier).state = false;
    }
  }
}