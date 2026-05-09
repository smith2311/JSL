import 'package:jhaveri_jsl_app/core/imports.dart';
import 'package:jhaveri_jsl_app/features/auth/screens/Discover/All_Mutual_Funds/mutual_funds_screen.dart';
import 'package:jhaveri_jsl_app/features/auth/screens/Discover/Most_Popular_Funds/discover_most_popular_funds.dart';
import '../features/auth/screens/Portfolio/SIPs_Screen/SIP/sip_sip_fund_detail_screen.dart';
import '../features/auth/screens/Portfolio/SIPs_Screen/SWP/sip_swp_fund_detail_screen.dart';
export '../features/auth/screens/User_Profile/Account_Details_Screen/Linked_Bank_Accounts_Screen/link_bank_acc_screen.dart';

final portfolioTabStateProvider = StateProvider<Map<String, int>>((ref) => {
  'selectedTab': 0,
  'selectedSubTab': 0,
});

class RedeemFormState {
  final bool isAmountMode;
  final String inputValue;
  final bool isRedeemAll;
  final String? errorMessage;

  RedeemFormState({
    this.isAmountMode = false,
    this.inputValue = '',
    this.isRedeemAll = false,
    this.errorMessage,
  });

  RedeemFormState copyWith({
    bool? isAmountMode,
    String? inputValue,
    bool? isRedeemAll,
    String? errorMessage,
  }) {
    return RedeemFormState(
      isAmountMode: isAmountMode ?? this.isAmountMode,
      inputValue: inputValue ?? this.inputValue,
      isRedeemAll: isRedeemAll ?? this.isRedeemAll,
      errorMessage: errorMessage,
    );
  }
}

class RedeemFormNotifier extends StateNotifier<RedeemFormState> {
  RedeemFormNotifier() : super(RedeemFormState());

  void toggleMode() {
    state = state.copyWith(
      isAmountMode: !state.isAmountMode,
      inputValue: '',
      isRedeemAll: false,
      errorMessage: null,
    );
  }

  void updateInputValue(String value) {
    state = state.copyWith(
      inputValue: value,
      errorMessage: null,
    );
  }

  void toggleRedeemAll(bool value, {double? maxValue}) {
    if (value && maxValue != null) {
      state = state.copyWith(
        isRedeemAll: true,
        inputValue: state.isAmountMode
            ? maxValue.toStringAsFixed(0)
            : maxValue.toStringAsFixed(2),
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        isRedeemAll: false,
        inputValue: '',
        errorMessage: null,
      );
    }
  }

  void validateInput(double maxValue, bool isAmount) {
    if (state.inputValue.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter ${isAmount ? 'amount' : 'units'}',
      );
      return;
    }

    final value = double.tryParse(state.inputValue);
    if (value == null) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid number',
      );
      return;
    }

    if (isAmount) {
      if (value < 1) {
        state = state.copyWith(
          errorMessage: 'Minimum amount is ₹1',
        );
        return;
      }
      if (value > maxValue) {
        state = state.copyWith(
          errorMessage: 'Amount cannot exceed ₹${maxValue.toStringAsFixed(2)}',
        );
        return;
      }
    } else {
      if (value <= 0) {
        state = state.copyWith(
          errorMessage: 'Units must be greater than 0',
        );
        return;
      }
      if (value > maxValue) {
        state = state.copyWith(
          errorMessage: 'Units cannot exceed ${maxValue.toStringAsFixed(3)}',
        );
        return;
      }
    }

    state = state.copyWith(errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final redeemFormProvider =
StateNotifierProvider.autoDispose<RedeemFormNotifier, RedeemFormState>(
      (ref) => RedeemFormNotifier(),
);

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final path = state.matchedLocation;

      if (path == '/') return null;

      final hasToken = await _hasValidToken();
      final hasCompletedOnboarding = await _hasCompletedOnboarding();

      if (hasToken && (path == '/onboarding' || path == '/login' || path == '/email_login')) {
        return '/dashboard';
      }

      if (!hasToken && _isProtectedRoute(path)) {
        if (!hasCompletedOnboarding) {
          return '/onboarding';
        }
        return '/login';
      }

      if (hasToken && path == '/onboarding') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/email_login',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final clearEmail = extra?['clear_email'] ?? false;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EmailLoginScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/password_login',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PasswordLoginScreen(email: email),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),

      // Registration OTP Screen
      GoRoute(
        path: '/registration-otp',
        builder: (context, state) => const RegistrationOtpScreen(),
      ),

