import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

class PatientHandler {
  final Router _router = Router();

  PatientHandler() {
    _setupRoutes();
  }

  void _setupRoutes() {
    // Получить всех пациентов
    _router.get('/patients', _getPatients);
    
    // Добавить нового пациента
    _router.post('/patients', _addPatient);
    
    // Обновить данные пациента
    _router.put('/patients/<id>', _updatePatient);
    
    // Удалить пациента
    _router.delete('/patients/<id>', _deletePatient);
  }

  // Получить всех пациентов
  Future<Response> _getPatients(Request request) async {
    try {
      final result = await Database.connection.query('SELECT * FROM "Пациент"');

      final patients = result.map((row) {
        return {
          'medical_card_id': row[0],
          'age': row[1],
          'full_name': row[2],
          'phone': row[3],
          'oms_policy': row[4],
          'snils': row[5],
        };
      }).toList();

      return Response.ok(
        json.encode(patients),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      print('❌ Ошибка при получении пациентов: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка базы данных: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Добавить нового пациента
  Future<Response> _addPatient(Request request) async {
    try {
      final body = await request.readAsString();
      final patientData = json.decode(body) as Map<String, dynamic>;

      // Валидация обязательных полей
      if (patientData['full_name'] == null || patientData['full_name'].toString().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'ФИО обязательно для заполнения'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      // Вставляем данные в базу
      final result = await Database.connection.query(
        '''
        INSERT INTO "Пациент" (age, full_name, phone, oms_policy, snils)
        VALUES (@age, @full_name, @phone, @oms_policy, @snils)
        RETURNING medical_card_id
        ''',
        substitutionValues: {
          'age': patientData['age'] ?? 0,
          'full_name': patientData['full_name'],
          'phone': patientData['phone'] ?? '',
          'oms_policy': patientData['oms_policy'] ?? '',
          'snils': patientData['snils'] ?? '',
        },
      );

      return Response.ok(
        json.encode({
          'message': 'Пациент успешно добавлен',
          'medical_card_id': result[0][0],
        }),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      print('❌ Ошибка при добавлении пациента: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при добавлении пациента: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Обновить данные пациента
  Future<Response> _updatePatient(Request request, String id) async {
    try {
      final medicalCardId = int.tryParse(id);
      if (medicalCardId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Неверный ID пациента'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      final body = await request.readAsString();
      final patientData = json.decode(body) as Map<String, dynamic>;

      // Валидация обязательных полей
      if (patientData['full_name'] == null || patientData['full_name'].toString().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'ФИО обязательно для заполнения'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      // Обновляем данные в базе
      final result = await Database.connection.query(
        '''
        UPDATE "Пациент" 
        SET age = @age, 
            full_name = @full_name, 
            phone = @phone, 
            oms_policy = @oms_policy, 
            snils = @snils
        WHERE medical_card_id = @id
        RETURNING medical_card_id
        ''',
        substitutionValues: {
          'id': medicalCardId,
          'age': patientData['age'] ?? 0,
          'full_name': patientData['full_name'],
          'phone': patientData['phone'] ?? '',
          'oms_policy': patientData['oms_policy'] ?? '',
          'snils': patientData['snils'] ?? '',
        },
      );

      if (result.affectedRowCount > 0) {
        return Response.ok(
          json.encode({
            'message': 'Пациент успешно обновлен',
            'medical_card_id': result[0][0],
          }),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        return Response.notFound(
          json.encode({'error': 'Пациент не найден'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    } catch (e) {
      print('❌ Ошибка при обновлении пациента: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при обновлении пациента: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  // Удалить пациента
  Future<Response> _deletePatient(Request request, String id) async {
    try {
      final medicalCardId = int.tryParse(id);
      if (medicalCardId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Неверный ID пациента'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }

      final result = await Database.connection.query(
        'DELETE FROM "Пациент" WHERE medical_card_id = @id',
        substitutionValues: {'id': medicalCardId},
      );

      if (result.affectedRowCount > 0) {
        return Response.ok(
          json.encode({'message': 'Пациент успешно удален'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        return Response.notFound(
          json.encode({'error': 'Пациент не найден'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    } catch (e) {
      print('❌ Ошибка при удалении пациента: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Ошибка при удалении пациента: $e'}),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  Router get router => _router;
}