import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../providers/user_provider.dart';

// API Models
class ContactUsResponse {
  final int status;
  final String message;
  final ContactData data;

  ContactUsResponse({required this.status, required this.message, required this.data});

  factory ContactUsResponse.fromJson(Map<String, dynamic> json) {
    return ContactUsResponse(
      status: json['status'],
      message: json['message'],
      data: ContactData.fromJson(json['data']),
    );
  }
}

class ContactData {
  final CompanyDetails companyDetails;
  final RmDetails rmDetails;

  ContactData({required this.companyDetails, required this.rmDetails});

  factory ContactData.fromJson(Map<String, dynamic> json) {
    return ContactData(
      companyDetails: CompanyDetails.fromJson(json['company_details']),
      rmDetails: RmDetails.fromJson(json['rm_details']),
    );
  }
}

class CompanyDetails {
  final String companyName;
  final String address;
  final String mobileNo;
  final String email;

  CompanyDetails({required this.companyName, required this.address, required this.mobileNo, required this.email});

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      companyName: json['company_name'],
      address: json['address'],
      mobileNo: json['mobile_no'],
      email: json['email'],
    );
  }
}

class RmDetails {
  final String rmName;
  final String mobileNo;
  final String email;

  RmDetails({required this.rmName, required this.mobileNo, required this.email});

  factory RmDetails.fromJson(Map<String, dynamic> json) {
    return RmDetails(
      rmName: json['rm_name'],
      mobileNo: json['mobile_no'],
      email: json['email'],
    );
  }
}

// Main Screen
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  ContactData? contactData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchContactDetails();
  }

  Future<void> fetchContactDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = ref.read(userProvider);
      final token = user.token;
      final baseUrl =EnvConfig.apiBaseUrl;

      if (baseUrl.isEmpty || token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Configuration missing';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/contact-us'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final contactResponse = ContactUsResponse.fromJson(json.decode(response.body));
        if (contactResponse.status == 1) {
          setState(() {
            contactData = contactResponse.data;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = contactResponse.message;
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthorized. Please login again.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch contact details (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  // Helper methods for launching links
  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('${AppStrings.map_add}$query');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (!await launchUrl(url)) {
      throw 'Could not dial $phone';
    }
  }

  Future<void> _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (!await launchUrl(url)) {
      throw 'Could not send email to $email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            AppStrings.back_icon,
            width: 24,
            height: 24,
            color: Colors.black,
          ),
          onPressed: () => context.go('/user_profile'),
        ),
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchContactDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : contactData != null
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Details Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4), // white space at top
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F3FE),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contactData!.companyDetails.companyName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildCompanyRow('Address', contactData!.companyDetails.address, onTap: () {
                    _launchMaps(contactData!.companyDetails.address);
                  }),
                  _buildCompanyRow('Mobile', contactData!.companyDetails.mobileNo, onTap: () {
                    _launchPhone(contactData!.companyDetails.mobileNo);
                  }),
                  _buildCompanyRow('Email ID', contactData!.companyDetails.email, onTap: () {
                    _launchEmail(contactData!.companyDetails.email);
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // RM Details Title
            const Text(
              'RM Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // RM Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRmRow('RM Name', contactData!.rmDetails.rmName),
                  const SizedBox(height: 8),
                  _buildRmRow('RM Mobile', contactData!.rmDetails.mobileNo, onTap: () {
                    _launchPhone(contactData!.rmDetails.mobileNo);
                  }),
                  const SizedBox(height: 8),
                  _buildRmRow('RM Email', contactData!.rmDetails.email, onTap: () {
                    _launchEmail(contactData!.rmDetails.email);
                  }),
                ],
              ),
            ),
          ],
        ),
      )
          : const Center(child: Text('No data available')),
    );
  }

  Widget _buildCompanyRow(String title, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? Colors.blue : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRmRow(String title, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? Colors.blue : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}