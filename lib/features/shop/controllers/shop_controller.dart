import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/more_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_info_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart' as s;
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/services/shop_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

import '../../../data/model/governates_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class ShopController extends ChangeNotifier {
  final ShopServiceInterface? shopServiceInterface;
  ShopController({required this.shopServiceInterface});

  String? _searchText;
  String? get searchText => _searchText;

  String? shopName;
  void setShopName(String? name, {bool notify = true}){
    shopName = name;
    if(notify){
      notifyListeners();
    }
  }


  int shopMenuIndex = 0;
  void setMenuItemIndex(int index, {bool notify = true}){
    shopMenuIndex = index;
    if(notify){
      notifyListeners();
    }
  }


  SellerInfoModel? sellerInfoModel ;
  Future<void> getSellerInfo(String sellerId) async {
    ApiResponse apiResponse = await shopServiceInterface!.get(sellerId);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      sellerInfoModel = SellerInfoModel.fromJson(apiResponse.response!.data);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }



  bool isLoading = false;
  List<MostPopularStoreModel> moreStoreList =[];
  Future<ApiResponse> getMoreStore() async {
    var localData =  await database.getCacheResponseById(AppConstants.moreStore);

    if(localData != null) {
      var moreStoreList = jsonDecode(localData.response);

      moreStoreList.forEach((store)=> moreStoreList.add(MostPopularStoreModel.fromJson(store)));
      notifyListeners();
    }

    moreStoreList = [];
    isLoading = true;
    ApiResponse apiResponse = await shopServiceInterface!.getMoreStore();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      apiResponse.response?.data.forEach((store)=> moreStoreList.add(MostPopularStoreModel.fromJson(store)));

      if(localData != null) {
        await database.updateCacheResponse(AppConstants.moreStore, CacheResponseCompanion(
          endPoint: const Value(AppConstants.moreStore),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.moreStore),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }


    } else {
      isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }
  String sellerType = "top";
  String sellerTypeTitle = "top_seller";
  void setSellerType(String type, BuildContext context,{bool notify = true}){
    sellerType = type;
    sellerModel = null;
    if(sellerType == "top"){
      sellerTypeTitle = "top_seller";
    }
    else if(sellerType == "new"){
      sellerTypeTitle = "new_seller";
    }else{
      sellerTypeTitle = "all_seller";
    }
    getTopSellerList(true, 1,context,type: sellerType);
    if(notify){
      notifyListeners();
    }
  }
  Future<List<int>> getGovernates(BuildContext context) async {
    ProfileController profileController = Provider.of<ProfileController>(context, listen: false);

    ProfileModel? updateUserInfoModel = profileController.userInfoModel;

    if (updateUserInfoModel == null) {
      // ممكن تعمل تسجيل خروج، أو ترجع قائمة فاضية لحد ما البيانات تتحمل
      return [];
    }

    int? govId = updateUserInfoModel.governorate_id;

    if (govId == null) {
      return [];
    }

    return [govId];
  }
  s.SellerModel? sellerModel;
  Future<void> getTopSellerList(bool reload, int offset, BuildContext context, {required String type}) async {
    isLoading = true;
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    // Get allowed governorate IDs
    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

    // Load all governorates with their names
    await getAllGovernates();

    // Extract allowed governorate names
    List<String> allowedGovernorateNames = governates!
        .where((g) => allowedGovernorateIds.contains(g.id))
        .map((g) => g.name?.trim().toLowerCase() ?? '')
        .toList();

    String cacheKey = "${AppConstants.sellerList}$type";
    var localData = await database.getCacheResponseById(cacheKey);

    if (localData != null && offset == 1) {
      s.SellerModel cachedModel = s.SellerModel.fromJson(jsonDecode(localData.response));
      List<s.Seller> filteredCachedSellers = [];

      if (!isLoggedIn) {
        filteredCachedSellers = cachedModel.sellers ?? [];
      } else {
        for (var seller in cachedModel.sellers ?? []) {
          List<dynamic> sellerGovs = seller.seller_governorates ?? [];

          List<String> sellerGovernorateNames = sellerGovs
              .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
              .toList();

          String? sellerName = seller.fName?.toLowerCase().trim();

          bool isDentofly = sellerName == 'dentofly';

          if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
            filteredCachedSellers.add(seller);
          }
        }
      }

      sellerModel = s.SellerModel(
        sellers: filteredCachedSellers,
        totalSize: filteredCachedSellers.length,
        offset: cachedModel.offset,
        limit: cachedModel.limit,
      );

      notifyListeners();
    }

    if (reload || offset == 1 || sellerModel == null) {
      ApiResponse apiResponse = await shopServiceInterface!.getSellerList(type, offset);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        s.SellerModel fetchedModel = s.SellerModel.fromJson(apiResponse.response!.data);
        List<s.Seller> filteredFetchedSellers = [];

        if (!isLoggedIn) {
          filteredFetchedSellers = fetchedModel.sellers ?? [];
        } else {
          for (var seller in fetchedModel.sellers ?? []) {
            List<dynamic> sellerGovs = seller.seller_governorates ?? [];

            List<String> sellerGovernorateNames = sellerGovs
                .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
                .toList();

            String? sellerName = seller.fName?.toLowerCase().trim();

            bool isDentofly = sellerName == 'dentofly';

            if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
              filteredFetchedSellers.add(seller);
            }
          }
        }

        if (offset == 1 || sellerModel == null) {
          sellerModel = s.SellerModel(
            sellers: filteredFetchedSellers,
            totalSize: fetchedModel.totalSize,
            offset: fetchedModel.offset,
            limit: fetchedModel.limit,
          );
        } else {
          sellerModel?.sellers?.addAll(filteredFetchedSellers);
          sellerModel?.offset = fetchedModel.offset;
          sellerModel?.totalSize = fetchedModel.totalSize;
        }

        try {
          if (localData != null && offset == 1) {
            await database.updateCacheResponse(
              cacheKey,
              CacheResponseCompanion(
                endPoint: Value(cacheKey),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: Value(cacheKey),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache error: $e");
        }

        isLoading = false;
        notifyListeners();
      }
    }
  }




  List<Datum>? governates;
  List<String>? governatesNames;

  Future<void> getAllGovernates() async {
    isLoading = true;
    final Dio dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    try {
      final response = await dio.get(
        "/api/v1/governorates",
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        Governates governatesModel = Governates.fromJson(response.data);
        governates = governatesModel.data;
        governatesNames = governates?.map((g) => g.name ?? '').toList() ?? [];
      } else {
        ScaffoldMessenger.of(Get.context!)
            .showSnackBar(const SnackBar(content: Text('Error fetching Governates')));
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(
          content: Text('Error occurred while connecting to the Server')));
    } finally {
      isLoading = false;
    }
  }

  s.SellerModel? allSellerModel;

  Future<void> getAllSellerList(bool reload, int offset, BuildContext context, {required String type}) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

    // تحميل المحافظات
    await getAllGovernates();

    // استخراج أسماء المحافظات المسموح بها
    List<String> allowedGovernorateNames = governates!
        .where((g) => allowedGovernorateIds.contains(g.id))
        .map((g) => g.name?.trim().toLowerCase() ?? '')
        .toList();

    String cacheKey = "${AppConstants.sellerList}$type";
    var localData = await database.getCacheResponseById(cacheKey);

    if (localData != null && offset == 1) {
      s.SellerModel cachedModel = s.SellerModel.fromJson(jsonDecode(localData.response));
      List<s.Seller> filteredCachedSellers = [];

      if (!isLoggedIn) {
        filteredCachedSellers = cachedModel.sellers ?? [];
      } else {
        for (var seller in cachedModel.sellers ?? []) {
          List<dynamic> sellerGovs = seller.seller_governorates ?? [];

          List<String> sellerGovernorateNames = sellerGovs
              .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
              .toList();

          String? sellerName = seller.fName?.toLowerCase().trim();

          bool isDentofly = sellerName == 'dentofly';

          if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
            filteredCachedSellers.add(seller);
          }
        }
      }

      allSellerModel = s.SellerModel(
        sellers: filteredCachedSellers,
        offset: cachedModel.offset,
        totalSize: filteredCachedSellers.length,
      );

      notifyListeners();
    }

    ApiResponse apiResponse = await shopServiceInterface!.getSellerList('all', offset);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      s.SellerModel fetchedModel = s.SellerModel.fromJson(apiResponse.response!.data);
      List<s.Seller> filteredFetchedSellers = [];

      if (!isLoggedIn) {
        filteredFetchedSellers = fetchedModel.sellers ?? [];
      } else {
        for (var seller in fetchedModel.sellers ?? []) {
          List<dynamic> sellerGovs = seller.seller_governorates ?? [];

          List<String> sellerGovernorateNames = sellerGovs
              .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
              .toList();

          String? sellerName = seller.fName?.toLowerCase().trim();

          bool isDentofly = sellerName == 'dentofly';

          if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
            filteredFetchedSellers.add(seller);
          }
        }
      }

      if (offset == 1) {
        allSellerModel = s.SellerModel(
          sellers: filteredFetchedSellers,
          offset: fetchedModel.offset,
          totalSize: fetchedModel.totalSize,
        );

        if (localData != null) {
          await database.updateCacheResponse(
            cacheKey,
            CacheResponseCompanion(
              endPoint: Value(cacheKey),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: Value(cacheKey),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }
      } else {
        allSellerModel?.sellers?.addAll(filteredFetchedSellers);
        allSellerModel?.offset = fetchedModel.offset;
        allSellerModel?.totalSize = fetchedModel.totalSize;
      }

      notifyListeners();
    }
  }










  ProductModel? clearanceProductModel;
  Future<void> getClearanceShopProductList(String type, String offset, String sellerId, BuildContext context, {bool reload = false}) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];
    await getAllGovernates();

    List<String> allowedGovernorateNames = governates!
        .where((g) => allowedGovernorateIds.contains(g.id))
        .map((g) => g.name?.trim().toLowerCase() ?? '')
        .toList();

    String cacheKey = "${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type";
    var localData = await database.getCacheResponseById(cacheKey);

    if (localData != null) {
      ProductModel cachedModel = ProductModel.fromJson(jsonDecode(localData.response));

      List<Product> filteredCachedProducts = [];

      if (!isLoggedIn) {
        filteredCachedProducts = cachedModel.products ?? [];
      } else {
        for (var product in cachedModel.products ?? []) {
          var seller = product.seller;
          if (seller != null) {
            List<dynamic> sellerGovs = seller['seller_governorates'] ?? [];

            List<String> sellerGovernorateNames = sellerGovs
                .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
                .toList();

            String? sellerName = seller['f_name']?.toString().trim().toLowerCase();
            bool isDentofly = sellerName == 'dentofly';

            if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
              filteredCachedProducts.add(product);
            }
          }
        }
      }

      clearanceProductModel = ProductModel(
        products: filteredCachedProducts,
        totalSize: filteredCachedProducts.length,
        offset: cachedModel.offset,
        limit: cachedModel.limit,
      );

      notifyListeners();
    }

    ApiResponse apiResponse = await shopServiceInterface!.getClearanceShopProductList(type, offset, sellerId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      ProductModel fetchedModel = ProductModel.fromJson(apiResponse.response!.data);
      List<Product> filteredFetchedProducts = [];

      if (!isLoggedIn) {
        filteredFetchedProducts = fetchedModel.products ?? [];
      } else {
        for (var product in fetchedModel.products ?? []) {
          var seller = product.seller;
          if (seller != null) {
            List<dynamic> sellerGovs = seller['seller_governorates'] ?? [];

            List<String> sellerGovernorateNames = sellerGovs
                .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
                .toList();

            String? sellerName = seller.fName?.toLowerCase().trim();

            bool isDentofly = sellerName == 'dentofly';

            if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
              filteredFetchedProducts.add(product);
            }
          }
        }
      }

      if (offset == '1') {
        clearanceProductModel = ProductModel(
          products: filteredFetchedProducts,
          totalSize: fetchedModel.totalSize,
          offset: fetchedModel.offset,
          limit: fetchedModel.limit,
        );
      } else {
        clearanceProductModel?.products?.addAll(filteredFetchedProducts);
        clearanceProductModel?.offset = fetchedModel.offset;
        clearanceProductModel?.totalSize = fetchedModel.totalSize;
      }

      if (localData != null) {
        await database.updateCacheResponse(
          cacheKey,
          CacheResponseCompanion(
            endPoint: Value(cacheKey),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: Value(cacheKey),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }

      notifyListeners();
    }
  }



  void emptyClearanceProductList() {
    clearanceProductModel = null;
  }


  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future <ApiResponse> getClearanceSearchProduct(String sellerId, int offset, String productId, {
    required BuildContext context,
    bool reload = true,
    String search = '',
    String? categoryIds = '[]',
    String? brandIds = '[]',
    String? authorIds = '[]',
    String? publishingIds = '[]',
    String? productType = 'all',
    String? offerType = 'clearance_sale',
    bool fromPaginantion = false
  }) async {

    !fromPaginantion ? isSearchLoading = true : null;
    notifyListeners();

    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    // Get allowed governorate IDs and names
    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];
    await getAllGovernates();
    List<String> allowedGovernorateNames = governates!
        .where((g) => allowedGovernorateIds.contains(g.id))
        .map((g) => g.name?.trim().toLowerCase() ?? '')
        .toList();

    ApiResponse apiResponse = await shopServiceInterface!.getClearanceSearchProduct(
      sellerId,
      offset.toString(),
      productId,
      categoryIds: categoryIds,
      brandIds: brandIds,
      search: search,
      authorIds: authorIds,
      publishingIds: publishingIds,
      productType: productType,
      offerType: offerType,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      ProductModel fetchedModel = ProductModel.fromJson(apiResponse.response!.data);
      List<Product> filteredProducts = [];

      if (!isLoggedIn) {
        filteredProducts = fetchedModel.products ?? [];
      } else {
        for (var product in fetchedModel.products ?? []) {
          var seller = product.seller;

          if (seller != null) {
            List<dynamic> sellerGovs = seller['seller_governorates'] ?? [];

            List<String> sellerGovernorateNames = sellerGovs
                .map((g) => (g is Map && g['name'] != null) ? g['name'].toString().trim().toLowerCase() : '')
                .toList();

            String? sellerName = seller.fName?.toLowerCase().trim();

            bool isDentofly = sellerName == 'dentofly';

            if (isDentofly || sellerGovernorateNames.any((name) => allowedGovernorateNames.contains(name))) {
              filteredProducts.add(product);
            }
          }
        }
      }

      if (offset == 1) {
        clearanceSearchProductModel = ProductModel(
          products: filteredProducts,
          totalSize: fetchedModel.totalSize,
          offset: fetchedModel.offset,
          limit: fetchedModel.limit,
        );
      } else {
        clearanceSearchProductModel?.products?.addAll(filteredProducts);
        clearanceSearchProductModel?.offset = fetchedModel.offset;
        clearanceSearchProductModel?.totalSize = fetchedModel.totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    isSearchLoading = false;
    notifyListeners();
    return apiResponse;
  }


  int? _clearanceSaleProductSelectedIndex;
  int? get clearanceSaleProductSelectedIndex => _clearanceSaleProductSelectedIndex;

  void changeSelectedIndex(int selectedIndex) {
    _clearanceSaleProductSelectedIndex = selectedIndex;
    notifyListeners();
  }


  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }


}
