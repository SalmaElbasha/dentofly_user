import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/digital_payment_order_place_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../data/model/governate_model.dart' as g;
import '../../../utill/app_constants.dart';
import '../../profile/domain/models/profile_model.dart';
import '../domain/models/service_fees_model.dart';

class CheckoutController with ChangeNotifier {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  int? _addressIndex;
  int? _billingAddressIndex;
  int? get billingAddressIndex => _billingAddressIndex;
  int? _shippingIndex;
  bool _isLoading = false;
  bool _isCheckCreateAccount = false;
  bool _newUser = false;

  int _paymentMethodIndex = -1;
  bool _onlyDigital = true;
  bool get onlyDigital => _onlyDigital;
  int? get addressIndex => _addressIndex;
  int? get shippingIndex => _shippingIndex;
  bool get isLoading => _isLoading;
  int get paymentMethodIndex => _paymentMethodIndex;
  bool get isCheckCreateAccount => _isCheckCreateAccount;

  String selectedPaymentName = '';
  void setSelectedPayment(String payment){
    selectedPaymentName = payment;
    notifyListeners();
  }
  Future<int> getGovernates(BuildContext context) async {
    ProfileController profileController = Provider.of<ProfileController>(context, listen: false);

    ProfileModel? updateUserInfoModel = profileController.userInfoModel;

    if (updateUserInfoModel == null) {
      return 0;
    }

    int? govId = updateUserInfoModel.governorate_id;

    if (govId == null) {
      return 0;
    }

    return govId;
  }
  final TextEditingController orderNoteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  List<String> inputValueList = [];

