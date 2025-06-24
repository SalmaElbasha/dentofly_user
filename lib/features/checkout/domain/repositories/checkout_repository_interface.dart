import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class CheckoutRepositoryInterface implements RepositoryInterface{

  Future<dynamic> cashOnDeliveryPlaceOrder( String? addressId,
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
      List<String>? inputValues,);

  Future<dynamic> offlinePaymentPlaceOrder( String? addressId,
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
      List<String> typeValue);

  Future<dynamic> walletPaymentPlaceOrder( String? addressId,
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
      List<String>? inputValues,);

  Future<dynamic> digitalPaymentPlaceOrder( String? addressId,
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
      List<String>? inputValues,);

  Future<dynamic> offlinePaymentList();
}