// To parse this JSON data, do
//
//     final serviceFees = serviceFeesFromJson(jsonString);

import 'dart:convert';

ServiceFees serviceFeesFromJson(String str) {
  final jsonData = json.decode(str);
  return ServiceFees.fromJson(jsonData);
}

String serviceFeesToJson(ServiceFees data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class ServiceFees {
  String? serviceFee;

  ServiceFees({
    this.serviceFee,
  });

  factory ServiceFees.fromJson(Map<String, dynamic> json) => new ServiceFees(
    serviceFee: json["service_fee"] == null ? null : json["service_fee"],
  );

  Map<String, dynamic> toJson() => {
    "service_fee": serviceFee == null ? null : serviceFee,
  };
}
