class ShiftPosition {
  int? id;
  int? shiftId;
  int? positionId;
  int? quantity;
  int? available;

  ShiftPosition({
    this.id,
    this.shiftId,
    this.positionId,
    this.quantity,
    this.available,
  });

  factory ShiftPosition.fromJson(Map<String, dynamic> json) => ShiftPosition(
        id: json["id"],
        shiftId: json["shiftId"],
        positionId: json["positionId"],
        quantity: json["quantity"],
        available: json["available"],
      );
}
