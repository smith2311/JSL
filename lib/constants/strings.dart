import 'package:flutter/material.dart';

class DropdownConstants {
  // Account Types
  static const List<Map<String, String>> accountTypes = [
    {'value': 'SB', 'label': 'SB'},
    {'value': 'CA', 'label': 'CA'},
  ];

  // Account Owners
  static const List<Map<String, String>> accountOwners = [
    {'value': 'SELF', 'label': 'Self'},
    {'value': 'JOINT', 'label': 'Joint'},
  ];

  // Helper methods to get labels
  static String getAccountTypeLabel(String value) {
    return accountTypes.firstWhere(
      (type) => type['value'] == value,
      orElse: () => {'label': value},
    )['label']!;
  }

  static String getAccountOwnerLabel(String value) {
    return accountOwners.firstWhere(
      (owner) => owner['value'] == value,
      orElse: () => {'label': value},
    )['label']!;
  }
}

class AppStrings {
  // Onboarding_Screen Data
  static final List<Map<String, String>> onboardingData = [
    {
      "image": onboarding_3,
      "title": "Grow Your Wealth, Smarter",
      "description":
          "Invest in top-performing mutual funds curated by experts. Start your journey with confidence and clarity."
    },
    {
      "image": onboarding_1,
      "title": "Simple. Secure. Seamless.",
      "description":
          "Jhaveri Wealth Track makes investing effortless— open your account, pick a plan, and start in minutes."
    },
    {
      "image": onboarding_2,
      "title": "Invest with Purpose",
      "description":
          "Whether it's retirement, education, or a dream vacation—we help you plan and invest with purpose."
    },
  ];

  // 🔹 Example future strings
  static const String loginTitle = "Welcome Back!";
  static const String loginSubtitle =
      "Sign in to continue managing your investments securely.";
  static const String next = "Next";
  static const String start = "Let's Get Started";
  static const String dashboard_skip = "SKIP";
  static const String pop_funds = "Popular funds";
  static const String view_all_funds = "View all";
  static const String dashboard_collections = "Collections";
  static const String tools = "Tools";
  static const String greetings = "Namaste,";
  static const String home_lbl = "Home";
  static const String portfolio_lbl = "Portfolio";
  static const String discover_lbl = "Discover";

  static const String dashboard_success_lbl = "You're all set to invest";
  static const String dashboard_kyc_lbl = "Almost there";

  static const String subtitle =
      "Start your SIP or explore funds personalized for you.";
  static const String dashboard_kyc_subtitle_lbl =
      "Sign up and complete your KYC to start investing in mutual funds with ease.";
  static const String dahsboard_cta_Kyc = "Complete KYC";
  static const String dashboard_btn_lbl = "Start Investing";
  static const String high_ret = "High Return";
  static const String jv_picks_lbl = "Jhaveri Picks";
  static const String nfo_lbl = "NFO";
  static const String large_cap = "Large Cap";
  static const String mid_cap = "Mid Cap";
  static const String small_cap = "Small Cap";
  static const String amc = "AMC's";
  static const String sectorial = "Sectorial";
  static const String tax_sav = "Tax Saver";

  static const List<String> notificationFilters = [
    "All",
    "SIPs",
    "Investments",
    "Portfolio Updates",
    "KYC"
  ];
  static const List<Map<String, dynamic>> notifications = [
    {
      "icon": "check_circle",
      "title": "Mutual Fund autopay was Successful",
      "subtitle": "₹4000 for your SIP was Successful",
      "time": "11 hour ago"
    },
    {
      "icon": "account_balance_wallet",
      "title": "MF Weekly Portfolio Update",
      "subtitle":
          "Current Value: ₹34,000.45\nInvested Value: ₹18,000.45\nReturns: ₹14000.45 • 85.55%",
      "time": "11 hour ago"
    },
    {
      "icon": "notifications",
      "title": "New Updates",
      "subtitle":
          "Lorem ipsum dolor sit amet consectetur. At eget vitae pretium facilisi aliquam.",
      "time": "11 hour ago"
    },
  ];
  static const String lbl_google = "Continue with Google";
  static const String lbl_mail = "Continue with Email";

  static const String login_title = "Let's get started with us";
  static const String email_login_title = "Enter Your Email ID";
  static const String pwd_login_title = "Enter Password";

  static const String email_lbl = "Email ID";
  static const String terms_and_cond_1 =
      "By Proceeding, you agree with Jhaveri wealth Track";
  static const String terms_and_cond_2 = "terms and conditions";
  static const String terms_and_cond_3 = "and";
  static const String terms_and_cond_4 = "Privacy Policy";
  static const String emailRegexPattern = r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$';

  static const String people_invested = "people have invested in this fund";

  static const String continue_btn = "Continue";

  static const String discover_tab1 = "Explore";
  static const String discover_tab2 = "Watchlist";
  static const String discover_title = "Discover";
  static const String most_pop_funds = "Most popular funds";
  static const String discover_jhaveri_picks = "Jhaveri Picks";
  static const String yr_returns = "3Y Returns: ";
  static const String yr_returns_MF = "3Y Returns";
  static const String yr_returns_fund = "3Y Returns";
  static const String D_G = "Direct . Growth";
  static const String min_investment = "Min. Investment: ";
  static const String min_invest_graph = "Min. Investment";
  static const String inv_now = "Invest Now";
  static const String forgot_password = "Forgot Password ?";
  static const String enter_passw = "Enter your password";
  static const String pwd = "Password";

