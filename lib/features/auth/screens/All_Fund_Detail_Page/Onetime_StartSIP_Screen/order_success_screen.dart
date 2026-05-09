import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class OrderSuccessScreen extends StatelessWidget {
  final String fundName;
  final String bseClientId;
  final double amount;
  final bool isSip;

  const OrderSuccessScreen({
    super.key,
    required this.fundName,
    required this.bseClientId,
    required this.amount,
    this.isSip = false,
  });

  static const _buttonStyle = ButtonStyle(
    padding: MaterialStatePropertyAll<EdgeInsets>(
      EdgeInsets.symmetric(vertical: 14),
    ),
    shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  static final _primaryButtonStyle = _buttonStyle.copyWith(
    backgroundColor: const MaterialStatePropertyAll<Color>(Color(0xFF0060A6)),
    foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
    elevation: const MaterialStatePropertyAll<double>(0),
  );

  static final _secondaryButtonStyle = _buttonStyle.copyWith(
    foregroundColor: const MaterialStatePropertyAll<Color>(Color(0xFF0060A6)),
    side: const MaterialStatePropertyAll<BorderSide>(
      BorderSide(color: Color(0xFF0060A6), width: 1.5),
    ),
  );

  Future<void> _openMailbox(BuildContext context) async {
    bool opened = false;

    try {
      final mailApps = Platform.isIOS
          ? [
              Uri.parse('message://'), // Apple Mail
              Uri.parse('googlegmail://'), // Gmail
              Uri.parse('mailto:'), // Default
            ]
          : [
              Uri.parse('googlegmail://'), // Gmail
              Uri.parse('mailto:'), // Default
            ];

      for (final uri in mailApps) {
        if (await canLaunchUrl(uri)) {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (opened) break;
        }
      }

      // Fallback to Gmail web
      if (!opened) {
        opened = await launchUrl(
          Uri.parse('https://mail.google.com'),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened && context.mounted) {
        _showErrorSnackBar(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.couldnt_open_mail),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDiscover(BuildContext context) {
    context.go('/discover');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F5),
        title: Text(
          fundName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/discover');
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              _buildSuccessCard(),
              const SizedBox(height: 24),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFundHeader(),
            const SizedBox(height: 15),
            const Divider(thickness: 1),
            _buildTransactionDetails(),
            const SizedBox(height: 32),
            _buildSuccessImage(),
            const SizedBox(height: 24),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFundHeader() {
    return Row(
      children: [
        Image.asset(
          AppStrings.iconFunds_png,
          color: Colors.white,
          height: 24,
          width: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            fundName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.orders_bseid_lbl,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8F969C),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bseClientId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              AppStrings.amt,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8F969C),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessImage() {
    return SvgPicture.asset(
      AppStrings.success_mail,
      width: 200,
      height: 200,
      placeholderBuilder: (context) => Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 80,
              color: const Color(0xFF0060A6).withOpacity(0.3),
            ),
            const Positioned(
              top: 60,
              right: 60,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE91E63),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Text(
      AppStrings.order_success_inst,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _openMailbox(context),
            style: _primaryButtonStyle,
            child: const Text(
              AppStrings.go_to_mailbox,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _navigateToDiscover(context),
            style: _secondaryButtonStyle,
            child: const Text(
              AppStrings.explore_more,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
