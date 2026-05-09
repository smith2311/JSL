<div align="center">

```
     ██╗███████╗██╗         ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗███████╗███████╗
     ██║██╔════╝██║         ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝██║██╔════╝██╔════╝
     ██║███████╗██║         ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║   ██║█████╗  ███████╗
██   ██║╚════██║██║         ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║   ██║██╔══╝  ╚════██║
╚█████╔╝███████║███████╗    ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║   ██║███████╗███████║
 ╚════╝ ╚══════╝╚══════╝    ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝╚══════╝╚══════╝
```

### *Your Wealth. Your Way. Always Secure.*

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-SDK_^3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.5.1-00B4D8?style=for-the-badge&logo=data:image/png;base64,iVBORw=)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0+1-success?style=for-the-badge)](./pubspec.yaml)
[![Platform](https://img.shields.io/badge/Platform-Android_|_iOS-lightgrey?style=for-the-badge&logo=android)](.)

<br/>

> **Jhaveri Securities Limited (JSL)** is a full-featured, production-grade Flutter mobile application  
> for intelligent **Mutual Fund investment, portfolio management, and financial planning** —  
> built with security-first architecture, silky-smooth UX, and real-time financial data at its core.

<br/>

---

</div>

<br/>

## 🗺️ Table of Contents

| # | Section |
|---|---------|
| 01 | [✨ What Is This App?](#-what-is-this-app) |
| 02 | [🎯 Core Features](#-core-features) |
| 03 | [🏗️ Architecture Deep Dive](#️-architecture-deep-dive) |
| 04 | [📂 Project Structure](#-project-structure) |
| 05 | [📱 Screens & Navigation](#-screens--navigation) |
| 06 | [🔐 Security Architecture](#-security-architecture) |
| 07 | [🌐 Networking Layer](#-networking-layer) |
| 08 | [🧠 State Management](#-state-management) |
| 09 | [📦 Dependencies](#-dependencies) |
| 10 | [🚀 Getting Started](#-getting-started) |
| 11 | [⚙️ Configuration & Environment](#️-configuration--environment) |
| 12 | [📊 Project Stats](#-project-stats) |
| 13 | [🔮 Roadmap](#-roadmap) |

<br/>

---

<br/>

## ✨ What Is This App?

**JSL** is the official mobile application of **Jhaveri Securities Limited**, a wealth management firm. The app serves as a one-stop platform allowing users to:

- 📈 **Invest** in Mutual Funds — one-time or SIP
- 💼 **Manage** their full investment portfolio in real time
- 🔁 **Perform** advanced fund operations: STP, SWP, Switch, Redeem
- 📊 **Discover** curated fund picks, collections, and market data
- 🧾 **Access** detailed reports — Capital Gains, Folio Ledger, Valuation Summary
- 👨‍👩‍👧 **Manage** family accounts, nominees, and bank mandates
- 🔐 Complete **KYC** directly within the app

Built with Flutter, it targets both **Android** and **iOS** from a single, maintainable Dart codebase.

<br/>

---

<br/>

## 🎯 Core Features

<br/>

### 🏠 Dashboard
```
┌─────────────────────────────────────────────┐
│  📊 Live Market Marquee (Real-time ticker)  │
│  💡 Curated Fund Collections                │
│  🛠️  Financial Tools Panel                 │
│     ├── SIP Calculator                      │
│     └── Fund Comparison Tool               │
│  🔔 In-App Notifications                   │
└─────────────────────────────────────────────┘
```

### 🔍 Discover
```
┌─────────────────────────────────────────────┐
│  🌟 Jhaveri Picks (Curated Funds)           │
│  📂 All Mutual Funds (Filterable)           │
│  🔥 Most Popular Funds                     │
│  🆕 NFO (New Fund Offers)                  │
│  ⭐ Watchlist & Bookmarks                  │
└─────────────────────────────────────────────┘
```

### 💼 Portfolio
```
┌─────────────────────────────────────────────┐
│  📁 Fund Holdings Overview                  │
│  🔁 SIP Management                         │
│     ├── Pause / Resume SIP                 │
│     └── Cancel SIP with Reason             │
│  ↔️  Fund Actions                           │
│     ├── Redeem                             │
│     ├── Switch Funds                       │
│     ├── STP (Systematic Transfer Plan)     │
│     └── SWP (Systematic Withdrawal Plan)   │
│  📋 Orders & Transaction History           │
└─────────────────────────────────────────────┘
```

### 👤 User Profile
```
┌─────────────────────────────────────────────┐
│  🏦 Linked Bank Accounts                   │
│  📜 Nominee Management                     │
│  📂 Mandate Centre                         │
│  👨‍👩‍👧 Family Member Accounts               │
│  📄 Reports                                │
│     ├── Capital Gain Report                │
│     ├── Folio Ledger Report                │
│     └── Valuation Summary                 │
│  🛎️  Request Services                      │
│  📞 Contact Us                             │
└─────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 🏗️ Architecture Deep Dive

This project follows a **Feature-First Clean Architecture** pattern — keeping business logic, data, and presentation clearly separated.

```
┌───────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                         │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐ │
│   │   Screens    │   │   Widgets    │   │  App Navigation      │ │
│   │  (57 total)  │   │  (74 total)  │   │    (GoRouter)        │ │
│   └──────┬───────┘   └──────┬───────┘   └──────────────────────┘ │
└──────────┼─────────────────┼───────────────────────────────────── ┘
           │                 │  reads/watches
┌──────────▼─────────────────▼───────────────────────────────────── ┐
│                       STATE LAYER                                  │
│         ┌────────────────────────────────────┐                    │
│         │   Riverpod Providers (52 total)    │                    │
│         │   + Provider (screen-level state)  │                    │
│         └────────────────┬───────────────────┘                    │
└──────────────────────────┼────────────────────────────────────────┘
                           │  calls
┌──────────────────────────▼────────────────────────────────────────┐
│                        DATA LAYER                                  │
│   ┌──────────────────┐       ┌─────────────────────────────────┐  │
│   │  Repositories    │       │           Models                │  │
│   │  (17 repos)      │       │         (32 models)             │  │
│   └────────┬─────────┘       └─────────────────────────────────┘  │
└────────────┼──────────────────────────────────────────────────────┘
             │  uses
┌────────────▼──────────────────────────────────────────────────────┐
│                        CORE LAYER                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────┐  ┌───────────┐  │
│  │  ApiClient  │  │  AuthHelper  │  │  Secure  │  │   Token   │  │
│  │  (REST)     │  │  (Auth flow) │  │  Store   │  │  Helper   │  │
│  └─────────────┘  └──────────────┘  └──────────┘  └───────────┘  │
│  ┌──────────────────────┐  ┌────────────────────────────────────┐  │
│  │  AutoRetryService    │  │       Network Connection           │  │
│  │  (Exp. backoff)      │  │       Monitor                     │  │
│  └──────────────────────┘  └────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 📂 Project Structure

```
jhaveri_jsl_app/
│
├── 📁 android/                     # Android native configuration
├── 📁 ios/                         # iOS native configuration
├── 📁 assets/
│   ├── 🖼️  images/                 # SVG & PNG assets (50+ icons)
│   └── 🔤 fonts/Figtree/           # Custom Figtree variable font
│
└── 📁 lib/
    │
    ├── 📄 main.dart                # App entry point
    │
    ├── 📁 app/
    │   ├── app.dart                # MaterialApp.router setup
    │   └── router.dart             # GoRouter — all routes defined
    │
    ├── 📁 constants/
    │   ├── strings.dart            # All UI string constants
    │   └── messages.dart           # API/error message constants
    │
    ├── 📁 core/
    │   ├── api_client.dart         # Generic REST client (GET/POST/PUT/DELETE)
    │   ├── auth_helper.dart        # Login state, logout, onboarding
    │   ├── secure_store.dart       # Encrypted token storage
    │   ├── token_helper.dart       # Auto token refresh logic
    │   ├── imports.dart            # Centralized barrel file
    │   ├── 📁 config/
    │   │   └── env.dart            # Environment variable loader
    │   ├── 📁 network/
    │   │   ├── auto_retry_service.dart  # Exponential backoff retry
    │   │   ├── connection.dart          # Network connectivity monitor
    │   │   └── http_client.dart         # Low-level HTTP wrapper
    │   └── 📁 utils/
    │       ├── api_service.dart    # API abstraction layer
    │       ├── stp_api_service.dart# STP-specific API calls
    │       ├── date_utils.dart     # Date formatting helpers
    │       ├── logger.dart         # Debug logging utility
    │       └── keep_alive.dart     # Widget keep-alive mixin
    │
    ├── 📁 features/
    │   └── 📁 auth/
    │       ├── 📁 data/
    │       │   ├── 📁 models/      # 32 data models
    │       │   │   ├── mutual_fund.dart
    │       │   │   ├── portfolio.dart
    │       │   │   ├── sip_sip_details.dart
    │       │   │   ├── stp_detail.dart
    │       │   │   ├── swp_detail.dart
    │       │   │   └── ... (27 more)
    │       │   └── 📁 repo/        # 17 repository classes
    │       │       ├── auth_repo.dart
    │       │       ├── portfolio_repo.dart
    │       │       ├── jhaveri_picks_repo.dart
    │       │       └── ... (14 more)
    │       └── 📁 screens/         # 57 screens organized by section
    │           ├── Splash_Screen/
    │           ├── Onboarding_Screen/
    │           ├── Sign_In_Screen/
    │           ├── Email_Login_Screen/
    │           ├── Forgot_Password/
    │           ├── User_SignUp_Screen/
    │           ├── Dashboard_Screen/
    │           ├── Discover/
    │           ├── Portfolio/
    │           ├── All_Fund_Detail_Page/
    │           ├── User_Profile/
    │           └── Common_Screens/
    │
    ├── 📁 providers/               # 52 Riverpod providers
    │   ├── user_provider.dart
    │   ├── watchlist_provider.dart
    │   ├── portfolio_provider.dart
    │   └── ... (49 more)
    │
    └── 📁 widgets/                 # 74 reusable UI components
        ├── fund_card.dart
        ├── portfolio_card.dart
        ├── investment_chart.dart
        └── ... (71 more)
```

<br/>

---

<br/>

## 📱 Screens & Navigation

The app uses **GoRouter** for declarative, type-safe navigation across **57 screens**:

```
🚀 App Launch
     │
     ▼
 [Splash Screen]
     │
     ├──► Has Completed Onboarding? ──NO──► [Onboarding Screen]
     │                                              │
     │                                              ▼
     ▼                                       [Login Screen]
 Is Authenticated?
     │
     ├──NO──► [Login / Sign Up / Forgot Password]
     │
     └──YES──►  ┌─────────────────────────────────────────────────┐
                │            MAIN APP (Bottom Nav)                │
                │                                                 │
                │  🏠 Dashboard  🔍 Discover  💼 Portfolio  👤 Profile │
                └─────────────────────────────────────────────────┘
                        │             │            │          │
                        ▼             ▼            ▼          ▼
                  Collections    Jhaveri       Fund        Account
                  Notifications  Picks         Detail      Details
                  SIP Calc       Mutual        SIP/SWP     Reports
                  Fund Compare   Funds         STP         Mandates
                                 NFOs          Switch      Nominees
                                 Popular       Redeem      Family
                                               Orders      KYC
```

<br/>

---

<br/>

## 🔐 Security Architecture

Security is not an afterthought — it's woven into every layer of the app.

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1 — Token Storage                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  FlutterSecureStorage (AES encrypted on device)     │   │
│  │  ├── Access Token     (key: auth_access_token)      │   │
│  │  ├── Refresh Token    (key: auth_refresh_token)     │   │
│  │  └── Token Expiry     (key: auth_expiry)            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Layer 2 — Token Lifecycle                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  TokenHelper — Automatic refresh before expiry      │   │
│  │  ├── Checks expiry on EVERY API call                │   │
│  │  ├── Silently refreshes via /auth/refresh-token     │   │
│  │  └── Forces re-login if refresh token invalid       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Layer 3 — API Request Security                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Every request includes:                            │   │
│  │  ├── Authorization: Bearer <token>                  │   │
│  │  └── Content-Type: application/json                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Layer 4 — Data Encryption                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  encrypt package — AES encryption for sensitive data│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Layer 5 — Logout & Cleanup                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AuthHelper.logout():                               │   │
│  │  ├── Calls /logout API                              │   │
│  │  ├── Clears all secure storage tokens               │   │
│  │  ├── Clears SharedPreferences user state            │   │
│  │  └── Redirects to /login                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 🌐 Networking Layer

The networking stack is robust, resilient, and designed for poor network conditions.

### 📡 API Client

A centralized `ApiClient` class handles all HTTP communication:

```dart
// Every call is token-aware and auto-refreshing
ApiClient.get('/portfolio/summary');
ApiClient.post('/orders/sip', body: {...});
ApiClient.put('/profile/update', body: {...});
ApiClient.delete('/watchlist/123');
```

### 🔄 Auto-Retry with Exponential Backoff

The `AutoRetryService` automatically retries failed operations without user intervention:

```
Request Fails
     │
     ├── Retry #1 → wait  2s
     ├── Retry #2 → wait  4s
     ├── Retry #3 → wait  8s
     ├── Retry #4 → wait 16s
     └── Retry #5 → wait 30s (capped)
```

Handles: `SocketException`, `TimeoutException`, `HttpException` — all silently retried.

### 📶 Connection Monitor

Real-time network connectivity monitoring — UI adapts instantly to offline/online state changes.

<br/>

---

<br/>

## 🧠 State Management

The app uses a **hybrid state management** approach:

| Layer | Tool | Purpose |
|-------|------|---------|
| Global App State | `flutter_riverpod` | User data, portfolio, watchlist, providers |
| Screen UI State | `Provider` | Screen-level UI and form state |
| Persistent State | `SharedPreferences` | Onboarding flags, user preferences |
| Secure State | `FlutterSecureStorage` | Auth tokens, sensitive keys |

### Key Providers

```dart
// User state — persisted across app restarts
final userProvider = StateNotifierProvider<UserNotifier, UserState>(...);

// Portfolio tabs — shared across Portfolio section
final portfolioTabStateProvider = StateProvider<Map<String, int>>(...);

// Redeem form — scoped to the redeem flow
final redeemFormProvider = StateNotifierProvider<RedeemFormNotifier, RedeemFormState>(...);

// Watchlist — persisted and syncable
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, WatchlistState>(...);
```

<br/>

---

<br/>

## 📦 Dependencies

```yaml
# ── State Management ──────────────────────────
flutter_riverpod: ^2.5.1          # Primary state management
provider: ^6.1.5+1                # Screen-level UI state

# ── Navigation ────────────────────────────────
go_router: ^14.0.2                # Declarative routing

# ── UI & Design ───────────────────────────────
google_fonts: ^6.2.1              # Typography
flutter_svg: ^2.2.1               # SVG rendering
lottie: ^3.1.2                    # Lottie animations
shimmer: ^3.0.0                   # Loading skeletons
shimmer_animation: ^2.2.2         # Animated shimmers
smooth_page_indicator: ^1.1.0     # Onboarding dots
marquee_list: ^1.0.0              # Scrolling market ticker
fluttertoast: ^8.2.4              # Toast notifications

# ── Charts & Data Viz ─────────────────────────
fl_chart: ^1.1.1                  # Portfolio charts, performance graphs

# ── Security ──────────────────────────────────
flutter_secure_storage: ^9.2.2    # Encrypted token vault
encrypt: ^5.0.3                   # AES data encryption

# ── Persistence ───────────────────────────────
shared_preferences: ^2.2.3        # Key-value storage

# ── Configuration ─────────────────────────────
flutter_dotenv: ^6.0.0            # .env file support

# ── File & Permissions ────────────────────────
permission_handler: ^11.3.1       # Runtime permissions
file_picker: ^10.3.3              # Document selection
open_file: ^3.5.8                 # Open downloaded reports

# ── Notifications ─────────────────────────────
flutter_local_notifications: ^17.2.3  # Push notifications

# ── KYC ───────────────────────────────────────
kyc_workflow: ^2.0.13             # In-app KYC completion

# ── Utilities ─────────────────────────────────
intl: ^0.18.1                     # Date & number formatting
url_launcher: ^6.1.10             # Open URLs / deep links
email_validator: ^2.1.17          # Email validation
package_info_plus: ^8.0.0         # App version info
```

<br/>

---

<br/>

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

```bash
# Flutter SDK (3.x or higher)
flutter --version

# Dart SDK (^3.9.2)
dart --version

# Android Studio / Xcode (for emulators)
# Git
```

### 1. Clone the Repository

```bash
git clone https://github.com/smith2311/JSL.git
cd JSL
git checkout development   # 🔀 Switch to the development branch
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
# Debug mode (development)
flutter run

# Specific device
flutter run -d <device_id>

# Release build
flutter run --release

# List available devices
flutter devices
```

### 4. Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

<br/>

---

<br/>

## ⚙️ Configuration & Environment

The app uses `flutter_dotenv` to load environment variables at runtime. Configuration values are accessed via:

```dart
final baseUrl = EnvConfig.apiBaseUrl;
```
<br/>

## 📊 Project Stats

```
╔══════════════════════════════════════════════════════════╗
║                   📈  CODEBASE AT A GLANCE               ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║   Total Dart Files        ████████████████████  269      ║
║   Screens                 ██████████████░░░░░░   57      ║
║   Reusable Widgets        █████████████░░░░░░░   74      ║
║   Riverpod Providers      ██████████████░░░░░░   52      ║
║   Data Models             ████████░░░░░░░░░░░░   32      ║
║   Repositories            █████░░░░░░░░░░░░░░░   17      ║
║   Assets (Images/SVGs)    ██████████░░░░░░░░░░   50+     ║
║   Custom Font Variants    ██████░░░░░░░░░░░░░░   14      ║
║                                                          ║
║   Target Platforms        Android ✅   iOS ✅            ║
║   State Management        Riverpod + Provider            ║
║   Navigation              GoRouter (Declarative)         ║
║   Font Family             Figtree (Variable)             ║
║   Primary Color           Indigo                         ║
║   Background Color        #F6F8FB                        ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

<br/>

---

<br/>

## 🔮 Roadmap

- [ ] 🌙 **Dark Mode** support
- [ ] 🌐 **Multi-language** support (Hindi, Gujarati)
- [ ] 📤 **Share portfolio performance** as image/card
- [ ] 🔔 **Push notifications** for SIP reminders and order updates
- [ ] 📲 **Biometric login** (Fingerprint / Face ID)
- [ ] ✅ **Unit & widget tests** for core business logic
- [ ] 🔍 **Semantic search** for mutual fund discovery
- [ ] 📊 **Advanced analytics** — portfolio insights and fund comparisons

<br/>

---

<br/>

<div align="center">

```
╔══════════════════════════════════════════════╗
║                                              ║
║    Built with ❤️  by the Smith Kansara       ║
║                                              ║
║                                              ║
║    Flutter  •  Dart  •  Riverpod             ║
║                                              ║
╚══════════════════════════════════════════════╝
```
---

⭐ **If this project helped you, leave a star on the repo!**

</div>