  static const String mf_min_investment = "Min. Investment: ";
  static const List<String> discover_mutual_funds_categories = [
    "All",
    "High Return",
    "Popular Funds",
    "Jhaveri Picks",
    "NFO"
  ];
  static const String discover_all_MF = "All mutual funds";

  static const String mutual_funds = "All Mutual Funds";
  static const String filter_lbl = "Filters";
  static const String comp_kyc_lbl = "Start Your Investment Journey";
  static const String comp_kyc_subtitle =
      "Complete your KYC or make your first investment to see your portfolio here.";
  static const filterCategories = [
    "Fund House",
    "Fund Category",
    "Sub Category",
    "Risk Level",
    "Fund Size"
  ];

  static const List<Map<String, String>> relationOptions = [
    {'value': '1', 'label': 'Aunt'},
    {'value': '2', 'label': 'Brother'},
    {'value': '3', 'label': 'Daughter'},
    {'value': '4', 'label': 'Daughter In Law'},
    {'value': '5', 'label': 'Father'},
    {'value': '6', 'label': 'Father In Law'},
    {'value': '7', 'label': 'Grand Daughter'},
    {'value': '8', 'label': 'Grand Son'},
    {'value': '9', 'label': 'Grand Father'},
    {'value': '10', 'label': 'Grand Mother'},
    {'value': '11', 'label': 'Husband'},
    {'value': '12', 'label': 'Mother'},
    {'value': '13', 'label': 'Mother In Law'},
    {'value': '14', 'label': 'Nephew'},
    {'value': '15', 'label': 'Niece'},
    {'value': '16', 'label': 'Friend'},
    {'value': '17', 'label': 'Sister'},
    {'value': '18', 'label': 'Son'},
    {'value': '19', 'label': 'Son In Law'},
    {'value': '20', 'label': 'Uncle'},
    {'value': '21', 'label': 'Wife'},
    {'value': '22', 'label': 'Others'},
  ];

