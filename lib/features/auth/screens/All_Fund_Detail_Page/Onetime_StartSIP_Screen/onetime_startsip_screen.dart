import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../providers/selected_fund_provider.dart';
import '../../../../../../providers/onetime_startsip_provider.dart';
import '../../../../../../widgets/Onetime Start SIP/account_selection_card.dart';
import '../../../../../../widgets/Onetime Start SIP/investment_amount_card.dart';
import '../../../../../../widgets/Onetime Start SIP/sip_details_card.dart';
import '../../../../../constants/messages.dart';
import '../../../data/models/family_member.dart';
import '../../../data/repo/family_member_repo.dart';
import '../../../../../../constants/strings.dart';

class OnetimeStartsipScreen extends ConsumerStatefulWidget {
  final int fundId;
  final int? initialTab;
  final String? fundName;

  const OnetimeStartsipScreen({
    super.key,
    required this.fundId,
    this.initialTab,
    this.fundName,
  });

  @override
  ConsumerState<OnetimeStartsipScreen> createState() =>
      _OnetimeStartsipScreenState();
}

class _OnetimeStartsipScreenState extends ConsumerState<OnetimeStartsipScreen> {
  int _selectedTab = 0;
  int _selectedFrequencyIndex = 0;
  String? _selectedFrequency;

  final TextEditingController _investmentController =
      TextEditingController(text: '5000');
  final TextEditingController _sipAmountController =
      TextEditingController(text: '5000');
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();

  String? _validationMessage;
  String? _sipValidationMessage;
  String? _installmentsValidationMessage;
  bool _payFirstInstallment = false;
  bool _isProcessingOrder = false;
  FamilyMember? selectedClient;
  BseAccount? selectedBseAccount;
  String? selectedFolio;
  Mandate? selectedMandate;
  bool bseAccountsFetched = false;
  bool foliosFetched = false;
  bool mandatesFetched = false;
  double? originalMinAmount;
  double? originalSipMinAmount;

