import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

class ServiceHandler {
  final Router _router = Router();

  ServiceHandler() {
    _setupRoutes();
  }

  void _setupRoutes() {
    // Получить все услуги
    _router.get('/services', _getServices);
    
    // Добавить услугу
    _router.post('/services', _addService);
    
    // Обновить услугу
    _router.put('/services/<id>', _updateService);
    
    // Удалить услугу
    _router.delete('/services/<id>', _deleteService);
    
    // Сброс ID последовательности
    _router.post('/services/reset-sequence', _resetSequence);
  }

  // Получить все услуги
  Future<Response> _getServices(Request request) async {
    try {
      final result = await Database.connection.query('''
        SELECT service_id, name, price, is_available 
        FROM "Услуга" 
        ORDER BY service_id
      ''');

      final services = result.map((row) {
        // Безопасное преобразование типов
        dynamic price = row[2];
        if (price is String) {
          price = double.tryParse(price) ?? 0.0;
        } else if (price is int) {
          price = price.toDouble();
        }

        dynamic isAvailable = row[3];
        if (isAvailable is String) {
          isAvailable = isAvailable.toLowerCase() == 'true';
        }

        return {
          'service_id': row[0],
          'name': row[1],
          'price': price,
          'is_available': isAvailable,
        };
      }).toList();

      return Response.ok(
        json.encode(services),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      print('❌ Ошибка при получении услуг: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при получении услуг: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Добавить услугу
  Future<Response> _addService(Request request) async {
    try {
      final body = await request.readAsString();
      final serviceData = json.decode(body) as Map<String, dynamic>;

      print('📥 Получены данные для создания услуги: $serviceData');

      // Валидация
      if (serviceData['name'] == null || serviceData['name'].toString().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Название услуги обязательно'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      // Безопасное преобразование цены
      dynamic price = serviceData['price'] ?? 0.0;
      if (price is String) {
        price = double.tryParse(price) ?? 0.0;
      }

      // Безопасное преобразование доступности
      dynamic isAvailable = serviceData['is_available'] ?? true;
      if (isAvailable is String) {
        isAvailable = isAvailable.toLowerCase() == 'true';
      }

      print('🔧 Преобразованные данные: name=${serviceData['name']}, price=$price, is_available=$isAvailable');

      // Проверяем, есть ли уже услуги
      final checkResult = await Database.connection.query(
        'SELECT COUNT(*) as count FROM "Услуга"'
      );
      final serviceCount = (checkResult[0][0] as int);

      String query;
      Map<String, dynamic> substitutionValues;

      if (serviceCount == 0) {
        // Если услуг нет, создаем первую с ID=1
        query = '''
          INSERT INTO "Услуга" (service_id, name, price, is_available)
          VALUES (1, @name, @price, @is_available)
          RETURNING service_id
        ''';
      } else {
        // Если услуги есть, используем автоматическое присвоение ID
        query = '''
          INSERT INTO "Услуга" (name, price, is_available)
          VALUES (@name, @price, @is_available)
          RETURNING service_id
        ''';
      }

      substitutionValues = {
        'name': serviceData['name'].toString(),
        'price': price,
        'is_available': isAvailable,
      };

      final result = await Database.connection.query(
        query,
        substitutionValues: substitutionValues,
      );

      final newServiceId = result[0][0];
      print('✅ Услуга создана с ID: $newServiceId');

      return Response.ok(
        json.encode({
          'message': 'Услуга успешно добавлена',
          'service_id': newServiceId,
        }),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      print('❌ Ошибка при добавлении услуги: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при добавлении услуги: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Обновить услугу
  Future<Response> _updateService(Request request, String id) async {
    try {
      final serviceId = int.tryParse(id);
      if (serviceId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Неверный ID услуги'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      final body = await request.readAsString();
      final serviceData = json.decode(body) as Map<String, dynamic>;

      print('📥 Получены данные для обновления услуги $serviceId: $serviceData');

      if (serviceData['name'] == null || serviceData['name'].toString().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Название услуги обязательно'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      // Безопасное преобразование цены
      dynamic price = serviceData['price'] ?? 0.0;
      if (price is String) {
        price = double.tryParse(price) ?? 0.0;
      }

      // Безопасное преобразование доступности
      dynamic isAvailable = serviceData['is_available'] ?? true;
      if (isAvailable is String) {
        isAvailable = isAvailable.toLowerCase() == 'true';
      }

      print('🔧 Преобразованные данные: name=${serviceData['name']}, price=$price, is_available=$isAvailable');

      final result = await Database.connection.query(
        '''
        UPDATE "Услуга" 
        SET name = @name, price = @price, is_available = @is_available
        WHERE service_id = @id
        ''',
        substitutionValues: {
          'id': serviceId,
          'name': serviceData['name'].toString(),
          'price': price,
          'is_available': isAvailable,
        },
      );

      print('✅ Обновлено строк: ${result.affectedRowCount}');

      if (result.affectedRowCount > 0) {
        return Response.ok(
          json.encode({'message': 'Услуга успешно обновлена'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        return Response.notFound(
          json.encode({'error': 'Услуга не найдена'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    } catch (e) {
      print('❌ Ошибка при обновлении услуги: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при обновлении услуги: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Удалить услугу
  Future<Response> _deleteService(Request request, String id) async {
    try {
      final serviceId = int.tryParse(id);
      if (serviceId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Неверный ID услуги'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      final result = await Database.connection.query(
        'DELETE FROM "Услуга" WHERE service_id = @id',
        substitutionValues: {'id': serviceId},
      );

      if (result.affectedRowCount > 0) {
        return Response.ok(
          json.encode({'message': 'Услуга успешно удалена'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        return Response.notFound(
          json.encode({'error': 'Услуга не найдена'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    } catch (e) {
      print('❌ Ошибка при удалении услуги: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при удалении услуги: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Сброс ID последовательности
  Future<Response> _resetSequence(Request request) async {
    try {
      // Проверяем, пуста ли таблица
      final checkResult = await Database.connection.query(
        'SELECT COUNT(*) as count FROM "Услуга"'
      );
      final serviceCount = (checkResult[0][0] as int);

      if (serviceCount == 0) {
        // Сбрасываем последовательность к 1
        await Database.connection.query(
          'ALTER SEQUENCE "Услуга_service_id_seq" RESTART WITH 1'
        );
        print('✅ Последовательность сброшена к 1');
        
        return Response.ok(
          json.encode({'message': 'Последовательность ID сброшена к 1'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        return Response.badRequest(
          body: json.encode({'error': 'Нельзя сбросить последовательность, таблица не пуста'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    } catch (e) {
      print('❌ Ошибка при сбросе последовательности: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при сбросе последовательности: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  Router get router => _router;
}