  static const List<Map<String, String>> countryOptions = [
    {'value': 'IND', 'label': 'India'},
    {'value': 'ABW', 'label': 'Aruba'},
    {'value': 'AFG', 'label': 'Afghanistan'},
    {'value': 'AGO', 'label': 'Angola'},
    {'value': 'AIA', 'label': 'Anguilla'},
    {'value': 'ALA', 'label': 'Åland Islands'},
    {'value': 'ALB', 'label': 'Albania'},
    {'value': 'AND', 'label': 'Andorra'},
    {'value': 'ARE', 'label': 'United Arab Emirates'},
    {'value': 'ARG', 'label': 'Argentina'},
    {'value': 'ARM', 'label': 'Armenia'},
    {'value': 'ASM', 'label': 'American Samoa'},
    {'value': 'ATA', 'label': 'Antarctica'},
    {'value': 'ATF', 'label': 'French Southern Territories'},
    {'value': 'ATG', 'label': 'Antigua and Barbuda'},
    {'value': 'AUS', 'label': 'Australia'},
    {'value': 'AUT', 'label': 'Austria'},
    {'value': 'AZE', 'label': 'Azerbaijan'},
    {'value': 'BDI', 'label': 'Burundi'},
    {'value': 'BEL', 'label': 'Belgium'},
    {'value': 'BEN', 'label': 'Benin'},
    {'value': 'BES', 'label': 'Bonaire, Sint Eustatius and Saba'},
    {'value': 'BFA', 'label': 'Burkina Faso'},
    {'value': 'BGD', 'label': 'Bangladesh'},
    {'value': 'BGR', 'label': 'Bulgaria'},
    {'value': 'BHR', 'label': 'Bahrain'},
    {'value': 'BHS', 'label': 'Bahamas'},
    {'value': 'BIH', 'label': 'Bosnia and Herzegovina'},
    {'value': 'BLM', 'label': 'Saint Barthélemy'},
    {'value': 'BLR', 'label': 'Belarus'},
    {'value': 'BLZ', 'label': 'Belize'},
    {'value': 'BMU', 'label': 'Bermuda'},
    {'value': 'BOL', 'label': 'Bolivia, Plurinational State of'},
    {'value': 'BRA', 'label': 'Brazil'},
    {'value': 'BRB', 'label': 'Barbados'},
    {'value': 'BRN', 'label': 'Brunei Darussalam'},
    {'value': 'BTN', 'label': 'Bhutan'},
    {'value': 'BVT', 'label': 'Bouvet Island'},
    {'value': 'BWA', 'label': 'Botswana'},
    {'value': 'CAF', 'label': 'Central African Republic'},
    {'value': 'CAN', 'label': 'Canada'},
    {'value': 'CCK', 'label': 'Cocos (Keeling) Islands'},
    {'value': 'CHE', 'label': 'Switzerland'},
    {'value': 'CHL', 'label': 'Chile'},
    {'value': 'CHN', 'label': 'China'},
    {'value': 'CIV', 'label': "Côte d'Ivoire"},
    {'value': 'CMR', 'label': 'Cameroon'},
    {'value': 'COD', 'label': 'Congo, Democratic Republic of the'},
    {'value': 'COG', 'label': 'Congo'},
    {'value': 'COK', 'label': 'Cook Islands'},
    {'value': 'COL', 'label': 'Colombia'},
    {'value': 'COM', 'label': 'Comoros'},
    {'value': 'CPV', 'label': 'Cabo Verde'},
    {'value': 'CRI', 'label': 'Costa Rica'},
    {'value': 'CUB', 'label': 'Cuba'},
    {'value': 'CUW', 'label': 'Curaçao'},
    {'value': 'CXR', 'label': 'Christmas Island'},
    {'value': 'CYM', 'label': 'Cayman Islands'},
    {'value': 'CYP', 'label': 'Cyprus'},
    {'value': 'CZE', 'label': 'Czechia'},
    {'value': 'DEU', 'label': 'Germany'},
    {'value': 'DJI', 'label': 'Djibouti'},
    {'value': 'DMA', 'label': 'Dominica'},
    {'value': 'DNK', 'label': 'Denmark'},
    {'value': 'DOM', 'label': 'Dominican Republic'},
    {'value': 'DZA', 'label': 'Algeria'},
    {'value': 'ECU', 'label': 'Ecuador'},
    {'value': 'EGY', 'label': 'Egypt'},
    {'value': 'ERI', 'label': 'Eritrea'},
    {'value': 'ESH', 'label': 'Western Sahara'},
    {'value': 'ESP', 'label': 'Spain'},
    {'value': 'EST', 'label': 'Estonia'},
    {'value': 'ETH', 'label': 'Ethiopia'},
    {'value': 'FIN', 'label': 'Finland'},
    {'value': 'FJI', 'label': 'Fiji'},
    {'value': 'FLK', 'label': 'Falkland Islands (Malvinas)'},
    {'value': 'FRA', 'label': 'France'},
    {'value': 'FRO', 'label': 'Faroe Islands'},
    {'value': 'FSM', 'label': 'Micronesia, Federated States of'},
    {'value': 'GAB', 'label': 'Gabon'},
    {
      'value': 'GBR',
      'label': 'United Kingdom of Great Britain and Northern Ireland'
    },
    {'value': 'GEO', 'label': 'Georgia'},
    {'value': 'GGY', 'label': 'Guernsey'},
    {'value': 'GHA', 'label': 'Ghana'},
    {'value': 'GIB', 'label': 'Gibraltar'},
    {'value': 'GIN', 'label': 'Guinea'},
    {'value': 'GLP', 'label': 'Guadeloupe'},
    {'value': 'GMB', 'label': 'Gambia'},
    {'value': 'GNB', 'label': 'Guinea-Bissau'},
    {'value': 'GNQ', 'label': 'Equatorial Guinea'},
    {'value': 'GRC', 'label': 'Greece'},
    {'value': 'GRD', 'label': 'Grenada'},
    {'value': 'GRL', 'label': 'Greenland'},
    {'value': 'GTM', 'label': 'Guatemala'},
    {'value': 'GUF', 'label': 'French Guiana'},
    {'value': 'GUM', 'label': 'Guam'},
    {'value': 'GUY', 'label': 'Guyana'},
    {'value': 'HKG', 'label': 'Hong Kong'},
    {'value': 'HMD', 'label': 'Heard Island and McDonald Islands'},
    {'value': 'HND', 'label': 'Honduras'},
    {'value': 'HRV', 'label': 'Croatia'},
    {'value': 'HTI', 'label': 'Haiti'},
    {'value': 'HUN', 'label': 'Hungary'},
    {'value': 'IDN', 'label': 'Indonesia'},
    {'value': 'IMN', 'label': 'Isle of Man'},
    {'value': 'IOT', 'label': 'British Indian Ocean Territory'},
    {'value': 'IRL', 'label': 'Ireland'},
    {'value': 'IRN', 'label': 'Iran, Islamic Republic of'},
    {'value': 'IRQ', 'label': 'Iraq'},
    {'value': 'ISL', 'label': 'Iceland'},
    {'value': 'ISR', 'label': 'Israel'},
    {'value': 'ITA', 'label': 'Italy'},
    {'value': 'JAM', 'label': 'Jamaica'},
    {'value': 'JEY', 'label': 'Jersey'},
    {'value': 'JOR', 'label': 'Jordan'},
    {'value': 'JPN', 'label': 'Japan'},
    {'value': 'KAZ', 'label': 'Kazakhstan'},
    {'value': 'KEN', 'label': 'Kenya'},
    {'value': 'KGZ', 'label': 'Kyrgyzstan'},
    {'value': 'KHM', 'label': 'Cambodia'},
    {'value': 'KIR', 'label': 'Kiribati'},
    {'value': 'KNA', 'label': 'Saint Kitts and Nevis'},
    {'value': 'KOR', 'label': 'Korea, Republic of'},
    {'value': 'KWT', 'label': 'Kuwait'},
    {'value': 'LAO', 'label': "Lao People's Democratic Republic"},
    {'value': 'LBN', 'label': 'Lebanon'},
    {'value': 'LBR', 'label': 'Liberia'},
    {'value': 'LBY', 'label': 'Libya'},
    {'value': 'LCA', 'label': 'Saint Lucia'},
    {'value': 'LIE', 'label': 'Liechtenstein'},
    {'value': 'LKA', 'label': 'Sri Lanka'},
    {'value': 'LSO', 'label': 'Lesotho'},
    {'value': 'LTU', 'label': 'Lithuania'},
    {'value': 'LUX', 'label': 'Luxembourg'},
    {'value': 'LVA', 'label': 'Latvia'},
    {'value': 'MAC', 'label': 'Macao'},
    {'value': 'MAF', 'label': 'Saint Martin (French part)'},
    {'value': 'MAR', 'label': 'Morocco'},
    {'value': 'MCO', 'label': 'Monaco'},
    {'value': 'MDA', 'label': 'Moldova, Republic of'},
    {'value': 'MDG', 'label': 'Madagascar'},
    {'value': 'MDV', 'label': 'Maldives'},
    {'value': 'MEX', 'label': 'Mexico'},
    {'value': 'MHL', 'label': 'Marshall Islands'},
    {'value': 'MKD', 'label': 'North Macedonia'},
    {'value': 'MLI', 'label': 'Mali'},
    {'value': 'MLT', 'label': 'Malta'},
    {'value': 'MMR', 'label': 'Myanmar'},
    {'value': 'MNE', 'label': 'Montenegro'},
    {'value': 'MNG', 'label': 'Mongolia'},
    {'value': 'MNP', 'label': 'Northern Mariana Islands'},
    {'value': 'MOZ', 'label': 'Mozambique'},
    {'value': 'MRT', 'label': 'Mauritania'},
    {'value': 'MSR', 'label': 'Montserrat'},
    {'value': 'MTQ', 'label': 'Martinique'},
    {'value': 'MUS', 'label': 'Mauritius'},
    {'value': 'MWI', 'label': 'Malawi'},
    {'value': 'MYS', 'label': 'Malaysia'},
    {'value': 'MYT', 'label': 'Mayotte'},
    {'value': 'NAM', 'label': 'Namibia'},
    {'value': 'NCL', 'label': 'New Caledonia'},
    {'value': 'NER', 'label': 'Niger'},
    {'value': 'NFK', 'label': 'Norfolk Island'},
    {'value': 'NGA', 'label': 'Nigeria'},
    {'value': 'NIC', 'label': 'Nicaragua'},
    {'value': 'NIU', 'label': 'Niue'},
    {'value': 'NLD', 'label': 'Netherlands, Kingdom of the'},
    {'value': 'NOR', 'label': 'Norway'},
    {'value': 'NPL', 'label': 'Nepal'},
    {'value': 'NRU', 'label': 'Nauru'},
    {'value': 'NZL', 'label': 'New Zealand'},
    {'value': 'OMN', 'label': 'Oman'},
    {'value': 'PAK', 'label': 'Pakistan'},
    {'value': 'PAN', 'label': 'Panama'},
    {'value': 'PCN', 'label': 'Pitcairn'},
    {'value': 'PER', 'label': 'Peru'},
    {'value': 'PHL', 'label': 'Philippines'},
    {'value': 'PLW', 'label': 'Palau'},
    {'value': 'PNG', 'label': 'Papua New Guinea'},
    {'value': 'POL', 'label': 'Poland'},
    {'value': 'PRI', 'label': 'Puerto Rico'},
    {'value': 'PRK', 'label': "Korea, Democratic People's Republic of"},
    {'value': 'PRT', 'label': 'Portugal'},
    {'value': 'PRY', 'label': 'Paraguay'},
    {'value': 'PSE', 'label': 'Palestine, State of'},
    {'value': 'PYF', 'label': 'French Polynesia'},
    {'value': 'QAT', 'label': 'Qatar'},
    {'value': 'REU', 'label': 'Réunion'},
    {'value': 'ROU', 'label': 'Romania'},
    {'value': 'RUS', 'label': 'Russian Federation'},
    {'value': 'RWA', 'label': 'Rwanda'},
    {'value': 'SAU', 'label': 'Saudi Arabia'},
    {'value': 'SDN', 'label': 'Sudan'},
    {'value': 'SEN', 'label': 'Senegal'},
    {'value': 'SGP', 'label': 'Singapore'},
    {'value': 'SGS', 'label': 'South Georgia and the South Sandwich Islands'},
    {'value': 'SHN', 'label': 'Saint Helena, Ascension and Tristan da Cunha'},
    {'value': 'SJM', 'label': 'Svalbard and Jan Mayen'},
    {'value': 'SLB', 'label': 'Solomon Islands'},
    {'value': 'SLE', 'label': 'Sierra Leone'},
    {'value': 'SLV', 'label': 'El Salvador'},
    {'value': 'SMR', 'label': 'San Marino'},
    {'value': 'SOM', 'label': 'Somalia'},
    {'value': 'SPM', 'label': 'Saint Pierre and Miquelon'},
    {'value': 'SRB', 'label': 'Serbia'},
    {'value': 'SSD', 'label': 'South Sudan'},
    {'value': 'STP', 'label': 'Sao Tome and Principe'},
    {'value': 'SUR', 'label': 'Suriname'},
    {'value': 'SVK', 'label': 'Slovakia'},
    {'value': 'SVN', 'label': 'Slovenia'},
    {'value': 'SWE', 'label': 'Sweden'},
    {'value': 'SWZ', 'label': 'Eswatini'},
    {'value': 'SXM', 'label': 'Sint Maarten (Dutch part)'},
    {'value': 'SYC', 'label': 'Seychelles'},
    {'value': 'SYR', 'label': 'Syrian Arab Republic'},
    {'value': 'TCA', 'label': 'Turks and Caicos Islands'},
    {'value': 'TCD', 'label': 'Chad'},
    {'value': 'TGO', 'label': 'Togo'},
    {'value': 'THA', 'label': 'Thailand'},
    {'value': 'TJK', 'label': 'Tajikistan'},
    {'value': 'TKL', 'label': 'Tokelau'},
    {'value': 'TKM', 'label': 'Turkmenistan'},
    {'value': 'TLS', 'label': 'Timor-Leste'},
    {'value': 'TON', 'label': 'Tonga'},
    {'value': 'TTO', 'label': 'Trinidad and Tobago'},
    {'value': 'TUN', 'label': 'Tunisia'},
    {'value': 'TUR', 'label': 'Türkiye'},
    {'value': 'TUV', 'label': 'Tuvalu'},
    {'value': 'TWN', 'label': 'Taiwan, Province of China'},
    {'value': 'TZA', 'label': 'Tanzania, United Republic of'},
    {'value': 'UGA', 'label': 'Uganda'},
    {'value': 'UKR', 'label': 'Ukraine'},
    {'value': 'UMI', 'label': 'United States Minor Outlying Islands'},
    {'value': 'URY', 'label': 'Uruguay'},
    {'value': 'USA', 'label': 'United States of America'},
    {'value': 'UZB', 'label': 'Uzbekistan'},
    {'value': 'VAT', 'label': 'Holy See'},
    {'value': 'VCT', 'label': 'Saint Vincent and the Grenadines'},
    {'value': 'VEN', 'label': 'Venezuela, Bolivarian Republic of'},
    {'value': 'VGB', 'label': 'Virgin Islands (British)'},
    {'value': 'VIR', 'label': 'Virgin Islands (U.S.)'},
    {'value': 'VNM', 'label': 'Viet Nam'},
    {'value': 'VUT', 'label': 'Vanuatu'},
    {'value': 'WLF', 'label': 'Wallis and Futuna'},
    {'value': 'WSM', 'label': 'Samoa'},
    {'value': 'YEM', 'label': 'Yemen'},
    {'value': 'ZAF', 'label': 'South Africa'},
    {'value': 'ZMB', 'label': 'Zambia'},
    {'value': 'ZWE', 'label': 'Zimbabwe'},
  ];
  static const Map<String, String> countryCodeAliases = {
    'US': 'USA', // API returns "US" but we use "USA"
    'UK': 'GBR', // In case API returns "UK" instead of "GBR"
  };
  static const List<Map<String, String>> idTypeOptions = [
    {'value': 'pan', 'label': 'Pan Card'},
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'driving_license', 'label': 'Driving Licence'},
  ];

  // Sort options for Portfolio/Funds tab
  static const List<Map<String, dynamic>> filter_sortOptions = [
    {'id': 'current', 'name': 'Current Value', 'icon': Icons.attach_money},
    {'id': 'invested', 'name': 'Invested Value', 'icon': Icons.trending_up},
    {'id': 'xirr', 'name': 'XIRR', 'icon': Icons.percent},
    {'id': 'folio_no', 'name': 'Folio No', 'icon': Icons.description},
    {'id': 'fund_type', 'name': 'Fund Type', 'icon': Icons.numbers},
    {
      'id': 'absolute_return',
      'name': 'Absolute Return',
      'icon': Icons.bar_chart
    },
  ];

