class ApplicationRequestModel {
  int? storeId;
  List<int>? workShifts;

  ApplicationRequestModel({
    this.storeId,
    this.workShifts,
  });

  Map<String, dynamic> toJson() => {
        "storeId": storeId,
        "workShifts": List<dynamic>.from(workShifts!.map((x) => x)),
      };
}
