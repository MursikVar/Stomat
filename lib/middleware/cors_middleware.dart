import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

// CORS middleware для работы с Flutter Web
Middleware corsHeaders() {
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
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Authorization, X-Requested-With',
      'Access-Control-Allow-Credentials': 'true',
    };

Future<HttpServer> startServer(Handler handler, int preferredPort) async {
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