// full code for OrderSummaryScreen.dart with refund and add review buttons

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/widgets/refund_request_bottom_sheet.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../localization/language_constrants.dart';
import '../../../utill/color_resources.dart';
import '../../../utill/custom_themes.dart';
import '../../../utill/dimensions.dart';
import '../../../utill/images.dart';
import '../../home/shimmers/order_details_shimmer.dart';
import '../../order_details/widgets/cancel_and_support_center_widget.dart';
import '../../order_details/widgets/review_reply_widget.dart';
import '../../review/controllers/review_controller.dart';
import '../../review/widgets/review_dialog_widget.dart';
import '../domain/models/order_model.dart';

class OrderSummaryScreen extends StatefulWidget {
  final List<Orders> orders;

  const OrderSummaryScreen({super.key, required this.orders});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool isLoading = true;
  List<List<OrderDetailsModel>>? orderes;
  ScrollController scrollController = ScrollController();

  Future<void> generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final user = Provider.of<ProfileController>(context, listen: false).userInfoModel;

    final Uint8List logoBytes = await rootBundle.load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final fontData = await rootBundle.load('assets/fonts/arabic/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final logoImage = pw.MemoryImage(logoBytes);

    double total = 0, tax = 0, discount = 0;

    for (var order in widget.orders) {
      for (var detail in order.details ?? []) {
        total += detail.price ?? 0;
        tax += detail.tax ?? 0;
        discount += detail.discount ?? 0;
      }
    }

    double shipping = widget.orders.first.shippingCost ?? 0;
    double serviceFee = double.tryParse(widget.orders.first.serviceFee ?? '') ?? 0;
    double finalTotal = total + tax + shipping + serviceFee - discount;

    pdf.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: ttf),
      build: (context) => [
        pw.Container(
          color: PdfColors.teal300,
          padding: const pw.EdgeInsets.all(12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("ملخص طلبك من Dentofly", style: pw.TextStyle(fontSize: 20, color: PdfColors.white)),
                  pw.Text("شكرًا لثقتك بنا ", style: pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                ],
              ),
              pw.Image(logoImage, width: 100, height: 100),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("تاريخ الطلب: ${widget.orders[0].createdAt?.split('T')[0] ?? ''}"),
            pw.Text("رقم الطلب: ${widget.orders[0].id ?? ''}"),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("اسم العميل: ${user?.fName ?? ''}"),
            pw.Text("طريقة الدفع: ${widget.orders[0].paymentNote ?? widget.orders[0].paymentMethod ?? ''}"),
          ],
        ),
        pw.SizedBox(height: 16),
        ...widget.orders.asMap().entries.map((entry) {
          int index = entry.key;
          Orders order = entry.value;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              ...order.details!.asMap().entries.map((detailEntry) {
                int productIndex = detailEntry.key;
                final detail = detailEntry.value;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("المنتج رقم ${productIndex + 1}", style: pw.TextStyle(fontSize: 20)),
                      pw.Text("${detail.product?.name ?? ''}", style: pw.TextStyle(fontSize: 14)),
                      pw.Text("البائع: ${order.seller?.fName ?? ''}"),
                      pw.Text("الكمية: ${detail.qty}", style: pw.TextStyle(color: PdfColors.blue)),
                      pw.Text("السعر: ج.م${(detail.price ?? 0).toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.green800)),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
        pw.Divider(),
        pw.Text("مصاريف الشحن: ج.م${shipping.toStringAsFixed(2)}"),
        pw.Text("رسوم الخدمة: ج.م${serviceFee.toStringAsFixed(2)}"),
        pw.SizedBox(height: 10),
        pw.Text("الإجمالي النهائي: ج.م${finalTotal.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.red, fontSize: 16)),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          color: PdfColors.yellow100,
          child: pw.Text("هذه وثيقة تأكيد طلب وليست فاتورة ضريبية. سيتم إصدار الفاتورة الرسمية عند التسليم.", style: pw.TextStyle(fontSize: 12)),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> loadOrderDetails() async {
    final controller = Provider.of<OrderDetailsController>(context, listen: false);
    List<List<OrderDetailsModel>> allDetails = [];

    for (var order in widget.orders) {
      var details = await controller.fetchOrderDetailsList(order.id.toString());
      allDetails.add(details);
    }

    setState(() {
      orderes = allDetails;
      isLoading = false;
    });
  }

  Future<void> load() async {
    await loadOrderDetails();
  }

  @override
  void initState() {
    print("Service fee: ${widget.orders.first.serviceFee}");
    print("Shipping cost: ${widget.orders.first.shippingCost}");
print((double.parse((((double.tryParse(widget.orders.first.serviceFee ?? "") ?? 0) / 100) * (widget.orders.first.shippingCost ?? 0)).toStringAsFixed(3))));
    super.initState();
    Provider.of<ProfileController>(context, listen: false).getUserInfo(context);
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const OrderDetailsShimmer();

    double total = 0, tax = 0, discount = 0;

    for (var order in widget.orders) {
      for (var detail in order.details ?? []) {
        total += detail.price ?? 0;
        tax += detail.tax ?? 0;
        discount += detail.discount ?? 0;
      }
    }

    double shipping = widget.orders.first.shippingCost ?? 0;
    int serviceFee = (
        ((double.tryParse(widget.orders.first.serviceFee ?? "") ?? 0) / 100) *
            (widget.orders.first.shippingCost ?? 0)
    ).floor();

    double finalTotal = total + tax + shipping + serviceFee - discount;

    final reviewController = Provider.of<ReviewController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text("${getTranslated('Your_order_summary_from', context)} Dentofly 🎉"),
        centerTitle: true,
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                buildHeader(context),
                buildCustomerInfoSection(context),
                const Divider(thickness: 1),
                buildOrderList(context, reviewController),
                const Divider(thickness: 1),
                buildSummary(context, shipping, serviceFee, tax, discount, finalTotal),
                CancelAndSupportWidget(ordersList: widget.orders),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("${getTranslated('warning', context)} ⚠️",
                      style: const TextStyle(color: Colors.orange), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA6), Color(0xFF00A199)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("${getTranslated('Your_order_summary_from', context)} Dentofly",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text("${getTranslated("Thank_you_for_your_trust_in_us", context)}",
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget buildCustomerInfoSection(BuildContext context) {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(children: [
        buildInfoRow(getTranslated('Customer_Name', context), profileController.userInfoModel?.fName ?? ""),
        const SizedBox(height: 8),
        buildInfoRow(getTranslated('payment_method', context),
            widget.orders[0].paymentNote ?? widget.orders[0].paymentMethod ?? ""),
        const SizedBox(height: 8),
        buildInfoRow(
          getTranslated('download_invoice', context),
          "",
          trailing: InkWell(
            onTap: () async {
              if (widget.orders.isNotEmpty) {
                await generatePdf(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No order found to download invoice')));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).primaryColor.withAlpha(40)),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Image.asset(Images.downloadIcon, height: 15, width: 15),
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildInfoRow(String? label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing ?? Text(value),
      ],
    );
  }

  Widget buildOrderList(BuildContext context, ReviewController reviewController) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.orders.length,
      itemBuilder: (context, index) {
        final order = widget.orders[index];
        final orderDetailsList = orderes?[index] ?? [];
        final firstDetail = orderDetailsList.isNotEmpty ? orderDetailsList[0] : null;

        if (order.orderStatus?.toLowerCase() == 'delivered' && order.orderType != "POS" && firstDetail != null) {
          reviewController.getReviewList(firstDetail.productId, order.id.toString(), context);
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${getTranslated('Order_Number', context)} ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.details?.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(detail.product?.name ?? ""),
                          Text("${getTranslated('EGP', context)}${detail.price?.toStringAsFixed(0)}"),
                        ]),
                        Text("${getTranslated('quantity', context)}: ${detail.qty}"),
                        Text("${getTranslated('seller', context)}: ${order.seller?.fName}"),
                      ],
                    ),
                  );
                }).toList() ?? [],

                if (order.orderStatus?.toLowerCase() == 'delivered' && order.orderType != "POS" && firstDetail != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [

                     InkWell(

                       onTap: () {
                         final detail = order.details?.isNotEmpty == true ? order.details!.first : null;
                         if (detail != null) {
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (_) => RefundBottomSheet(
                               product: detail?.product,
                               orderDetailsId: detail?.id??0,
                               orderId: order?.id.toString()??"",
                             ),
                           );
                         }
                       },


                       child: Container(decoration: BoxDecoration(color:  Colors.redAccent,
                           borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),child: Row(


                             children: [
                               const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                               const Icon(Icons.refresh_outlined, color: Colors.white, size: 20,),
                               const SizedBox(width: Dimensions.paddingSizeSmall),
                               Text(getTranslated('refund', context) ?? 'Refund',style: textRegular.copyWith(
                                   fontSize: Dimensions.fontSizeDefault, color: ColorResources.white)),
                             ],
                           )),

                     ),
                     InkWell(
                         onTap: () {
                           final detail = order.details?.isNotEmpty == true ? order.details!.first : null;
                           if (detail != null) {
                             Provider.of<ReviewController>(context, listen: false).removeData();
                             showDialog(
                               context: context,
                               builder: (context) => Dialog(
                                 insetPadding: EdgeInsets.zero,
                                 backgroundColor: Colors.transparent,
                                 child: ReviewDialog(
                                   productID: order.details?[0].product?.id.toString()??"",
                                   orderId: order.id.toString(),
                                   callback: () {
                                     setState(() {}); // or any relevant refresh logic
                                   },
                                   orderDetailsModel: orderDetailsList[0],
                                   orderType: order.orderType ?? "",
                                 ),
                               ),
                             );
                           }
                         },

                         child: Container(decoration: BoxDecoration(color:  Colors.deepOrangeAccent,
                             borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                             child: Row(children: [
                               const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                               const Icon(Icons.star_outline_outlined, color: Colors.white, size: 20,),
                               const SizedBox(width: Dimensions.paddingSizeSmall),

                               Text(getTranslated(orderDetailsList[0].reviewModel == null ? 'review' : 'reviewed', context)!, style: textRegular.copyWith(
                                   fontSize: Dimensions.fontSizeDefault, color: ColorResources.white)),
                               const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                             ])))
                   ],),
                      const SizedBox(height: 8),
                      ReviewReplyWidget(orderDetailsModel: firstDetail, index: index),


                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSummary(BuildContext context, double shipping, int serviceFee, double tax, double discount, double finalTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(children: [
        buildSummaryRow(getTranslated('shipping_fee', context), shipping),
        buildSummaryRow(getTranslated('service_fee', context), serviceFee.toDouble()),
        buildSummaryRow(getTranslated('tax', context), tax),
        buildSummaryRow(getTranslated('discount', context), -discount),
        const SizedBox(height: 10),
        buildSummaryRow(getTranslated('total_price', context), finalTotal, highlight: true),
      ]),
    );
  }

  Widget buildSummaryRow(String? label, double value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:",
            style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.normal, color: highlight ? Colors.red : null)),
        Text("${getTranslated('EGP', context)}${value.toStringAsFixed(0)}",
            style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.normal, color: highlight ? Colors.red : null)),
      ],
    );
  }
}
