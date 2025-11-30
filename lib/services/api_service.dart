import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';
import '../models/service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080'; // БЕЗ /api!

  // Пациенты
  static Future<List<Patient>> getPatients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }

  static Future<void> deletePatient(int medicalCardId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/patients/$medicalCardId'),
      );
      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при удалении пациента: $e');
    }
  }

  // Услуги
  static Future<List<Service>> getServices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/services'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          return Service.fromJson(json);
        }).toList();
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка подключения при получении услуг: $e');
      throw Exception('Ошибка подключения: $e');
    }
  }

  static Future<Service> addService(Service service) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/services'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(service.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Service.fromJson({...service.toJson(), 'service_id': data['service_id']});
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Ошибка сервера: ${response.statusCode} - ${errorData['error']}');
      }
    } catch (e) {
      print('❌ Ошибка при добавлении услуги: $e');
      throw Exception('Ошибка при добавлении услуги: $e');
    }
  }

  static Future<void> updateService(Service service) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/services/${service.serviceId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(service.toJson()),
      );
      
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Ошибка сервера: ${response.statusCode} - ${errorData['error']}');
      }
    } catch (e) {
      print('❌ Ошибка при обновлении услуги: $e');
      throw Exception('Ошибка при обновлении услуги: $e');
    }
  }

  static Future<void> deleteService(int serviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/services/$serviceId'),
      );
      
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Ошибка сервера: ${response.statusCode} - ${errorData['error']}');
      }
    } catch (e) {
      print('❌ Ошибка при удалении услуги: $e');
      throw Exception('Ошибка при удалении услуги: $e');
    }
  }
}