
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class CheckoutRepository implements CheckoutRepositoryInterface{
  final DioClient? dioClient;
  CheckoutRepository({required this.dioClient});


  @override

  Future<ApiResponse> cashOnDeliveryPlaceOrder(
      String? addressId,
      String? couponCode,
      String? selectedDeliveryTime,
      int? governorateId,
      String? shippingFee,
      String? deliveryDate,
      String? couponAmount,
      String? serviceFee,
      String? billingAddressId,
      String? shippingAddressId,
      String? orderNote,
      String? paymentNote,
      int? id,
      String? name,
      List<String>? inputValues,
      ) async {
    try {
      Map<String, dynamic> body = {
        "address_id": addressId,
        "coupon_code": couponCode,
        "selected_delivery_time": selectedDeliveryTime,
        "governorate_id": governorateId,
        "shipping_fee": shippingFee,
        "delivery_date": deliveryDate,
        "coupon_amount": couponAmount,
        "service_fee": serviceFee,
        "billing_address_id": billingAddressId,
        "shipping_address_id": shippingAddressId,
        "order_note": orderNote,
        "payment_note": paymentNote,
        "id": id,
        "name": name,
        "input_values": inputValues,
        "guest_id": Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
        "is_guest": Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() ? 0 : 1,
      };

      body.removeWhere((key, value) => value == null);

      final response = await dioClient!.getWithBody(
        AppConstants.orderPlaceUri,
        data: body,
      );

      print("POST ${AppConstants.orderPlaceUri}");
      print("Body: $body");
      print("Response: ${response.data}");

      return ApiResponse.withSuccess(response);
    } catch (e) {
      print("Error: ${ApiErrorHandler.getMessage(e)}");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override
  Future<ApiResponse> offlinePaymentPlaceOrder( String? addressId,
      String? couponCode,
      String? selectedDeliveryTime,
      int? governorateId,
      String? shippingFee,
      String? deliveryDate,
      String? couponAmount,
      String? serviceFee,
      String? billingAddressId,
      String? shippingAddressId,
      String? orderNote,
      String? paymentNote,
      int? id,
      String? name,
      List<String>? inputValues,
      List <String?> typeKey,
      List<String> typeValue
      ) async {
    try {
      Map<String?, String> fields = {};
      Map<String?, String> info = {};
      for(var i = 0; i < typeKey.length; i++){
        info.addAll(<String?, String>{
          typeKey[i] : typeValue[i]
        });
      }

      fields.addAll(<String, String>{
        "method_informations" : base64.encode(utf8.encode(jsonEncode(info))),
        'method_name': name??"",
        'method_id': id.toString(),
        'payment_note' : paymentNote??'',
        'address_id': addressId??'',
        'coupon_code' : couponCode??"",
        'coupon_discount' : couponAmount??'',
        'billing_address_id' : billingAddressId??'',
        'order_note' : orderNote??'',
        'guest_id': Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()??'',
        'is_guest' : Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()? '0':'1',
      });
      Map<String, dynamic> body = {
        "method_informations" : base64.encode(utf8.encode(jsonEncode(info))),
        'method_name': name??"",
        'method_id': id.toString(),
        "address_id": addressId,
        "coupon_code": couponCode,
        "selected_delivery_time": selectedDeliveryTime,
        "governorate_id": governorateId,
        "shipping_fee": shippingFee,
        "delivery_date": deliveryDate,
        "coupon_amount": couponAmount,
        "service_fee": serviceFee,
        "billing_address_id": billingAddressId,
        "shipping_address_id": shippingAddressId,
        "order_note": orderNote,
        "payment_note": paymentNote,
        "id": id,
        "name": name,
        "input_values": inputValues,
        "guest_id": Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
        "is_guest": Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() ? 0 : 1,
      };
      Response response = await dioClient!.post(AppConstants.offlinePayment, data: body);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponse> walletPaymentPlaceOrder( String? addressId,
      String? couponCode,
      String? selectedDeliveryTime,
      int? governorateId,
      String? shippingFee,
      String? deliveryDate,
      String? couponAmount,
      String? serviceFee,
      String? billingAddressId,
      String? shippingAddressId,
      String? orderNote,
      String? paymentNote,
      int? id,
      String? name,
      List<String>? inputValues,
      ) async {
    Map<String, dynamic> body = {
      "address_id": addressId,
      "coupon_code": couponCode,
      "selected_delivery_time": selectedDeliveryTime,
      "governorate_id": governorateId,
      "shipping_fee": shippingFee,
      "delivery_date": deliveryDate,
      "coupon_amount": couponAmount,
      "service_fee": serviceFee,
      "billing_address_id": billingAddressId,
      "shipping_address_id": shippingAddressId,
      "order_note": orderNote,
      "payment_note": paymentNote,
      "id": id,
      "name": name,
      "input_values": inputValues,
      "guest_id": Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
      "is_guest": Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() ? 0 : 1,
    };
    try {
      final response = await dioClient!.getWithBody(AppConstants.walletPayment,data: body);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponse> offlinePaymentList() async {
    try {
      final response = await dioClient!.get('${AppConstants.offlinePaymentList}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}&is_guest=${!Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()}');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> digitalPaymentPlaceOrder(
  String? addressId,
  String? couponCode,
  String? selectedDeliveryTime,
  int? governorateId,
  String? shippingFee,
  String? deliveryDate,
  String? couponAmount,
  String? serviceFee,
  String? billingAddressId,
  String? shippingAddressId,
  String? orderNote,
  String? paymentNote,
  int? id,
  String? name,
  List<String>? inputValues,
  )  async {

    try {

  Map<String, dynamic> body = {
  "address_id": addressId,
  "coupon_code": couponCode,
  "selected_delivery_time": selectedDeliveryTime,
  "governorate_id": governorateId,
  "shipping_fee": shippingFee,
  "delivery_date": deliveryDate,
  "coupon_amount": couponAmount,
  "service_fee": serviceFee,
  "billing_address_id": billingAddressId,
  "shipping_address_id": shippingAddressId,
  "order_note": orderNote,
  "payment_note": paymentNote,
  "id": id,
  "name": name,
  "input_values": inputValues,
  "guest_id": Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
  "is_guest": Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() ? 0 : 1,
  };


      final response = await dioClient!.post(AppConstants.digitalPayment, data: body);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
