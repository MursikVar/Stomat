class Patient {
  final int medicalCardId;
  final int age;
  final String fullName;
  final String phone;
  final String omsPolicy;
  final String snils;

  Patient({
    required this.medicalCardId,
    required this.age,
    required this.fullName,
    required this.phone,
    required this.omsPolicy,
    required this.snils,
  });

  Map<String, dynamic> toJson() {
    return {
      'medical_card_id': medicalCardId,
      'age': age,
      'full_name': fullName,
      'phone': phone,
      'oms_policy': omsPolicy,
      'snils': snils,
    };
  }

  static Patient fromJson(Map<String, dynamic> json) {
    return Patient(
      medicalCardId: json['medical_card_id'] as int,
      age: json['age'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      omsPolicy: json['oms_policy'] as String,
      snils: json['snils'] as String,
    );
  }
}