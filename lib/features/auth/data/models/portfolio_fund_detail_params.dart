class FundDetailParams {
  final int fundId;
  final String folioNo;

  const FundDetailParams({
    required this.fundId,
    required this.folioNo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FundDetailParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId &&
              folioNo == other.folioNo;

  @override
  int get hashCode => fundId.hashCode ^ folioNo.hashCode;
}