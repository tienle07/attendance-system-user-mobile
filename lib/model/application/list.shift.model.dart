class ShiftApplicationModel {
  int? id;
  int? employeeId;
  String? employeeName;
  int? storeId;
  int? workShiftId;
  int? positionId;
  String? shiftName;
  DateTime? startTime;
  DateTime? endTime;
  String? note;
  DateTime? registerDate;
  int? registerBy;
  DateTime? updateDate;
  int? updateBy;
  DateTime? approvalDate;
  int? approverId;
  int? status;

  ShiftApplicationModel({
    this.id,
    this.employeeId,
    this.employeeName,
    this.storeId,
    this.workShiftId,
    this.positionId,
    this.shiftName,
    this.startTime,
    this.endTime,
    this.note,
    this.registerDate,
    this.registerBy,
    this.updateDate,
    this.updateBy,
    this.approvalDate,
    this.approverId,
    this.status,
  });

  factory ShiftApplicationModel.fromJson(Map<String, dynamic> json) =>
      ShiftApplicationModel(
        id: json["id"],
        employeeId: json["employeeId"],
        employeeName: json["employeeName"],
        storeId: json["storeId"],
        workShiftId: json["workShiftId"],
        positionId: json["positionId"],
        shiftName: json["shiftName"],
        startTime: json["startTime"] != null
            ? DateTime.parse(json["startTime"])
            : null,
        endTime:
            json["endTime"] != null ? DateTime.parse(json["endTime"]) : null,
        note: json["note"],
        registerDate: json["registerDate"] != null
            ? DateTime.parse(json["registerDate"])
            : null,
        registerBy: json["registerBy"],
        updateDate: json["updateDate"] != null
            ? DateTime.parse(json["updateDate"])
            : null,
        updateBy: json["updateBy"],
        approvalDate: json["approvalDate"] != null
            ? DateTime.parse(json["approvalDate"])
            : null,
        approverId: json["approverId"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "employeeId": employeeId,
        "employeeName": employeeName,
        "storeId": storeId,
        "workShiftId": workShiftId,
        "positionId": positionId,
        "shiftName": shiftName,
        "startTime": startTime?.toIso8601String(),
        "endTime": endTime?.toIso8601String(),
        "note": note,
        "registerDate": registerDate?.toIso8601String(),
        "registerBy": registerBy,
        "updateDate": updateDate,
        "updateBy": updateBy,
        "approvalDate": approvalDate?.toIso8601String(),
        "approverId": approverId,
        "status": status,
      };
}
