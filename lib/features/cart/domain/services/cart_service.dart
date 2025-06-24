import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/services/cart_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/models/service_fees_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:provider/provider.dart';

import '../../../address/controllers/address_controller.dart';

class CartService implements CartServiceInterface{
  CartRepositoryInterface cartRepositoryInterface;
  CartService({required this.cartRepositoryInterface});

  double getOrderAmount(List<CartModel> cartList, {double? discount, String? discountType}) {
    double amount = 0;
    for(var cart in cartList){
      amount += (cart.price! - cart.discount!) * cart.quantity!;
    }
    return amount;
  }

  static double getOrderTaxAmount(List<CartModel> cartList, BuildContext context, {double? discount, String? discountType}) {
    Provider.of<CartController>(context, listen: false).getSeviceFees();
    double tax = Provider.of<CartController>(context, listen: false).serviceFees ?? 0;

    for(var cart in cartList){
      if(cart.taxModel == "exclude"){
        tax += cart.tax ?? 0;
      }
    }
    return tax;
  }

  static double getOrderDiscountAmount(List<CartModel> cartList, {double? discount, String? discountType}) {
    double discountTotal = 0;
    for(var cart in cartList){
      discountTotal += cart.discount! * cart.quantity!;
    }
    return discountTotal;
  }

  static bool emptyCheck(List<CartModel> cartList) {
    bool hasNull = false;
    if(Provider.of<SplashController>(Get.context!, listen: false).configModel!.shippingMethod == 'sellerwise_shipping'){
      for(var cart in cartList) {
        if(cart.productType == 'physical') {
          var shippingController = Provider.of<ShippingController>(Get.context!, listen: false);
          if(shippingController.shippingList == null || shippingController.shippingList!.isEmpty) {
            hasNull = true;
            break;
          }
        }
      }
    }
    log("emptyCheck result: $hasNull");
    return hasNull;
  }

  static bool checkMinimumOrderAmount(BuildContext context, List<CartModel> cartList, double shippingAmount) {
    shippingAmount = Provider.of<AddressController>(context, listen: false).shippingCost ?? 0;
    double total = 0;
    for(var cart in cartList){
      total += (cart.price! - cart.discount!) * cart.quantity!;
    }
    total += getOrderTaxAmount(cartList, context) + shippingAmount;

    bool minimum = false;
    for(var cart in cartList){
      if(total < (cart.minimumOrderAmountInfo ?? 0)){
        minimum = true;
        break;
      }
    }

    log("checkMinimumOrderAmount result: $minimum");
    return minimum;
  }



  @override
  Future addToCartListData(CartModelBody cart, List<ChoiceOptions> choiceOptions, List<int>? variationIndexes, int buyNow, int? shippingMethodExist, int? shippingMethodId) async {
    return await cartRepositoryInterface.addToCartListData(cart, choiceOptions, variationIndexes, buyNow, shippingMethodExist, shippingMethodId);
  }

  @override
  Future restockRequest(CartModelBody cart, List<ChoiceOptions> choiceOptions, List<int>? variationIndexes, int buyNow, int? shippingMethodExist, int? shippingMethodId) async {
    return await cartRepositoryInterface.restockRequest(cart, choiceOptions, variationIndexes, buyNow, shippingMethodExist, shippingMethodId);
  }


  @override
  Future updateQuantity(int? key, int quantity) async {
    return await cartRepositoryInterface.updateQuantity(key, quantity);
  }

  @override
  Future delete(int id) async{
    return await cartRepositoryInterface.delete(id);
  }

  @override
  Future getList() async{
    return await cartRepositoryInterface.getList();
  }

  @override
  Future addRemoveCartSelectedItem(Map<String,dynamic> data) async{
    return await cartRepositoryInterface.addRemoveCartSelectedItem(data);
  }
}