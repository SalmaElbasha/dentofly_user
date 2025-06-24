import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/widgets/order_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/widgets/order_type_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/widgets/order_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:provider/provider.dart';

import '../../order_details/domain/models/order_details_model.dart';
import '../domain/models/order_model.dart';
import 'order_summary.dart';

class OrderScreen extends StatefulWidget {
  final bool isBacButtonExist;
  const OrderScreen({super.key, this.isBacButtonExist = true});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  ScrollController scrollController = ScrollController();
  late bool isGuestMode;
  Orders? o;




  @override
  void initState() {
    super.initState();
    isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
o= Provider.of<OrderController>(context, listen: false).mergeAllOrdersIntoOne();
    if (!isGuestMode) {
      final orderController = Provider.of<OrderController>(context, listen: false);
      orderController.setIndex(0, notify: false);
      orderController.getOrderList(1, 'ongoing');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: getTranslated('order', context),
        isBackButtonExist: widget.isBacButtonExist,
      ),
      body: isGuestMode
          ? NotLoggedInWidget(message: getTranslated('to_view_the_order_history', context))
          : Consumer<OrderController>(
        builder: (context, orderController, child) {
          if (orderController.isLoading) {
            return const OrderShimmerWidget();
          }

          if (orderController.orderModel?.orders == null ||
              orderController.orderModel!.orders!.isEmpty) {
            return const NoInternetOrDataScreenWidget(
              isNoInternet: false,
              icon: Images.noOrder,
              message: 'no_order_found',
            );
          }

          // جمع الأوردرات حسب order_group_id
          List<List<Orders>> groupedOrdersList = orderController.getGroupedOrdersAsListOfLists();

print(groupedOrdersList.length);
print(orderController.orderModel);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Row(
                  children: [
                    OrderTypeButton(text: getTranslated('RUNNING', context), index: 0),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    OrderTypeButton(text: getTranslated('DELIVERED', context), index: 1),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    OrderTypeButton(text: getTranslated('CANCELED', context), index: 2),
                  ],
                ),
              ),
          Expanded(
                child: PaginatedListView(
                  scrollController: scrollController,
                  onPaginate: (int? offset) async {
                    await orderController.getOrderList(offset!, orderController.selectedType);
                  },
                  totalSize: orderController.orderModel?.totalSize,
                  offset: orderController.orderModel?.offset != null
                      ? int.parse(orderController.orderModel!.offset!)
                      : 1,
                  itemView: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedOrdersList.length,
                    itemBuilder: (context, index) {
                      List<Orders> groupOrders = groupedOrdersList[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${getTranslated('my_order', context) ?? ""} #${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...groupOrders.map((order) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderSummaryScreen(orders: groupOrders),
                                ),
                              );
                            },
                            child: OrderWidget(orderModel: order),
                          )),
                        ],
                      );
                    },
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}
