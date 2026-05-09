import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../../core/utils/keep_alive.dart';
import '../../../../../../../providers/add_nominee_provider.dart';
import '../../../../../../../providers/nominee_list_provider.dart';
import '../../../../data/models/nominee_centre.dart';

class AddNomineeScreen extends ConsumerStatefulWidget {
  final String bseClientId;
  final List<Nominee> existingNominees;
  final int? initialTab;

  const AddNomineeScreen({
    super.key,
    required this.bseClientId,
    required this.existingNominees,
    this.initialTab,
  });

  @override
  ConsumerState<AddNomineeScreen> createState() => _AddNomineeScreenState();
}

class _AddNomineeScreenState extends ConsumerState<AddNomineeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<GlobalKey<FormState>> _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final Map<String, List<TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    for (int i = 0; i < 3; i++) {
      _controllers['nominee_$i'] = [
        TextEditingController(), // 0: firstName
        TextEditingController(), // 1: middleName
        TextEditingController(), // 2: lastName
        TextEditingController(), // 3: applicablePercentage
        TextEditingController(), // 4: mobile
        TextEditingController(), // 5: email
        TextEditingController(), // 6: address1
        TextEditingController(), // 7: address2
        TextEditingController(), // 8: address3
        TextEditingController(), // 9: pin
        TextEditingController(), // 10: city
        TextEditingController(), // 11: state
        TextEditingController(), // 12: idNumber
        TextEditingController(), // 13: guardianName
        TextEditingController(), // 14: guardianPan
      ];
    }

    // Set existing nominees BEFORE initializing TabController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 Setting existing nominees: ${widget.existingNominees.length}');
      ref.read(addNomineeProvider.notifier).setExisting(widget.existingNominees);

      // Update controllers after state is set
      _updateControllersFromState();

      // Force rebuild to show the data
      if (mounted) {
        setState(() {});
      }
    });

    // Initialize TabController with the correct initial index
    final initialIndex = widget.initialTab ?? _getNextEmptyTab();
    print('📍 Initial tab index: $initialIndex');
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_handleTabChange);
  }

  void _updateControllersFromState() {
    final state = ref.read(addNomineeProvider);
    print('📝 Updating controllers from state');

    for (int i = 0; i < 3; i++) {
      final nominee = state.nominees[i];
      final controllers = _controllers['nominee_$i']!;

      print('   Nominee $i: ${nominee.firstName} ${nominee.lastName}');

      controllers[0].text = nominee.firstName;
      controllers[1].text = nominee.middleName;
      controllers[2].text = nominee.lastName;
      controllers[3].text = nominee.applicablePercentage;
      controllers[4].text = nominee.mobile;
      controllers[5].text = nominee.email;
      controllers[6].text = nominee.address1;
      controllers[7].text = nominee.address2;
      controllers[8].text = nominee.address3;
      controllers[9].text = nominee.pin;
      controllers[10].text = nominee.city;
      controllers[11].text = nominee.state;
      controllers[12].text = nominee.idNumber;
      controllers[13].text = nominee.guardianName;
      controllers[14].text = nominee.guardianPan;
    }
  }

  int _getNextEmptyTab() {
    return widget.existingNominees.length < 3 ? widget.existingNominees.length : 0;
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      print('🔄 Tab changing to: $newIndex');

      for (int i = 0; i < newIndex; i++) {
        if (!ref.read(addNomineeProvider.notifier).isStarted(i)) {
          _tabController.index = _tabController.previousIndex;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please add Nominee ${i + 1} first'),
                backgroundColor: Colors.red,
              )
          );
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _controllers.values.forEach((list) {
      for (var controller in list) {
        controller.dispose();
      }
    });
    super.dispose();
  }

  // ✅ BUILD PERCENTAGE INDICATOR
  Widget _buildPercentageIndicator() {
    final state = ref.watch(addNomineeProvider);

    // Calculate total percentage from all started nominees
    double totalPercentage = 0;
    int filledCount = 0;
    List<int> nomineesWith100 = [];

    for (int i = 0; i < 3; i++) {
      if (state.nominees[i].isStarted) {
        filledCount++;
        final percentage = double.tryParse(state.nominees[i].applicablePercentage) ?? 0;
        totalPercentage += percentage;

        if (percentage == 100) {
          nomineesWith100.add(i);
        }
      }
    }

    // Determine color and message
    Color indicatorColor;
    String message;
    IconData icon;

    if (filledCount == 0) {
      indicatorColor = Colors.grey;
      message = 'No nominees added yet';
      icon = Icons.info_outline;
    } else if (nomineesWith100.isNotEmpty && filledCount > 1) {
      indicatorColor = Colors.orange;
      message = 'Nominee ${nomineesWith100.first + 1} has 100%. Reduce their share to add others.';
      icon = Icons.warning_amber_rounded;
    } else if (totalPercentage > 100) {
      indicatorColor = Colors.red;
      message = 'Total exceeds 100%: ${totalPercentage.toStringAsFixed(1)}%';
      icon = Icons.error_outline;
    } else if (totalPercentage < 100 && filledCount > 0) {
      indicatorColor = Colors.orange;
      message = 'Total: ${totalPercentage.toStringAsFixed(1)}% (Need ${(100 - totalPercentage).toStringAsFixed(1)}% more)';
      icon = Icons.warning_amber_rounded;
    } else if (totalPercentage == 100) {
      indicatorColor = Colors.green;
      message = 'Perfect! Total: 100%';
      icon = Icons.check_circle_outline;
    } else {
      indicatorColor = Colors.grey;
      message = 'Add nominee details';
      icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        border: Border.all(color: indicatorColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: indicatorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: indicatorColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SUBMIT METHOD WITH ENHANCED VALIDATION
  Future<void> _submit() async {
    print('\n' + '🔒' * 35);
    print('🔘 SUBMIT BUTTON PRESSED');
    print('🔒' * 35);

    bool allValid = true;
    List<int> startedIndices = [];

    // ✅ STEP 1: Check which nominees are started
    for (int i = 0; i < 3; i++) {
      final isStarted = ref.read(addNomineeProvider.notifier).isStarted(i);
      print('   Nominee ${i + 1} started: $isStarted');

      if (isStarted) {
        startedIndices.add(i);
      }
    }

    // ✅ STEP 2: Check if at least one nominee is added
    if (startedIndices.isEmpty) {
      print('   ❌ No nominees started');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one nominee'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print('\n📊 Found ${startedIndices.length} started nominee(s)');

    // ✅ STEP 3: Validate each started nominee's form
    for (int i in startedIndices) {
      print('🔹 Validating Nominee ${i + 1}');

      // Check if form key exists
      if (_formKeys[i].currentState == null) {
        print('   ❌ Nominee ${i + 1} form not initialized!');
        allValid = false;
        continue;
      }

      // Validate form fields
      final formValid = _formKeys[i].currentState!.validate();
      print('   🧾 Nominee ${i + 1} form valid: $formValid');
      if (!formValid) {
        allValid = false;
        print('   ❌ Form validation failed for Nominee ${i + 1}');
      }

      // Check if file is uploaded
      final nomineeFile = ref.read(addNomineeProvider).nominees[i].file;
      final hasFile = nomineeFile != null;
      print('   📎 Nominee ${i + 1} has file: $hasFile');

      if (!hasFile) {
        ref.read(addNomineeProvider.notifier).updateFile(
            i,
            null,
            error: 'Document is required'
        );
        allValid = false;
        print('   ❌ File missing for Nominee ${i + 1}');
      }

      // Validate guardian fields for minors
      final guardianValid = ref.read(addNomineeProvider.notifier).validateGuardianFields(i);
      print('   🧒 Nominee ${i + 1} guardian valid: $guardianValid');
      if (!guardianValid) {
        allValid = false;
        print('   ❌ Guardian validation failed for Nominee ${i + 1}');
      }
    }

    // ✅ STEP 4: Enhanced share percentage validation
    print('\n💯 Validating Share Percentages...');

    double totalPercentage = 0;
    bool shareError = false;
    int nomineeWithFullShare = -1;

    // Calculate total and check for 100% nominee
    for (int i in startedIndices) {
      final percentage = double.tryParse(
        ref.read(addNomineeProvider).nominees[i].applicablePercentage,
      ) ?? 0;

      print('   Nominee ${i + 1} percentage: $percentage%');
      totalPercentage += percentage;

      // Detect if anyone has full 100%
      if (percentage == 100) {
        nomineeWithFullShare = i;
      }
    }

    print('   Total percentage: $totalPercentage%');
    print('   Nominee with 100%: ${nomineeWithFullShare != -1 ? "Nominee ${nomineeWithFullShare + 1}" : "None"}');

    // 🛑 VALIDATION CASE 1: One nominee has 100% and others exist
    if (nomineeWithFullShare != -1 && startedIndices.length > 1) {
      shareError = true;
      allValid = false;

      print('   ❌ Validation failed: Nominee ${nomineeWithFullShare + 1} has 100% but multiple nominees added');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominee ${nomineeWithFullShare + 1} already has 100% share. Please reduce their allocation before adding other nominees.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );

      // Switch to the tab with 100% to help user fix it
      setState(() {
        _tabController.animateTo(nomineeWithFullShare);
      });
    }
    // 🛑 VALIDATION CASE 2: Total exceeds 100%
    else if (totalPercentage > 100) {
      shareError = true;
      allValid = false;

      print('   ❌ Validation failed: Total exceeds 100%');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total allocation cannot exceed 100%. Currently ${totalPercentage.toStringAsFixed(1)}%. Please adjust the shares.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // 🛑 VALIDATION CASE 3: Total less than 100%
    else if (totalPercentage < 100) {
      shareError = true;
      allValid = false;

      print('   ❌ Validation failed: Total less than 100%');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total allocation must equal 100%. Currently ${totalPercentage.toStringAsFixed(1)}%. Please add ${(100 - totalPercentage).toStringAsFixed(1)}% more.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // ✅ CASE 4: Exactly 100%
    else if (totalPercentage == 100) {
      print('   ✅ Total percentage is exactly 100%');
    }

    // ✅ STEP 5: Check agreement checkbox
    final isAgreed = ref.read(addNomineeProvider).isAgreed;
    print('\n📋 Terms agreed: $isAgreed');

    if (!isAgreed) {
      allValid = false;
      print('   ❌ User has not agreed to terms');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // ✅ STEP 6: Final validation check
    print('\n🎯 FINAL VALIDATION CHECK:');
    print('   Started nominees: ${startedIndices.length}');
    print('   All fields valid: $allValid');
    print('   Share allocation valid: ${!shareError}');
    print('   Terms agreed: $isAgreed');

    if (!allValid) {
      print('\n❌ VALIDATION FAILED - Cannot submit');
      print('   Please fix the errors shown above');
      print('🔒' * 35 + '\n');

      // Show generic error if no specific error was shown
      if (!shareError && isAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix all errors before submitting'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('\n✅ VALIDATION PASSED - Proceeding with submission');
    print('🔒' * 35 + '\n');

    // ✅ STEP 7: Show loading dialog and submit
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0066A6)),
      ),
    );

    final success = await ref.read(addNomineeProvider.notifier).submit(widget.bseClientId);

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ref.read(nomineeListProvider(widget.bseClientId).notifier).refresh(widget.bseClientId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominees updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        final errorMsg = ref.read(addNomineeProvider).globalError ?? 'Failed to update nominees';
        print('❌ Submission failed: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addNomineeProvider);

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
          'Add Nominee',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Tab Selection
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(3, (i) {
                final isSelected = _tabController.index == i;
                final hasData = state.nominees[i].isStarted;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(i);
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == 2 ? 0 : 4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0066A6) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nominee ${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // ✅ ADD PERCENTAGE INDICATOR
          _buildPercentageIndicator(),

          const SizedBox(height: 8),

          // Form Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  3,
                      (i) => KeepAlivePage(child: _buildForm(i)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Bottom Buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final index = _tabController.index;
                      ref.read(addNomineeProvider.notifier).clearNominee(index);
                      final controllers = _controllers['nominee_$index']!;
                      for (var controller in controllers) {
                        controller.clear();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0066A6), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color(0xFF0066A6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(int index) {
    final nominee = ref.watch(addNomineeProvider.select((s) => s.nominees[index]));
    final controllers = _controllers['nominee_$index']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[index],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Name'),
            _textFieldWithController(
              'Enter Your Name',
              controllers[0],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'firstName', v),
              required: true,
            ),

            _buildSectionTitle('Middle Name'),
            _textFieldWithController(
              'Enter Middle Name',
              controllers[1],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'middleName', v),
            ),

            _buildSectionTitle('Last Name'),
            _textFieldWithController(
              'Enter Last Name',
              controllers[2],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'lastName', v),
              required: true,
            ),

            _buildSectionTitle('Relationship'),
            _dropdownWithOptions(
              'Select Relationship',
              AppStrings.relationOptions,
              nominee.relationLabel,
                  (selectedLabel) {
                final apiKey = AppStrings.getRelationKey(selectedLabel!);
                ref.read(addNomineeProvider.notifier).updateRelation(index, apiKey, selectedLabel);
              },
              required: true,
            ),

            _buildSectionTitle('Share Applicable'),
            _textFieldWithController(
              'Enter Percentage',
              controllers[3],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'applicablePercentage', v),
              required: true,
              keyboard: TextInputType.number,
              suffix: '%',
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Share percentage is required';
                }
                final value = double.tryParse(v);
                if (value == null) {
                  return 'Must be a valid number';
                }
                if (value <= 0 || value > 100) {
                  return 'Must be between 1 and 100';
                }
                return null;
              },
            ),

            _buildSectionTitle('Date of Birth'),
            _dateField(context, index, nominee.dob),

            if (nominee.isMinor) ...[
              _buildSectionTitle('Guardian Name'),
              _textFieldWithController(
                'Enter Guardian Name',
                controllers[13],
                    (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'guardianName', v),
                required: true,
              ),

              _buildSectionTitle('Guardian PAN'),
              _textFieldWithController(
                'Enter Guardian PAN',
                controllers[14],
                    (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'guardianPan', v.toUpperCase()),
                required: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Guardian PAN is required';
                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                  if (!panRegex.hasMatch(v)) return 'Invalid PAN format (e.g., ABCDE1234F)';
                  return null;
                },
              ),
            ],

            _buildSectionTitle('Mobile'),
            _textFieldWithController(
              'Enter Mobile Number',
              controllers[4],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'mobile', v),
              required: true,
              keyboard: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Mobile number is required';
                if (v.length != 10) return 'Mobile must be 10 digits';
                return null;
              },
            ),

            _buildSectionTitle('Email'),
            _textFieldWithController(
              'Enter Email',
              controllers[5],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'email', v),
              required: true,
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(v)) return 'Invalid email address';
                return null;
              },
            ),

            _buildSectionTitle('Address'),
            _textFieldWithController(
              'Enter Address',
              controllers[6],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'address1', v),
              required: true,
            ),

            _buildSectionTitle('Address Line 2'),
            _textFieldWithController(
              'Enter Address Line 2',
              controllers[7],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'address2', v),
            ),

            _buildSectionTitle('Address Line 3'),
            _textFieldWithController(
              'Enter Address Line 3',
              controllers[8],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'address3', v),
            ),

            _buildSectionTitle('PIN Code'),
            _textFieldWithController(
              'Enter PIN Code',
              controllers[9],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'pin', v),
              required: true,
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'PIN code is required';
                if (v.length != 6) return 'PIN must be 6 digits';
                return null;
              },
            ),

            _buildSectionTitle('City'),
            _textFieldWithController(
              'Enter City',
              controllers[10],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'city', v),
              required: true,
            ),

            _buildSectionTitle('State'),
            _textFieldWithController(
              'Enter State',
              controllers[11],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'state', v),
              required: true,
            ),

            _buildSectionTitle('Country'),
            _dropdownWithOptions(
              'Select Country',
              AppStrings.countryOptions,
              nominee.countryLabel,
                  (selectedLabel) {
                final apiKey = AppStrings.getCountryKey(selectedLabel!);
                ref.read(addNomineeProvider.notifier).updateCountry(index, apiKey, selectedLabel);
              },
              required: true,
            ),

            _buildSectionTitle('ID Card Type'),
            _dropdownWithOptions(
              'Select ID Type',
              AppStrings.idTypeOptions,
              nominee.idTypeLabel,
                  (selectedLabel) {
                final apiValue = AppStrings.getApiIdType(selectedLabel!);
                ref.read(addNomineeProvider.notifier).updateIdType(index, apiValue, selectedLabel);
              },
              required: true,
            ),

            _buildSectionTitle('ID Number'),
            _textFieldWithController(
              'Enter ID Number',
              controllers[12],
                  (v) => ref.read(addNomineeProvider.notifier).updateField(index, 'idNumber', v),
              required: true,
            ),

            const SizedBox(height: 8),
            _buildSectionTitle('Upload'),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: nominee.fileError != null
                      ? Border.all(color: Colors.red, width: 1)
                      : null
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _pickFile(index),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.file_upload_outlined, color: Color(0xFF0066A6), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Choose File',
                          style: TextStyle(
                            color: Color(0xFF0066A6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (nominee.file != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              nominee.file!.path.split('/').last,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (nominee.fileError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      nominee.fileError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Kindly Upload a clear, high-quality image (JPG, PNG, or PDF – max 1 MB).',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: ref.watch(addNomineeProvider.select((s) => s.isAgreed)),
                    onChanged: (v) => ref.read(addNomineeProvider.notifier).toggleAgree(v!),
                    activeColor: const Color(0xFF0066A6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I/we confirm that Details provided by me/us are true and correct.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      if (file.lengthSync() > 1024 * 1024) {
        ref.read(addNomineeProvider.notifier).updateFile(index, null, error: 'File size must be less than 1MB');
      } else {
        ref.read(addNomineeProvider.notifier).updateFile(index, file);
      }
    }
  }

  Widget _textFieldWithController(
      String hint,
      TextEditingController controller,
      Function(String) onChanged, {
        bool required = false,
        TextInputType? keyboard,
        String? suffix,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0066A6), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixText: suffix,
          suffixStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
        ),
        keyboardType: keyboard,
        validator: validator ?? (required
            ? (v) => v == null || v.isEmpty ? 'This field is required' : null
            : null),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownWithOptions(
      String hint,
      List<Map<String, String>> options,
      String displayValue,
      Function(String?) onChanged, {
        bool required = false,
      }) {
    String? selectedLabel;
    if (displayValue.isNotEmpty) {
      selectedLabel = options.firstWhere(
            (item) => item['label'] == displayValue,
        orElse: () => {},
      )['label'];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<String>(
        value: selectedLabel,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0066A6), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option['label'],
            child: Text(
              option['label']!,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        validator: required ? (v) => v == null ? 'This field is required' : null : null,
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        dropdownColor: Colors.white,
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _dateField(BuildContext context, int index, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        readOnly: true,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'dd/mm/yyyy',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0066A6), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 18),
        ),
        controller: TextEditingController(text: _formatDateForDisplay(value)),
        validator: (v) => v!.isEmpty ? 'Date of Birth is required' : null,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF0066A6),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            final formatted = DateFormat('yyyy-MM-dd').format(date);
            ref.read(addNomineeProvider.notifier).updateField(index, 'dob', formatted);
          }
        },
      ),
    );
  }

  String _formatDateForDisplay(String date) {
    if (date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }
}