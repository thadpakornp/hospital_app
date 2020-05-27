import 'dart:async';

import 'package:http/http.dart' as http;

class ApiProvider {
  ApiProvider();

  String endPoint = 'https://suratstroke.com/api/v1';

  Future<http.Response> getID(String token) async {
    String _url = '$endPoint/users/id';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };

    return http.post(_url, headers: headers);
  }

  Future<http.Response> checkToken(String token) async {
    String _url = '$endPoint/users/token';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };

    return http.post(_url, headers: headers);
  }

  Future<http.Response> doForget(String username) async {
    String _url = '$endPoint/forget';
    var body = {
      'email': '$username',
    };
    return http.post(_url, body: body);
  }

  Future<http.Response> doLogin(
      String username, String password, String device_token) async {
    String _url = '$endPoint/login';
    var body = {
      'email': '$username',
      'password': '$password',
      'device_token': '$device_token',
    };

    return http.post(_url, body: body);
  }

  Future<http.Response> doLogout(String token) async {
    String _url = '$endPoint/logout';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };

    return http.post(_url, headers: headers);
  }

  Future<http.Response> getCharts(String token, String status) async {
    String _url = '$endPoint/charts/index/$status';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    return http.get(_url, headers: headers);
  }

  Future<http.Response> getChats(String token) async {
    String _url = '$endPoint/charts/chats';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    return http.get(_url, headers: headers);
  }

  Future<http.Response> uploadWithOutFile(
      String token, String description, String lat, String lng) async {
    String _url = '$endPoint/charts/uploaded';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      "g_location_lat": lat == null ? null : lat.toString(),
      "g_location_long": lng == null ? null : lng.toString(),
      "description": description,
      "type_charts": '1'
    };
    return http.post(_url, headers: headers, body: bodys);
  }

  Future<http.Response> uploadWithOutFileByID(
      String token, String description, int id, String lat, String lng) async {
    String _url = '$endPoint/charts/stored';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      "id": '$id',
      "description": description,
      "g_location_lat": lat == null ? null : lat.toString(),
      "g_location_long": lng == null ? null : lng.toString(),
    };
    return http.post(_url, headers: headers, body: bodys);
  }

  Future<http.Response> getChartsByID(String token, int id) async {
    String _url = '$endPoint/charts/descriptions';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'charts_id': '$id',
    };
    return http.post(_url, body: bodys, headers: headers);
  }

  Future<http.Response> getFile(String token, int id) async {
    String _url = '$endPoint/charts/files';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'charts_desc_id': '$id',
    };
    return http.post(_url, body: bodys, headers: headers);
  }

  Future<http.Response> successCharts(String token, int id) async {
    String _url = '$endPoint/charts/descriptions/success';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'id': '$id',
    };
    return http.post(_url, body: bodys, headers: headers);
  }

  Future<http.Response> deletedCharts(String token, int id) async {
    String _url = '$endPoint/charts/descriptions/deleted';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'id': '$id',
    };
    return http.post(_url, body: bodys, headers: headers);
  }

  Future<http.Response> getProfile(String token) async {
    String _url = '$endPoint/users/profile';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    return http.get(_url, headers: headers);
  }

  Future<http.Response> getPrefix() async {
    String _url = '$endPoint/prefix';

    return http.get(_url);
  }

  Future<http.Response> sendNotifyToWeb(String token) async {
    String _url = '$endPoint/charts/stw';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    return http.get(_url, headers: headers);
  }

  Future<http.Response> sendNotifyToWebAndMobile(String token, int id) async {
    String _url = '$endPoint/charts/stwsb';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'id': '$id',
    };
    return http.post(_url, body: bodys, headers: headers);
  }

  Future<http.Response> changePassword(String token, String oldPassword,
      String newPassword1, String newPassword2) async {
    String _url = '$endPoint/users/password';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      'oldPassword': '$oldPassword',
      'newPassword1': '$newPassword1',
      'newPassword2': '$newPassword2',
    };
    return http.post(_url, body: bodys, headers: headers);
  }
}
