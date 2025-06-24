import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/services/order_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

import '../../order_details/domain/models/order_details_model.dart';
import '../../review/widgets/review_dialog_widget.dart';

class OrderController with ChangeNotifier {
  final OrderServiceInterface orderServiceInterface;
  OrderController({required this.orderServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OrderModel? orderModel;
  OrderModel? deliveredOrderModel;

  Future<void> getOrderList(int offset, String status, {String? type}) async {
    _isLoading=true;
    var localData = await database.getCacheResponseById(AppConstants.orderUri);

    if (type == 'reorder') {
      if (localData != null) {
        deliveredOrderModel = OrderModel.fromJson(jsonDecode(localData.response));
        notifyListeners();
      }
    }

    if (offset == 1) {
      orderModel = null;
    }

    ApiResponse apiResponse = await orderServiceInterface.getOrderList(offset, status, type: type);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if (offset == 1) {
        orderModel = OrderModel.fromJson(apiResponse.response?.data);

        if (type == 'reorder') {
          deliveredOrderModel = OrderModel.fromJson(apiResponse.response?.data);

          if (localData != null) {
            await database.updateCacheResponse(
              AppConstants.orderUri,
              CacheResponseCompanion(
                endPoint: Value(AppConstants.orderUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: Value(AppConstants.orderUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        }
      } else {
        var newOrders = OrderModel.fromJson(apiResponse.response?.data).orders ?? [];
        orderModel!.orders!.addAll(newOrders);
        orderModel!.offset = OrderModel.fromJson(apiResponse.response?.data).offset;
        orderModel!.totalSize = OrderModel.fromJson(apiResponse.response?.data).totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    _isLoading=false;
    notifyListeners();

  }

  int _orderTypeIndex = 0;
  int get orderTypeIndex => _orderTypeIndex;

  String selectedType = 'ongoing';

  void setIndex(int index, {bool notify = true}) {
    _orderTypeIndex = index;

    if (_orderTypeIndex == 0) {
      selectedType = 'ongoing';
      getOrderList(1, 'ongoing');
    } else if (_orderTypeIndex == 1) {
      selectedType = 'delivered';
      getOrderList(1, 'delivered');
    } else if (_orderTypeIndex == 2) {
      selectedType = 'canceled';
      getOrderList(1, 'canceled');
    }

    if (notify) {
      notifyListeners();
    }
  }

  Orders? trackingModel;
  Future<void> initTrackingInfo(String orderID) async {
    ApiResponse apiResponse = await orderServiceInterface.getTrackingInfo(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      trackingModel = Orders.fromJson(apiResponse.response!.data);
    }
    notifyListeners();
  }


  List<List<Orders>> getGroupedOrdersAsListOfLists() {
    if (orderModel == null || orderModel!.orders == null) return [];

    Map<String, List<Orders>> groupedMap = {};

    // Debug: Print all order_group_ids
    print("===== All order_group_ids =====");
    for (var order in orderModel!.orders!) {
      print("Raw Group ID: '${order.orderGroupId}'");
    }


    // Group orders by order_group_id
    for (var order in orderModel!.orders!) {
      String groupId = (order.orderGroupId ?? 'unknown_group').trim().toLowerCase();

      if (!groupedMap.containsKey(groupId)) {
        groupedMap[groupId] = [];
      }
      groupedMap[groupId]!.add(order);
    }

    // Debug: Print grouped map
    print("\n===== Grouped Map =====");
    groupedMap.forEach((key, orders) {
      print("Group ID: '$key' | Orders: ${orders.length}");
    });

    List<List<Orders>> result = [];

    // Add groups with multiple orders first
    groupedMap.forEach((key, ordersList) {
      if (ordersList.length > 1) {
        result.add(ordersList);
      }
    });

    // Add single-order groups
    groupedMap.forEach((key, ordersList) {
      if (ordersList.length == 1) {
        result.add(ordersList);
      }
    });

    // Debug: Print final result
    print("\n===== Final Result =====");
    print("Total groups: ${result.length}");
    for (int i = 0; i < result.length; i++) {
      print("Group $i: ${result[i].length} orders");
      if (result[i].length > 1) {
        print("  Orders: ${result[i].map((o) => o.id).join(', ')}");
      }
    }

    return result;
  }







  Future<ApiResponse> cancelOrder(BuildContext context, int? orderId) async {
    _isLoading = true;
    notifyListeners();

    ApiResponse apiResponse = await orderServiceInterface.cancelOrder(orderId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
    } else {
      _isLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Orders? mergeAllOrdersIntoOne() {
    if (orderModel == null || orderModel!.orders == null || orderModel!.orders!.isEmpty) {
      return null;
    }

    double totalOrderAmount = 0.0;
    double totalShippingCost = 0.0;
    double totalServiceFee = 0.0;
    List<Details> allDetails = [];

    for (var order in orderModel!.orders!) {
      totalOrderAmount += order.orderAmount ?? 0;
      totalShippingCost += order.shippingCost ?? 0;
      totalServiceFee += double.tryParse(order.serviceFee?.toString() ?? '0') ?? 0;

      if (order.details != null) {
        allDetails.addAll(order.details!);
      }
    }

    Orders baseOrder = orderModel!.orders!.first;

    return Orders(
      id: int.tryParse(baseOrder.orderGroupId ?? '') ?? 0,
      orderGroupId: baseOrder.orderGroupId,
      createdAt: baseOrder.createdAt,
      orderAmount: totalOrderAmount,
      shippingCost: totalShippingCost,
      serviceFee: totalServiceFee.toStringAsFixed(2),
      seller: baseOrder.seller,
      details: allDetails,
    );
  }

}