// Sort options for Orders tab
  static const List<Map<String, dynamic>> ordersSortOptions = [
    {'id': 'invested_amount', 'name': 'Amount', 'icon': Icons.attach_money},
    {
      'id': 'investment_date',
      'name': 'Order Date',
      'icon': Icons.calendar_today
    },
    {'id': 'order_type', 'name': 'Order Type', 'icon': Icons.repeat},
    {'id': 'fund_name', 'name': 'Fund Name', 'icon': Icons.description},
    {'id': 'folio_no', 'name': 'Folio No.', 'icon': Icons.tag},
    {'id': 'order_status', 'name': 'Status', 'icon': Icons.check_circle},
  ];

// ✅ Dynamic sort options for SIP/SWP/STP based on sub-tab (0=SIP, 1=SWP, 2=STP)
  static List<Map<String, dynamic>> getSipSwpStpSortOptions(int subTab) {
    String amountKey;

    switch (subTab) {
      case 0: // SIP
        amountKey = 'amount';
        break;
      case 1: // SWP
        amountKey = 'amount';
        break;
      case 2: // STP
        amountKey = 'amount';
        break;
      default:
        amountKey = 'amount';
    }

    return [
      {'id': amountKey, 'name': 'Amount', 'icon': Icons.attach_money},
      {'id': 'fund_name', 'name': 'Fund Name', 'icon': Icons.description},
      {'id': 'folio_no', 'name': 'Folio No.', 'icon': Icons.tag},
      {'id': 'status', 'name': 'Status', 'icon': Icons.check_circle},
      {'id': 'frequency', 'name': 'Frequency', 'icon': Icons.repeat},
    ];
  }

