import 'dart:async';

import 'package:hospitalapp/resources/getPrefix.dart';
import 'package:http/http.dart' as http;

class ApiProvider {
  ApiProvider();

  String endPoint = 'http://192.168.101.61/api/v1';

  Future<http.Response> doLogin(String username, String password) async {
    String _url = '$endPoint/login';
    var body = {
      'email': username,
      'password': password,
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

  Future<http.Response> getCharts(String token) async {
    String _url = '$endPoint/charts/index';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    return http.get(_url, headers: headers);
  }

  Future<http.Response> uploadWithOutFile(
      String token, String description) async {
    String _url = '$endPoint/charts/uploaded';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      "description": description,
    };
    return http.post(_url, headers: headers, body: bodys);
  }

  Future<http.Response> uploadWithOutFileByID(
      String token, String description, int id) async {
    String _url = '$endPoint/charts/stored';
    var headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    };
    var bodys = {
      "id": '$id',
      "description": description,
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

  Future<http.Response> getProfix() async {
    String _url = '$endPoint/prefix';

    return http.get(_url);
  }
}
