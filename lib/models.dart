class Patient {
  final int medicalCardId;
  final int age;
  final String fullName;
  final String phone;
  final String omaPolicy;
  final String snls;

  Patient({
    required this.medicalCardId,
    required this.age,
    required this.fullName,
    required this.phone,
    required this.omaPolicy,
    required this.snls,
  });

  Map<String, dynamic> toJson() {
    return {
      'medical_card_id': medicalCardId,
      'age': age,
      'full_name': fullName,
      'phone': phone,
      'oma_policy': omaPolicy,
      'snls': snls,
    };
  }

  static Patient fromJson(Map<String, dynamic> json) {
    return Patient(
      medicalCardId: json['medical_card_id'] as int,
      age: json['age'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      omaPolicy: json['oma_policy'] as String,
      snls: json['snls'] as String,
    );
  }
}

class MedicalRecord {
  final int recordId;
  final int medicalCardId;
  final double totalAmount;
  final DateTime datetime;
  final String recordType;
  final String complaints;
  final String workResult;

  MedicalRecord({
    required this.recordId,
    required this.medicalCardId,
    required this.totalAmount,
    required this.datetime,
    required this.recordType,
    required this.complaints,
    required this.workResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'medical_card_id': medicalCardId,
      'total_amount': totalAmount,
      'datetime': datetime.toIso8601String(),
      'record_type': recordType,
      'complaints': complaints,
      'work_result': workResult,
    };
  }
}

class Employee {
  final int employeeId;
  final String position;
  final String fullName;
  final String phone;
  final int experience;
  final String education;

  Employee({
    required this.employeeId,
    required this.position,
    required this.fullName,
    required this.phone,
    required this.experience,
    required this.education,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'position': position,
      'full_name': fullName,
      'phone': phone,
      'experience': experience,
      'education': education,
    };
  }
}