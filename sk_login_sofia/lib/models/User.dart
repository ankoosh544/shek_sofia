class User {
  String? username;
  String? firstName;
  String? lastName;
  bool? isPresident;
  bool? isDisablePeople;

  User({
    this.username,
    this.firstName,
    this.lastName,
    this.isPresident,
    this.isDisablePeople,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['Username'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      isPresident: json['IsPresident'],
      isDisablePeople: json['IsDisablePeople'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Username'] = this.username;
    data['FirstName'] = this.firstName;
    data['LastName'] = this.lastName;
    data['IsPresident'] = this.isPresident;
    data['IsDisablePeople'] = this.isDisablePeople;
    return data;
  }
}