  late final familyMembersProvider =
      FutureProvider<List<FamilyMember>>((ref) async {
    final repo = FamilyMemberRepository();
    return repo.fetchFamilyMembers();
  });

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _selectedTab = widget.initialTab!;
    }

    Future.microtask(() {
      ref.read(fundConstraintProvider.notifier).fetchConstraint(widget.fundId);
      ref.read(sipFrequencyProvider.notifier).fetchFrequencies(widget.fundId);

      if (_selectedTab == 1) {
        _initializeSipTab();
      }
    });
  }

  void _initializeSipTab() {
    ref
        .read(sipFrequencyProvider.notifier)
        .fetchFrequencies(widget.fundId)
        .then((_) {
      final frequenciesAsync = ref.read(sipFrequencyProvider);
      frequenciesAsync.whenData((frequencies) {
        if (frequencies.isNotEmpty) {
          _selectedFrequency = frequencies[0];
          _fetchSipConstraintAndSetInstallments();
        }
      });
    });
  }

  void _fetchSipConstraintAndSetInstallments() {
    ref
        .read(sipConstraintProvider.notifier)
        .fetchSipConstraint(widget.fundId, _selectedFrequency!)
        .then((_) {
      final constraintAsync = ref.read(sipConstraintProvider);
      constraintAsync.whenData((constraint) {
        if (!_payFirstInstallment) {
          _installmentsController.text = constraint.minInstallments.toString();
        }
      });
    });
  }

  @override
  void dispose() {
    _investmentController.dispose();
    _sipAmountController.dispose();
    _dateController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  void _onTabChanged(int newTab) {
    setState(() => _selectedTab = newTab);
    if (newTab == 1) {
      final frequenciesAsync = ref.read(sipFrequencyProvider);
      frequenciesAsync.whenData((frequencies) {
        if (frequencies.isNotEmpty && _selectedFrequency == null) {
          _selectedFrequency = frequencies[0];
          _fetchSipConstraintAndSetInstallments();
        }
      });
    }
  }

  void _handleContinue() async {
    if (_isProcessingOrder) return; // Prevent multiple clicks

    String? errorMessage = _validateForm();

    if (errorMessage != null) {
      _showErrorSnackBar(errorMessage);
      return;
    }

    setState(() => _isProcessingOrder = true);

    final orderNotifier = ref.read(orderPlacementProvider.notifier);
    // Use widget.fundName if available, otherwise fall back to provider or default
    final displayFundName =
        widget.fundName ?? ref.read(selectedFundProvider)['fundName'] ?? AppStrings.na;

    try {
      if (_selectedTab == 0) {
        await _placeLumpsumOrder(orderNotifier, displayFundName);
      } else {
        await _placeSipOrder(orderNotifier, displayFundName);
      }
    } finally {
      // Only reset if still mounted (user hasn't navigated away)
      if (mounted) {
        setState(() => _isProcessingOrder = false);
      }
    }
  }

  String? _validateForm() {
    if (_selectedTab == 0) {
      return _validateLumpsumForm();
    } else {
      return _validateSipForm();
    }
  }

  String? _validateLumpsumForm() {
    if (selectedClient == null) return ValidationMessages.please_select_account;
    if (selectedBseAccount == null) return ValidationMessages.please_select_bse_account;
    if (selectedFolio == null) return ValidationMessages.please_select_folio;
    if (_validationMessage != null) return _validationMessage;
    if (_investmentController.text.trim().isEmpty)
      return ValidationMessages.please_enter_investment;
    return null;
  }

  String? _validateSipForm() {
    if (selectedClient == null) return ValidationMessages.please_select_account;
    if (selectedBseAccount == null) return ValidationMessages.please_select_bse_account;
    if (selectedFolio == null) return ValidationMessages.please_select_folio;
    if (selectedMandate == null) return ValidationMessages.no_mandate_warning;
    if (_dateController.text.trim().isEmpty)
      return ValidationMessages.please_select_date;
    if (_installmentsController.text.trim().isEmpty)
      return ValidationMessages.please_enter_installments;
    if (_sipValidationMessage != null) return _sipValidationMessage;
    if (_installmentsValidationMessage != null)
      return _installmentsValidationMessage;
    if (_sipAmountController.text.trim().isEmpty)
      return ValidationMessages.please_enter_sip;
    return null;
  }

  Future<void> _placeLumpsumOrder(
      dynamic orderNotifier, String displayFundName) async {
    try {
      await orderNotifier.placeLumpsumOrder(
        fundId: widget.fundId,
        folioNo: selectedFolio!,
        amount: double.parse(_investmentController.text.trim()),
        bseClientId: selectedBseAccount!.bseClientId,
      );

      // Check the result after API call completes
      final orderState = ref.read(orderPlacementProvider);
      orderState.when(
        data: (_) {
          if (mounted) {
            context.push('/order-success', extra: {
              'fundName': displayFundName,
              'bseClientId': selectedBseAccount!.bseClientId,
              'amount': double.parse(_investmentController.text.trim()),
              'isSip': false,
            });
          }
        },
        loading: () {
          // Still loading
        },
        error: (e, st) {
          if (mounted) {
            _showErrorSnackBar('${ErrorMessages.error_lumpsum_order}$e');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${ErrorMessages.unexpected_error}$e');
      }
    }
  }

  Future<void> _placeSipOrder(
      dynamic orderNotifier, String displayFundName) async {
    try {
      final dateParts = _dateController.text.trim().split('/');
      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      await orderNotifier.placeSipOrder(
        bseClientId: selectedBseAccount!.bseClientId,
        fundId: widget.fundId,
        folioNo: selectedFolio!,
        amount: double.parse(_sipAmountController.text.trim()),
        frequency: _selectedFrequency!,
        startDate: formattedDate,
        noOfInstallments: int.parse(_installmentsController.text.trim()),
        mandateId: selectedMandate!.mandateId,
        firstOrder: _payFirstInstallment,
      );

      // Check the result after API call completes
      final orderState = ref.read(orderPlacementProvider);
      orderState.when(
        data: (_) {
          if (mounted) {
            context.go('/order-success', extra: {
              'fundName': displayFundName,
              'bseClientId': selectedBseAccount!.bseClientId,
              'amount': double.parse(_sipAmountController.text.trim()),
              'isSip': true,
            });
          }
        },
        loading: () {
          // Still loading
        },
        error: (e, st) {
          if (mounted) {
            _showErrorSnackBar('${ErrorMessages.error_sip_order}$e');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${ErrorMessages.unexpected_error}$e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.fundName if available, otherwise fall back to provider or default
    final displayFundName = widget.fundName ??
        ref.watch(selectedFundProvider)['fundName'] ??
        AppStrings.invest;
    return PopScope(
      canPop: !_isProcessingOrder, // Prevent back navigation during API call
      onPopInvoked: (didPop) {
        if (!didPop && _isProcessingOrder) {
          _showInfoSnackBar(AppStrings.please_wait_order);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F3F5),
          title: Text(displayFundName,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isProcessingOrder
                ? () => _showInfoSnackBar(
                    AppStrings.please_wait_order)
                : () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              InvestmentAmountCard(
                fundId: widget.fundId,
                selectedTab: _selectedTab,
                onTabChanged: _onTabChanged,
                investmentController: _investmentController,
                sipAmountController: _sipAmountController,
                validationMessage: _validationMessage,
                sipValidationMessage: _sipValidationMessage,
                onValidationMessageChanged: (msg) =>
                    setState(() => _validationMessage = msg),
                onSipValidationMessageChanged: (msg) =>
                    setState(() => _sipValidationMessage = msg),
                selectedFolio: selectedFolio,
                originalMinAmount: originalMinAmount,
                originalSipMinAmount: originalSipMinAmount,
                onOriginalMinAmountChanged: (amt) =>
                    setState(() => originalMinAmount = amt),
                onOriginalSipMinAmountChanged: (amt) =>
                    setState(() => originalSipMinAmount = amt),
              ),
              if (_selectedTab == 1)
                SipDetailsCard(
                  fundId: widget.fundId,
                  selectedFrequencyIndex: _selectedFrequencyIndex,
                  selectedFrequency: _selectedFrequency,
                  dateController: _dateController,
                  installmentsController: _installmentsController,
                  installmentsValidationMessage: _installmentsValidationMessage,
                  payFirstInstallment: _payFirstInstallment,
                  onFrequencyChanged: (index, freq) {
                    setState(() {
                      _selectedFrequencyIndex = index;
                      _selectedFrequency = freq;
                    });
                    _fetchSipConstraintAndSetInstallments();
                  },
                  onInstallmentsValidationChanged: (msg) =>
                      setState(() => _installmentsValidationMessage = msg),
                  onPayFirstInstallmentChanged: (value) {
                    setState(() {
                      _payFirstInstallment = value;
                      _dateController.clear();
                      _installmentsController.clear();
                    });
                  },
                ),
              AccountSelectionCard(
                fundId: widget.fundId,
                selectedTab: _selectedTab,
                familyMembersProvider: familyMembersProvider,
                selectedClient: selectedClient,
                selectedBseAccount: selectedBseAccount,
                selectedFolio: selectedFolio,
                selectedMandate: selectedMandate,
                bseAccountsFetched: bseAccountsFetched,
                foliosFetched: foliosFetched,
                mandatesFetched: mandatesFetched,
                onClientChanged:
                    (client, bseFetched, folioFetched, mandateFetched) {
                  setState(() {
                    selectedClient = client;
                    bseAccountsFetched = bseFetched;
                    foliosFetched = folioFetched;
                    mandatesFetched = mandateFetched;
                  });
                },
                onBseAccountChanged: (account, mandateFetched) {
                  setState(() {
                    selectedBseAccount = account;
                    mandatesFetched = mandateFetched;
                  });
                },
                onFolioChanged: (folio) =>
                    setState(() => selectedFolio = folio),
                onMandateChanged: (mandate) =>
                    setState(() => selectedMandate = mandate),
                onResetMinAmounts: () {
                  if (originalMinAmount != null) {
                    ref
                        .read(fundConstraintProvider.notifier)
                        .updateMinAmount(originalMinAmount!);
                    originalMinAmount = null;
                  }
                  if (originalSipMinAmount != null) {
                    ref
                        .read(sipConstraintProvider.notifier)
                        .updateMinAmount(originalSipMinAmount!);
                    originalSipMinAmount = null;
                  }
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingOrder ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0060A6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF0060A6).withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: _isProcessingOrder
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                AppStrings.processing,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : const Text(
                            AppStrings.continue_btn,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
