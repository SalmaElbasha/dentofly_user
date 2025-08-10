import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_billing_address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/amount_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/choose_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/wallet_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utill/color_resources.dart';
import '../../auth/domain/repositories/GovernateRepository.dart';
import '../../auth/domain/services/GovernateService.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel> cartList;

  final bool fromProductDetails;
  final double totalOrderAmount;
  final double shippingFee;
  final double discount;
   double? tax;
  final int? sellerId;
  final bool onlyDigital;
  final bool hasPhysical;
  final int quantity;
  double?serviceFees;

   CheckoutScreen({super.key, required this.cartList, this.fromProductDetails = false,
    required this.discount, this.tax, required this.totalOrderAmount, required this.shippingFee,
    this.sellerId, this.onlyDigital = false, required this.quantity, required this.hasPhysical});


  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  final FocusNode _cityNode = FocusNode();
  final FocusNode _orderNoteNode = FocusNode();
  double _order = 0;
  late bool _billingAddress;
  double? _couponDiscount;
  late final GovernateService governateService;
  int? govId;


  @override
  @override
  void initState() {
    super.initState();
    print("Service fee: ${Provider.of<CheckoutController>(context, listen: false).serviceFees}");
    print("Shipping cost: ${Provider.of<CheckoutController>(context, listen: false).shippingCost}");

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      if (Provider.of<AddressController>(context, listen: false).selectAddressIndex != null) {

      }
      if (Provider.of<CheckoutController>(context, listen: false).shippingCost == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(getTranslated('Warning', context)!),
              content: const Text('This location is outside delivery range.'),
              actions: [
                TextButton(
                  child: Text(getTranslated('ok', context)!),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
    Future.microtask(() async {
      govId=await Provider.of<AddressController>(context, listen: false).getGovernatesIds(context);
      final prefs = await SharedPreferences.getInstance();
      governateService = GovernateService(governateRepo: GovernateRepository(sharedPreferences: prefs));
      await Provider.of<AddressController>(context, listen: false).getGovernateDetails(govId??0);
    });
    Provider.of<AddressController>(context, listen: false).getAddressList();
    Provider.of<CouponController>(context, listen: false).removePrevCouponData();
    Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CheckoutController>(context, listen: false).resetPaymentMethod();
    Provider.of<CheckoutController>(context, listen: false).getSeviceFees();
    Provider.of<ShippingController>(context, listen: false).getChosenShippingMethod(context);
    widget.serviceFees=double.parse((((Provider.of<CheckoutController>(context, listen: false).serviceFees??1)/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(0)).ceilToDouble();
    if (Provider.of<SplashController>(context, listen: false).configModel != null &&
        Provider.of<SplashController>(context, listen: false).configModel!.offlinePayment != null) {
      Provider.of<CheckoutController>(context, listen: false).getOfflinePaymentList();
    }

    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<CouponController>(context, listen: false).getAvailableCouponList();
    }

    _billingAddress = Provider.of<SplashController>(Get.context!, listen: false)
        .configModel!
        .billingInputByCustomer ==
        1;
    Provider.of<CheckoutController>(context, listen: false).clearData();
  }


  @override
  Widget build(BuildContext context) {
    _order = widget.totalOrderAmount + widget.discount;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,

      bottomNavigationBar: Consumer<AddressController>(
        builder: (context, locationProvider,_) {

          return Consumer<CheckoutController>(
            builder: (context, orderProvider, child) {
              print('CheckoutScreen rebuilding with addressIndex: ${Provider.of<CheckoutController>(context, listen: false).addressIndex}');
              return Consumer<CouponController>(
                builder: (context, couponProvider, _) {
                  return Consumer<CartController>(
                    builder: (context, cartProvider,_) {
                      return Consumer<ProfileController>(
                        builder: (context, profileProvider,_) {
                          return orderProvider.isLoading ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: 30,height: 30,child: CircularProgressIndicator())]) :

                          Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            child: CustomButton(onTap: () async {

                                if(orderProvider.addressIndex == null && widget.hasPhysical) {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) =>  SavedAddressListScreen(cartList: widget.cartList,discount: widget.discount,fromProductDetails: widget.fromProductDetails,hasPhysical: widget.hasPhysical,onlyDigital: widget.onlyDigital,quantity: widget.quantity,shippingFee: widget.shippingFee,totalOrderAmount: widget.totalOrderAmount,)),
                                  );

                                  if (result != null) {
                                    final checkoutController = Provider.of<CheckoutController>(context, listen: false);

                                    checkoutController.setAddressIndex(result['selectedIndex']);
                                    checkoutController.shippingCost = result['shippingCost'];

                                    final addressController = Provider.of<AddressController>(context, listen: false);
                                    addressController.lat = result['lat'];
                                    addressController.lang = result['lng'];

                                    // Force UI refresh if needed
                                    setState(() {});
                                  }

                                  showCustomSnackBar(getTranslated('select_a_shipping_address', context), context, isToaster: true);
                                } else if (Provider.of<CheckoutController>(context, listen: false).shippingCost == null) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(getTranslated('Warning', context)!),
                                        content: const Text('This location is outside delivery range.'),
                                        actions: [
                                          TextButton(
                                            child: Text(getTranslated('ok', context)!),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }else if((orderProvider.billingAddressIndex == null && !widget.hasPhysical &&  !_billingAddress)) {
                                  showCustomSnackBar(getTranslated('you_cant_place_order_of_digital_product_without_billing_address', context), context, isToaster: true);
                                } else if((orderProvider.billingAddressIndex == null && !widget.hasPhysical && !orderProvider.sameAsBilling && _billingAddress) || (orderProvider.billingAddressIndex == null && _billingAddress && !orderProvider.sameAsBilling)){
                                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => const SavedBillingAddressListScreen()));
                                  showCustomSnackBar(getTranslated('select_a_billing_address', context), context, isToaster: true);
                                }

                                // else if (orderProvider.isCheckCreateAccount && orderProvider.passwordController.text.isEmpty) {
                                //   showCustomSnackBar(getTranslated('password_is_required', context), context);
                                // } else if (orderProvider.isCheckCreateAccount && orderProvider.passwordController.text.length < 8){
                                //   showCustomSnackBar(getTranslated('minimum_password_is_8_character', context), context);
                                // } else if (orderProvider.isCheckCreateAccount && orderProvider.confirmPasswordController.text.isEmpty){
                                //   showCustomSnackBar(getTranslated('confirm_password_must_be_required', context), context);
                                // }else if (orderProvider.isCheckCreateAccount && (orderProvider.passwordController.text != orderProvider.confirmPasswordController.text)) {
                                //   showCustomSnackBar(getTranslated('confirm_password_not_matched', context), context);
                                // }

                                else {
                                  if(!orderProvider.isCheckCreateAccount || (orderProvider.isCheckCreateAccount && (passwordFormKey.currentState?.validate() ?? false))) {
                                    String orderNote = orderProvider.orderNoteController.text.trim();
                                    String couponCode = couponProvider.discount != null && couponProvider.discount != 0? couponProvider.couponCode : '';
                                    String couponCodeAmount = couponProvider.discount != null && couponProvider.discount != 0?
                                    couponProvider.discount.toString() : '0';

                                    // String addressId = !widget.onlyDigital? locationProvider.addressList![orderProvider.addressIndex!].id.toString():'';
                                    // String billingAddressId = (_billingAddress)? orderProvider.sameAsBilling? addressId:
                                    // locationProvider.addressList![orderProvider.billingAddressIndex!].id.toString() : '';

                                    String addressId =  orderProvider.addressIndex != null ?
                                    locationProvider.addressList![orderProvider.addressIndex!].id.toString() : '';

                                    String billingAddressId = (_billingAddress) ?
                                    !orderProvider.sameAsBilling ?
                                    locationProvider.addressList![orderProvider.billingAddressIndex!].id.toString() : locationProvider.addressList![orderProvider.addressIndex!].id.toString() : '';



                                    if(orderProvider.paymentMethodIndex != -1){
                                      orderProvider.digitalPaymentPlaceOrder(
                                        context,
                                          orderNote: orderNote,
                                          customerId: Provider.of<AuthController>(context, listen: false).isLoggedIn() ?
                                          profileProvider.userInfoModel?.id.toString() : Provider.of<AuthController>(context, listen: false).getGuestToken(),
                                          addressId: addressId,
                                          billingAddressId: billingAddressId,
                                          couponCode: couponCode,
                                          couponAmount: couponCodeAmount,
                                          paymentNote: orderProvider.selectedDigitalPaymentMethodName);

                                    } else if (orderProvider.codChecked && !widget.onlyDigital){
                                      orderProvider.placeOrder(context,callback: _callback,
                                          addressID : addressId,
                                          couponCode : couponCode,
                                          couponAmount : couponCodeAmount,
                                          billingAddressId : billingAddressId,

                                          orderNote : orderNote);
                                    }

                                    else if(orderProvider.offlineChecked){
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_)=>
                                          OfflinePaymentScreen(payableAmount:               (_order ?? 0) +
                                              (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0) -
                                              (widget.discount ?? 0) -
                                              (_couponDiscount ?? 0) +
                                              double.parse((((Provider.of<CheckoutController>(context, listen: false).serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(0))+(widget.tax??0), callback: _callback)));
                                    }

                                    else if(orderProvider.walletChecked){
                                      showAnimatedDialog(context, WalletPaymentWidget(
                                          currentBalance: profileProvider.balance ?? 0,
                                          orderAmount: _order + (Provider.of<CheckoutController>(context, listen: false).shippingCost??0) - widget.discount - _couponDiscount! + (widget.tax??0),
                                          onTap: (){if(profileProvider.balance! <
                                              (_order +(Provider.of<CheckoutController>(context, listen: false).shippingCost??0)- widget.discount - _couponDiscount! + (widget.tax??0))){
                                            showCustomSnackBar(getTranslated('insufficient_balance', context), context, isToaster: true);
                                          }else{
                                            Navigator.pop(context);
                                            orderProvider.placeOrder(context,callback: _callback,wallet: true,
                                                addressID : addressId,
                                                couponCode : couponCode,
                                                couponAmount : couponCodeAmount,
                                                billingAddressId : billingAddressId,
                                                orderNote : orderNote,

                                            );

                                          }}), dismissible: false, willFlip: true);
                                    }
                                    else {
                                      showModalBottomSheet(
                                        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                        builder: (c) => PaymentMethodBottomSheetWidget(onlyDigital: widget.onlyDigital),
                                      );
                                    }
                                  }
                                }
                              },
                              buttonText: '${getTranslated('proceed', context)}',
                            ),
                          );
                        }
                      );
                    }
                  );
                }
              );
            }
          );
        }
      ),

      appBar: CustomAppBar(title: getTranslated('checkout', context)),
      body: Consumer<AuthController>(
        builder: (context, authProvider,_) {
          return Consumer<CheckoutController>(
            builder: (context, orderProvider,_) {
              return Column(children: [

                  Expanded(child: ListView(physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(0), children: [
                      Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: ShippingDetailsWidget(hasPhysical: widget.hasPhysical, billingAddress: _billingAddress, passwordFormKey: passwordFormKey,cartList: widget.cartList,discount: widget.discount,fromProductDetails: widget.fromProductDetails,onlyDigital: widget.onlyDigital,quantity: widget.quantity,shippingFee: widget.shippingFee,totalOrderAmount: widget.totalOrderAmount,)),


                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                        Consumer<AddressController>(
                          builder: (context, addressController, child) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 10,right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                  Text(getTranslated('Delivery Time', context)!, style: textRegular.copyWith(
                                    color: ColorResources.black,
                                    fontSize: Dimensions.fontSizeSmall,
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    margin: const EdgeInsets.only(
                                      left: Dimensions.marginSizeDefault - 15,
                                      right: Dimensions.marginSizeDefault - 15,
                                      top: Dimensions.marginSizeSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: Text(
                                          "Choose delivery time",
                                          style: textRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        value: addressController.selectedDate,
                                        items: addressController.delivery?.map((time) {
                                          return DropdownMenuItem<String>(
                                            value: time,
                                            child: Text(
                                              time,
                                              style: textRegular.copyWith(
                                                fontSize: Dimensions.fontSizeDefault,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            addressController.selectedDate = value;
                                            addressController.todayOrTomorrow.text =
                                                addressController.getDayLabel(addressController.selectedDate ?? "");
                                            addressController.note=addressController.governate?.note;
                                          }
                                          setState(() {

                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                        Padding(
                          padding: const EdgeInsets.only(left: 10,right: 10),
                          child: Text(getTranslated('Delivery Date', context)!, style: textRegular.copyWith(
                            color: ColorResources.black,
                            fontSize: Dimensions.fontSizeSmall,
                          )),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                        Padding(
                          padding: const EdgeInsets.only(left: 10,right: 10),
                          child: CustomTextFieldWidget(
                            labelText: getTranslated('Delivery Date', context),
                            hintText: getTranslated('Delivery Date', context),
                            inputType: TextInputType.text,
                            inputAction: TextInputAction.next,
                            required: false,
                            nextFocus: _cityNode,
                            controller:  Provider.of<AddressController>(context, listen: false).todayOrTomorrow,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                      if(Provider.of<AuthController>(context, listen: false).isLoggedIn())
                      Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        child: CouponApplyWidget(couponController: _controller, orderAmount: _order)),



                       Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: ChoosePaymentWidget(onlyDigital: widget.onlyDigital)),

                      Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,Dimensions.paddingSizeSmall),
                        child: Text(getTranslated('order_summary', context)??'',
                          style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge))),



                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: Consumer<CheckoutController>(
                            builder: (context, checkoutController, child) {
                              return Consumer<AddressController>(
                                builder: (context, addressController, child) {
                                  _couponDiscount = Provider.of<CouponController>(context).discount ?? 0;

                                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    widget.quantity > 1
                                        ? AmountWidget(
                                        title: '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('items', context)})',
                                        amount: PriceConverter.convertPrice(context, _order))
                                        : AmountWidget(
                                        title: '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('item', context)})',
                                        amount: PriceConverter.convertPrice(context, _order)),
                                    AmountWidget(
                                      title: getTranslated('shipping_fee', context),
                                      amount: PriceConverter.convertPrice(context, checkoutController.shippingCost),
                                    ),
                                    AmountWidget(
                                      title: getTranslated('discount', context),
                                      amount: PriceConverter.convertPrice(context, widget.discount),
                                    ),
                                    AmountWidget(
                                      title: getTranslated('coupon_voucher', context),
                                      amount: PriceConverter.convertPrice(context, _couponDiscount),
                                    ),
                                    AmountWidget(
                                      title: getTranslated('tax', context),
                                      amount: PriceConverter.convertPrice(context, widget.tax),
                                    ),
                                    AmountWidget(
                                      title: getTranslated('service_fee', context),
                                      amount: PriceConverter.convertPrice(
                                          context,
                                          double.parse((((Provider.of<CheckoutController>(context, listen: false).serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(3)).ceilToDouble()
                                      ),
                                    ),

                                    Divider(height: 5, color: Theme.of(context).hintColor),
                                    AmountWidget(
                                      title: getTranslated('total_payable', context),
                                      amount: PriceConverter.convertPrice(
                                        context,
                                        (_order ?? 0) +
                                            (checkoutController.shippingCost ?? 0) -
                                            (widget.discount ?? 0) -
                                            (_couponDiscount ?? 0) +
                                            double.parse((((Provider.of<CheckoutController>(context, listen: false).serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(0)).ceilToDouble()+(widget.tax??0),
                                      ),
                                    ),
                                  ]);
                                },
                              );
                            },
                          ),
                        )



                      ,Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault,Dimensions.paddingSizeDefault,0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                              Text('${getTranslated('order_note', context)}',
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge))]),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          CustomTextFieldWidget(
                            hintText: getTranslated('enter_note', context),
                            inputType: TextInputType.multiline,
                            inputAction: TextInputAction.done,
                            maxLines: 3,
                            focusNode: _orderNoteNode,
                            controller: orderProvider.orderNoteController)])),
                    ]),
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }

  void _callback(bool isSuccess, String message, String orderID, bool createAccount) async {
    if(isSuccess) {
        Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
        showAnimatedDialog(context, OrderPlaceDialogWidget(
          icon: Icons.check,
          title: getTranslated(createAccount ? 'order_placed_Account_Created' : 'order_placed', context),
          description: getTranslated('your_order_placed', context),
          isFailed: false,
        ), dismissible: false, willFlip: true);
    }else {
      showCustomSnackBar(message, context, isToaster: true);
    }
  }
}