// ✅ Get the correct date field name based on sub-tab
  static String getDateFieldName(int subTab) {
    switch (subTab) {
      case 0: // SIP
        return 'next_installment_date';
      case 1: // SWP
        return 'next_withdrawal_date';
      case 2: // STP
        return 'next_transfer_date';
      default:
        return 'next_installment_date';
    }
  }

  static const List<String> filter_categories = [
    'Sort',
    'Fund House',
    'Fund Category',
    'Sub Category',
  ];
  static const relation = [
    'Aunt',
    'Brother',
    'Daughter',
    'Father',
    'Mother',
    'Sister',
    'Son',
    'Spouse',
    'Uncle'
  ];
  static const id_type = [
    'Pan Card',
    'Aadhaar Card',
    'Passport',
    'Driving Licence'
  ];

  // ✅ ID Type mapping between API and display values
  static const Map<String, String> idTypeApiToDisplay = {
    'pan': 'Pan Card',
    'aadhaar': 'Aadhaar Card',
    'passport': 'Passport',
    'driving_license': 'Driving Licence',
  };

  static const Map<String, String> idTypeDisplayToApi = {
    'Pan Card': 'pan',
    'Aadhaar Card': 'aadhaar',
    'Passport': 'passport',
    'Driving Licence': 'driving_license',
  };

