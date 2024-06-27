class DetailsStoreModel {
  int? id;
  int? brandId;
  String? storeName;
  String? storeManager;
  DateTime? createDate;
  String? address;
  String? openTime;
  String? closeTime;
  bool? active;

  DetailsStoreModel({
    this.id,
    this.brandId,
    this.storeName,
    this.storeManager,
    this.createDate,
    this.address,
    this.openTime,
    this.closeTime,
    this.active,
  });

  factory DetailsStoreModel.fromJson(Map<String, dynamic> json) =>
      DetailsStoreModel(
        id: json["id"],
        brandId: json["brandId"],
        storeName: json["storeName"],
        storeManager: json["storeManager"],
        createDate: DateTime.parse(json["createDate"]),
        address: json["address"],
        openTime: json["openTime"],
        closeTime: json["closeTime"],
        active: json["active"],
      );
}
