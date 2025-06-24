import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/compare/controllers/compare_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/author_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/suggestion_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class SearchProductController with ChangeNotifier {
  final SearchProductServiceInterface? searchProductServiceInterface;
  SearchProductController({required this.searchProductServiceInterface});

  int _filterIndex = 0;
  List<String> _historyList = [];
  List<AuthorModel>? _authorsList;
  List<AuthorModel>? _publishingHouseList;
  List<AuthorModel>? _sellerAuthorsList;
  List<AuthorModel>? _sellerPublishingHouseList;

  int get filterIndex => _filterIndex;
  List<String> get historyList => _historyList;
  List<AuthorModel>? get authorsList => _authorsList;
  List<AuthorModel>? get publishingHouseList => _publishingHouseList;
  List<AuthorModel>? get sellerAuthorsList => _sellerAuthorsList;
  List<AuthorModel>? get sellerPublishingHouseList => _sellerPublishingHouseList;

  final List<int> _selectedAuthorIds = [];
  List<int> get selectedAuthorIds => _selectedAuthorIds;

  final List<int> _publishingHouseIds = [];
  List<int> get publishingHouseIds => _publishingHouseIds;

  List<int> _selectedSellerAuthorIds = [];
  List<int> get selectedSellerAuthorIds => _selectedSellerAuthorIds;

  List<int> _sellerPublishingHouseIds = [];
  List<int> get sellerPublishingHouseIds => _sellerPublishingHouseIds;

  double minPriceForFilter = AppConstants.minFilter;
  double maxPriceForFilter = AppConstants.maxFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _productTypeIndex = 0;
  int get productTypeIndex => _productTypeIndex;

  void setMinMaxPriceForFilter(RangeValues currentRangeValues){
    minPriceForFilter = currentRangeValues.start;
    maxPriceForFilter = currentRangeValues.end;
    notifyListeners();
  }

  bool _isFilterApplied = false;
  bool _isSortingApplied = false;

  bool get isFilterApplied => _isFilterApplied;
  bool get isSortingApplied => _isSortingApplied;

  void setFilterApply({bool? isFiltered, bool? isSorted}){
    if(isFiltered != null) _isFilterApplied = isFiltered;
    if(isSorted != null) _isSortingApplied = isSorted;
    notifyListeners();
  }

  String sortText = 'low-high';
  void setFilterIndex(int index) {
    _filterIndex = index;
    if(index == 0){
      sortText = 'latest';
    }else if(index == 1){
      sortText = 'a-z';
    }else if(index == 2){
      sortText = 'z-a';
    }else if(index == 3){
      sortText = 'low-high';
    }else if(index ==4){
      sortText = 'high-low';
    }
    notifyListeners();
  }

  double minFilterValue = 0;
  double maxFilterValue = 0;
  void setFilterValue(double min, double max){
    minFilterValue = min;
    maxFilterValue = max;
  }

  bool _isClear = true;
  bool get isClear => _isClear;

  void cleanSearchProduct({bool notify = false}) {
    searchedProduct = null;
    minFilterValue = 0;
    maxFilterValue = 0;
    _isClear = true;
    if(notify){
      notifyListeners();
    }
  }

  Future<List<int>> getGovernates(BuildContext context) async {
    ProfileController profileController = Provider.of<ProfileController>(context, listen: false);
    ProfileModel? updateUserInfoModel = profileController.userInfoModel;
    if (updateUserInfoModel == null) return [];
    int? govId = updateUserInfoModel.governorate_id;
    return govId == null ? [] : [govId];
  }

  ProductModel? searchedProduct;
  Future<List<int>> getGovernoratesFromProfile(ProfileModel? userInfoModel) async {
    if (userInfoModel == null) return [];
    int? govId = userInfoModel.governorate_id;
    return govId == null ? [] : [govId];
  }


  Future<void> searchProduct({
    required String query,
    String? categoryIds,
    String? brandIds,
    String? authorIds,
    String? publishingIds,
    String? sort,
    String? priceMin,
    String? priceMax,
    required int offset,
    required BuildContext context,
  }) async {
    if (query.isNotEmpty) {
      searchController.text = query;
    }

    if (offset == 1) {
      _isLoading = true;
      notifyListeners();
    }

    // ✅ استخراج البيانات المطلوبة من الـ context قبل أي await
    final bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    final ProfileModel? userInfoModel = Provider.of<ProfileController>(context, listen: false).userInfoModel;

    // 🕐 إجراء طلب البحث
    ApiResponse apiResponse = await searchProductServiceInterface?.getSearchProductList(
      query,
      categoryIds,
      brandIds,
      authorIds,
      publishingIds,
      sort,
      priceMin,
      priceMax,
      offset,
      _productTypeIndex == 0 ? 'all' : _productTypeIndex == 1 ? 'physical' : 'digital',
    );

    print('query: $query');
    print('categoryIds: $categoryIds');
    print('brandIds: $brandIds');
    print('authorIds: $authorIds');
    print('publishingIds: $publishingIds');
    print('sort: $sort');
    print('priceMin: $priceMin');
    print('priceMax: $priceMax');
    print('offset: $offset');

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var responseData = apiResponse.response!.data;
      List<dynamic> originalProductList = responseData['products'] ?? [];

      List<Map<String, dynamic>> filteredProductJsons = [];

      if (isLoggedIn) {
        List<int> allowedGovernorateIds = await getGovernoratesFromProfile(userInfoModel);

        for (var productJson in originalProductList) {
          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            var govList = productJson['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null && productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          if (productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
            filteredProductJsons.add(productJson as Map<String, dynamic>);
          }
        }
      } else {
        filteredProductJsons = List<Map<String, dynamic>>.from(originalProductList);
      }

      responseData['products'] = filteredProductJsons;
      ProductModel filteredModel = ProductModel.fromJson(responseData);

      if (offset == 1) {
        searchedProduct = null;
        searchedProduct = filteredModel;
        if (searchedProduct?.minPrice != null) minFilterValue = searchedProduct!.minPrice!;
        if (searchedProduct?.maxPrice != null) maxFilterValue = searchedProduct!.maxPrice!;
        _isLoading = false;
      } else {
        searchedProduct?.products?.addAll(filteredModel.products ?? []);
        searchedProduct?.offset = filteredModel.offset;
        searchedProduct?.totalSize = filteredModel.totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  SuggestionModel? suggestionModel;
  List<String> nameList = [];
  List<int> idList = [];
  Future<void> getSuggestionProductName(BuildContext context, String name) async {
    ApiResponse apiResponse = await searchProductServiceInterface!.getSearchProductName(name);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      nameList = [];
      idList = [];

      // تحميل المحافظات المسموح بها للمستخدم
      List<int> allowedGovernorateIds = await getGovernates(context);

      suggestionModel = SuggestionModel.fromJson(apiResponse.response?.data);

      for (var product in suggestionModel!.products!) {
        bool matchesGovernorate = false;

        // لو المنتج فيه بائعين
        if (product.seller != null && product.seller!.isNotEmpty) {
          for (var seller in product.seller!) {
            // نجيب رقم المحافظة من الـ pivot
            int govId = seller.pivot?.governorateId ?? -1;

            // نتحقق إذا كانت المحافظة من ضمن المحافظات المسموح بها
            if (allowedGovernorateIds.contains(govId)) {
              matchesGovernorate = true;
              break;
            }
          }
        }

        // لو المنتج متاح في محافظة مسموح بها
        if (matchesGovernorate) {
          nameList.add(product.name!);
          idList.add(product.id!);
        }
      }
    }

    notifyListeners();
  }




  void initHistoryList() {
    _historyList = [];
    _historyList.addAll(searchProductServiceInterface!.getSavedSearchProductName());
  }

  int selectedSearchedProductId = 0;
  void setSelectedProductId(int index, int? compareId){
    if(suggestionModel!.products!.isNotEmpty){
      selectedSearchedProductId = suggestionModel!.products![index].id!;
    }
    if(compareId != null){
      Provider.of<CompareController>(Get.context!, listen: false).replaceCompareList(compareId ,selectedSearchedProductId);
    }else{
      Provider.of<CompareController>(Get.context!, listen: false).addCompareList(selectedSearchedProductId);
    }
    notifyListeners();
  }

  void saveSearchAddress(String searchAddress) async {
    searchProductServiceInterface!.saveSearchProductName(searchAddress);
    if (!_historyList.contains(searchAddress)) {
      _historyList.add(searchAddress);
    }
    notifyListeners();
  }

  void removeSearchAddress(int? index) async {
    _historyList.removeAt(index!);
    searchProductServiceInterface!.clearSavedSearchProductName();
    for(int i =0; i<_historyList.length; i++ ) {
      searchProductServiceInterface!.saveSearchProductName(_historyList[i]);
    }
    notifyListeners();
  }

  void clearSearchAddress() async {
    searchProductServiceInterface!.clearSavedSearchProductName();
    _historyList = [];
    notifyListeners();
  }

  void setInitialFilerData() {
    _filterIndex = 0;
  }

  Future<void> getAuthorList(int? sellerId) async {
    ApiResponse apiResponse = await searchProductServiceInterface!.getAuthorList(sellerId);
    if(sellerId != null && apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _sellerAuthorsList = [];
      apiResponse.response!.data.forEach((author) {
        _sellerAuthorsList!.add(AuthorModel.fromJson(author));
      });
    } else if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _authorsList = [];
      apiResponse.response!.data.forEach((author) {
        _authorsList!.add(AuthorModel.fromJson(author));
      });
    }
    notifyListeners();
  }

  Future<void> getPublishingHouseList(int? sellerId) async {
    ApiResponse apiResponse = await searchProductServiceInterface!.getPublishingHouse(sellerId);
    if(sellerId != null && apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _sellerPublishingHouseList = [];
      apiResponse.response!.data.forEach((house) {
        _sellerPublishingHouseList!.add(AuthorModel.fromJson(house));
      });
    } else if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _publishingHouseList = [];
      apiResponse.response!.data.forEach((house) {
        _publishingHouseList!.add(AuthorModel.fromJson(house));
      });
    }
    notifyListeners();
  }

  void checkedToggleAuthors(int index, bool formShop) {
    if(formShop) {
      _sellerAuthorsList![index].isChecked = !_sellerAuthorsList![index].isChecked!;
      if(_sellerAuthorsList![index].isChecked ?? false) {
        if(!_selectedSellerAuthorIds.contains(_sellerAuthorsList![index].id)) {
          _selectedSellerAuthorIds.add(_sellerAuthorsList![index].id!);
        }
      }else {
        _selectedSellerAuthorIds.remove(_sellerAuthorsList![index].id!);
      }
    } else {
      _authorsList![index].isChecked = !_authorsList![index].isChecked!;
      if(_authorsList![index].isChecked ?? false) {
        if(!_selectedAuthorIds.contains(_authorsList![index].id)) {
          _selectedAuthorIds.add(_authorsList![index].id!);
        }
      }else {
        _selectedAuthorIds.remove(_authorsList![index].id!);
      }
    }
    notifyListeners();
  }

  void checkedTogglePublishingHouse(int index, bool fromShop, {bool fromHomePage = false}) {
    if(fromHomePage){
      _sellerPublishingHouseIds = [];
      _publishingHouseList?.map((house) { house.isChecked = false; }).toList();
    }
    if(fromShop){
      _sellerPublishingHouseList![index].isChecked = !_sellerPublishingHouseList![index].isChecked!;
      if(_sellerPublishingHouseList![index].isChecked ?? false) {
        if(!_sellerPublishingHouseIds.contains(_sellerPublishingHouseList![index].id!)) {
          _sellerPublishingHouseIds.add(_sellerPublishingHouseList![index].id!);
        }
      }else {
        _sellerPublishingHouseIds.remove(_sellerPublishingHouseList![index].id!);
      }
    }else{
      _publishingHouseList![index].isChecked = !_publishingHouseList![index].isChecked!;
      if(_publishingHouseList![index].isChecked ?? false) {
        if(!_publishingHouseIds.contains(_publishingHouseList![index].id)) {
          _publishingHouseIds.add(_publishingHouseList![index].id!);
        }
      }else {
        _publishingHouseIds.remove(_publishingHouseList![index].id!);
      }
    }
    notifyListeners();
  }

  void setProductTypeIndex(int index, bool notify) {
    _productTypeIndex = index;
    if(notify) notifyListeners();
  }

  void clearSellerAuthorHouse() {
    _selectedSellerAuthorIds = [];
    _sellerAuthorsList =[];
    _sellerPublishingHouseList = [];
    _sellerPublishingHouseIds = [];
  }

  Future<void> resetChecked(int? id, bool fromShop) async{
    if(fromShop){
      getAuthorList(id);
      getPublishingHouseList(id);
    }else{
      getAuthorList(null);
      getPublishingHouseList(null);
    }
  }
}