// ✅ UPDATED: Handle both label and key formats
  static String getRelationLabel(String input) {
    // If it's already a label (like "Aunt"), return as-is
    final existingLabel = relationOptions.firstWhere(
      (r) => r['label'] == input,
      orElse: () => {},
    );

    if (existingLabel.isNotEmpty) {
      return input; // Already a label
    }

    // Otherwise, treat it as a key and find the label
    final relation = relationOptions.firstWhere(
      (r) => r['value'] == input,
      orElse: () => {'label': input},
    );
    return relation['label']!;
  }

// ✅ UPDATED: Handle both label and key formats
  static String getRelationKey(String input) {
    // If it's a key (like "1"), return as-is
    final existingKey = relationOptions.firstWhere(
      (r) => r['value'] == input,
      orElse: () => {},
    );

    if (existingKey.isNotEmpty) {
      return input; // Already a key
    }

    // Otherwise, treat it as a label and find the key
    final relation = relationOptions.firstWhere(
      (r) => r['label'] == input,
      orElse: () => {'value': input},
    );
    return relation['value']!;
  }

// ✅ UPDATED: Handle both label and key formats for country
  static String getCountryLabel(String input) {
    // First, check if there's an alias
    final normalizedInput = countryCodeAliases[input] ?? input;

    // If it's already a label, return as-is
    final existingLabel = countryOptions.firstWhere(
      (c) => c['label'] == normalizedInput,
      orElse: () => {},
    );

    if (existingLabel.isNotEmpty) {
      return normalizedInput;
    }

    // Otherwise, treat it as a key
    final country = countryOptions.firstWhere(
      (c) => c['value'] == normalizedInput,
      orElse: () => {'label': normalizedInput},
    );
    return country['label']!;
  }

// ✅ UPDATED: Handle both label and key formats for country
  static String getCountryKey(String input) {
    // First, check if there's an alias
    final normalizedInput = countryCodeAliases[input] ?? input;

    // If it's a key, return as-is
    final existingKey = countryOptions.firstWhere(
      (c) => c['value'] == normalizedInput,
      orElse: () => {},
    );

    if (existingKey.isNotEmpty) {
      return normalizedInput;
    }

    // Otherwise, treat it as a label
    final country = countryOptions.firstWhere(
      (c) => c['label'] == normalizedInput,
      orElse: () => {'value': normalizedInput},
    );
    return country['value']!;
  }

