import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/find_what_you_need.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/home_category_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/most_demanded_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class ProductController extends ChangeNotifier {
  final ProductServiceInterface? productServiceInterface;
  final BuildContext? context;
  ProductController({required this.productServiceInterface,this.context});

  List<Product>? _latestProductList = [];
  List<Product>? _lProductList;
  List<Product>? get lProductList=> _lProductList;
  List<Product>? _featuredProductList;



  ProductType _productType = ProductType.newArrival;
  String? _title = '${getTranslated('best_selling', Get.context!)}';

  bool _filterIsLoading = false;
  bool _filterFirstLoading = true;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool _firstFeaturedLoading = true;
  bool _firstLoading = true;
  int? _latestPageSize = 1;
  int _lOffset = 1;
  int? _lPageSize;
  int? get lPageSize=> _lPageSize;
  int? _featuredPageSize;
  int _lOffsetFeatured = 1;


  ProductType get productType => _productType;
  String? get title => _title;
  int get lOffset => _lOffset;
  int get lOffsetFeatured => _lOffsetFeatured;


  List<int> _offsetList = [];
  List<String> _lOffsetList = [];
  List<String> get lOffsetList=>_lOffsetList;
  List<String> _featuredOffsetList = [];

  List<Product>? get latestProductList => _latestProductList;
  List<Product>? get featuredProductList => _featuredProductList;

  Product? _recommendedProduct;
  Product? get recommendedProduct=> _recommendedProduct;

  bool get filterIsLoading => _filterIsLoading;
  bool get filterFirstLoading => _filterFirstLoading;
  bool get isLoading => _isLoading;
  bool get firstFeaturedLoading => _firstFeaturedLoading;
  bool get firstLoading => _firstLoading;
  int? get latestPageSize => _latestPageSize;
  int? get featuredPageSize => _featuredPageSize;

  ProductModel? _discountedProductModel;
  ProductModel? get discountedProductModel => _discountedProductModel;


  bool filterApply = false;

  String? _searchText;
  String? get searchText => _searchText;



  void isFilterApply (bool apply, {bool reload = false}){
    filterApply = apply;
    if(reload){
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



  Future<void> getLatestProductList(int offset, BuildContext context, {bool reload = false}) async {
    String? endUrl;

    if (_productType == ProductType.bestSelling) {
      endUrl = AppConstants.bestSellingProductUri;
    } else if (_productType == ProductType.newArrival) {
      endUrl = AppConstants.newArrivalProductUri;
    } else if (_productType == ProductType.topProduct) {
      endUrl = AppConstants.topProductUri;
    } else if (_productType == ProductType.discountedProduct) {
      endUrl = AppConstants.discountedProductUri;
    }

    var localData = await database.getCacheResponseById(endUrl ?? '');

    if (localData != null &&
        offset == 1 &&
        ProductModel.fromJson(jsonDecode(localData.response)).products != null) {
      _latestProductList = [];
      _latestProductList!.addAll(ProductModel.fromJson(jsonDecode(localData.response)).products!);
      _latestPageSize = ProductModel.fromJson(jsonDecode(localData.response)).totalSize;
      _filterFirstLoading = false;
      notifyListeners();
    }

    if (reload || offset == 1) {
      _offsetList = [];
      if (localData == null) {
        _latestProductList = null;
      }
    }

    _lOffset = offset;
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);

      ApiResponse apiResponse = await productServiceInterface!.getFilteredProductList(
        Get.context!,
        offset.toString(),
        _productType,
        title,
      );

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        List<dynamic> data = apiResponse.response!.data['products'] ?? [];

        bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

        List<Product> filteredProducts = [];

        if (isLoggedIn) {
          // فلترة حسب المحافظات
          List<int> allowedGovernorateIds = await getGovernates(context);

          for (var productJson in data) {
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

            // ✅ منتجات الادمن دايمًا تظهر
            if (productJson['added_by'] == 'admin') {
              filteredProducts.add(Product.fromJson(productJson));
            } else {
              bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
              if (matches) {
                filteredProducts.add(Product.fromJson(productJson));
              }
            }
          }
        } else {
          // لو مش مسجل دخول، رجّع كل المنتجات
          filteredProducts = data.map((e) => Product.fromJson(e)).toList();
        }

        if (offset == 1) {
          _latestProductList = [];
        }
        _latestProductList!.addAll(filteredProducts);
        _latestPageSize = apiResponse.response!.data['total_size'] ?? filteredProducts.length;

        // كاش التحديث أو الإدخال
        try {
          if (localData != null && offset == 1) {
            await database.updateCacheResponse(
              endUrl ?? '',
              CacheResponseCompanion(
                endPoint: Value(endUrl ?? ''),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: Value(endUrl ?? ''),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache update/insert error: $e");
        }

        _filterFirstLoading = false;
        _filterIsLoading = false;
        removeFirstLoading();
      } else {
        if (reload || offset == 1) {
          _latestProductList = [];
        }
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();
    } else {
      if (_filterIsLoading) {
        _filterIsLoading = false;
        notifyListeners();
      }
    }
  }




  //latest product
  Future<void> getLProductList(String offset, BuildContext context, {bool reload = false}) async {
    var localData = await database.getCacheResponseById(AppConstants.latestProductUri);

    if (localData != null) {
      _lProductList = [];
      _lProductList!.addAll(ProductModel.fromJson(jsonDecode(localData.response)).products!);
      _lPageSize = ProductModel.fromJson(jsonDecode(localData.response)).totalSize;
      notifyListeners();
    }

    if (reload) {
      _lOffsetList = [];
      _lProductList = [];
    }

    if (!_lOffsetList.contains(offset)) {
      _lOffsetList.add(offset);

      ApiResponse apiResponse = await productServiceInterface!.getLatestProductList(offset);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        List<dynamic> data = apiResponse.response!.data['products'] ?? [];

        bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
        List<Product> filteredProducts = [];

        // ✅ Get allowed governorates if logged in
        List<int> allowedGovernorateIds = [];
        if (isLoggedIn) {
          allowedGovernorateIds = await getGovernates(context);
        }

        for (var productJson in data) {
          if (isLoggedIn) {
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

            // ✅ Always allow admin-added products
            if (productJson['added_by'] == 'admin') {
              filteredProducts.add(Product.fromJson(productJson));
            } else {
              bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
              if (matches) {
                filteredProducts.add(Product.fromJson(productJson));
              }
            }
          } else {
            // If not logged in, return all products
            filteredProducts.add(Product.fromJson(productJson));
          }
        }

        _lProductList = [];
        _lProductList?.addAll(filteredProducts);
        _lPageSize = apiResponse.response!.data['total_size'] ?? filteredProducts.length;
        _firstLoading = false;
        _isLoading = false;

        // Cache response
        try {
          if (localData != null) {
            await database.updateCacheResponse(
              AppConstants.latestProductUri,
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.latestProductUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.latestProductUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache insert/update error: $e");
        }
      } else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();
    } else {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }






  List<ProductTypeModel> productTypeList = [
    ProductTypeModel('new_arrival', ProductType.newArrival),
    ProductTypeModel('top_product', ProductType.topProduct),
    ProductTypeModel('best_selling', ProductType.bestSelling),
    ProductTypeModel('discounted_product', ProductType.discountedProduct),
  ];

  
int selectedProductTypeIndex = 0;
  void changeTypeOfProduct(ProductType type, String? title, BuildContext context, {int index = 0}) async {
    _productType = type;
    _title = title;
    _latestProductList = null;
    _latestPageSize = 1;
    _filterFirstLoading = true;
    _filterIsLoading = true;
    selectedProductTypeIndex = index;

    // استدعاء الدالة مع تمرير reload = true
    await getLatestProductList(1, context, reload: true);

    notifyListeners();
  }


  void showBottomLoader() {
    _isLoading = true;
    _filterIsLoading = true;
    notifyListeners();
  }

  void removeFirstLoading() {
    _firstLoading = true;
    notifyListeners();
  }


  TextEditingController sellerProductSearch = TextEditingController();
  void clearSearchField( String id){
    sellerProductSearch.clear();
    notifyListeners();
  }




  final List<Product> _brandOrCategoryProductList = [];
  bool? _hasData;

  List<Product> get brandOrCategoryProductList => _brandOrCategoryProductList;
  bool? get hasData => _hasData;


  Future<void> initBrandOrCategoryProductList(bool isBrand, String id, BuildContext context) async {
    _brandOrCategoryProductList.clear();
    _hasData = true;

    try {
      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

      List<int> allowedGovernorateIds = [];
      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context);
      }

      ApiResponse apiResponse = await productServiceInterface!.getBrandOrCategoryProductList(isBrand, id);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        List<dynamic> data = apiResponse.response!.data ?? [];
        List<Product> filteredProducts = [];

        for (var productJson in data) {
          if (isLoggedIn) {
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

            // ✅ Allow admin-added products even if not in allowed governorates
            if (productJson['added_by'] == 'admin') {
              filteredProducts.add(Product.fromJson(productJson));
            } else {
              bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
              if (matches) {
                filteredProducts.add(Product.fromJson(productJson));
              }
            }
          } else {
            // لو مش مسجل دخول، ضيف كل المنتجات بدون فلترة
            filteredProducts.add(Product.fromJson(productJson));
          }
        }

        _hasData = filteredProducts.isNotEmpty;
        _brandOrCategoryProductList.addAll(filteredProducts);
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e) {
      print("initBrandOrCategoryProductList error: $e");
      _hasData = false;
    }

    notifyListeners();
  }






  List<Product>? _relatedProductList;
  List<Product>? get relatedProductList => _relatedProductList;

  Future<void> initRelatedProductList(String id, BuildContext context) async {
    try {
      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

      // جلب قائمة المحافظات المسموح بها إذا المستخدم مسجل دخول
      List<int> allowedGovernorateIds = [];
      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context);
      }

      ApiResponse apiResponse = await productServiceInterface!.getRelatedProductList(id);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        List<dynamic> data = apiResponse.response!.data ?? [];
        List<Product> filteredProducts = [];

        for (var productJson in data) {
          if (isLoggedIn) {
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

            // ✅ لو المنتج مضاف بواسطة الأدمن، خليه يظهر دائمًا
            if (productJson['added_by'] == 'admin') {
              filteredProducts.add(Product.fromJson(productJson));
            } else {
              bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
              if (matches) {
                filteredProducts.add(Product.fromJson(productJson));
              }
            }
          } else {
            // المستخدم مش مسجل دخول، ضيف كل المنتجات
            filteredProducts.add(Product.fromJson(productJson));
          }
        }

        _relatedProductList = filteredProducts;
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e) {
      print("initRelatedProductList error: $e");
      _relatedProductList = [];
    }

    notifyListeners();
  }






  List<Product>? _moreProductList;
  List<Product>? get moreProductList => _moreProductList;

  Future<void> getMoreProductList(String id, BuildContext context) async {
    try {
      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

      // جلب المحافظات المسموح بها فقط إذا المستخدم مسجل دخول
      List<int> allowedGovernorateIds = [];
      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context);
      }

      ApiResponse apiResponse = await productServiceInterface!.getRelatedProductList(id);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        List<dynamic> data = apiResponse.response!.data ?? [];
        List<Product> filteredProducts = [];

        for (var productJson in data) {
          if (isLoggedIn) {
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

            // ✅ لو المنتج من الأدمن خليه يظهر دايمًا
            if (productJson['added_by'] == 'admin') {
              filteredProducts.add(Product.fromJson(productJson));
            } else {
              bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
              if (matches) {
                filteredProducts.add(Product.fromJson(productJson));
              }
            }
          } else {
            // لو مش مسجل دخول ضيف كل المنتجات بدون فلترة
            filteredProducts.add(Product.fromJson(productJson));
          }
        }

        _relatedProductList = filteredProducts;
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e) {
      print("getMoreProductList error: $e");
      _relatedProductList = [];
    }

    notifyListeners();
  }





  void removePrevRelatedProduct() {
    _relatedProductList = null;
  }


  int featuredIndex = 0;
  void setFeaturedIndex(int index){
    featuredIndex = index;
    notifyListeners();
  }


  Future<void> getFeaturedProductList(String offset, BuildContext context, {bool reload = false}) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    var localData = await database.getCacheResponseById(AppConstants.featuredProductUri);

    // جلب المحافظات المسموح بها
    List<int> allowedGovernorateIds = isLoggedIn ? await getGovernates(context) : [];

    // التعامل مع الكاش أولًا
    if (localData != null && offset == '1') {
      _featuredOffsetList = [];
      _featuredProductList = [];
      _isLoading = true;

      Map<String, dynamic> localJson = jsonDecode(localData.response);
      List<dynamic> data = localJson['products'] ?? [];

      List<Product> filteredCachedProducts = [];

      for (var productJson in data) {
        if (!isLoggedIn) {
          filteredCachedProducts.add(Product.fromJson(productJson));
        } else {
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

          if (productJson['added_by'] == 'admin' ||
              productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
            filteredCachedProducts.add(Product.fromJson(productJson));
          }
        }
      }

      _featuredProductList?.addAll(filteredCachedProducts);
      _featuredPageSize = localJson['total_size'] ?? filteredCachedProducts.length;
      notifyListeners();
    }

    // إعادة التحميل أو أول صفحة
    if (reload || offset == '1') {
      _featuredOffsetList = [];
      _featuredProductList = [];
    }

    if (!_featuredOffsetList.contains(offset)) {
      _featuredOffsetList.add(offset);
      _lOffsetFeatured = int.parse(offset);

      ApiResponse apiResponse = await productServiceInterface!.getFeaturedProductList(offset);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        Map<String, dynamic> jsonData = apiResponse.response!.data;
        List<dynamic> data = jsonData['products'] ?? [];

        List<Product> filteredFetchedProducts = [];

        for (var productJson in data) {
          if (!isLoggedIn) {
            filteredFetchedProducts.add(Product.fromJson(productJson));
          } else {
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

            if (productJson['added_by'] == 'admin' ||
                productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
              filteredFetchedProducts.add(Product.fromJson(productJson));
            }
          }
        }

        if (offset == '1') {
          _featuredProductList = [];
        }

        _featuredProductList?.addAll(filteredFetchedProducts);
        _featuredPageSize = jsonData['total_size'] ?? filteredFetchedProducts.length;

        try {
          if (localData != null && offset == '1') {
            await database.updateCacheResponse(
              AppConstants.featuredProductUri,
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.featuredProductUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.featuredProductUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache update/insert error: $e");
        }

        _firstFeaturedLoading = false;
        _isFeaturedLoading = false;
        _filterIsLoading = false;
        notifyListeners();
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } else {
      if (_isFeaturedLoading) {
        _isFeaturedLoading = false;
        notifyListeners();
      }
    }

    _isLoading = false;
  }






  bool recommendedProductLoading = false;
  Future<void> getRecommendedProduct(BuildContext context) async {
    try {
      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
      List<int> allowedGovernorateIds = isLoggedIn ? await getGovernates(context) ?? [] : [];

      var localData = await database.getCacheResponseById(AppConstants.dealOfTheDay);

      List<dynamic> cachedProductsData = [];

      if (localData != null) {
        Map<String, dynamic> decoded = jsonDecode(localData.response);
        cachedProductsData = decoded['products'] ?? [];
      }

      bool foundProduct = false;

      for (var productJson in cachedProductsData) {
        if (!isLoggedIn) {
          _recommendedProduct = Product.fromJson(productJson);
          foundProduct = true;
          break;
        }

        List<int> productGovernorates = [];

        if (productJson['governorates'] != null) {
          productGovernorates = (productJson['governorates'] as List<dynamic>)
              .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
              .where((id) => id != -1)
              .toList();
        } else if (productJson['seller'] != null &&
            productJson['seller']['governorates'] != null) {
          productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
              .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
              .where((id) => id != -1)
              .toList();
        }

        if (productJson['added_by'] == 'admin' ||
            productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
          _recommendedProduct = Product.fromJson(productJson);
          foundProduct = true;
          break;
        }
      }

      if (foundProduct) {
        notifyListeners();
        return;
      }

      // If no product from cache, fetch from API
      ApiResponse apiResponse = await productServiceInterface!.getRecommendedProduct();

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        Map<String, dynamic> decoded = apiResponse.response!.data;
        List<dynamic> productsData = decoded['products'] ?? [];

        for (var productJson in productsData) {
          if (!isLoggedIn) {
            _recommendedProduct = Product.fromJson(productJson);
            foundProduct = true;
          } else {
            List<int> productGovernorates = [];

            if (productJson['governorates'] != null) {
              productGovernorates = (productJson['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            } else if (productJson['seller'] != null &&
                productJson['seller']['governorates'] != null) {
              productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            }

            if (productJson['added_by'] == 'admin' ||
                productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
              _recommendedProduct = Product.fromJson(productJson);
              foundProduct = true;
            }
          }

          if (foundProduct) {
            // Save to cache
            if (localData != null) {
              await database.updateCacheResponse(
                AppConstants.dealOfTheDay,
                CacheResponseCompanion(
                  endPoint: const Value(AppConstants.dealOfTheDay),
                  header: Value(jsonEncode(apiResponse.response!.headers.map)),
                  response: Value(jsonEncode(apiResponse.response!.data)),
                ),
              );
            } else {
              await database.insertCacheResponse(
                CacheResponseCompanion(
                  endPoint: const Value(AppConstants.dealOfTheDay),
                  header: Value(jsonEncode(apiResponse.response!.headers.map)),
                  response: Value(jsonEncode(apiResponse.response!.data)),
                ),
              );
            }
            break;
          }
        }

        if (foundProduct) {
          notifyListeners();
        }
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e, stack) {
      print('Error in getRecommendedProduct: $e');
      print(stack);
    }
  }








  final List<HomeCategoryProduct> _homeCategoryProductList = [];
  List<HomeCategoryProduct> get homeCategoryProductList => _homeCategoryProductList;

  Future<void> getHomeCategoryProductList(BuildContext context, bool reload) async {
    const String endUrl = AppConstants.homeCategoryProductUri;
    var localData = await database.getCacheResponseById(endUrl);

    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];
    _homeCategoryProductList.clear();

    List<dynamic> sourceData = [];

    if (localData != null && !reload) {
      // Use cached data if available and not reloading
      sourceData = jsonDecode(localData.response);
    } else {
      ApiResponse apiResponse = await productServiceInterface!.getHomeCategoryProductList();

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        sourceData = apiResponse.response!.data ?? [];

        // Save cache
        try {
          if (localData != null) {
            await database.updateCacheResponse(
              endUrl,
              CacheResponseCompanion(
                endPoint: Value(endUrl),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: Value(endUrl),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache update/insert error: $e");
        }
      } else {
        ApiChecker.checkApi(apiResponse);
        return;
      }
    }

    for (var homeCategoryJson in sourceData) {
      List<dynamic> productListJson = homeCategoryJson['products'] ?? [];

      List<Map<String, dynamic>> filteredProductJsons = [];

      for (var productJson in productListJson) {
        if (isLoggedIn) {
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

          // ✅ Allow admin products or governorate match
          if (productJson['added_by'] == 'admin') {
            filteredProductJsons.add(productJson as Map<String, dynamic>);
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              filteredProductJsons.add(productJson as Map<String, dynamic>);
            }
          }
        } else {
          // Not logged in
          filteredProductJsons.add(productJson as Map<String, dynamic>);
        }
      }

      if (filteredProductJsons.isNotEmpty) {
        homeCategoryJson['products'] = filteredProductJsons;
        _homeCategoryProductList.add(HomeCategoryProduct.fromJson(homeCategoryJson));
      }
    }

    notifyListeners();
  }

  MostDemandedProductModel? mostDemandedProductModel;
  Future<void> getMostDemandedProduct(BuildContext context) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    var localData = await database.getCacheResponseById(AppConstants.mostDemandedProduct);

    List<int> allowedGovernorateIds = isLoggedIn ? await getGovernates(context) ?? [] : [];

    if (localData != null) {
      Map<String, dynamic> jsonData = jsonDecode(localData.response);

      if (jsonData['products'] != null) {
        List<dynamic> productsData = jsonData['products'];
        List<dynamic> filteredProducts = [];

        for (var productJson in productsData) {
          if (!isLoggedIn) {
            filteredProducts.add(productJson);
          } else {
            List<int> productGovernorates = [];

            if (productJson['governorates'] != null) {
              productGovernorates = (productJson['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            } else if (productJson['seller'] != null && productJson['seller']['governorates'] != null) {
              productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            }

            if (productJson['added_by'] == 'admin' ||
                productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
              filteredProducts.add(productJson);
            }
          }
        }

        jsonData['products'] = filteredProducts;
      }

      mostDemandedProductModel = MostDemandedProductModel.fromJson(jsonData);
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getMostDemandedProduct();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var responseData = apiResponse.response!.data;

      if (responseData != null && responseData.isNotEmpty && responseData != '[]') {
        Map<String, dynamic> jsonData = Map<String, dynamic>.from(responseData);
        List<dynamic> productsData = jsonData['products'] ?? [];
        List<dynamic> filteredProducts = [];

        for (var productJson in productsData) {
          if (!isLoggedIn) {
            filteredProducts.add(productJson);
          } else {
            List<int> productGovernorates = [];

            if (productJson['governorates'] != null) {
              productGovernorates = (productJson['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            } else if (productJson['seller'] != null && productJson['seller']['governorates'] != null) {
              productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
                  .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                  .where((id) => id != -1)
                  .toList();
            }

            if (productJson['added_by'] == 'admin' ||
                productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
              filteredProducts.add(productJson);
            }
          }
        }

        jsonData['products'] = filteredProducts;
        mostDemandedProductModel = MostDemandedProductModel.fromJson(jsonData);

        try {
          if (localData != null) {
            await database.updateCacheResponse(
              AppConstants.mostDemandedProduct,
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.mostDemandedProduct),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.mostDemandedProduct),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } catch (e) {
          print("Cache update/insert error: $e");
        }
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }

  FindWhatYouNeedModel? findWhatYouNeedModel;
  Future<void> findWhatYouNeed(BuildContext context) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    List<int> allowedGovernorateIds = isLoggedIn ? await getGovernates(context) ?? [] : [];

    var localData = await database.getCacheResponseById(AppConstants.findWhatYouNeed);

    if (localData != null) {
      Map<String, dynamic> jsonData = jsonDecode(localData.response);

      if (jsonData['products'] != null) {
        List<dynamic> productsData = jsonData['products'];
        List<dynamic> filteredProducts = [];

        for (var productJson in productsData) {
          if (!isLoggedIn) {
            filteredProducts.add(productJson);
            continue;
          }

          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            productGovernorates = (productJson['governorates'] as List<dynamic>)
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null && productJson['seller']['governorates'] != null) {
            productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          if (productJson['added_by'] == 'admin' ||
              productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
            filteredProducts.add(productJson);
          }
        }

        jsonData['products'] = filteredProducts;
      }

      findWhatYouNeedModel = FindWhatYouNeedModel.fromJson(jsonData);
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getFindWhatYouNeed();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map<String, dynamic> jsonData = apiResponse.response!.data;

      if (jsonData['products'] != null) {
        List<dynamic> productsData = jsonData['products'];
        List<dynamic> filteredProducts = [];

        for (var productJson in productsData) {
          if (!isLoggedIn) {
            filteredProducts.add(productJson);
            continue;
          }

          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            productGovernorates = (productJson['governorates'] as List<dynamic>)
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null && productJson['seller']['governorates'] != null) {
            productGovernorates = (productJson['seller']['governorates'] as List<dynamic>)
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          if (productJson['added_by'] == 'admin' ||
              productGovernorates.any((id) => allowedGovernorateIds.contains(id))) {
            filteredProducts.add(productJson);
          }
        }

        jsonData['products'] = filteredProducts;
      }

      findWhatYouNeedModel = FindWhatYouNeedModel.fromJson(jsonData);

      if (localData != null) {
        await database.updateCacheResponse(
          AppConstants.findWhatYouNeed,
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.findWhatYouNeed),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.findWhatYouNeed),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }


  List<Product>? justForYouProduct;
  Future<void> getJustForYouProduct(BuildContext context) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    var localData = await database.getCacheResponseById(AppConstants.justForYou);

    List<int> allowedGovernorateIds = await getGovernates(context);

    // Handle cache
    if (localData != null) {
      var decodedList = jsonDecode(localData.response) as List<dynamic>;

      justForYouProduct = [];

      for (var productJson in decodedList) {
        if (isLoggedIn) {
          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            justForYouProduct?.add(Product.fromJson(productJson));
            continue;
          }

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

          bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
          if (matches) {
            justForYouProduct?.add(Product.fromJson(productJson));
          }
        } else {
          justForYouProduct?.add(Product.fromJson(productJson));
        }
      }

      notifyListeners();
    }

    justForYouProduct = [];

    ApiResponse apiResponse = await productServiceInterface!.getJustForYouProductList();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var dataList = apiResponse.response!.data as List<dynamic>;

      for (var productJson in dataList) {
        if (isLoggedIn) {
          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            justForYouProduct?.add(Product.fromJson(productJson));
            continue;
          }

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

          bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
          if (matches) {
            justForYouProduct?.add(Product.fromJson(productJson));
          }
        } else {
          justForYouProduct?.add(Product.fromJson(productJson));
        }
      }

      // Update or insert cache
      if (localData != null) {
        await database.updateCacheResponse(
          AppConstants.justForYou,
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.justForYou),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.justForYou),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }


  ProductModel? mostSearchingProduct;
  Future<void> getMostSearchingProduct(int offset, BuildContext context, {bool reload = false}) async {
    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
    var localData = await database.getCacheResponseById(AppConstants.mostSearching);

    List<int> allowedGovernorateIds = await getGovernates(context);

    if (localData != null) {
      var cachedData = jsonDecode(localData.response);
      List<dynamic> cachedProducts = cachedData['products'] ?? [];

      List<Product> filteredCachedProducts = [];

      for (var productJson in cachedProducts) {
        if (isLoggedIn) {
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

          if (productJson['added_by'] == 'admin') {
            filteredCachedProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) filteredCachedProducts.add(Product.fromJson(productJson));
          }
        } else {
          filteredCachedProducts.add(Product.fromJson(productJson));
        }
      }

      mostSearchingProduct = ProductModel(
        products: filteredCachedProducts,
        offset: cachedData['offset'],
        totalSize: cachedData['totalSize'],
      );

      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getMostSearchingProductList(offset);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var data = apiResponse.response!.data;
      List<dynamic> apiProducts = data['products'] ?? [];

      List<Product> filteredApiProducts = [];

      for (var productJson in apiProducts) {
        if (isLoggedIn) {
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

          if (productJson['added_by'] == 'admin') {
            filteredApiProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) filteredApiProducts.add(Product.fromJson(productJson));
          }
        } else {
          filteredApiProducts.add(Product.fromJson(productJson));
        }
      }

      if (offset == 1) {
        mostSearchingProduct = ProductModel(
          products: filteredApiProducts,
          offset: data['offset'],
          totalSize: data['totalSize'],
        );

        if (localData != null) {
          await database.updateCacheResponse(
            AppConstants.mostSearching,
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.mostSearching),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(data)),
            ),
          );
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.mostSearching),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(data)),
            ),
          );
        }
      } else {
        if (mostSearchingProduct != null) {
          mostSearchingProduct!.products!.addAll(filteredApiProducts);
          mostSearchingProduct!.offset = data['offset'] ?? mostSearchingProduct!.offset;
          mostSearchingProduct!.totalSize = data['totalSize'] ?? mostSearchingProduct!.totalSize;
        }
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }





  int currentJustForYouIndex = 0;
  void setCurrentJustForYourIndex(int index){
    currentJustForYouIndex = index;
    notifyListeners();
  }

  Future<void> getDiscountedProductList(int offset, BuildContext context, bool reload, { bool isUpdate = true }) async {
    if (reload) {
      _discountedProductModel = null;
      if (isUpdate) {
        notifyListeners();
      }
    }

    bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    // جلب قائمة المحافظات المسموح بها
    List<int> allowedGovernorateIds = await getGovernates(context);

    ApiResponse apiResponse = await productServiceInterface!.getFilteredProductList(
      context,
      offset.toString(),
      ProductType.discountedProduct,
      title,
    );

    if (apiResponse.response?.data != null && apiResponse.response?.statusCode == 200) {
      var data = apiResponse.response!.data;
      List<dynamic> apiProducts = data['products'] ?? [];

      List<Product> filteredProducts = [];

      for (var productJson in apiProducts) {
        if (isLoggedIn) {
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

          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            filteredProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              filteredProducts.add(Product.fromJson(productJson));
            }
          }
        } else {
          // Not logged in, show all products
          filteredProducts.add(Product.fromJson(productJson));
        }
      }

      if (offset == 1) {
        _discountedProductModel = ProductModel(
          products: filteredProducts,
          offset: data['offset'],
          totalSize: data['totalSize'],
        );
      } else {
        _discountedProductModel?.products?.addAll(filteredProducts);
        _discountedProductModel?.offset = data['offset'] ?? _discountedProductModel?.offset;
        _discountedProductModel?.totalSize = data['totalSize'] ?? _discountedProductModel?.totalSize;
      }

      notifyListeners();
    } else {
      ApiChecker.checkApi(apiResponse);
    }
  }






  ProductModel? clearanceProductModel;
  Future<void> getClearanceAllProductList(String offset, BuildContext context, {bool reload = false}) async {
    var localData = await database.getCacheResponseById(AppConstants.clearanceAllProductUri);

    if (localData != null) {
      clearanceProductModel = ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getClearanceAllProductList(offset);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var data = apiResponse.response!.data;
      List<dynamic> apiProducts = data['products'] ?? [];

      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

      // جلب قائمة المحافظات المسموح بها
      List<int> allowedGovernorateIds = await getGovernates(context);

      List<Product> filteredProducts = [];

      for (var productJson in apiProducts) {
        if (isLoggedIn) {
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

          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            filteredProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              filteredProducts.add(Product.fromJson(productJson));
            }
          }
        } else {
          // Not logged in, add all products without filtering
          filteredProducts.add(Product.fromJson(productJson));
        }
      }

      if (offset == '1') {
        clearanceProductModel = ProductModel(
          products: filteredProducts,
          offset: data['offset'],
          totalSize: data['totalSize'],
        );
      } else {
        clearanceProductModel?.products?.addAll(filteredProducts);
        clearanceProductModel?.offset = data['offset'] ?? clearanceProductModel?.offset;
        clearanceProductModel?.totalSize = data['totalSize'] ?? clearanceProductModel?.totalSize;
      }

      if (localData != null) {
        await database.updateCacheResponse(
          AppConstants.clearanceAllProductUri,
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.clearanceAllProductUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.clearanceAllProductUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    }

    notifyListeners();
  }






  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future<ApiResponse> getClearanceSearchProduct({
    required String query,
    String? categoryIds,
    String? brandIds,
    String? authorIds,
    String? publishingIds,
    String? sort,
    String? priceMin,
    String? priceMax,
    required int offset,
    String? productType,
    String offerType = 'clearance_sale',
    bool fromPaginantion = false,
    bool isNotify = true,
    required BuildContext context,
  }) async {
    if (!fromPaginantion && isNotify) {
      isSearchLoading = true;
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getClearanceSearchProducts(
      query,
      categoryIds,
      brandIds,
      authorIds,
      publishingIds,
      sort,
      priceMin,
      priceMax,
      offset,
      productType,
      offerType,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      var data = apiResponse.response!.data;
      List<dynamic> apiProducts = data['products'] ?? [];

      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
      List<Product> filteredProducts = [];

      if (isLoggedIn) {
        // جلب قائمة المحافظات المسموح بها
        List<int> allowedGovernorateIds = await getGovernates(context);

        for (var productJson in apiProducts) {
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

          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            filteredProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              filteredProducts.add(Product.fromJson(productJson));
            }
          }
        }
      } else {
        // لو مش مسجل دخول، اعرض كل المنتجات بدون فلترة
        filteredProducts = apiProducts.map<Product>((json) => Product.fromJson(json)).toList();
      }

      if (offset == 1) {
        clearanceSearchProductModel = ProductModel(
          products: filteredProducts,
          offset: data['offset'],
          totalSize: data['totalSize'],
        );
      } else {
        clearanceSearchProductModel?.products?.addAll(filteredProducts);
        clearanceSearchProductModel?.offset = data['offset'] ?? clearanceSearchProductModel?.offset;
        clearanceSearchProductModel?.totalSize = data['totalSize'] ?? clearanceSearchProductModel?.totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    isSearchLoading = false;
    notifyListeners();
    return apiResponse;
  }



  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    clearanceSearchProductModel = null;
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }


}

class ProductTypeModel{
  String? title;
  ProductType productType;

  ProductTypeModel(this.title, this.productType);
}

