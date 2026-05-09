import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../constants/strings.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/request_services.dart';
import '../providers/request_services_provider.dart';

class RequestServiceForm extends ConsumerStatefulWidget {
  final int serviceIndex;

  const RequestServiceForm({
    super.key,
    required this.serviceIndex,
  });

  @override
  ConsumerState<RequestServiceForm> createState() => _RequestServiceFormState();
}

class _RequestServiceFormState extends ConsumerState<RequestServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _mobileController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _mobileController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get serviceTitle => AppStrings.requestServices[widget.serviceIndex]['title'];

  bool get isCollectCheque => serviceTitle == 'Collect Cheque';
  bool get isCollectDocuments => serviceTitle == 'Collect Documents';
  bool get isCallMe => serviceTitle == 'Call me';
  bool get isReportIssue => serviceTitle == 'Report an Issue';

  String get requestType {
    if (isCollectCheque) return 'Collect Cheque';
    if (isCollectDocuments) return 'Collect Document';
    if (isCallMe) return 'Call Me';
    if (isReportIssue) return 'Report an Issue';
    return '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final formData = ref.read(formDataProvider(widget.serviceIndex));
    final DateTime now = DateTime.now();
    final DateTime initialDate = formData.dateOfCollect != null
        ? DateFormat('yyyy-MM-dd').parse(formData.dateOfCollect!)
        : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066B2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      ref.read(formDataProvider(widget.serviceIndex).notifier).state =
          formData.copyWith(dateOfCollect: formattedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = ref.read(formDataProvider(widget.serviceIndex));

    // Build payload based on service type
    Map<String, dynamic> payload = {
      'request_type': requestType,
    };

    if (isCollectCheque || isCollectDocuments) {
      if (formData.dateOfCollect == null || formData.timeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      payload.addAll({
        'date_of_collect': formData.dateOfCollect,
        'time_slot': formData.timeSlot,
        'note': _noteController.text.trim(),
      });
    } else if (isCallMe) {
      if (formData.dateOfCollect == null ||
          formData.timeSlot == null ||
          _mobileController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      payload.addAll({
        'mobile_no': _mobileController.text.trim(),
        'date_of_call': formData.dateOfCollect,
        'time_slot': formData.timeSlot,
        'about_subject': _noteController.text.trim(),
      });
    } else if (isReportIssue) {
      if (formData.dateOfCollect == null ||
          _subjectController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      payload.addAll({
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date_of_occurrence': formData.dateOfCollect,
      });
    }

    ref.read(isSubmittingProvider.notifier).state = true;

    try {
      final token = await TokenHelper.getValidToken(); // ✅ get valid token
      if (token == null) {
        throw Exception('Authentication expired. Please login again.');
      }

      final baseUrl = EnvConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/request-services');

      print('📤 Submitting request to: $url');
      print('📦 Payload: $payload');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('✅ Response: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(selectedServiceIndexProvider.notifier).state = null;
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to submit request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(isSubmittingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(formDataProvider(widget.serviceIndex));
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final isSubmitting = ref.watch(isSubmittingProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text(
                isReportIssue ? 'Issue details' : 'When to ${isCallMe ? 'Call' : 'Collect'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // White Container with Form Fields
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Field
                    _buildLabel(isReportIssue
                        ? 'Date of Occurrence'
                        : isCallMe
                        ? 'Date of Call'
                        : 'Date of Collect'),
                    const SizedBox(height: 8),
                    _buildDateField(context, formData),
                    const SizedBox(height: 16),

                    // Mobile Number (Call Me only)
                    if (isCallMe) ...[
                      _buildLabel('Mobile Number'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _mobileController,
                        hint: 'Enter Your Mobile Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (value.length != 10) {
                            return 'Please enter valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Subject (Report Issue only)
                    if (isReportIssue) ...[
                      _buildLabel('Subject'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _subjectController,
                        hint: 'Enter Your title',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Time Slot (Not for Report Issue)
                    if (!isReportIssue) ...[
                      _buildLabel('Time Slot'),
                      const SizedBox(height: 8),
                      _buildTimeSlotDropdown(timeSlotsAsync, formData),
                      const SizedBox(height: 16),
                    ],

                    // Note/Description Field
                    _buildLabel(isReportIssue ? 'Description' : 'Note'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: isReportIssue ? _descriptionController : _noteController,
                      hint: 'Write here..',
                      maxLines: 5,
                      validator: isReportIssue
                          ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      }
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDateField(BuildContext context, RequestServiceFormData formData) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formData.dateOfCollect != null
                    ? DateFormat('dd/MM/yyyy').format(
                    DateFormat('yyyy-MM-dd').parse(formData.dateOfCollect!))
                    : 'Select',
                style: TextStyle(
                  fontSize: 14,
                  color: formData.dateOfCollect != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            SvgPicture.asset(
              AppStrings.calender,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                const Color(0xFF0066B2),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotDropdown(
      AsyncValue<List<String>> timeSlotsAsync,
      RequestServiceFormData formData,
      ) {
    return timeSlotsAsync.when(
      data: (timeSlots) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: formData.timeSlot,
              hint: Text(
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              items: timeSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(
                    slot,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(formDataProvider(widget.serviceIndex).notifier).state =
                      formData.copyWith(timeSlot: value);
                }
              },
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading time slots...'),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Text(
          'Failed to load time slots',
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0066B2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}