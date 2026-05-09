
import '../../../../core/network/http_client.dart';

class PortfolioService {
  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>> getPortfolioDetails({
    required String fundId,
    required String folioNo,
  }) async {
    final response = await _client.get(
      "/portfolio/details?fund_id=$fundId&folio_no=$folioNo",
    );
    return response;
  }
}