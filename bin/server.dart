import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';

import '../lib/database.dart';

void main(List<String> args) async {
  print('🚀 Запуск сервера...');
  
  try {
    // Подключаемся к базе данных
    await Database.connect();
    
    final router = Router();
    
    // Главная страница
    router.get('/', (Request request) {
      return Response.ok(
        'Стоматологический сервер работает! 🦷\n'
        'Доступные endpoints:\n'
        '  GET /health - проверка работы сервера и БД\n'
        '  GET /patients - список пациентов (JSON)\n'
        '  POST /patients - добавить пациента\n'
        '  PUT /patients/<id> - обновить пациента\n'
        '  DELETE /patients/<id> - удалить пациента',
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );
    });
    
    // Проверка здоровья сервера и БД
    router.get('/health', (Request request) async {
      try {
        final result = await Database.connection.query('SELECT 1 as test_value');
        return Response.ok(
          '✅ Сервер и БД работают\nТестовое значение: ${result[0][0]}',
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: '❌ Ошибка БД: $e',
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
        );
      }
    });

    // Получить всех пациентов
    router.get('/patients', (Request request) async {
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
    });

    // Добавить нового пациента
    router.post('/patients', (Request request) async {
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
    });

    // Обновить данные пациента
    router.put('/patients/<id>', (Request request, String id) async {
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
    });

    // Удалить пациента
    router.delete('/patients/<id>', (Request request, String id) async {
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
    });

    // Endpoint для отладки - проверка структуры таблицы
    router.get('/debug-table', (Request request) async {
      try {
        final result = await Database.connection.query('''
          SELECT column_name, data_type, is_nullable 
          FROM information_schema.columns 
          WHERE table_name = 'Пациент'
          ORDER BY ordinal_position
        ''');
        
        final columns = result.map((row) {
          return {
            'column_name': row[0],
            'data_type': row[1],
            'is_nullable': row[2],
          };
        }).toList();
        
        return Response.ok(
          json.encode({'table': 'Пациент', 'columns': columns}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } catch (e) {
        return Response.internalServerError(
          body: json.encode({'error': 'Ошибка при проверке таблицы: $e'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    });

    // Добавляем CORS middleware
    final handler = const Pipeline()
        .addMiddleware(_corsHeaders())
        .addHandler(router);

    // Получаем порт из .env или используем 8080
    final env = DotEnv()..load();
    final port = int.tryParse(env['SERVER_PORT'] ?? '8080') ?? 8080;

    // Запускаем сервер
    var server = await _startServer(handler, port);
    
    print('🎯 Сервер запущен на http://localhost:${server.port}');
    print('📋 Доступные endpoints:');
    print('   GET / - главная страница');
    print('   GET /health - проверка здоровья');
    print('   GET /patients - список пациентов');
    print('   POST /patients - добавить пациента');
    print('   PUT /patients/<id> - обновить пациента');
    print('   DELETE /patients/<id> - удалить пациента');
    print('   GET /debug-table - отладка структуры таблицы');
    
  } catch (e) {
    print('💥 Критическая ошибка при запуске сервера: $e');
    exit(1);
  }
}

Future<HttpServer> _startServer(Handler handler, int preferredPort) async {
  try {
    return await io.serve(handler, 'localhost', preferredPort);
  } catch (e) {
    if (e is SocketException && e.osError?.errorCode == 10048) {
      print('⚠️  Порт $preferredPort занят, пробую порт ${preferredPort + 1}');
      return await io.serve(handler, 'localhost', preferredPort + 1);
    }
    rethrow;
  }
}

// CORS middleware для работы с Flutter Web
Middleware _corsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Добавляем CORS заголовки к каждому запросу
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaderMap);
      }

      final Response response = await innerHandler(request);
      return response.change(headers: _corsHeaderMap);
    };
  };
}

Map<String, String> get _corsHeaderMap => {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With',
  'Access-Control-Allow-Credentials': 'true',
};