  List<g.DeliveryCenter>? deliveryCenters;
  List<g.DeliveryTime>? deliveryTimes;
  String? minShippingCost;
  String? note;
  List<String>? delivery;
  List<String> getFormattedDeliveryTimes() {
    if (deliveryTimes == null) return [];

    return deliveryTimes!.map((time) {
      String formatTime(String timeStr) {
        final parts = timeStr.split(":");
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        String period = hour >= 12 ? "PM" : "AM";
        int hour12 = hour % 12 == 0 ? 12 : hour % 12;

        return "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
      }

      String formattedStart = formatTime(time.startTime??"no delivery times added yet");
      String formattedEnd = formatTime(time.endTime??"no delivery times added yet");

      return "$formattedStart - $formattedEnd";
    }).toList();
  }
g.Data? governate;
  double? serviceFees;
  Future<void> getGovernateDetails(int id) async {
    _isLoading = true;
    notifyListeners();  // تنبيه بداية التحميل

    final Dio dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    try {
      final response = await dio.get(
        "/api/v1/governorates/$id",
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        g.GovernateById governateDetailsModel = g.GovernateById.fromJson(response.data);
        governate = governateDetailsModel.data;
        deliveryCenters = governate?.deliveryCenters;
        deliveryTimes = governate?.deliveryTimes;
        minShippingCost = governate?.minShippingCost;
        note = governate?.note;

        delivery = getFormattedDeliveryTimes();

        _isLoading = false;
        notifyListeners();  // تنبيه انتهاء التحميل وتحديث البيانات
      } else {
        ScaffoldMessenger.of(Get.context!)
            .showSnackBar(const SnackBar(content: Text('Error fetching Governates')));
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(
          content: Text('Error occurred while connecting to the Server')));
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> getSeviceFees() async {
    _isLoading = true;


    final Dio dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    try {
      final response = await dio.get(
        "/api/v1/settings/fees/",
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        print("Response data: ${response.data}");

        ServiceFees serviceFeesModel = ServiceFees.fromJson(response.data);
        print("Raw serviceFee string: ${serviceFeesModel.serviceFee}");

        serviceFees = double.tryParse(serviceFeesModel.serviceFee ?? "");
        print("Parsed serviceFees as double: $serviceFees");

        _isLoading = false;
        notifyListeners();

      } else {
        _isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(Get.context!)
            .showSnackBar(const SnackBar(content: Text('Error fetching service fees')));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(
          content: Text('Error occurred while connecting to the Server')));
    }
  }
  double? shippingCost;
  final isArabic = Localizations.localeOf(Get.context!).languageCode == 'ar';
  double? maxShippingDistance ;

  Future<void> calculateShippingFees(double userLat, double userLng) async {
    if (deliveryCenters == null || deliveryCenters!.isEmpty) {
      print("No delivery centers found.");
      return;
    }

    g.DeliveryCenter? closestCenter;
    double shortestDistance = double.infinity;

    for (var center in deliveryCenters!) {
      double centerLat = double.tryParse(center.latitude ?? '0') ?? 0;
      double centerLng = double.tryParse(center.longitude ?? '0') ?? 0;

      double distance = Geolocator.distanceBetween(userLat, userLng, centerLat, centerLng) / 1000; // كم

      if (distance < shortestDistance) {
        shortestDistance = distance;
        closestCenter = center;
        maxShippingDistance=closestCenter.maxDistanceKm?.toDouble()??distance+10;
      }
      notifyListeners();
    }

    if (shortestDistance > (maxShippingDistance ?? double.infinity)) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "لا يمكن التوصيل لهذا العنوان، خارج نطاق التوصيل"
                : "We can't deliver to this address. It's out of delivery range",
          ),
        ),
      );
      shippingCost = null;
      notifyListeners();
      return;
    }

    double pricePerKm = double.tryParse(minShippingCost ?? '0') ?? 0;
    double calculatedCost = pricePerKm * shortestDistance;

    // لو فيه حد أدنى لتكلفة الشحن، نتأكد إنها مش أقل منه
    double minCost = double.tryParse(minShippingCost ?? '0') ?? 0;
    if (calculatedCost < minCost && minCost > 0) {
      shippingCost = minCost;
    } else {
      shippingCost = calculatedCost;
    }

    print('أقرب مركز توصيل: ${closestCenter?.name}');
    print('المسافة: ${shortestDistance.toStringAsFixed(2)} كم');
    print('تكلفة الشحن: ${shippingCost?.toStringAsFixed(2)} جنيه');

    notifyListeners();
  }
  Future<void> placeOrder(BuildContext context,{
    required Function callback,
    String? addressID,
    String? couponCode,
    String? couponAmount,
    String? billingAddressId,
    String? orderNote,
    String? transactionId,
    String? paymentNote,
    int? id,
    String? name,
    bool isfOffline = false,
    bool wallet = false,

  }) async {
    inputValueList.clear();

    for(TextEditingController textEditingController in inputFieldControllerList) {
      inputValueList.add(textEditingController.text.trim());
    }

    _isLoading = true;
    notifyListeners();

    ApiResponse apiResponse;


    try {
      if (isfOffline) {
        DateTime date;
        String input =Provider.of<AddressController>(Get.context!, listen: false).todayOrTomorrow.text;
        if (input == "today") {
          date = DateTime.now();
        } else if (input == "tomorrow") {
          date = DateTime.now().add(Duration(days: 1));
        } else {
          date = DateTime.now(); // fallback if input is unknown
        }
        int allowedGovernorateIds = await getGovernates(context);
// If you want to format it to a string like "2025-05-23"
        String formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        apiResponse = await checkoutServiceInterface.offlinePaymentPlaceOrder( addressID, couponCode, Provider.of<AddressController>(Get.context!, listen: false).selectedDate,allowedGovernorateIds,"${Provider.of<CheckoutController>(Get.context!, listen: false).shippingCost}",formattedDate,couponAmount, double.parse((((serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(3)).ceil().toString(),billingAddressId,addressID ,orderNote,
            "paid cash on delivery",Provider.of<CartController>(Get.context!, listen: false).cart?.id,"", inputValueList,keyList, inputValueList);
      } else if (wallet) {
        DateTime date;
        String input =Provider.of<AddressController>(Get.context!, listen: false).todayOrTomorrow.text;
        if (input == "today") {
          date = DateTime.now();
        } else if (input == "tomorrow") {
          date = DateTime.now().add(Duration(days: 1));
        } else {
          date = DateTime.now(); // fallback if input is unknown
        }
        int allowedGovernorateIds = await getGovernates(context);

// If you want to format it to a string like "2025-05-23"
        String formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        apiResponse = await checkoutServiceInterface.walletPaymentPlaceOrder (addressID, couponCode, Provider.of<AddressController>(Get.context!, listen: false).selectedDate,allowedGovernorateIds,"${Provider.of<CheckoutController>(Get.context!, listen: false).shippingCost}",formattedDate,couponAmount,double.parse((((serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(3)).ceil().toString() ,billingAddressId,addressID ,orderNote,
    "paid by wallet",Provider.of<CartController>(Get.context!, listen: false).cart?.id,"", inputValueList);
      } else {
        DateTime date;
        String input =Provider.of<AddressController>(Get.context!, listen: false).todayOrTomorrow.text;
        if (input == "today") {
          date = DateTime.now();
        } else if (input == "tomorrow") {
          date = DateTime.now().add(Duration(days: 1));
        } else {
          date = DateTime.now(); // fallback if input is unknown
        }
        int allowedGovernorateIds = await getGovernates(context);
// If you want to format it to a string like "2025-05-23"
        String formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        apiResponse = await checkoutServiceInterface.cashOnDeliveryPlaceOrder(
            addressID, couponCode, Provider.of<AddressController>(Get.context!, listen: false).selectedDate,allowedGovernorateIds,"${Provider.of<CheckoutController>(Get.context!, listen: false).shippingCost}",formattedDate,couponAmount,double.parse((((serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(3)).ceil().toString() ,billingAddressId,addressID ,orderNote,
            "paid cash on delivery",Provider.of<CartController>(Get.context!, listen: false).cart?.id,"", inputValueList);
      }

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _isCheckCreateAccount = false;
        _isLoading = false;
        _addressIndex = null;
        _billingAddressIndex = null;
        sameAsBilling = false;

        if (!Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()) {
          _newUser = apiResponse.response!.data['new_user'];
        }

        String message = apiResponse.response!.data.toString();
        callback(true, message, '', _newUser);
      } else {
        _isLoading = false;
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e) {
      _isLoading = false;
      ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(content: Text('Failed to place order')));
    } finally {
      notifyListeners();
    }
  }

  // باقي الكود بدون تغيير

  double? userLat;
  double? userLng;

  void setUserLocation(double lat, double lng) {
    userLat = lat;
    userLng = lng;
    notifyListeners();
  }

  setAddressIndex(int index) {
    if (_addressIndex != index) {
      _addressIndex = index;
      notifyListeners();
    }
  }


  void setBillingAddressIndex(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }

  void resetPaymentMethod() {
    _paymentMethodIndex = -1;
    codChecked = false;
    walletChecked = false;
    offlineChecked = false;
  }

  void shippingAddressNull() {
    _addressIndex = null;
    notifyListeners();
  }

  void billingAddressNull() {
    _billingAddressIndex = null;
    notifyListeners();
  }

  void setSelectedShippingAddress(int index) {
    _shippingIndex = index;
    notifyListeners();
  }

  void setSelectedBillingAddress(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }

  bool offlineChecked = false;
  bool codChecked = false;
  bool walletChecked = false;

  void setOfflineChecked(String type) {
    if (type == 'offline') {
      offlineChecked = !offlineChecked;
      codChecked = false;
      walletChecked = false;
      _paymentMethodIndex = -1;
      setOfflinePaymentMethodSelectedIndex(0);
    } else if (type == 'cod') {
      codChecked = !codChecked;
      offlineChecked = false;
      walletChecked = false;
      _paymentMethodIndex = -1;
    } else if (type == 'wallet') {
      walletChecked = !walletChecked;
      offlineChecked = false;
      codChecked = false;
      _paymentMethodIndex = -1;
    }

    notifyListeners();
  }

  String selectedDigitalPaymentMethodName = '';

  void setDigitalPaymentMethodName(int index, String name) {
    _paymentMethodIndex = index;
    selectedDigitalPaymentMethodName = name;
    codChecked = false;
    walletChecked = false;
    offlineChecked = false;
    notifyListeners();
  }

  void digitalOnly(bool value, {bool isUpdate = false}) {
    _onlyDigital = value;
    if (isUpdate) {
      notifyListeners();
    }
  }

  OfflinePaymentModel? offlinePaymentModel;

  Future<ApiResponse> getOfflinePaymentList() async {
    ApiResponse apiResponse = await checkoutServiceInterface.offlinePaymentList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      offlineMethodSelectedIndex = 0;
      offlinePaymentModel = OfflinePaymentModel.fromJson(apiResponse.response?.data);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  List<TextEditingController> inputFieldControllerList = [];
  List<String?> keyList = [];
  int offlineMethodSelectedIndex = -1;
  int offlineMethodSelectedId = 0;
  String offlineMethodSelectedName = '';

  void setOfflinePaymentMethodSelectedIndex(int index, {bool notify = true}) {
    keyList = [];
    inputFieldControllerList = [];
    offlineMethodSelectedIndex = index;
    if (offlinePaymentModel != null && offlinePaymentModel!.offlineMethods != null && offlinePaymentModel!.offlineMethods!.isNotEmpty) {
      offlineMethodSelectedId = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].id!;
      offlineMethodSelectedName = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].methodName!;
    }

    if (offlinePaymentModel!.offlineMethods != null && offlinePaymentModel!.offlineMethods!.isNotEmpty && offlinePaymentModel!.offlineMethods![index].methodInformations!.isNotEmpty) {
      for (int i = 0; i < offlinePaymentModel!.offlineMethods![index].methodInformations!.length; i++) {
        inputFieldControllerList.add(TextEditingController());
        keyList.add(offlinePaymentModel!.offlineMethods![index].methodInformations![i].customerInput);
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<ApiResponse> digitalPaymentPlaceOrder(BuildContext context,{
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
  List<String>? inputValues, String? customerId,
  
  }) async {
    _isLoading = true;
    notifyListeners();
    DateTime date;
    String input =Provider.of<AddressController>(Get.context!, listen: false).todayOrTomorrow.text;
    if (input == "today") {
      date = DateTime.now();
    } else if (input == "tomorrow") {
      date = DateTime.now().add(Duration(days: 1));
    } else {
      date = DateTime.now(); // fallback if input is unknown
    }
    int allowedGovernorateIds = await getGovernates(context);
// If you want to format it to a string like "2025-05-23"
    String formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    ApiResponse apiResponse = await checkoutServiceInterface.digitalPaymentPlaceOrder( addressId, couponCode, Provider.of<AddressController>(Get.context!, listen: false).selectedDate,allowedGovernorateIds,"${Provider.of<AddressController>(Get.context!, listen: false).shippingCost}",formattedDate,couponAmount,double.parse((((serviceFees )!/ 100) * (Provider.of<CheckoutController>(context, listen: false).shippingCost ?? 0)).toStringAsFixed(3)).ceil().toString(),billingAddressId,addressId ,orderNote,
        "paid cash on delivery",Provider.of<CartController>(Get.context!, listen: false).cart?.id,"", inputValueList);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _addressIndex = null;
      _billingAddressIndex = null;
      sameAsBilling = false;
      _isLoading = false;
      Navigator.pushReplacement(Get.context!, MaterialPageRoute(builder: (_) => DigitalPaymentScreen(url: apiResponse.response?.data['redirect_link'])));
    } else if (apiResponse.error == 'Already registered ') {
      _isLoading = false;
      showCustomSnackBar('${getTranslated(apiResponse.error, Get.context!)}', Get.context!);
    } else {
      _isLoading = false;
      showCustomSnackBar('${getTranslated('payment_method_not_properly_configured', Get.context!)}', Get.context!);
    }
    notifyListeners();
    return apiResponse;
  }

  bool sameAsBilling = false;
  void setSameAsBilling() {
    sameAsBilling = !sameAsBilling;
    notifyListeners();
  }

  void clearData() {
    orderNoteController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _isCheckCreateAccount = false;
  }

  void setIsCheckCreateAccount(bool isCheck, {bool update = true}) {
    _isCheckCreateAccount = isCheck;
    if (update) {
      notifyListeners();
    }
  }
}
