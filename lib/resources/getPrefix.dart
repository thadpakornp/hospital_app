class get_Profix {
  final String code;
  final String name;
  const get_Profix({this.code, this.name});
  factory get_Profix.fromJSON(Map<String, dynamic> json) {
    return get_Profix(
      code: json['code'],
      name: json['name'],
    );
  }
}
