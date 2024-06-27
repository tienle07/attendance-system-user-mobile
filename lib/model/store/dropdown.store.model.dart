class DropdownStore {
  int? storeId;
  String? storeName;
  int? status;

  DropdownStore({
    this.storeId,
    this.storeName,
    this.status,
  });

  factory DropdownStore.fromJson(Map<String, dynamic> json) => DropdownStore(
        storeId: json["storeId"],
        storeName: json["storeName"],
        status: json["status"],
      );
}
