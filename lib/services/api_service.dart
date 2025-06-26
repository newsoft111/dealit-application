import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couphago_frontend/models/hotdeal.dart';
import 'package:couphago_frontend/models/category.dart';

class ApiService {
  static const String baseUrl = 'http://your-api-domain.com/api'; // 실제 API 도메인으로 변경

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
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hotdeals': (data['hotdeals'] as List)
              .map((json) => Hotdeal.fromJson(json))
              .toList(),
          'totalPages': data['totalPages'],
        };
      } else {
        throw Exception('Failed to load hotdeals');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Hotdeal> fetchHotdeal(int hotdealId) async {
    final uri = Uri.parse('$baseUrl/hotdeal').replace(
      queryParameters: {'hotdeal_id': hotdealId.toString()},
    );
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Hotdeal.fromJson(data);
      } else {
        throw Exception('Failed to load hotdeal');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/categories');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['categories'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}