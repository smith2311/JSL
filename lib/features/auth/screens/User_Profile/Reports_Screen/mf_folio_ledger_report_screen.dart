import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../constants/strings.dart';
import '../../../../../providers/family_members_provider.dart';
import '../../../data/repo/folio_ledger_repo.dart';

// State providers
final selectedGroupFolioProvider = StateProvider<String?>((ref) => null);
final selectedFolioProvider = StateProvider<String?>((ref) => null);
final selectedPeriodFolioProvider = StateProvider<String?>((ref) => null);
final fromDateFolioProvider = StateProvider<DateTime?>((ref) => null);
final toDateFolioProvider = StateProvider<DateTime?>((ref) => null);
final navDateFolioProvider = StateProvider<DateTime?>((ref) => null);
final isDownloadingFolioProvider = StateProvider<bool>((ref) => false);

// Period options provider
final periodOptionsFolioProvider = Provider<List<String>>((ref) {
  return AppStrings.capitalGainPeriods;
});

// Repository provider
final folioLedgerRepositoryProvider = Provider<FolioLedgerRepository>((ref) {
  return FolioLedgerRepository();
});

// Dynamic folio list provider based on selected member
// Replace the existing folioListProvider with this updated version:

final folioListProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final selectedGroup = ref.watch(selectedGroupFolioProvider);

  // When no group is selected, return empty list
  if (selectedGroup == null) {
    return [];
  }

  // ✅ When "ALL" is selected, fetch folios for all family members
  if (selectedGroup == 'ALL') {
    final familyMembers = ref.read(familyMembersProvider).value;
    if (familyMembers == null || familyMembers.allMembers.isEmpty) {
      return [];
    }

    final repository = ref.watch(folioLedgerRepositoryProvider);

    // Fetch folios for all family members
    List<String> allFolios = [];
    Set<String> uniqueFolios = {}; // Use Set to avoid duplicates

    for (var member in familyMembers.allMembers) {
      try {
        final folios = await repository.fetchFolioList(member.clientId.toString());
        uniqueFolios.addAll(folios);
      } catch (e) {
        print('Error fetching folios for client ${member.clientId}: $e');
        // Continue with other members even if one fails
      }
    }

    allFolios = uniqueFolios.toList()..sort(); // Sort alphabetically
    return allFolios;
  }

  // For individual member selection
  final repository = ref.watch(folioLedgerRepositoryProvider);
  return await repository.fetchFolioList(selectedGroup);
});

class MfFolioLedgerReportScreen extends ConsumerStatefulWidget {
  const MfFolioLedgerReportScreen({super.key});

  @override
  ConsumerState<MfFolioLedgerReportScreen> createState() =>
      _MfFolioLedgerReportScreenState();
}

