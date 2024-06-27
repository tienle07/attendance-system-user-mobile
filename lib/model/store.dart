class StoreLocation {
  int? id;
  int? companyId;
  String? address;
  double? latitude;
  double? longitude;
  String? bssid;
  bool? active;

  StoreLocation(
      {this.id,
      this.companyId,
      this.address,
      this.latitude,
      this.longitude,
      this.bssid,
      this.active});

  StoreLocation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['companyId'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    bssid = json['bssid'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['companyId'] = this.companyId;
    data['address'] = this.address;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['bssid'] = this.bssid;
    data['active'] = this.active;
    return data;
  }
}