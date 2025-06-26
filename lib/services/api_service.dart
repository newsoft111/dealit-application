import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dealit_app/models/hotdeal.dart';
import 'package:dealit_app/models/category.dart' as models;

class ApiService {
  static const String baseUrl = 'https://api.dealit.shop/api/v1'; // 실제 API 도메인으로 변경

  static Future<Map<String, dynamic>> fetchHotdeals({
    int? categoryId,
    int page = 1,
    int perPage = 30,
  }) async {
    final queryParameters = <String, String>{};
    if (categoryId != null) {
      queryParameters['category_id'] = categoryId.toString();
    }
    queryParameters['page'] = page.toString();
    queryParameters['per_page'] = perPage.toString();

    final uri = Uri.parse('$baseUrl/hotdeals').replace(queryParameters: queryParameters);
    
    print('Fetching hotdeals from: $uri');
    
    try {
      final response = await http.get(uri);
      print('Hotdeals response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hotdeals': (data['hotdeals'] as List)
              .map((json) => Hotdeal.fromJson(json))
              .toList(),
          'totalPages': data['totalPages'],
        };
      } else {
        throw Exception('Failed to load hotdeals: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchHotdeals: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Hotdeal> fetchHotdeal(int hotdealId) async {
    final uri = Uri.parse('$baseUrl/hotdeals?hotdeal_id=$hotdealId');
    
    print('Fetching hotdeal detail from: $uri');
    
    try {
      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // API가 핫딜 목록을 반환하므로 해당 ID의 핫딜을 찾음
        if (data['hotdeals'] != null) {
          final hotdeals = data['hotdeals'] as List;
          final targetHotdeal = hotdeals.firstWhere(
            (hotdeal) => hotdeal['id'] == hotdealId,
            orElse: () => throw Exception('Hotdeal with ID $hotdealId not found'),
          );
          return Hotdeal.fromJson(targetHotdeal);
        } else {
          // 단일 핫딜 응답인 경우
          return Hotdeal.fromJson(data);
        }
      } else {
        throw Exception('Failed to load hotdeal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in fetchHotdeal: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<List<models.Category>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/product-categories');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['categories'] as List)
            .map((json) => models.Category.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}