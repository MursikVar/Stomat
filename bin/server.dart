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

    // Синхронизируем последовательность при запуске сервера
    try {
      await _syncServiceSequence();
    } catch (e) {
      print('⚠️  Предупреждение при синхронизации последовательности: $e');
    }

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
        '  DELETE /patients/<id> - удалить пациента\n'
        '  GET /services - список услуг (JSON)\n'
        '  POST /services - добавить услугу\n'
        '  PUT /services/<id> - обновить услугу\n'
        '  DELETE /services/<id> - удалить услугу\n'
        '  POST /services/fix-sequence - исправить последовательность ID',
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

    // ========== ПАЦИЕНТЫ ==========
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

    // ========== УСЛУГИ ==========
    // Получить все услуги
    router.get('/services', (Request request) async {
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
    });

    // Добавить услугу (с безопасным сбросом ID при пустой таблице)
    router.post('/services', (Request request) async {
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

        // ПРОВЕРКА: Если таблица пуста, сбрасываем последовательность
        final checkResult = await Database.connection.query(
          'SELECT COUNT(*) as count FROM "Услуга"'
        );
        final serviceCount = (checkResult[0][0] as int);

        if (serviceCount == 0) {
          // Если таблица пуста, сбрасываем последовательность к 1
          await Database.connection.query(
            'ALTER SEQUENCE "Услуга_service_id_seq" RESTART WITH 1'
          );
          print('🔄 Таблица услуг пуста, сбрасываем последовательность к 1');
        }

        // Вставляем данные в базу (используем sequence)
        final result = await Database.connection.query(
          '''
          INSERT INTO "Услуга" (name, price, is_available)
          VALUES (@name, @price, @is_available)
          RETURNING service_id
          ''',
          substitutionValues: {
            'name': serviceData['name'].toString(),
            'price': price,
            'is_available': isAvailable,
          },
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
        
        // Обработка ошибки дублирования ключа
        if (e.toString().contains('23505')) {
          // Автоматически исправляем последовательность и пробуем снова
          try {
            print('🔄 Обнаружен конфликт ID, пытаемся автоматически исправить...');
            await _syncServiceSequence();
            
            // Повторяем вставку
            final body = await request.readAsString();
            final serviceData = json.decode(body) as Map<String, dynamic>;
            
            dynamic price = serviceData['price'] ?? 0.0;
            if (price is String) price = double.tryParse(price) ?? 0.0;
            
            dynamic isAvailable = serviceData['is_available'] ?? true;
            if (isAvailable is String) isAvailable = isAvailable.toLowerCase() == 'true';

            final retryResult = await Database.connection.query(
              '''
              INSERT INTO "Услуга" (name, price, is_available)
              VALUES (@name, @price, @is_available)
              RETURNING service_id
              ''',
              substitutionValues: {
                'name': serviceData['name'].toString(),
                'price': price,
                'is_available': isAvailable,
              },
            );

            final newServiceId = retryResult[0][0];
            print('✅ Услуга создана с ID: $newServiceId (после автоматического исправления)');

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
          } catch (retryError) {
            print('❌ Ошибка при повторной попытке добавления: $retryError');
            return Response.internalServerError(
              body: json.encode({'error': 'Критическая ошибка базы данных. Попробуйте позже.'}),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Access-Control-Allow-Origin': '*',
              },
            );
          }
        }
        
        return Response.internalServerError(
          body: json.encode({'error': 'Ошибка при добавлении услуги: $e'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    });

    // Обновить услугу
    router.put('/services/<id>', (Request request, String id) async {
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
    });

    // Удалить услугу (со сбросом последовательности если таблица стала пустой)
    router.delete('/services/<id>', (Request request, String id) async {
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
          // После удаления проверяем, не пуста ли таблица
          final checkResult = await Database.connection.query(
            'SELECT COUNT(*) as count FROM "Услуга"'
          );
          final serviceCount = (checkResult[0][0] as int);
          
          if (serviceCount == 0) {
            // Если таблица пуста, сбрасываем последовательность
            await Database.connection.query(
              'ALTER SEQUENCE "Услуга_service_id_seq" RESTART WITH 1'
            );
            print('🔄 Таблица услуг стала пустой, сбрасываем последовательность к 1');
          }

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
    });

    // Синхронизация последовательности (для ручного исправления)
    router.post('/services/fix-sequence', (Request request) async {
      try {
        await _syncServiceSequence();
        return Response.ok(
          json.encode({'message': 'Последовательность услуг синхронизирована'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } catch (e) {
        print('❌ Ошибка при синхронизации последовательности: $e');
        return Response.internalServerError(
          body: json.encode({'error': 'Ошибка при синхронизации последовательности: $e'}),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    });

    // Добавляем CORS middleware
    final handler = const Pipeline().addMiddleware(_corsHeaders()).addHandler(router);

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
    print('   GET /services - список услуг');
    print('   POST /services - добавить услугу');
    print('   PUT /services/<id> - обновить услугу');
    print('   DELETE /services/<id> - удалить услугу');
    print('   POST /services/fix-sequence - исправить последовательность ID');
  } catch (e) {
    print('💥 Критическая ошибка при запуске сервера: $e');
    exit(1);
  }
}

// Функция для синхронизации последовательности услуг
Future<void> _syncServiceSequence() async {
  try {
    // Получаем максимальный ID из таблицы
    final maxIdResult = await Database.connection.query(
      'SELECT COALESCE(MAX(service_id), 0) FROM "Услуга"'
    );
    final maxId = (maxIdResult[0][0] as int);
    final newSequenceValue = maxId + 1;

    // Синхронизируем последовательность с реальными данными
    await Database.connection.query(
      'ALTER SEQUENCE "Услуга_service_id_seq" RESTART WITH @newValue',
      substitutionValues: {'newValue': newSequenceValue},
    );

    print('🔄 Последовательность синхронизирована. Максимальный ID: $maxId, новая последовательность: $newSequenceValue');
  } catch (e) {
    print('❌ Ошибка при синхронизации последовательности: $e');
    rethrow;
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