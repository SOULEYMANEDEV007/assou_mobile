import 'dart:convert';
//import 'package:ASSOU/pages/services/envoyerbon_service.dart';

MesBonModel mesBonModelFromJson(String str) =>
    MesBonModel.fromJson(json.decode(str));

String mesBonModelToJson(MesBonModel data) => json.encode(data.toJson());

class MesBonModel {
  String contact;
  String idBonAchat;
  String message;

  MesBonModel({
    required this.contact,
    required this.idBonAchat,
    required this.message,
  });

  factory MesBonModel.fromJson(Map<String, dynamic> json) => MesBonModel(
        contact: json["contact"],
        idBonAchat: json["id_bon_achat"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "contact": contact,
        "id_bon_achat": idBonAchat,
        "message": message,
      };
}
