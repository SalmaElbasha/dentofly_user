class SuggestionModel {
  List<Products>? products;

  SuggestionModel({this.products});

  SuggestionModel.fromJson(Map<String, dynamic> json) {
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(Products.fromJson(v));
      });
    }
  }
}

class Products {
  int? id;
  String? name;
  List<Seller>? seller; // ⬅️ أضفنا الـ sellers هنا

  Products({this.id, this.name, this.seller});

  Products.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['seller'] != null) {
      seller = <Seller>[];
      json['seller'].forEach((v) {
        seller!.add(Seller.fromJson(v));
      });
    }
  }
}

class Seller {
  int? id;
  String? name;
  String? note;
  String? minShippingCost;
  String? createdAt;
  String? updatedAt;
  Pivot? pivot;

  Seller({
    this.id,
    this.name,
    this.note,
    this.minShippingCost,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  Seller.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    note = json['note'];
    minShippingCost = json['min_shipping_cost'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }
}

class Pivot {
  int? sellerId;
  int? governorateId;

  Pivot({this.sellerId, this.governorateId});

  Pivot.fromJson(Map<String, dynamic> json) {
    sellerId = json['seller_id'];
    governorateId = json['governorate_id'];
  }
}
