import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';

// Order Details Model
class OrderDetailsModel {
  final String schemeName;
  final double amount;
  final String status;
  final String transactionType;
  final String orderDateTime;
  final double units;
  final double nav;
  final String navDate;
  final String folioNo;
  final String transactionId;
  final String? currentStatus;

  OrderDetailsModel({
    required this.schemeName,
    required this.amount,
    required this.status,
    required this.transactionType,
    required this.orderDateTime,
    required this.units,
    required this.nav,
    required this.navDate,
    required this.folioNo,
    required this.transactionId,
    this.currentStatus,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      schemeName: json['scheme_name'] ?? json['src_scheme_name'] ?? '',
      amount: (json['amount'] ?? json['invested_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      transactionType: json['transaction_type'] ?? json['order_type'] ?? '',
      orderDateTime: json['order_date_time'] ?? json['placed_at'] ?? '',
      units: (json['units'] ?? 0).toDouble(),
      nav: (json['nav'] ?? 0).toDouble(),
      navDate: json['nav_date'] ?? '',
      folioNo: json['folio_no'] ?? '',
      transactionId: json['transaction_id'] ?? json['order_id']?.toString() ?? '',
      currentStatus: json['current_status'],
    );
  }
}

// Order History Model (from /orders/status API)
class OrderHistoryItem {
  final String status;
  final String msg;
  final String time;

  OrderHistoryItem({
    required this.status,
    required this.msg,
    required this.time,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      status: json['status'] ?? '',
      msg: json['msg'] ?? '',
      time: json['time'] ?? '',
    );
  }

  // Helper to determine the state for UI rendering
  String get state {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('complete') ||
        statusLower.contains('success') ||
        statusLower.contains('received')) {
      return 'successful';
    } else if (statusLower.contains('fail') ||
        statusLower.contains('reject') ||
        statusLower.contains('expired')) {
      return 'failed';
    } else {
      return 'pending';
    }
  }
}

// Complete Order Details Response
class OrderDetailsResponse {
  final OrderDetailsModel orderDetails;
  final List<OrderHistoryItem> orderHistory;

  OrderDetailsResponse({
    required this.orderDetails,
    required this.orderHistory,
  });

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    // Handle both nested and flat structures
    Map<String, dynamic> orderDetailsJson;
    List<dynamic> orderHistoryJson;

    // Check if data is nested under 'order_details' key
    if (json.containsKey('order_details')) {
      orderDetailsJson = json['order_details'];
      orderHistoryJson = json['order_history'] ?? [];
    } else {
      // Flat structure - the entire json is the order details
      orderDetailsJson = json;
      orderHistoryJson = json['order_history'] ?? [];
    }

    return OrderDetailsResponse(
      orderDetails: OrderDetailsModel.fromJson(orderDetailsJson),
      orderHistory: orderHistoryJson
          .map((item) => OrderHistoryItem.fromJson(item))
          .toList(),
    );
  }
}

// Provider
final orderDetailsProvider = StateNotifierProvider.family<
    OrderDetailsNotifier,
    AsyncValue<OrderDetailsResponse>,
    int>((ref, orderId) => OrderDetailsNotifier(orderId));

class OrderDetailsNotifier
    extends StateNotifier<AsyncValue<OrderDetailsResponse>> {
  final int orderId;

  OrderDetailsNotifier(this.orderId) : super(const AsyncValue.loading()) {
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('📋 Fetching order details for orderId: $orderId');

      // Fetch order details
      final detailsUri = Uri.parse('${EnvConfig.apiBaseUrl}/orders/details');
      final detailsResponse = await http.post(
        detailsUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"order_id": orderId}),
      );

      print('📡 Details response status: ${detailsResponse.statusCode}');
      print('📦 Details response body: ${detailsResponse.body}');

      if (detailsResponse.statusCode != 200) {
        throw Exception("HTTP error: ${detailsResponse.statusCode} - ${detailsResponse.body}");
      }

      final detailsData = jsonDecode(detailsResponse.body);
      if (detailsData['status'] != 1) {
        throw Exception(detailsData['message'] ?? "Failed to fetch order details");
      }

      // Fetch order history/status
      final statusUri = Uri.parse('${EnvConfig.apiBaseUrl}/orders/status');
      final statusResponse = await http.post(
        statusUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"order_id": orderId}),
      );

      print('📡 Status response status: ${statusResponse.statusCode}');
      print('📦 Status response body: ${statusResponse.body}');

      List<OrderHistoryItem> orderHistory = [];

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        if (statusData['status'] == 1 && statusData['data'] != null) {
          final dataList = statusData['data']['data_list'] as List<dynamic>? ?? [];
          orderHistory = dataList.map((item) => OrderHistoryItem.fromJson(item)).toList();
          print('✅ Fetched ${orderHistory.length} history items');
        }
      } else {
        print('⚠️ Could not fetch order history, continuing with details only');
      }

      // Combine both responses
      final orderDetailsJson = detailsData['data'];
      final orderDetails = OrderDetailsModel.fromJson(
          orderDetailsJson.containsKey('order_details')
              ? orderDetailsJson['order_details']
              : orderDetailsJson
      );

      state = AsyncValue.data(
        OrderDetailsResponse(
          orderDetails: orderDetails,
          orderHistory: orderHistory,
        ),
      );

    } catch (e, st) {
      print('❌ Error fetching order details: $e');
      print('📚 Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}