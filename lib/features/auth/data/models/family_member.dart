class FamilyMember {
  final int clientId;
  final String clientName;
  final bool isCurrentUser;
  final String? bseClientId; // ✅ Added for backward compatibility
  final bool isActive; // ✅ Added for backward compatibility

  FamilyMember({
    required this.clientId,
    required this.clientName,
    required this.isCurrentUser,
    this.bseClientId,
    this.isActive = true,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      clientId: json['client_id'] ?? 0,
      clientName: json['client_name'] ?? '',
      isCurrentUser: json['is_current_user'] ?? false,
      bseClientId: json['bse_client_id']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'client_name': clientName,
      'is_current_user': isCurrentUser,
      'bse_client_id': bseClientId,
      'is_active': isActive,
    };
  }
}