import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class CancelOrderDialogWidget extends StatefulWidget {
  final List<int> orderIds;  // الآن هي قائمة من الـ IDs
  const CancelOrderDialogWidget({super.key, required this.orderIds});

  @override
  State<CancelOrderDialogWidget> createState() => _CancelOrderDialogWidgetState();
}

class _CancelOrderDialogWidgetState extends State<CancelOrderDialogWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: _isLoading ? null : () {
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor.withAlpha(128),
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.clear),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            color: Theme.of(context).cardColor,
          ),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(Dimensions.homePagePadding),
          child: Column(
            children: [
              Image.asset(Images.cancelOrder, height: 60),
              const SizedBox(height: Dimensions.homePagePadding),

              Text(
                getTranslated('are_you_sure_you_want_to_cancel_your_order', context)!,
                textAlign: TextAlign.center,
                style: titilliumBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              const SizedBox(height: Dimensions.homePagePadding),
              const SizedBox(height: Dimensions.homePagePadding),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomButton(
                      textColor: Theme.of(context).textTheme.bodyLarge?.color,
                      backgroundColor: Theme.of(context).hintColor.withAlpha(128),
                      buttonText: getTranslated('NO', context)!,
                      onTap: _isLoading ? null : () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: Consumer<OrderController>(
                      builder: (context, orderController, _) {
                        return CustomButton(
                          buttonText: _isLoading
                              ? getTranslated('processing', context) ?? 'Processing...'
                              : getTranslated('YES', context)!,
                          onTap: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                            });

                            bool allSuccess = true;
                            for (var orderId in widget.orderIds) {
                              final result = await orderController.cancelOrder(context, orderId);
                              if (result.response?.statusCode != 200) {
                                allSuccess = false;
                                // لو حابب توقف هنا علطول ممكن تعمل break
                              }
                            }

                            if (allSuccess) {
                              orderController.getOrderList(1, orderController.selectedType);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              showCustomSnackBar(
                                getTranslated('order_cancelled_successfully', context)!,
                                context,
                                isError: false,
                              );
                            } else {
                              showCustomSnackBar(
                                getTranslated('error_occured_while_cancelling', context) ?? 'Error occurred while cancelling',
                                context,
                                isError: true,
                              );
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
