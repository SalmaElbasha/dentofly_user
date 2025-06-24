import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_type_widget.dart';
import 'package:provider/provider.dart';

import '../../cart/domain/models/cart_model.dart';
import '../../checkout/screens/checkout_screen.dart';
import 'add_new_address_screen.dart';

class SavedAddressListScreen extends StatefulWidget {
  final bool fromGuest;
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

   SavedAddressListScreen({super.key, this.fromGuest = false, required this.cartList, required this.fromProductDetails, required this.totalOrderAmount, required this.shippingFee, required this.discount, this.sellerId, required this.onlyDigital, required this.hasPhysical, required this.quantity});

  @override
  State<SavedAddressListScreen> createState() => _SavedAddressListScreenState();
}

class _SavedAddressListScreenState extends State<SavedAddressListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddNewAddressScreen(isBilling: false)),
        ),
        backgroundColor: ColorResources.getPrimary(context),
        child: Icon(Icons.add, color: Theme.of(context).highlightColor),
      ),
      appBar: CustomAppBar(
        title: widget.fromGuest
            ? getTranslated('ADDRESS_LIST', context)
            : getTranslated('SHIPPING_ADDRESS_LIST', context),
      ),
      body: SafeArea(
        child: Consumer<AddressController>(
          builder: (context, locationProvider, child) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  locationProvider.addressList != null
                      ? locationProvider.addressList!.isNotEmpty
                      ? ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locationProvider.addressList!.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          final checkoutController = Provider.of<CheckoutController>(context, listen: false);
                          final addressController = Provider.of<AddressController>(context, listen: false);

                          checkoutController.setAddressIndex(index);

                          // 👈 استني لحد ما بيانات المحافظة ترجع
                          await checkoutController.getGovernateDetails(
                              locationProvider.addressList![checkoutController.addressIndex!].governorateId ?? 0
                          );

                          // بعد كده احسبي الشحن
                          double lat = double.tryParse(locationProvider.addressList?[checkoutController.addressIndex??0].latitude ?? '') ?? 0;
                          double lng = double.tryParse(locationProvider.addressList?[checkoutController.addressIndex??0].longitude ?? '') ?? 0;

                          await checkoutController.calculateShippingFees(lat, lng);

                          print("Shipping cost: ${checkoutController.shippingCost}");

                      Navigator.pop(context);
                        },

                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault),
                          child: Container(
                            margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: ColorResources.getIconBg(context),
                              border: index ==
                                  Provider.of<CheckoutController>(context).addressIndex
                                  ? Border.all(
                                  width: 2, color: Theme.of(context).primaryColor)
                                  : null,
                            ),
                            child: AddressTypeWidget(
                                address: locationProvider.addressList?[index]),
                          ),
                        ),
                      );
                    },
                  )
                      : Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 3),
                    child: Center(
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeLarge),
                        child: const NoInternetOrDataScreenWidget(
                          isNoInternet: false,
                          message: 'no_address_found',
                          icon: Images.noAddress,
                        ),
                      ),
                    ),
                  )
                      : const AddressShimmerWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
