class Messages {
  int id;
  String description;
  int typeDesc;
  String addByUser;
  String files;
  String gLocationLat;
  String gLocationLong;
  String createdAt;
  String timedAt;

  Messages(
      {this.id,
      this.description,
      this.typeDesc,
      this.addByUser,
      this.files,
      this.gLocationLat,
      this.gLocationLong,
      this.createdAt,
      this.timedAt});

  Messages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    description = json['description'];
    typeDesc = json['type_desc'];
    addByUser = json['add_by_user'];
    files = json['files'];
    gLocationLat = json['g_location_lat'];
    gLocationLong = json['g_location_long'];
    createdAt = json['created_at'];
    timedAt = json['timed_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['description'] = this.description;
    data['type_desc'] = this.typeDesc;
    data['add_by_user'] = this.addByUser;
    data['files'] = this.files;
    data['g_location_lat'] = this.gLocationLat;
    data['g_location_long'] = this.gLocationLong;
    data['created_at'] = this.createdAt;
    data['timed_at'] = this.timedAt;
    return data;
  }
}
