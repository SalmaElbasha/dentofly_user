// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Governates governatesFromJson(String str) {
  final jsonData = json.decode(str);
  return Governates.fromJson(jsonData);
}

String governatesToJson(Governates data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Governates {
  List<Datum>? data;

  Governates({
    this.data,
  });

  factory Governates.fromJson(Map<String, dynamic> json) => Governates(
    data: json["data"] == null ? null : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "data": data?.map((x) => x.toJson()).toList(),

  };
}

class Datum {
  int? id;
  String? name;
  String? note;
  String? minShippingCost;
  List<DeliveryCenter>? deliveryCenters;
  List<DeliveryTime>? deliveryTimes;

  Datum({
    this.id,
    this.name,
    this.note,
    this.minShippingCost,
    this.deliveryCenters,
    this.deliveryTimes,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    name: json["name"],
    note: json["note"],
    minShippingCost: json["min_shipping_cost"],
    deliveryCenters: json["delivery_centers"] == null ? null : List<DeliveryCenter>.from(json["delivery_centers"].map((x) => DeliveryCenter.fromJson(x))),
    deliveryTimes: json["delivery_times"] == null ? null : List<DeliveryTime>.from(json["delivery_times"].map((x) => DeliveryTime.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "note": note,
    "min_shipping_cost": minShippingCost,
    "delivery_centers": deliveryCenters?.map((x) => x.toJson()).toList(),
    "delivery_times": deliveryTimes?.map((x) => x.toJson()).toList(),

  };
}

class DeliveryCenter {
  int? id;
  String? name;
  String? latitude;
  String? longitude;
  String? pricePerKg;
  int? maxDistanceKm;

  DeliveryCenter({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.pricePerKg,
    this.maxDistanceKm,
  });

  factory DeliveryCenter.fromJson(Map<String, dynamic> json) => DeliveryCenter(
    id: json["id"],
    name: json["name"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    pricePerKg: json["price_per_kg"],
    maxDistanceKm: json["max_distance_km"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "latitude": latitude,
    "longitude": longitude,
    "price_per_kg": pricePerKg,
    "max_distance_km": maxDistanceKm,
  };
}

class DeliveryTime {
  int? id;
  String? startTime;
  String? endTime;

  DeliveryTime({
    this.id,
    this.startTime,
    this.endTime,
  });

  factory DeliveryTime.fromJson(Map<String, dynamic> json) => DeliveryTime(
    id: json["id"],
    startTime: json["start_time"],
    endTime: json["end_time"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "start_time": startTime,
    "end_time": endTime,
  };
}
