import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/label_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/restricted_zip_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/services/address_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../data/model/governate_model.dart' as g;
import '../../../data/model/governates_model.dart';
import '../../../utill/app_constants.dart';
import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class AddressController with ChangeNotifier {
  final AddressServiceInterface addressServiceInterface;
  AddressController({required this.addressServiceInterface});

  List<String> _restrictedCountryList = [];
  List<String> get restrictedCountryList =>_restrictedCountryList;
  List<RestrictedZipModel> _restrictedZipList =[];
  List<RestrictedZipModel> get restrictedZipList => _restrictedZipList;
  final List<String> _zipNameList = [];
  List<String> get zipNameList => _zipNameList;
  final TextEditingController _searchZipController = TextEditingController();
  TextEditingController get searchZipController => _searchZipController;
  final TextEditingController _searchCountryController = TextEditingController();
  final isArabic = Localizations.localeOf(Get.context!).languageCode == 'ar';
double? lat;
double? lang;
  TextEditingController todayOrTomorrow=TextEditingController();
  List<AddressModel>? _addressList;
  List<AddressModel>? get addressList => _addressList;
  double? maxShippingDistance ; // الحد الأقصى للتوصيل بالكيلومتر
  double? shippingCost; // متغير لحفظ تكلفة الشحن

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

  List<g.DeliveryCenter>? deliveryCenters;
  List<g.DeliveryTime>? deliveryTimes;
  String? minShippingCost;
  String? note;
  String? selectedGovernate;
  List<String>? delivery;
  String? selectedDate;

  String getDayLabel(String selectedTimeRange) {
    // بنفصل الوقتين من النص
    List<String> parts = selectedTimeRange.split(' - ');
    String startTimeStr = parts[0]; // مثلاً "02:00 PM"

    // بنحول الوقت من 12 ساعة لـ 24 ساعة عشان نقدر نقارن
    DateTime now = DateTime.now();

    DateTime selectedTime = convert12HourToDateTime(startTimeStr, now);

    if (selectedTime.isAfter(now)) {
      return "Today";
    } else {
      return "Tomorrow";
    }
  }
  String? dayLabel;
// دالة لتحويل "hh:mm AM/PM" لـ DateTime بنفس يوم اليوم الحالي
  DateTime convert12HourToDateTime(String time12h, DateTime referenceDate) {
    final format = RegExp(r'(\d+):(\d+) (\w{2})');
    final match = format.firstMatch(time12h);
    if (match == null) throw FormatException("Invalid time format");

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    if (period == "PM" && hour != 12) {
      hour += 12;
    } else if (period == "AM" && hour == 12) {
      hour = 0;
    }

    return DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, minute);
  }

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


  Future<int> getGovernatesIds(BuildContext context) async {
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

  Future<void> getRestrictedDeliveryCountryList() async {
    ApiResponse apiResponse = await addressServiceInterface.getDeliveryRestrictedCountryList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _restrictedCountryList = [];
      apiResponse.response!.data.forEach((address) => _restrictedCountryList.add(address));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }


  Future<void> getRestrictedDeliveryZipList() async {
    ApiResponse apiResponse = await addressServiceInterface.getDeliveryRestrictedZipList();
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200) {
      _restrictedZipList = [];
      apiResponse.response!.data.forEach((address) => _restrictedZipList.add(RestrictedZipModel.fromJson(address)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  
  Future<void> getDeliveryRestrictedZipBySearch(String searchName) async {
    _restrictedZipList = [];
    ApiResponse response = await addressServiceInterface.getDeliveryRestrictedZipBySearch(searchName);
    if(response.response!.statusCode == 200) {
      _restrictedZipList = [];
      response.response!.data.forEach((address) {
        _restrictedZipList.add(RestrictedZipModel.fromJson(address));
      });
    }else {
      ApiChecker.checkApi(response);
    }
   notifyListeners();
  }


  Future<void> getDeliveryRestrictedCountryBySearch( String searchName) async {
    _restrictedCountryList = [];
    ApiResponse response = await addressServiceInterface.getDeliveryRestrictedCountryBySearch(searchName);
    if(response.response!.statusCode == 200) {
      _restrictedCountryList = [];
      response.response!.data.forEach((address) => _restrictedCountryList.add(address));
    }else {
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }


  bool _isLoading = false;
  bool get isLoading => _isLoading;



  Future<List<AddressModel>?> getAddressList({bool fromRemove = false, bool isShipping = false, bool isBilling = false, bool all = false }) async {
    _addressList = await addressServiceInterface.getList(isShipping: isShipping, isBilling: isBilling, fromRemove: fromRemove, all: all);
    notifyListeners();
    return _addressList;
  }




  Future<void> deleteAddress(int id) async {
    ApiResponse apiResponse = await addressServiceInterface.delete(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBar(apiResponse.response!.data['message'], Get.context!, isError: false);
      getAddressList(fromRemove: true);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  Future<ApiResponse> addAddress(AddressModel addressModel) async {
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await addressServiceInterface.add(addressModel);
    _isLoading = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBar(apiResponse.response!.data["message"], Get.context!, isError: false);
      getAddressList();
    }
    notifyListeners();
    return apiResponse;
  }


  Future<void> updateAddress(BuildContext context, {required AddressModel addressModel, int? addressId}) async {
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await addressServiceInterface.update(addressModel.toJson(), addressId!);
    _isLoading = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Navigator.pop(Get.context!);
      getAddressList();
      showCustomSnackBar(apiResponse.response!.data['message'], Get.context!, isError: false);
    }

    notifyListeners();
  }

  void setZip(String zip){
    _searchZipController.text = zip;
    notifyListeners();
  }
  
  void setCountry(String country){
    _searchCountryController.text = country;
    notifyListeners();
  }

  


  List<LabelAsModel> addressTypeList = [];
  int _selectAddressIndex = 0;

  int get selectAddressIndex => _selectAddressIndex;

  updateAddressIndex(int index, bool notify) {
    _selectAddressIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  Future<List<LabelAsModel>> getAddressType() async {
    if (addressTypeList.isEmpty) {
      addressTypeList = [];
      addressTypeList = addressServiceInterface.getAddressType();
    }
    return addressTypeList;
  }
  
}
