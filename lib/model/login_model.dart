class LoginModel {
  Account? account;
  Token? token;

  LoginModel({this.account, this.token});

  LoginModel.fromJson(Map<String, dynamic> json) {
    account =
        json['account'] != null ? Account.fromJson(json['account']) : null;
    token = json['token'] != null ? Token.fromJson(json['token']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (account != null) {
      data['account'] = account!.toJson();
    }
    if (token != null) {
      data['token'] = token!.toJson();
    }
    return data;
  }
}

class Account {
  int? id;
  String? username;
  int? employeeId;
  int? roleId;
  String? roleName;
  int? brandId;
  String? brandName;
  bool? active;

  Account(
      {this.id,
      this.username,
      this.employeeId,
      this.roleId,
      this.roleName,
      this.brandId,
      this.brandName,
      this.active});

  Account.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    employeeId = json['employeeId'];
    roleId = json['roleId'];
    roleName = json['roleName'];
    brandId = json['brandId'];
    brandName = json['brandName'];

    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = id;
    data['username'] = username;
    data['employeeId'] = employeeId;
    data['roleId'] = roleId;
    data['roleName'] = roleName;
    data['brandId'] = brandId;
    data['brandName'] = brandName;
    data['active'] = active;
    return data;
  }
}

class Token {
  String? accessToken;
  String? refreshToken;

  Token({this.accessToken, this.refreshToken});

  Token.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    return data;
  }
}