class _MfFolioLedgerReportScreenState
    extends ConsumerState<MfFolioLedgerReportScreen> {

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

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'folio_ledger_channel',
      'Folio Ledger Reports',
      description: 'Notifications for folio ledger report downloads',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showDownloadNotification(String filePath, String fileName) async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        return;
      }
    }

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'folio_ledger_channel',
      'Folio Ledger Reports',
      channelDescription: 'Notifications for folio ledger report downloads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        'Folio Ledger Report Downloaded',
        'Tap to open $fileName',
        notificationDetails,
        payload: filePath,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Map<String, String> _calculateDatesForPeriod(String period) {
    if (period.toLowerCase() == 'custom') {
      return {'from_date': '', 'to_date': ''};
    }

    final parts = period.split('-');
    if (parts.length == 2) {
      final startYear = int.tryParse(parts[0]);
      final endYearShort = int.tryParse(parts[1]);

      if (startYear != null && endYearShort != null) {
        final endYear = startYear + 1;
        final fromDate = '$startYear-04-01';
        final toDate = '$endYear-03-31';
        return {'from_date': fromDate, 'to_date': toDate};
      }
    }

    return {'from_date': '', 'to_date': ''};
  }

  String? _validateDates() {
    final fromDate = ref.read(fromDateFolioProvider);
    final toDate = ref.read(toDateFolioProvider);

    if (fromDate != null && toDate != null) {
      if (fromDate.isAfter(toDate)) {
        return 'From date cannot be after To date';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroup = ref.watch(selectedGroupFolioProvider);
    final selectedFolio = ref.watch(selectedFolioProvider);
    final selectedPeriod = ref.watch(selectedPeriodFolioProvider);
    final fromDate = ref.watch(fromDateFolioProvider);
    final toDate = ref.watch(toDateFolioProvider);
    final navDate = ref.watch(navDateFolioProvider);
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final periodOptions = ref.watch(periodOptionsFolioProvider);
    final isDownloading = ref.watch(isDownloadingFolioProvider);

    final dateValidationError = _validateDates();
    final isCustomPeriod = selectedPeriod == AppStrings.custom;

    if (selectedPeriod != null && !periodOptions.contains(selectedPeriod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedPeriodFolioProvider.notifier).state = null;
      });
    }

    // Form validation
    final isFormValid = selectedGroup != null &&
        selectedFolio != null &&
        selectedPeriod != null &&
        (!isCustomPeriod || (fromDate != null && toDate != null && dateValidationError == null)) &&
        navDate != null;

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
          'Folio Ledger Report',
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
                          {'id': 'ALL', 'name': 'All Family Members'}, // ✅ Add this option
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
                                ref.read(selectedGroupFolioProvider.notifier).state = value;
                                // Reset folio selection when group changes
                                ref.read(selectedFolioProvider.notifier).state = null;
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
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
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
                            const Expanded(
                              child: Text(
                                'Failed to load family members',
                                style: TextStyle(color: Colors.red),
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

                    // Select Folio Dropdown
                    const Text(
                      'Select Folio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFolioDropdown(selectedGroup, selectedFolio),

                    const SizedBox(height: 24),

                    // Period Dropdown
                    const Text(
                      'Period',
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
                              'Select',
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
                            ref.read(selectedPeriodFolioProvider.notifier).state = value;
                            ref.read(fromDateFolioProvider.notifier).state = null;
                            ref.read(toDateFolioProvider.notifier).state = null;
                          },
                        ),
                      ),
                    ),

                    // Show date pickers only when Custom period is selected
                    if (isCustomPeriod) ...[
                      const SizedBox(height: 24),

                      // From Date
                      const Text(
                        'From Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDateField(context, fromDate, true),
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
                        'To Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDateField(context, toDate, false),
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

                    const SizedBox(height: 24),

                    // NAV Date
                    const Text(
                      'NAV Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNavDateField(context, navDate),
                    if (navDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'NAV date is required',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
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

  Widget _buildFolioDropdown(String? selectedGroup, String? selectedFolio) {
    if (selectedGroup == null) {
      // Disabled state
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Folio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      );
    }

    final folioListAsync = ref.watch(folioListProvider);

    return folioListAsync.when(
      data: (folioList) {
        // Add "All Folio" option
        final folioOptions = ['All Folio', ...folioList];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFolio,
              isExpanded: true,
              dropdownColor: Colors.white,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Folio',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.keyboard_arrow_down),
              ),
              items: folioOptions.map((folio) {
                return DropdownMenuItem<String>(
                  value: folio,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      folio,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(selectedFolioProvider.notifier).state = value;
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading folios...',
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
            const Expanded(
              child: Text(
                'Failed to load folios',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(folioListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, bool isFromDate) {
    final fromDate = ref.read(fromDateFolioProvider);
    final toDate = ref.read(toDateFolioProvider);
    final dateValidationError = _validateDates();

    return InkWell(
      onTap: () => _selectDate(context, ref, isFromDate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFromDate
                ? (fromDate == null && toDate != null
                ? Colors.red.shade300
                : Colors.grey.shade300)
                : ((toDate == null && fromDate != null) || dateValidationError != null
                ? Colors.red.shade300
                : Colors.grey.shade300),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select',
              style: TextStyle(
                fontSize: 16,
                color: date != null ? Colors.black87 : Colors.grey,
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
    );
  }

  Widget _buildNavDateField(BuildContext context, DateTime? navDate) {
    return InkWell(
      onTap: () => _selectNavDate(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: navDate == null ? Colors.red.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              navDate != null ? DateFormat('dd/MM/yyyy').format(navDate) : 'Select',
              style: TextStyle(
                fontSize: 16,
                color: navDate != null ? Colors.black87 : Colors.grey,
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
    );
  }

  Future<void> _selectDate(
      BuildContext context, WidgetRef ref, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final fromDate = ref.read(fromDateFolioProvider);
    final toDate = ref.read(toDateFolioProvider);

    DateTime initialDate = now;
    if (isFromDate && fromDate != null) {
      initialDate = fromDate;
    } else if (!isFromDate && toDate != null) {
      initialDate = toDate;
    } else if (!isFromDate && fromDate != null) {
      initialDate = fromDate;
    }

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
      if (isFromDate) {
        ref.read(fromDateFolioProvider.notifier).state = picked;
        final currentToDate = ref.read(toDateFolioProvider);
        if (currentToDate != null && picked.isAfter(currentToDate)) {
          ref.read(toDateFolioProvider.notifier).state = null;
        }
      } else {
        final currentFromDate = ref.read(fromDateFolioProvider);
        if (currentFromDate == null || !picked.isBefore(currentFromDate)) {
          ref.read(toDateFolioProvider.notifier).state = picked;
        } else {
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

  Future<void> _selectNavDate(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    final navDate = ref.read(navDateFolioProvider);

    DateTime initialDate = navDate ?? now;
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
      ref.read(navDateFolioProvider.notifier).state = picked;
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

  Future<void> _handleEmail(BuildContext context, WidgetRef ref) async {
    final selectedGroup = ref.read(selectedGroupFolioProvider);
    final selectedFolio = ref.read(selectedFolioProvider);
    final selectedPeriod = ref.read(selectedPeriodFolioProvider);
    final fromDate = ref.read(fromDateFolioProvider);
    final toDate = ref.read(toDateFolioProvider);
    final navDate = ref.read(navDateFolioProvider);

    ref.read(isDownloadingFolioProvider.notifier).state = true;

    try {
      // ✅ Handle single or all family members
      List<int> clientIds = [];
      if (selectedGroup == 'ALL') {
        final familyMembers = ref.read(familyMembersProvider).value;
        if (familyMembers != null) {
          clientIds = familyMembers.allMembers.map((m) => m.clientId).toList();
        }
      } else {
        clientIds = [int.parse(selectedGroup!)];
      }

      String folioNo = '';
      bool isFolio = true;

      // Check if "All Folio" is selected
      if (selectedFolio == 'All Folio') {
        isFolio = false;
        folioNo = '';
      } else {
        isFolio = true;
        folioNo = selectedFolio ?? '';
      }

      // Format dates for API (yyyy-MM-dd format)
      String formattedFromDate = '';
      String formattedToDate = '';
      String? periodToSend;

      if (selectedPeriod == AppStrings.custom) {
        formattedFromDate = fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate)
            : '';
        formattedToDate = toDate != null
            ? DateFormat('yyyy-MM-dd').format(toDate)
            : '';
        periodToSend = null;
      } else {
        final calculatedDates = _calculateDatesForPeriod(selectedPeriod!);
        formattedFromDate = calculatedDates['from_date']!;
        formattedToDate = calculatedDates['to_date']!;
        periodToSend = selectedPeriod;
      }

      // Format NAV date (yyyy-MM-dd format)
      String formattedNavDate = navDate != null
          ? DateFormat('yyyy-MM-dd').format(navDate)
          : '';

      final repository = ref.read(folioLedgerRepositoryProvider);
      final result = await repository.emailFolioLedgerReport(
        isFolio: isFolio,
        clientIds: clientIds,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        folioNo: folioNo,
        period: periodToSend,
        navDate: formattedNavDate,
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
      ref.read(isDownloadingFolioProvider.notifier).state = false;
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final permissionStatus = await _requestStoragePermission();

    if (!permissionStatus) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Storage permission is required to download the report'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final selectedGroup = ref.read(selectedGroupFolioProvider);
    final selectedFolio = ref.read(selectedFolioProvider);
    final selectedPeriod = ref.read(selectedPeriodFolioProvider);
    final fromDate = ref.read(fromDateFolioProvider);
    final toDate = ref.read(toDateFolioProvider);
    final navDate = ref.read(navDateFolioProvider);

    ref.read(isDownloadingFolioProvider.notifier).state = true;

    try {
      // ✅ Handle single or all family members
      List<int> clientIds = [];
      if (selectedGroup == 'ALL') {
        final familyMembers = ref.read(familyMembersProvider).value;
        if (familyMembers != null) {
          clientIds = familyMembers.allMembers.map((m) => m.clientId).toList();
        }
      } else {
        clientIds = [int.parse(selectedGroup!)];
      }

      String folioNo = '';
      bool isFolio = true;

      // Check if "All Folio" is selected
      if (selectedFolio == 'All Folio') {
        isFolio = false;
        folioNo = '';
      } else {
        isFolio = true;
        folioNo = selectedFolio ?? '';
      }

      // Format dates for API (yyyy-MM-dd format)
      String formattedFromDate = '';
      String formattedToDate = '';
      String? periodToSend;

      if (selectedPeriod == AppStrings.custom) {
        formattedFromDate = fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate)
            : '';
        formattedToDate = toDate != null
            ? DateFormat('yyyy-MM-dd').format(toDate)
            : '';
        periodToSend = null;
      } else {
        final calculatedDates = _calculateDatesForPeriod(selectedPeriod!);
        formattedFromDate = calculatedDates['from_date']!;
        formattedToDate = calculatedDates['to_date']!;
        periodToSend = selectedPeriod;
      }

      // Format NAV date (yyyy-MM-dd format)
      String formattedNavDate = navDate != null
          ? DateFormat('yyyy-MM-dd').format(navDate)
          : '';

      final repository = ref.read(folioLedgerRepositoryProvider);
      final result = await repository.downloadFolioLedgerReport(
        isFolio: isFolio,
        clientIds: clientIds,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        folioNo: folioNo,
        period: periodToSend,
        navDate: formattedNavDate,
      );

      if (context.mounted) {
        if (result['success']) {
          if (result['filePath'] != null && result['fileName'] != null) {
            await _showDownloadNotification(
              result['filePath'],
              result['fileName'],
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? 'Report downloaded successfully'),
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
      ref.read(isDownloadingFolioProvider.notifier).state = false;
    }
  }
}