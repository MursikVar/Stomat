import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

class Database {
  static late PostgreSQLConnection connection;

  static Future<void> connect() async {
    final env = DotEnv()..load();
    
    final host = env['DB_HOST'] ?? 'localhost';
    final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
    final databaseName = env['DB_NAME'] ?? 'stomatology';
    final username = env['DB_USER'] ?? 'postgres';
    final password = env['DB_PASSWORD'] ?? 'password';

    print('🔄 Попытка подключения к базе данных...');
    print('📍 Хост: $host, Порт: $port, База: $databaseName');
    print('👤 Пользователь: $username');

    connection = PostgreSQLConnection(
      host,
      port,
      databaseName,
      username: username,
      password: password,
      timeoutInSeconds: 30,
      queryTimeoutInSeconds: 30,
    );
    
    try {
      await connection.open();
      print('✅ Подключение к базе данных установлено');
      
      // Проверяем подключение простым запросом
      final result = await connection.query('SELECT version()');
      print('📊 Версия PostgreSQL: ${result[0][0]}');
      
    } catch (e) {
      print('❌ Ошибка подключения к базе данных: $e');
      print('💡 Проверь:');
      print('   - Запущен ли PostgreSQL сервер');
      print('   - Правильность пароля');
      print('   - Существует ли база данных "$databaseName"');
      print('   - Доступность хоста "$host" на порту $port');
      rethrow;
    }
  }

  static Future<void> disconnect() async {
    await connection.close();
    print('🔌 Подключение к базе данных закрыто');
  }
}