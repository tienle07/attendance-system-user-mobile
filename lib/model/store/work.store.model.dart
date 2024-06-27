class WorkStoreModel {
  int? id;
  int? storeId;
  String? storeName;
  int? employeeId;
  String? employeeName;
  int? positionId;
  String? positionName;
  int? typeId;
  String? typeName;
  DateTime? assignedDate;
  int? status;

  WorkStoreModel({
    this.id,
    this.storeId,
    this.storeName,
    this.employeeId,
    this.employeeName,
    this.positionId,
    this.positionName,
    this.typeId,
    this.typeName,
    this.assignedDate,
    this.status,
  });

  factory WorkStoreModel.fromJson(Map<String, dynamic> json) => WorkStoreModel(
        id: json["id"],
        storeId: json["storeId"],
        storeName: json["storeName"],
        employeeId: json["employeeId"],
        employeeName: json["employeeName"],
        positionId: json["positionId"],
        positionName: json["positionName"],
        typeId: json["typeId"],
        typeName: json["typeName"],
        assignedDate: DateTime.parse(json["assignedDate"]),
        status: json["status"],
      );
}
