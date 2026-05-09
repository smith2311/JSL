class ValidationMessages {
  static const String please_select_account = "Please select an account";
  static const String please_select_bse_account = "Please select a BSE account";
  static const String please_select_folio = "Please select a folio";
  static const String please_select_date = "Please select date of investment";
  static const String please_enter_installments = "Please enter number of installments";
  static const String please_enter_investment = "Please enter investment amount";
  static const String please_enter_sip = "Please enter SIP amount";
  static const String no_mandate_warning = "No mandates found for this account. Please create a mandate first.";
  static const String from_date_required = 'From date is required';
  static const String to_date_required = 'To date is required';
  static const String from_date_after_to_date = 'From date cannot be after To date';
  static const String to_date_before_from_date = 'To date cannot be before From date';
  static const String storage_permission_required = 'Storage permission is required to download the report';
   static const String errorText = "Please enter a valid email address";
}

class SuccessMessages {
    static const String report_downloaded_success = 'Report downloaded successfully';
    static const String sip_res = 'SIP resumed successfully';
}

class ErrorMessages {
    static const String unauth_login = "Unauthorized. Please login again.";
    static const String failed_to_fetch = "Failed to fetch popular funds ";
    static const String no_funds = "No funds available";
    static const String no_options = "No options available for this category.";
    static const String errorLoadingFundDetails = "Error loading fund details";
    static const String fail_fam_mem = 'Failed to load family members';
    static const String failed_load_family = 'Failed to load family members';
    static const String failed_load_folios = 'Failed to load folios';
    static const String report_download_failed = 'Failed to download report';
    static const String error_prefix = 'Error: ';
    static const String error_sip_order = "Error placing SIP order: ";
    static const String error_lumpsum_order = "Error placing lumpsum order: ";
    static const String unexpected_error = "Unexpected error: ";
}
