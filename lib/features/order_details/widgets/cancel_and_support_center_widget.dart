import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/widgets/cancel_order_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/reorder/controllers/re_order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/screens/support_ticket_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/tracking/screens/tracking_result_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:provider/provider.dart';

import '../../cart/screens/cart_screen.dart';
class CancelAndSupportWidget extends StatelessWidget {
  final List<Orders>? ordersList;
  final bool fromNotification;

  const CancelAndSupportWidget({super.key, this.ordersList, this.fromNotification = false});

  @override
  Widget build(BuildContext context) {
    if (ordersList == null || ordersList!.isEmpty) {
      return const SizedBox();
    }

    final profileController = Provider.of<ProfileController>(context, listen: false);
    final userId = int.tryParse(profileController.userID) ?? -1;

    // فلترة الطلبات التي تخص المستخدم (غير POS)
    final userOrders = ordersList!
        .where((order) => order.customerId == userId && order.orderType != "POS")
        .toList();

    if (userOrders.isEmpty) {
      return const SizedBox();
    }

    final firstOrder = userOrders.first;

    Widget? actionButton;

    // دالة تنفيذ الوظيفة حسب حالة أول طلب على كل الطلبات
    void onActionPressed() {
      if (firstOrder.orderStatus == 'pending') {
        final pendingOrderIds = ordersList!
            .where((order) => order.orderStatus == 'pending')
            .map((order) => order.id)
            .toList();

        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: CancelOrderDialogWidget(
              orderIds: ordersList!
                  .where((order) => order.orderStatus == 'pending' && order.id != null)
                  .map((order) => order.id!)
                  .toList(),
            ),
          ),
        );
      } else if (firstOrder.orderStatus == 'delivered') {
        final deliveredOrders = ordersList!
            .where((order) => order.orderStatus == 'delivered')
            .toList();

        final reOrderController = Provider.of<ReOrderController>(context, listen: false);

        for (var order in deliveredOrders) {
          reOrderController.reorder(orderId: order.id.toString());
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
      } else {
        // Add this part to fix the issue
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackingResultScreen(orderID: firstOrder.id.toString()),
          ),
        );
      }
    }



    // إنشاء زر واحد فقط حسب حالة أول طلب
    if (firstOrder.orderStatus == 'pending') {
      actionButton = CustomButton(
        textColor: Theme.of(context).colorScheme.error,
        backgroundColor: Theme.of(context).colorScheme.error.withAlpha(25),
        buttonText: getTranslated('cancel_order', context),
        onTap: onActionPressed,
      );
    } else if (firstOrder.orderStatus == 'delivered') {
      actionButton = CustomButton(
        textColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        buttonText: getTranslated('re_order', context),
        onTap: onActionPressed,
      );
    } else if (firstOrder.orderStatus != 'canceled' &&
        firstOrder.orderStatus != 'returned' &&
        firstOrder.orderStatus != 'fail_to_delivered') {
      actionButton = CustomButton(
        buttonText: getTranslated('TRACK_ORDER', context),
        onTap: onActionPressed,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportTicketScreen()),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: getTranslated(
                        'if_you_cannot_contact_with_seller_or_facing_any_trouble_then_contact',
                        context),
                    style: titilliumRegular.copyWith(
                        color: ColorResources.hintTextColor,
                        fontSize: Dimensions.fontSizeSmall),
                  ),
                  TextSpan(
                    text: ' ${getTranslated('SUPPORT_CENTER', context)}',
                    style: titilliumSemiBold.copyWith(
                        color: ColorResources.getPrimary(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimensions.homePagePadding),

          if (actionButton != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: actionButton,
            ),
        ],
      ),
    );
  }


}

