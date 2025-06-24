import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
class ReviewReplyWidget extends StatefulWidget {
  final OrderDetailsModel orderDetailsModel;
  final int index;

  const ReviewReplyWidget({super.key, required this.orderDetailsModel, required this.index});

  @override
  State<ReviewReplyWidget> createState() => _ReviewReplyWidgetState();
}

class _ReviewReplyWidgetState extends State<ReviewReplyWidget> {
  bool _loading = false;

  Future<void> _fetchReview(BuildContext context) async {
    setState(() {
      _loading = true;
    });
    await Provider.of<ReviewController>(context, listen: false)
        .getOrderWiseReview(widget.orderDetailsModel.productId.toString(),
        widget.orderDetailsModel.orderId.toString(),
        showLoading: false);
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewController>(
      builder: (context, reviewController, _) {
        final review = reviewController.getOrderWiseReviewData(
          widget.orderDetailsModel.productId.toString(),
          widget.orderDetailsModel.orderId.toString(),
        );

        return Column(
          children: [
            Divider(thickness: 0.1, color: Theme.of(context).primaryColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(Images.myReviewIcon, height: 30, width: 30),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('${getTranslated('my_review', context)}',
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  ]),

                  if(widget.orderDetailsModel.order != null)
                    InkWell(
                      onTap: () async {
                        setState(() {
                          widget.orderDetailsModel.isExpanded = !(widget.orderDetailsModel.isExpanded ?? false);
                        });
                        if (widget.orderDetailsModel.isExpanded == true) {
                          await _fetchReview(context);
                        }
                      },
                      child: Icon(
                        widget.orderDetailsModel.isExpanded! ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      ),
                    ),
                ],
              ),
            ),

            if (widget.orderDetailsModel.isExpanded!) ...[
              Divider(thickness: 0.1, color: Theme.of(context).primaryColor),

              _loading
                  ? const HorizontalLoader()
                  : review != null
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      review.createdAt != null
                          ? Text(
                          DateConverter.dateTimeStringToMonthDateAndTime(review.createdAt!),
                          style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).hintColor))
                          : const SizedBox(),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 2),
                          Text(
                            '(${double.parse(review.rating.toString()).toStringAsFixed(1)})',
                            style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  ReadMoreText(
                    review.comment ?? '',
                    trimMode: TrimMode.Line,
                    trimLines: 3,
                    textAlign: TextAlign.justify,
                    preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                    colorClickableText: Theme.of(context).primaryColor,
                    trimCollapsedText: getTranslated('view_moree', context)!,
                    trimExpandedText: getTranslated('view_less', context)!,
                  ),

                  if (review.attachmentFullUrl != null && review.attachmentFullUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                      child: SizedBox(
                        height: 45,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: review.attachmentFullUrl?.length ?? 0,
                          itemBuilder: (BuildContext context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(Dimensions.paddingSizeExtraSmall)),
                                  child: CustomImageWidget(
                                    height: 40,
                                    width: 40,
                                    image: review.attachmentFullUrl?[index].path ?? '',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (review.reply != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(Images.sellerReplyIcon, height: 20, width: 20),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text(getTranslated('reply_by_seller', context)!,
                                style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          ],
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                            DateConverter.dateTimeStringToMonthDateAndTime(
                                review.reply!.createdAt!),
                            style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).hintColor)),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        ReadMoreText(
                          review.reply?.replyText ?? '',
                          trimMode: TrimMode.Line,
                          trimLines: 3,
                          textAlign: TextAlign.justify,
                          preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                          colorClickableText: Theme.of(context).primaryColor,
                          trimCollapsedText: getTranslated('view_moree', context)!,
                          trimExpandedText: getTranslated('view_less', context)!,
                        ),
                      ],
                    )
                ]),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text(getTranslated('no_review_found', context)!),
              )
            ],
          ],
        );
      },
    );
  }
}



class HorizontalLoader extends StatefulWidget {
  const HorizontalLoader({super.key});

  @override
  _HorizontalLoaderState createState() => _HorizontalLoaderState();
}

class _HorizontalLoaderState extends State<HorizontalLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: false);

    _animations = List.generate(4, (index) {
      final startInterval = index * 0.25;
      final endInterval = startInterval + 0.25;

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startInterval, endInterval, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return FadeTransition(
            opacity: _animations[index],
            child: Container(
              width: 10,
              height: 10,
              color: Theme.of(context).primaryColor,
            ),
          );
        }),
      ),
    );
  }
}
