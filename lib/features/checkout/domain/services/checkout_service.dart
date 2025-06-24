import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';

class CheckoutService implements CheckoutServiceInterface{
  CheckoutRepositoryInterface checkoutRepositoryInterface;


  CheckoutService({required this.checkoutRepositoryInterface});

  @override
  Future cashOnDeliveryPlaceOrder(
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
     ) async{
    return await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(addressId, couponCode, selectedDeliveryTime,governorateId,shippingFee,deliveryDate,couponAmount, serviceFee,billingAddressId, shippingAddressId,orderNote,paymentNote,id,name,inputValues);
  }

  @override
  Future digitalPaymentPlaceOrder(
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
    return await checkoutRepositoryInterface.digitalPaymentPlaceOrder(addressId, couponCode, selectedDeliveryTime,governorateId,shippingFee,deliveryDate,couponAmount, serviceFee,billingAddressId, shippingAddressId,orderNote,paymentNote,id,name,inputValues);
  }

  @override
  Future offlinePaymentList()  async{
   return await checkoutRepositoryInterface.offlinePaymentList();
  }

  @override
  Future offlinePaymentPlaceOrder(
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
      List <String?> typeKey,
      List<String> typeValue
      ) async{
    return await checkoutRepositoryInterface.offlinePaymentPlaceOrder(addressId, couponCode, selectedDeliveryTime,governorateId,shippingFee,deliveryDate,couponAmount, serviceFee,billingAddressId, shippingAddressId,orderNote,paymentNote,id,name,inputValues,typeKey,typeValue);
  }

  @override
  Future walletPaymentPlaceOrder(
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
      ) async{
    return await checkoutRepositoryInterface.walletPaymentPlaceOrder(addressId, couponCode, selectedDeliveryTime,governorateId,shippingFee,deliveryDate,couponAmount, serviceFee,billingAddressId, shippingAddressId,orderNote,paymentNote,id,name,inputValues);
  }

}