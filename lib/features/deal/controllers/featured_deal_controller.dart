import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/domain/services/featured_deal_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';

import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

import '../../profile/controllers/profile_contrroller.dart';
import '../../profile/domain/models/profile_model.dart';

class FeaturedDealController extends ChangeNotifier {
  final FeaturedDealServiceInterface featuredDealServiceInterface;
  FeaturedDealController({required this.featuredDealServiceInterface});

  int? _featuredDealSelectedIndex;
  List<Product>? _featuredDealProductList;
  List<Product>? get featuredDealProductList =>_featuredDealProductList;
  int? get featuredDealSelectedIndex => _featuredDealSelectedIndex;

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
  Future<void> getFeaturedDealList(bool reload, BuildContext context) async {
    var localData = await database.getCacheResponseById(AppConstants.featuredDealUri);

    // Load allowed governorates once
    List<int> allowedGovernorateIds = await getGovernates(context) ?? [];

    if (localData != null) {
      _featuredDealProductList = [];
      List<dynamic> cachedData = jsonDecode(localData.response);

      // Filter cached products by governorates
      List<Product> filteredCachedProducts = [];
      for (var productJson in cachedData) {
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
          filteredCachedProducts.add(Product.fromJson(productJson));
        }
      }

      _featuredDealProductList?.addAll(filteredCachedProducts);
      notifyListeners();
    }

    // Clear the list before fetching new data if reload requested
    if (reload) {
      _featuredDealProductList = [];
    }

    ApiResponse apiResponse = await featuredDealServiceInterface.getFeaturedDeal();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200 && apiResponse.response!.data.toString() != '{}') {
      List<dynamic> fetchedData = apiResponse.response!.data;

      // Filter fetched products by governorates
      List<Product> filteredFetchedProducts = [];
      for (var productJson in fetchedData) {
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
          filteredFetchedProducts.add(Product.fromJson(productJson));
        }
      }

      if (reload) {
        _featuredDealProductList = [];
      }

      _featuredDealProductList?.addAll(filteredFetchedProducts);
      _featuredDealSelectedIndex = 0;

      // Update cache with fresh data
      try {
        if (localData != null) {
          await database.updateCacheResponse(
            AppConstants.featuredDealUri,
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.featuredDealUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.featuredDealUri),
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
    }

    notifyListeners();
  }


  void changeSelectedIndex(int selectedIndex) {
    _featuredDealSelectedIndex = selectedIndex;
    notifyListeners();
  }
}
