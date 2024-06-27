class LeaveApplicationModel {
  int? id;
  int? brandId;
  int? storeId;
  int? timeFrameId;
  int? workShiftId;
  String? storeName;
  String? storeAddress;
  String? shiftName;
  DateTime? startTime;
  DateTime? endTime;
  int? employeeId;
  String? employeeName;
  bool? leaveRequest;
  DateTime? requestDate;
  String? requestNote;
  DateTime? approvalDate;
  String? approverName;
  String? responseNote;
  int? requestStatus;
  DateTime? checkIn;
  DateTime? checkOut;
  String? duration;
  int? processingStatus;

  LeaveApplicationModel({
    this.id,
    this.brandId,
    this.storeId,
    this.timeFrameId,
    this.workShiftId,
    this.storeName,
    this.storeAddress,
    this.shiftName,
    this.startTime,
    this.endTime,
    this.employeeId,
    this.employeeName,
    this.leaveRequest,
    this.requestDate,
    this.requestNote,
    this.approvalDate,
    this.approverName,
    this.responseNote,
    this.requestStatus,
    this.checkIn,
    this.checkOut,
    this.duration,
    this.processingStatus,
  });

  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) =>
      LeaveApplicationModel(
        id: json["id"],
        brandId: json["brandId"],
        storeId: json["storeId"],
        timeFrameId: json["timeFrameId"],
        workShiftId: json["workShiftId"],
        storeName: json["storeName"],
        storeAddress: json["storeAddress"],
        shiftName: json["shiftName"],
        startTime: json["startTime"] != null
            ? DateTime.tryParse(json["startTime"])
            : null,
        endTime:
            json["endTime"] != null ? DateTime.tryParse(json["endTime"]) : null,
        employeeId: json["employeeId"],
        employeeName: json["employeeName"],
        leaveRequest: json["leaveRequest"],
        requestDate: json["requestDate"] != null
            ? DateTime.parse(json["requestDate"])
            : null,
        requestNote: json["requestNote"],
        approvalDate: json["approvalDate"] != null
            ? DateTime.parse(json["approvalDate"])
            : null,
        approverName: json["approverName"],
        responseNote: json["responseNote"],
        requestStatus: json["requestStatus"],
        checkIn:
            json["checkIn"] != null ? DateTime.parse(json["checkIn"]) : null,
        checkOut:
            json["checkOut"] != null ? DateTime.parse(json["checkOut"]) : null,
        duration: json["duration"],
        processingStatus: json["processingStatus"],
      );
}
