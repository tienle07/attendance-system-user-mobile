class DropdownItem {
  int? id;
  String? name;

  DropdownItem({this.id, this.name});

  factory DropdownItem.fromJson(Map<String, dynamic> json) {
    return DropdownItem(
      id: json["id"],
      name: json["name"],
    );
  }
}
