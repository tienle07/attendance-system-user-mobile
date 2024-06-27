class EmployeeShiftModel {
  WorkShift? workShift;

  EmployeeShiftModel({
    this.workShift,
  });

  factory EmployeeShiftModel.fromJson(Map<String, dynamic> json) =>
      EmployeeShiftModel(
        workShift: WorkShift.fromJson(json["workShift"]),
      );
}

class WorkShift {
  int? id;
  int? workScheduleId;
  int? holidayId;
  String? shiftName;
  DateTime? startTime;
  DateTime? endTime;
  bool? isSplitShift;
  int? status;

  WorkShift({
    this.id,
    this.workScheduleId,
    this.holidayId,
    this.shiftName,
    this.startTime,
    this.endTime,
    this.isSplitShift,
    this.status,
  });

  factory WorkShift.fromJson(Map<String, dynamic> json) => WorkShift(
        id: json["id"],
        workScheduleId: json["workScheduleId"],
        holidayId: json["holidayId"],
        shiftName: json["shiftName"],
        startTime: DateTime.parse(json["startTime"]),
        endTime: DateTime.parse(json["endTime"]),
        isSplitShift: json["isSplitShift"],
        status: json["status"],
      );
}
