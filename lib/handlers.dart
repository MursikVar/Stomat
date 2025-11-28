import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'database.dart';
import 'models.dart';

class PatientHandler {
  Router get router {
    final router = Router();
    
    router.get('/', _getAllPatients);
    router.get('/<id>', _getPatientById);
    router.post('/', _createPatient);
    router.put('/<id>', _updatePatient);
    router.delete('/<id>', _deletePatient);
    
    return router;
  }

  Future<Response> _getAllPatients(Request request) async {
    try {
      final result = await Database.connection.query('''
        SELECT * FROM "Flaunetr"
      ''');
      
      final patients = result.map((row) {
        return Patient(
          medicalCardId: row[0] as int,
          age: row[1] as int,
          fullName: row[2] as String,
          phone: row[3] as String,
          omaPolicy: row[4] as String,
          snls: row[5] as String,
        ).toJson();
      }).toList();
      
      return Response.ok(
        patients.toString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _getPatientById(Request request, String id) async {
    try {
      final result = await Database.connection.query('''
        SELECT * FROM "Flaunetr" WHERE medical_card_id = @id
      ''', substitutionValues: {'id': int.tryParse(id)});
      
      if (result.isEmpty) {
        return Response.notFound('Patient not found');
      }
      
      final row = result.first;
      final patient = Patient(
        medicalCardId: row[0] as int,
        age: row[1] as int,
        fullName: row[2] as String,
        phone: row[3] as String,
        omaPolicy: row[4] as String,
        snls: row[5] as String,
      );
      
      return Response.ok(
        patient.toJson().toString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _createPatient(Request request) async {
    try {
      final body = await request.readAsString();
      // Здесь нужно добавить парсинг JSON и валидацию
      
      await Database.connection.query('''
        INSERT INTO "Flaunetr" (age, full_name, phone, oma_policy, snls)
        VALUES (@age, @full_name, @phone, @oma_policy, @snls)
      ''', substitutionValues: {
        'age': 0, // заменить на реальные данные из body
        'full_name': '',
        'phone': '',
        'oma_policy': '',
        'snls': '',
      });
      
      return Response.ok('Patient created successfully');
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _updatePatient(Request request, String id) async {
    try {
      final body = await request.readAsString();
      // Парсинг JSON и валидация
      
      await Database.connection.query('''
        UPDATE "Flaunetr" 
        SET age = @age, full_name = @full_name, phone = @phone, 
            oma_policy = @oma_policy, snls = @snls
        WHERE medical_card_id = @id
      ''', substitutionValues: {
        'id': int.tryParse(id),
        'age': 0,
        'full_name': '',
        'phone': '',
        'oma_policy': '',
        'snls': '',
      });
      
      return Response.ok('Patient updated successfully');
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _deletePatient(Request request, String id) async {
    try {
      await Database.connection.query('''
        DELETE FROM "Flaunetr" WHERE medical_card_id = @id
      ''', substitutionValues: {'id': int.tryParse(id)});
      
      return Response.ok('Patient deleted successfully');
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }
}

class MedicalRecordHandler {
  Router get router {
    final router = Router();
    
    router.get('/', _getAllRecords);
    router.get('/patient/<patientId>', _getRecordsByPatient);
    
    return router;
  }

  Future<Response> _getAllRecords(Request request) async {
    try {
      final result = await Database.connection.query('''
        SELECT * FROM "Samись_ua_npnew"
      ''');
      
      final records = result.map((row) {
        return MedicalRecord(
          recordId: row[0] as int,
          medicalCardId: row[1] as int,
          totalAmount: row[2] as double,
          datetime: row[3] as DateTime,
          recordType: row[4] as String,
          complaints: row[5] as String,
          workResult: row[6] as String,
        ).toJson();
      }).toList();
      
      return Response.ok(
        records.toString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _getRecordsByPatient(Request request, String patientId) async {
    try {
      final result = await Database.connection.query('''
        SELECT * FROM "Samись_ua_npnew" 
        WHERE medical_card_id = @patientId
      ''', substitutionValues: {'patientId': int.tryParse(patientId)});
      
      final records = result.map((row) {
        return MedicalRecord(
          recordId: row[0] as int,
          medicalCardId: row[1] as int,
          totalAmount: row[2] as double,
          datetime: row[3] as DateTime,
          recordType: row[4] as String,
          complaints: row[5] as String,
          workResult: row[6] as String,
        ).toJson();
      }).toList();
      
      return Response.ok(
        records.toString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }
}