import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/seller_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/shop_again_from_recent_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class SellerProductController extends ChangeNotifier {
  final SellerProductServiceInterface? sellerProductServiceInterface;
  SellerProductController({required this.sellerProductServiceInterface});


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
  ProductModel? sellerProduct;
  ProductModel? sellerMoreProduct;
  Future<ApiResponse> getSellerProductList(
      String sellerId,
      int offset,
      String productId, {
        required BuildContext context,
        bool reload = true,
        String search = '',
        String? categoryIds = '[]',
        String? brandIds = '[]',
        String? authorIds = '[]',
        String? publishingIds = '[]',
        String? productType = 'all',
      }) async {
    ApiResponse apiResponse = await sellerProductServiceInterface!.getSellerProductList(
      sellerId,
      offset.toString(),
      productId,
      categoryIds: categoryIds,
      brandIds: brandIds,
      search: search,
      authorIds: authorIds,
      publishingIds: publishingIds,
      productType: productType,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map<String, dynamic> jsonData = apiResponse.response!.data;
      List<dynamic> data = jsonData['products'] ?? [];

      List<Product> finalProducts = [];
      bool isLoggedIn = Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

      if (isLoggedIn) {
        List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

        for (var productJson in data) {
          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            var govList = productJson['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null &&
              productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          // ✅ Allow all admin products
          if (productJson['added_by'] == 'admin') {
            finalProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              finalProducts.add(Product.fromJson(productJson));
            }
          }
        }
      } else {
        // لو مش مسجل دخوله، رجّع كل المنتجات
        finalProducts = data.map((e) => Product.fromJson(e)).toList();
      }

      if (offset == 1) {
        sellerProduct = ProductModel(
          products: finalProducts,
          totalSize: jsonData['total_size'],
          limit: jsonData['limit'],
          offset: jsonData['offset'],
        );
      } else {
        sellerProduct?.products?.addAll(finalProducts);
        sellerProduct?.offset = jsonData['offset'];
        sellerProduct?.totalSize = jsonData['total_size'];
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
    return apiResponse;
  }




  Future<ApiResponse> getSellerMoreProductList(
      String sellerId,
      int offset,
      String productId,
      BuildContext context,
      ) async {
    sellerMoreProduct = null;

    ApiResponse apiResponse = await sellerProductServiceInterface!
        .getSellerProductList(sellerId, offset.toString(), productId);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {

      Map<String, dynamic> jsonData = apiResponse.response!.data;
      List<dynamic> data = jsonData['products'] ?? [];

      List<Product> finalProducts = [];

      bool isLoggedIn = Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

      if (isLoggedIn) {
        List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

        for (var productJson in data) {
          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            var govList = productJson['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null &&
              productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          // ✅ Allow admin products always
          if (productJson['added_by'] == 'admin') {
            finalProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any(
                    (id) => allowedGovernorateIds.contains(id));
            if (matches) {
              finalProducts.add(Product.fromJson(productJson));
            }
          }
        }
      } else {
        // مش مسجل دخوله -> رجع كل المنتجات
        finalProducts = data.map((e) => Product.fromJson(e)).toList();
      }

      if (offset == 1) {
        sellerMoreProduct = ProductModel(
          products: finalProducts,
          totalSize: jsonData['total_size'],
          limit: jsonData['limit'],
          offset: jsonData['offset'],
        );
      }

    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
    return apiResponse;
  }



  ProductModel? productModel;
  Future<void> getSellerWiseBestSellingProductList(String sellerId, int offset, BuildContext context) async {
    ApiResponse apiResponse = await sellerProductServiceInterface!
        .getSellerWiseBestSellingProductList(sellerId, offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map<String, dynamic> jsonData = apiResponse.response!.data;
      List<dynamic> data = jsonData['products'] ?? [];

      List<Product> finalProducts = [];

      bool isLoggedIn = Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

      if (isLoggedIn) {
        List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

        for (var productJson in data) {
          List<int> productGovernorates = [];

          if (productJson['governorates'] != null) {
            var govList = productJson['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          } else if (productJson['seller'] != null &&
              productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          // ✅ Allow admin-added products always
          if (productJson['added_by'] == 'admin') {
            finalProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              finalProducts.add(Product.fromJson(productJson));
            }
          }
        }
      } else {
        // المستخدم مش مسجل → نرجع كل المنتجات بدون فلترة
        finalProducts = data.map((e) => Product.fromJson(e)).toList();
      }

      if (offset == 1) {
        productModel = ProductModel(
          products: finalProducts,
          totalSize: jsonData['total_size'],
          limit: jsonData['limit'],
          offset: jsonData['offset'],
        );
      } else {
        productModel?.products?.addAll(finalProducts);
        productModel?.offset = jsonData['offset'];
        productModel?.totalSize = jsonData['total_size'];
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }




  ProductModel? sellerWiseFeaturedProduct;
  Future<void> getSellerWiseFeaturedProductList(String sellerId, int offset, BuildContext context) async {
    ApiResponse apiResponse = await sellerProductServiceInterface!
        .getSellerWiseFeaturedProductList(sellerId, offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map<String, dynamic> jsonData = apiResponse.response!.data;
      List<dynamic> data = jsonData['products'] ?? [];

      List<Product> finalProducts = [];

      bool isLoggedIn = Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();
      List<int> allowedGovernorateIds = [];

      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context) ?? [];
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
          } else if (productJson['seller'] != null &&
              productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            finalProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              finalProducts.add(Product.fromJson(productJson));
            }
          }
        } else {
          // Not logged in → add all
          finalProducts.add(Product.fromJson(productJson));
        }
      }

      if (offset == 1) {
        sellerWiseFeaturedProduct = ProductModel(
          products: finalProducts,
          totalSize: jsonData['total_size'],
          limit: jsonData['limit'],
          offset: jsonData['offset'],
        );
      } else {
        sellerWiseFeaturedProduct?.products?.addAll(finalProducts);
        sellerWiseFeaturedProduct?.offset = jsonData['offset'];
        sellerWiseFeaturedProduct?.totalSize = jsonData['total_size'];
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }



  ProductModel? sellerWiseRecommandedProduct;
  Future<void> getSellerWiseRecommandedProductList(String sellerId, int offset, BuildContext context) async {
    ApiResponse apiResponse = await sellerProductServiceInterface!
        .getSellerWiseRecomendedProductList(sellerId, offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map<String, dynamic> jsonData = apiResponse.response!.data;
      List<dynamic> data = jsonData['products'] ?? [];

      List<Product> finalProducts = [];

      bool isLoggedIn = Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();
      List<int> allowedGovernorateIds = [];

      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context) ?? [];
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
          } else if (productJson['seller'] != null &&
              productJson['seller']['governorates'] != null) {
            var govList = productJson['seller']['governorates'] as List<dynamic>;
            productGovernorates = govList
                .map<int>((g) => int.tryParse(g['id'].toString()) ?? -1)
                .where((id) => id != -1)
                .toList();
          }

          // ✅ Always allow admin-added products
          if (productJson['added_by'] == 'admin') {
            finalProducts.add(Product.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              finalProducts.add(Product.fromJson(productJson));
            }
          }
        } else {
          // Not logged in, allow all
          finalProducts.add(Product.fromJson(productJson));
        }
      }

      if (offset == 1) {
        sellerWiseRecommandedProduct = ProductModel(
          products: finalProducts,
          totalSize: jsonData['total_size'],
          limit: jsonData['limit'],
          offset: jsonData['offset'],
        );
      } else {
        sellerWiseRecommandedProduct?.products?.addAll(finalProducts);
        sellerWiseRecommandedProduct?.offset = jsonData['offset'];
        sellerWiseRecommandedProduct?.totalSize = jsonData['total_size'];
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }




  List<ShopAgainFromRecentStoreModel> shopAgainFromRecentStoreList = [];
  Future<void> getShopAgainFromRecentStore(BuildContext context) async {
    List<ShopAgainFromRecentStoreModel> shopAgainFromRecentStoreList = [];

    var localData = await database.getCacheResponseById(AppConstants.shopAgainFromRecentStore);

    if (localData != null) {
      var cachedList = jsonDecode(localData.response) as List<dynamic>;
      shopAgainFromRecentStoreList = cachedList
          .map((store) => ShopAgainFromRecentStoreModel.fromJson(store))
          .toList();
      notifyListeners();
    }

    ApiResponse apiResponse = await sellerProductServiceInterface!.getShopAgainFromRecentStoreList();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      List<dynamic> data = apiResponse.response!.data;

      bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
      List<ShopAgainFromRecentStoreModel> filteredList = [];

      List<int> allowedGovernorateIds = [];
      if (isLoggedIn) {
        allowedGovernorateIds = await getGovernates(context) ?? [];
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
            filteredList.add(ShopAgainFromRecentStoreModel.fromJson(productJson));
          } else {
            bool matches = productGovernorates.any((id) => allowedGovernorateIds.contains(id));
            if (matches) {
              filteredList.add(ShopAgainFromRecentStoreModel.fromJson(productJson));
            }
          }
        } else {
          // Not logged in, add all
          filteredList.add(ShopAgainFromRecentStoreModel.fromJson(productJson));
        }
      }

      shopAgainFromRecentStoreList.addAll(filteredList);

      // تحديث الكاش
      if (localData != null) {
        await database.updateCacheResponse(
            AppConstants.shopAgainFromRecentStore,
            CacheResponseCompanion(
              endPoint: Value(AppConstants.shopAgainFromRecentStore),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: Value(AppConstants.shopAgainFromRecentStore),
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






  void clearSellerProducts() {
    sellerWiseFeaturedProduct = null;
    sellerWiseRecommandedProduct = null;
  }

}