// Registration Create Password Screen
      GoRoute(
        path: '/registration-create-password',
        builder: (context, state) => const RegistrationCreatePasswordScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => WillPopScope(
          onWillPop: () async {
            GoRouter.of(context).go('/dashboard');
            return false;
          },
          child: Scaffold(
            body: child,
            bottomNavigationBar: const AppBottomNav(),
          ),
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => NoTransitionPage(child: const DiscoverScreen()),
          ),
          GoRoute(
            path: '/portfolio',
            pageBuilder: (context, state) => const NoTransitionPage(child: PortfolioScreen()),
          ),
        ],
      ),

      GoRoute(
        path: '/sip-calculator',
        name: 'sip-calculator',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SipCalculatorScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: '/forgot_password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/forgot-password-otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';

          if (email.isEmpty) {
            return MaterialPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text("Email is required")),
              ),
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: ForgotPasswordOtpScreen(email: email),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),

      GoRoute(
        path: '/user_profile',
        pageBuilder: (context, state) => const MaterialPage(child: UserProfile()),
      ),
      GoRoute(
        path: '/contact_us',
        pageBuilder: (context, state) => const MaterialPage(child: ContactUsScreen()),
      ),
      GoRoute(
        path: '/popular-funds',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PopularFundsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/fund-details/:fundId',
        builder: (context, state) {
          final fundId = int.tryParse(state.pathParameters['fundId'] ?? '');
          if (fundId == null) return const Scaffold(body: Center(child: Text("Invalid Fund ID")));

          final extraData = state.extra as Map<String, dynamic>?;
          final fundName = extraData?['fundName'] ?? 'Fund $fundId';

          return AllFundDetailScreen(fundId: fundId, fundName: fundName, extraData: extraData);
        },
      ),
      GoRoute(
        path: '/fund-detail/:fundId',
        builder: (context, state) {
          final fundIdStr = state.pathParameters['fundId'];
          final fundId = int.tryParse(fundIdStr ?? '');
          if (fundId == null) {
            return const Scaffold(
              body: Center(child: Text("Invalid Fund ID")),
            );
          }

          final extraData = state.extra as Map<String, dynamic>?;
          final fundName = extraData?['fundName'] ?? "Fund $fundId";

          return AllFundDetailScreen(
            fundId: fundId,
            fundName: fundName,
            extraData: extraData,
          );
        },
      ),
      GoRoute(
        name: 'onetime-startsip',
        path: '/onetime-startsip/:fundId',
        builder: (context, state) {
          final fundIdStr = state.pathParameters['fundId'];
          final fundId = int.tryParse(fundIdStr ?? '');
          if (fundId == null) {
            return const Scaffold(
              body: Center(child: Text("Invalid Fund ID")),
            );
          }

          final extraData = state.extra as Map<String, dynamic>?;
          final initialTab = extraData?['initialTab'] as int?;
          final fundName = extraData?['fundName'] as String?; // ✅ Extract fundName from extra

          return OnetimeStartsipScreen(
            fundId: fundId,
            initialTab: initialTab,
            fundName: fundName, // ✅ Pass fundName to constructor
          );
        },
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OrderSuccessScreen(
            fundName: extra['fundName'] as String,
            bseClientId: extra['bseClientId'] as String,
            amount: extra['amount'] as double,
            isSip: extra['isSip'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/mutual_funds',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MutualFundsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/funds/:category',
        pageBuilder: (context, state) {
          final category = state.pathParameters['category'] ?? 'high-returns';
          final title = state.uri.queryParameters['title'] ?? 'Funds';

          return CustomTransitionPage(
            key: state.pageKey,
            child: CollectionsCategoryDetailScreen(
              category: category,
              title: title,
            ),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/jhaveri_all_funds',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JhaveriPicksAllFunds(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OrdersScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/order-details/:orderId',
        pageBuilder: (context, state) {
          final orderIdStr = state.pathParameters['orderId'];
          final orderId = int.tryParse(orderIdStr ?? '');

          if (orderId == null) {
            return MaterialPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text("Invalid Order ID")),
              ),
            );
          }

          return MaterialPage(
            child: OrderDetailsScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/portfolio-fund-details/:fundId/:folioNo',
        name: 'portfolio-fund-details',
        pageBuilder: (context, state) {
          final fundIdStr = state.pathParameters['fundId'];
          final folioNoEncoded = state.pathParameters['folioNo'];

          final fundId = int.tryParse(fundIdStr ?? '');
          final folioNo = Uri.decodeComponent(folioNoEncoded ?? '');
          final clientName = (state.extra as Map<String, dynamic>?)?['clientName'];
          if (fundId == null || folioNo.isEmpty) {
            return MaterialPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text("Invalid Fund ID or Folio Number")),
              ),
            );
          }
          return MaterialPage(
            child: PortfolioFundDetailScreen(
              fundId: fundId,
              folioNo: folioNo,
              clientName: clientName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/redeem',
        name: 'redeem',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fundId = extra?['fundId'] as int? ?? 0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['client_id'] as String? ?? '';

          if (fundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return RedeemScreen(
            fundId: fundId,
            folioNo: folioNo,
            clientId: clientId,
          );
        },
      ),

      GoRoute(
        path: '/mf_folio_ledger_report',
        builder: (context, state) => const MfFolioLedgerReportScreen(),
      ),

      GoRoute(
        path: '/swp-confirm',
        name: 'swp-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid SWP details'),
              ),
            );
          }

          return SwpConfirmScreen(
            fundId: extra['fundId'] as int,
            folioNo: extra['folioNo'] as String,
            bseClientId: extra['bseClientId'] as String,
            withdrawalBy: extra['withdrawalBy'] as String,
            amount: extra['amount'] as double,
            frequency: extra['frequency'] as String,
            swpDate: extra['swpDate'] as String,
            noOfInstallments: extra['noOfInstallments'] as int,
            firstOrder: extra['firstOrder'] as bool,
            fundName: extra['fundName'] as String,
            availableUnits: extra['availableUnits'] as double,
            availableAmount: extra['availableAmount'] as double,
            bankName: extra['bankName'] as String,
            accountNo: extra['accountNo'] as String,
            clientId: extra['clientId'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/switch-confirm',
        name: 'switch-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid switch details'),
              ),
            );
          }

          return SwitchConfirmScreen(
            confirmData: extra,
          );
        },
      ),
      GoRoute(
        path: '/redemption-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Navigation data is missing'),
              ),
            );
          }

          final clientId = extra['clientId'] as int? ?? 0;
          final transactionType = extra['transactionType'] as String?;
          final redemptionData = extra['redemptionData'] as Map<String, dynamic>? ?? {};
          final stpData = extra['stpData'] as Map<String, dynamic>?;
          final switchData = extra['switchData'] as Map<String, dynamic>?;

          return OtpScreen(
            clientId: clientId,
            redemptionData: redemptionData,
            fundId: extra['fundId'] as int?,
            folioNo: extra['folioNo'] as String?,
            bseClientId: extra['bseClientId'] as String?,
            redeemType: extra['redeemType'] as String?,
            redeemBy: extra['redeemBy'] as String?,
            amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
            transactionType: transactionType,
            switchData: switchData,
            stpData: stpData,
          );
        },
      ),

      GoRoute(
        path: '/all-transactions',
        name: 'all-transactions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fundId = extra?['fundId'] as int? ?? 0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final fundName = extra?['fundName'] as String? ?? '';

          if (fundId == 0 || folioNo.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details'),
              ),
            );
          }

          return PortDialogAllTrans(
            fundId: fundId,
            folioNo: folioNo,
            fundName: fundName,
          );
        },
      ),
      GoRoute(
        path: '/redemption-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final amountParam = extra?['amount'];
          final double amount = amountParam is String
              ? double.tryParse(amountParam) ?? 0.0
              : (amountParam is num ? amountParam.toDouble() : 0.0);

          final fundIdParam = extra?['fundId'];
          final int? fundId = fundIdParam is String
              ? int.tryParse(fundIdParam)
              : (fundIdParam is int ? fundIdParam : null);

          final noOfInstallmentsParam = extra?['noOfInstallments'];
          final int? noOfInstallments = noOfInstallmentsParam is String
              ? int.tryParse(noOfInstallmentsParam)
              : (noOfInstallmentsParam is int ? noOfInstallmentsParam : null);

          final fundIdFromParam = extra?['fundIdFrom'];
          final int? fundIdFrom = fundIdFromParam is String
              ? int.tryParse(fundIdFromParam)
              : (fundIdFromParam as int?);

          final fundIdToParam = extra?['fundIdTo'];
          final int? fundIdTo = fundIdToParam is String
              ? int.tryParse(fundIdToParam)
              : (fundIdToParam as int?);

          return OrderResultScreen(
            isLoading: extra?['isLoading'] as bool?,
            isSuccess: extra?['isSuccess'] as bool?,
            orderId: extra?['orderId'] as String?,
            bseClientId: extra?['bseClientId'] as String?,
            fundName: extra?['fundName'] as String? ?? '',
            amount: amount,
            bankName: extra?['bankName'] as String? ?? '',
            accountNo: extra?['accountNo'] as String? ?? '',
            errorMessage: extra?['errorMessage'] as String?,
            transactionType: extra?['transactionType'] as String?,
            frequency: extra?['frequency'] as String?,
            noOfInstallments: noOfInstallments,
            firstOrder: extra?['firstOrder'] as bool?,
            swpDate: extra?['swpDate'] as String?,
            fundId: fundId,
            folioNo: extra?['folioNo'] as String?,
            redeemType: extra?['redeemType'] as String?,
            redeemBy: extra?['redeemBy'] as String?,
            otp: extra?['otp'] as String?,
            redemptionData: extra?['redemptionData'] as Map<String, dynamic>?,
            fromFundName: extra?['fromFundName'] as String?,
            toFundName: extra?['toFundName'] as String?,
            isAmount: extra?['isAmount'] as bool?,
            displayValue: extra?['displayValue'] as String?,
            fundIdFrom: fundIdFrom,
            fundIdTo: fundIdTo,
            switchBy: extra?['switchBy'] as String?,
            switchTo: extra?['switchTo'] as String?,
            stpDate: extra?['stpDate'] as String?,
            transferBy: extra?['transferBy'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/stp-confirm',
        name: 'stp-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid STP details'),
              ),
            );
          }

          return StpConfirmScreen(
            confirmData: extra,
          );
        },
      ),
      // ✅ FIXED SIP/SWP/STP ROUTES
      GoRoute(
        path: '/sip-details/:sxpId',
        name: 'sip-details',
        builder: (context, state) {
          final sxpId = state.pathParameters['sxpId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final currentTab = extra?['currentTab'] as int? ?? 1;
          final currentSubTab = extra?['currentSubTab'] as int? ?? 0;

          return SipDetailScreen(
            sxpId: sxpId,
            currentTab: currentTab,
            currentSubTab: currentSubTab,
          );
        },
      ),
      GoRoute(
        path: '/swp-details/:sxpId',
        name: 'swp-details',
        builder: (context, state) {
          final sxpId = state.pathParameters['sxpId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final currentTab = extra?['currentTab'] as int? ?? 1;
          final currentSubTab = extra?['currentSubTab'] as int? ?? 1;

          return SwpDetailScreen(
            sxpId: sxpId,
            currentTab: currentTab,
            currentSubTab: currentSubTab,
          );
        },
      ),
      GoRoute(
        path: '/stp-details/:sxpId',
        name: 'stp-details',
        builder: (context, state) {
          final sxpId = state.pathParameters['sxpId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final currentTab = extra?['currentTab'] as int? ?? 1;
          final currentSubTab = extra?['currentSubTab'] as int? ?? 2;

          return StpDetailScreen(
            sxpId: sxpId,
            currentTab: currentTab,
            currentSubTab: currentSubTab,
          );
        },
      ),
      GoRoute(
        path: '/pause-sip',
        name: 'pause-sip',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final sxpId = extra?['sxpId'] as String? ?? '';
          final sipDetail = extra?['sipDetail'];

          if (sxpId.isEmpty || sipDetail == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid SIP details'),
              ),
            );
          }

          return PauseSipScreen(
            sxpId: sxpId,
            sipDetail: sipDetail,
          );
        },
      ),
      GoRoute(
        path: '/capital-gain-report',
        builder: (context, state) => const MfCapitalGainReportScreen(),
      ),
      GoRoute(
        path: '/folio-ledger-report',
        builder: (context, state) => const MfCapitalGainReportScreen(),
      ),
      GoRoute(
        path: '/portfolio-valuation-summary',
        builder: (context, state) => const PortfolioValuationSummaryScreen(),
      ),
      GoRoute(
        path: '/discover_most_popular_funds',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DiscoverMostPopularFundsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/redeem-confirm',
        name: 'redeem-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid redeem details'),
              ),
            );
          }

          return RedeemConfirmScreen(
            fundId: extra['fundId'] as int,
            folioNo: extra['folioNo'] as String,
            bseClientId: extra['bseClientId'] as String,
            redeemType: extra['redeemType'] as String,
            redeemBy: extra['redeemBy'] as String,
            value: extra['value'] as double,
            fundName: extra['fundName'] as String,
            availableUnits: extra['availableUnits'] as double,
            availableAmount: extra['availableAmount'] as double,
            bankName: extra['bankName'] as String,
            accountNo: extra['accountNo'] as String,
            clientId: extra['clientId'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/portfolio-funds-swp',
        name: 'portfolio-funds-swp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fundId = extra?['fundId'] as int? ?? 0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['clientId'] as String? ?? '';

          if (fundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return PortfolioFundsDialogSwpScreen(
            fundId: fundId,
            folioNo: folioNo,
            clientId: clientId,
          );
        },
      ),
      GoRoute(
        path: '/switch-funds',
        name: 'switch-funds',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fundId = extra?['fundId'] as int? ?? 0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['clientId'] as String? ?? '';

          if (fundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return SwitchFundsScreen(
            fundId: fundId,
            fundName: extra?['fundName'] ?? '',
            availableUnits: extra?['availableUnits']?.toDouble() ?? 0.0,
            availableAmount: extra?['availableAmount']?.toDouble() ?? 0.0,
            folioNo: folioNo,
            clientId: extra?['clientId'] ?? '',
            clientName: extra?['clientName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/stp-dialog-funds',
        name: 'stp-dialog-funds',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fundId = extra?['fundId'] as int? ?? 0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['clientId'] as String? ?? '';

          if (fundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return StpDialogFundsScreen(
            fundId: fundId,
            fundName: extra?['fundName'] ?? '',
            availableUnits: extra?['availableUnits']?.toDouble() ?? 0.0,
            availableAmount: extra?['availableAmount']?.toDouble() ?? 0.0,
            folioNo: folioNo,
            clientId: extra?['clientId'] ?? '',
            clientName: extra?['clientName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/switch-fund-detail',
        name: 'switch-fund-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final fromFundId = extra?['fromFundId'] as int? ?? 0;
          final fromFundName = extra?['fromFundName'] as String? ?? '';
          final toFundId = extra?['toFundId'] as int? ?? 0;
          final toFundName = extra?['toFundName'] as String? ?? '';
          final toFundType = extra?['toFundType'] as String? ?? '';
          final toFundSubType = extra?['toFundSubType'] as String? ?? '';
          final availableUnits = extra?['availableUnits'] as double? ?? 0.0;
          final availableAmount = extra?['availableAmount'] as double? ?? 0.0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['clientId'] as String? ?? '';
          final clientName = extra?['clientName'] as String? ?? '';

          if (fromFundId == 0 || toFundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return SwitchFundDetailScreen(
            fromFundId: fromFundId,
            fromFundName: fromFundName,
            toFundId: toFundId,
            toFundName: toFundName,
            toFundType: toFundType,
            toFundSubType: toFundSubType,
            availableUnits: availableUnits,
            availableAmount: availableAmount,
            folioNo: folioNo,
            clientId: clientId,
            clientName: clientName,
          );
        },
      ),
      GoRoute(
        path: '/account_details',
        pageBuilder: (context, state) => const MaterialPage(child: AccountDetailScreen()),
      ),
      GoRoute(
        path: '/all_mandates',
        name: 'all_mandates',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bseClientId = extra?['bseClientId'] as String? ?? '';

          if (bseClientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('BSE Client ID is required'),
              ),
            );
          }

          return AllMandatesScreen(bseClientId: bseClientId);
        },
      ),
      GoRoute(
        path: '/family-members',
        name: 'family-members',
        builder: (context, state) => const FamilyMembersScreen(),
      ),
      GoRoute(
        path: '/add_mandate',
        name: 'add_mandate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bseClientId = extra?['bseClientId'] as String? ?? '';

          if (bseClientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('BSE Client ID is required'),
              ),
            );
          }

          return AddMandateScreen(bseClientId: bseClientId);
        },
      ),
      GoRoute(
        path: '/bank_detail_screen',
        name: 'bank_detail_screen',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bseClientId = extra?['bseClientId'] as String? ?? '';

          if (bseClientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('BSE Client ID is required'),
              ),
            );
          }

          return BankDetailsScreen(bseClientId: bseClientId);
        },
      ),
      GoRoute(
        path: '/link_bank_account',
        name: 'link_bank_account',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bseClientId = extra?['bseClientId'] as String? ?? '';

          return LinkBankAccScreen(bseClientId: bseClientId);
        },
      ),
      GoRoute(
        path: '/nominee_centre',
        name: 'nominee_centre',
        builder: (context, state) {
          final bseClientId = (state.extra as Map?)?['bseClientId'] as String? ?? '';
          return bseClientId.isEmpty
              ? const Scaffold(body: Center(child: Text('Error: BSE ID missing')))
              : NomineeCentreScreen(bseClientId: bseClientId);
        },
      ),
      GoRoute(
        path: '/add_nominee',
        name: 'add_nominee',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bseClientId = extra?['bseClientId'] as String? ?? '';
          final existing = extra?['existingNominees'] as List<Nominee>? ?? [];
          final initialTab = extra?['initialTab'] as int?;

          if (bseClientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('BSE Client ID is required'),
              ),
            );
          }

          return AddNomineeScreen(
            bseClientId: bseClientId,
            existingNominees: existing,
            initialTab: initialTab,
          );
        },
      ),
      GoRoute(
        path: '/request_services',
        builder: (context, state) => const RequestServicesScreen(),
      ),

      GoRoute(
        path: '/compare-funds',
        builder: (context, state) => const CompareFundsScreen(),
      ),

      GoRoute(
        path: '/stp-fund-detail',
        name: 'stp-fund-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final fromFundId = extra?['fromFundId'] as int? ?? 0;
          final fromFundName = extra?['fromFundName'] as String? ?? '';
          final toFundId = extra?['toFundId'] as int? ?? 0;
          final toFundName = extra?['toFundName'] as String? ?? '';
          final toFundType = extra?['toFundType'] as String? ?? '';
          final toFundSubType = extra?['toFundSubType'] as String? ?? '';
          final availableUnits = extra?['availableUnits'] as double? ?? 0.0;
          final availableAmount = extra?['availableAmount'] as double? ?? 0.0;
          final folioNo = extra?['folioNo'] as String? ?? '';
          final clientId = extra?['clientId'] as String? ?? '';
          final clientName = extra?['clientName'] as String? ?? '';

          if (fromFundId == 0 || toFundId == 0 || folioNo.isEmpty || clientId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid fund details or client ID missing'),
              ),
            );
          }

          return PortfDialogStpDetailScreen(
            fromFundId: fromFundId,
            fromFundName: fromFundName,
            toFundId: toFundId,
            toFundName: toFundName,
            toFundType: toFundType,
            toFundSubType: toFundSubType,
            availableUnits: availableUnits,
            availableAmount: availableAmount,
            folioNo: folioNo,
            clientId: clientId,
            clientName: clientName,
          );
        },
      ),
    ],
  );

  static Future<bool> _hasValidToken() async {
    final token = await SecureStore.getToken();
    if (token == null) return false;

    final isExpired = await SecureStore.isTokenExpired();
    return !isExpired;
  }

  static Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("onboarding_complete") ?? false;
  }

  static bool _isProtectedRoute(String path) {
    const protectedRoutes = [
      '/dashboard',
      '/discover',
      '/portfolio',
      '/user_profile',
      '/popular-funds',
      '/mutual_funds',
      '/orders',
      '/reports',
      '/notifications',
      '/switch-confirm',
      '/redemption-otp',
      '/redemption-result',
      '/stp-confirm',
    ];

    return protectedRoutes.any((route) => path.startsWith(route)) ||
        path.contains('/fund-details/') ||
        path.contains('/fund-detail/') ||
        path.contains('/portfolio-fund-details/') ||
        path.contains('/order-details/') ||
        path.contains('/investment/') ||
        path.contains('/portfolio-funds-swp') ||
        path.contains('/switch-funds') ||
        path.contains('/switch-fund-detail');
  }
}