// ✅ ID Type helpers remain the same
  static String getDisplayIdType(String apiValue) {
    return idTypeApiToDisplay[apiValue.toLowerCase()] ?? apiValue;
  }

  static String getApiIdType(String displayValue) {
    final apiValue = idTypeDisplayToApi[displayValue];
    if (apiValue != null) {
      print('✅ Found mapping: $displayValue -> $apiValue');
      return apiValue;
    }
    print('❌ No mapping found for: $displayValue, using fallback');
    return displayValue.toLowerCase().replaceAll(' ', '_');
  }

  // ✅ Get list of relation labels only (for dropdown display)
  static List<String> get relationLabels =>
      relationOptions.map((r) => r['label']!).toList();

  // ✅ Get list of country labels only (for dropdown display)
  static List<String> get countryLabels =>
      countryOptions.map((c) => c['label']!).toList();

  // ✅ Get list of ID type labels only (for dropdown display)
  static List<String> get idTypeLabels => id_type;

  static const String add_filters = "Add";
  static const String clear_filters = "Clear";
  static const String searching_filter = "Search...";

  static const String sel_categ = "Select a category";
  static const String no_macth = 'No matching options';
  static const String no_results = "No matching results";

  static const String profile_title = "Profile";
  static const String acc_det_txt = "Account Details";

  static const List<Map<String, dynamic>> profileOptions = [
    {
      'title': 'Account Details',
      'icon': acc_det,
      'route': '/account_details',
      'showArrow': true,
    },
    {
      'title': 'Reports',
      'icon': rep,
      'route': '/reports',
      'showArrow': true,
    },
    {
      'title': 'Request Services',
      'icon': req_serv,
      'route': '/request_services',
      'showArrow': true,
    },
    {
      'title': 'Orders',
      'icon': orders,
      'route': '/orders',
      'showArrow': true,
    },
    {
      'title': 'Contact Us',
      'icon': contact,
      'route': '/contact_us',
      'showArrow': true,
    },
    {
      'title': 'Log out',
      'icon': logout,
      'route': null,
      'showArrow': false,
    },
  ];

  static const List<Map<String, dynamic>> requestServices = [
    {
      'title': 'Collect Cheque',
      'icon': acc_det,
    },
    {
      'title': 'Collect Documents',
      'icon': rep,
    },
    {
      'title': 'Call me',
      'icon': contact,
    },
    {
      'title': 'Report an Issue',
      'icon': contact,
    },
  ];

  static const reports = [
    {
      'title': cap_gain,
      'icon': acc_det,
      'route': '/capital-gain-report',
    },
    {
      'title': fol_led,
      'icon': mf_folio,
      'route': '/mf_folio_ledger_report',
    },
    {
      'title': por_vs,
      'icon': mf_folio_vs,
      'route': '/portfolio-valuation-summary',
    },
  ];
  static const Map<String, dynamic> allFamily = {
    'id': 'all',
    'name': 'All Family Members',
    'isCurrentUser': false, // optional for consistency
  };

  static const String orders_title_lbl = "Orders";
  static const String orders_name_lbl = "Name";
  static const String orders_amt_lbl = "Amount";
  static const String orders_date_lbl = "Date";
  static const String orders_bseid_lbl = "BSE ID";
  static const String map_add = "https://www.google.com/maps/search/?api=1&query=";
  static const String couldnt_open_mail = 'Could not open mail app. Please check your email manually.';

  static const String fund_info = "Fund information";
  static const String inv_return = "Investment return";
  static const String hold_sum = "Holding summary";
  static const String categ_returns = "Category returns";
  static const String min_ret = "Min. Returns";
  static const String max_ret = "Max. Returns";
  static const String hs_tab1 = "Sector Wise";
  static const String hs_tab2 = "Company Wise";
  static const String def_time_period = "1m";
  static const String returns = "Returns";
  static const String performance = "Performance";
  static const String abs = "ABS";
  static const String cagr = "CAGR";
  static const String would_return = "Would have given return of";
  static const String onetime_btn = "One-Time";
  static const String start_sip_btn = "Start SIP";
  static const String view_less = "View Less";

  static const String my_inv = "My Investments";
  static const String current = "Current";
  static const String inv = "Invested";
  static const String one_d_ret = "1D Return";
  static const String xirr = "XIRR";
  static const String fam_lbl = "My Family";
  static const String my_fam_inv = "My Family Investments";
  static const String all = "All";
  static const String me = "Me";

  static const String name = "Name";
  static const String type = "Type";
  static const String amt = "Amount";
  static const String resp_success = "successful";
  static const String complete = "complete";
  static const String completed = "completed";
  static const String resp_failed = "failed";
  static const String resp_pend = "pending";
  static const String failed = "Failed";
  static const String pend = "Awaiting";
  static const String inv_more = "Invest More";
  static const String trans_stat = "Transaction Status";
  static const String tran_id = "Transaction ID";
  static const String fol_no = "Folio No.";
  static const String nav_date = "NAV Date";
  static const String nav_price = "NAV(Price)";
  static const String units = "Units";
  static const String d_and_t = "Date & Time";
  static const String inv_type = "Investment Type";
  static const String bal_unit = "Balance Unit";
  static const String avg_nav = "Avg. NAV";
  static const String oth_det = "Other Details";
  static const String inv_date = "Investment Date";
  static const String hol_pat = "Holding Status";
  static const String joint_hol = "Joint Holder";
  static const String action = "Action";
  static const String act_sip = "Active SIPs";
  static const String tot_sip_amt = "Total SIP Amount";
  static const String sip = "SIP";
  static const String swp = "SWP";
  static const String stp = "STP";
  static const String sip_tab_amt = "Amount :";
  static const String freq = "Frequency";
  static const nextInstallment = 'Next Installment';
  static const nextWithdrawal = 'Next Withdrawal';
  static const nextTransfer = 'Next Transfer';
  static const String report = "Reports";
  static const String totalSIPAmount = 'Total SIP Amount';
  static const String totalSWPAmount = 'Total SWP Amount';
  static const String totalSTPAmount = 'Total STP Amount';
  static const String activeSIP = 'Active SIP';
  static const String activeSWP = 'Active SWP';
  static const String activeSTP = 'Active STP';
  static const String cap_gain = "MF Captial Gain Report";
  static const String fol_led = "MF Folio Ledger Report";
  static const String por_vs = "MF Portfolio Valuation Summary";

  static const String sel_grou = 'Select Group';
  static const String select = 'Select';
  static const String load_fam_mem = 'Loading family members...';
  static const String period = 'Period';
  static const String custom = 'Custom';
  static const String from_date = 'From Date';
  static const String to_date = 'To Date';
  static const String download = 'Download';
  static const String email = 'Email';

  static const String mf_folio_ledger_title = 'MF Folio Ledger Report';
  static const String group_wise_tab = 'Group Wise';
  static const String folio_wise_tab = 'Folio Wise';
  static const String select_folio = 'Select folio';
  static const String all_family_members = 'All Family Members';
  static const String loading_family_members = 'Loading family members...';
  static const String loading_folios = 'Loading folios...';
  static const String retry = 'Retry';
  
  static const String download_btn = 'Download';
  static const String email_btn = 'Email';
  
  static const String sending_email = 'Sending report via email...';
  static const String folio_ledger_downloaded =
      'Folio Ledger Report Downloaded';
  static const String tap_to_open = 'Tap to open';

  static const String swi = "Switch";
  static const String red = "Redeem";
  static const String all_trans = "All Transaction";

  static const String order_success_inst =
      'Please check your SMS or Email for the BSE link to authorize the transaction and continue.';

  static const String avl_units = "Available Units";
  static const String avl_amt = "Available Amount";
  static const String ent_units = 'Enter Units';
  static const String amt_hint = "5,000";
  static const String units_hint = '0';
  static const String red_all_uni = "Redeem All Units";
  static const String red_tot_amt = 'Redeem Total Amount';

  static const String confirm = "Confirm";
  static const String cancel = "Cancel";
  static const String cnf_res_sip = 'Are you sure you want to Resume this SIP?';
  static const String pls_wait = "Please wait";
  static const String pau_sip = "Pause SIP";
  static const String curr_amt = 'Current Amount';
  static const String sel_acc = 'Select Account';
  static const String selc_bse_acc = 'Select BSE Account';
  static const String sel_fol = 'Select Folio';
  static const String new_folio = "New Folio";
  static const String loading = "Loading...";
  static const String tax_status = "Tax Status";
  static const String processing = "Processing...";
  static const String please_wait_order =
      "Please wait while we process your order...";
  static const String processing_order = "Processing order...";
  static const String second_holder_name = "Second Holder Name";
  static const String select_mandate = "Select Mandate";
  
  static const String mandate_id = "Mandate ID";
  static const String bank_name = "Bank Name";
  static const String account_number = "Account Number";
  static const String ifsc = "IFSC";
  static const String note_min_investment_new_folio =
      "Note: Minimum investment amount for new folio is ₹";
  static const String my_jsl_prof = 'My JSL Profile';
  static const String mf_acc = 'Mutual Fund Account';
  static const String ban_lin_desc =
      'Select and pay ₹1 via UPI from the bank account you want to link.';
  static const String govt_rules =
      'As per Govt. regulations, investments must be made from a linked bank account.';

  // Labels
  static const riskLabels = [
    'Low',
    'Moderately Low',
    'Moderate',
    'Moderately High',
    'High',
  ];
  static const List<String> time_periods = [
    '1m',
    '6m',
    '1yr',
    '3yr',
    '5yr',
    'Max'
  ];
  static const List<String> port_tab_title = ['Funds', 'SIPs', 'Orders'];
  static const List<String> capitalGainPeriods = [
    '2025-26',
    '2024-25',
    '2023-24',
    'Custom'
  ];
  static const List<int> amt_txtbtns = [500, 1000, 5000, 10000];

  // Logos & Assets
  static const String back_icon = "assets/images/arrow_left.svg";
  static const String blueLogo = "assets/images/blue_logo.svg";
  static const String whiteLogo = "assets/images/white_logo.svg";
  static const String onboardingBG = "assets/images/OnboardingBG.jpg";

  static const String onboarding_1 = "assets/images/onboarding_1.png";
  static const String onboarding_2 = "assets/images/onboarding_2.png";
  static const String onboarding_3 = "assets/images/onboarding_3.png";

  static const String img_verified_dash = "assets/images/on_success.svg";
  static const String img_complete_kyc = "assets/images/complete_kyc.svg";
  static const String home = "assets/images/default_home.svg";
  static const String filled_home = "assets/images/filled_home.svg";

  static const String portfolio = "assets/images/default_portfolio.svg";
  static const String filled_portfolio = "assets/images/filled_portfolio.svg";

  static const String discover = "assets/images/default_discover.svg";
  static const String filled_discover = "assets/images/filled_discover.svg";
  static const String iconFund = "assets/images/funds_logo.svg";
  static const String iconFunds_png = "assets/images/funds_logo.png";
  static const String above_sign = "assets/images/above_sign.svg";

  static const String notify = "assets/images/notification.svg";
  static const String search = "assets/images/search.svg";

  static const String calculator = "assets/images/calculator.svg";
  static const String nfo = "assets/images/nfo.svg";

  static const String iconHighReturn = "assets/images/high_return.svg";
  static const String iconJhaveriPicks = "assets/images/jhaveri_picks.svg";
  static const String iconNfo = "assets/images/nfo.svg";
  static const String iconLargeCap = "assets/images/large_cap.svg";
  static const String iconMidCap = "assets/images/mid_cap.svg";
  static const String iconSmallCap = "assets/images/small_cap.svg";
  static const String iconAmcs = "assets/images/amcs.svg";
  static const String iconSectorial = "assets/images/sectorial.svg";
  static const String iconTaxSaver = "assets/images/tax_saver.svg";
  static const String login_bg = "assets/images/LoginBG.jpg";
  static const String google = "assets/images/google.png";
  static const String mail = "assets/images/mail.svg";
  static const String filter = "assets/images/filter.svg";
  static const String save = "assets/images/bookmark.svg";

  static const String fund_comp = "assets/images/fund_compare.svg";
  static const String acc_det = "assets/images/acc_details.svg";
  static const String rep = "assets/images/reports.svg";
  static const String req_serv = "assets/images/request_services.svg";
  static const String orders = "assets/images/orders.svg";
  static const String contact = "assets/images/contact_us.svg";
  static const String logout = "assets/images/logout.svg";
  static const String down_red = "assets/images/red_arrow.svg";
  static const String down_red_arrow = "assets/images/double_arrow_red.svg";
  static const String up_green = "assets/images/green_arrow.svg";
  static const String up_green_arrow = "assets/images/double_arrow_green.svg";
  static const String user_group = "assets/images/user_group_white.svg";
  static const String curr_user = "assets/images/user.svg";

  static const String mf_folio = "assets/images/mf_folio.svg";
  static const String mf_folio_vs = "assets/images/mf_folio_vs.svg";

  static const String calender = "assets/images/calendar.svg";
  static const String bob_icon = "assets/images/bob_png.png";
  static const String success_mail = "assets/images/success_mailed.svg";

  static const String success_icon = "assets/images/redeem_success.svg";
  static const String error_icon = "assets/images/redeem_failed.svg";

  static const String note = "assets/images/note.svg";
  static const String user_acc_svg = "assets/images/user_account.svg";
  static const String todo_task = "assets/images/todo_task.svg";

  static const String one_rs = "assets/images/one_rs.svg";
  static const String money = "assets/images/money_bag.svg";

  // Order Success Screen
  static const String go_to_mailbox = "Go to Mail Box";
  static const String explore_more = "Explore More";

  // Validation Messages
  static const String invest = "Invest";
  static const String na = "N/A";

  static const String add_nom = "assets/images/add_nominee.svg";
}
