class Service {
  final int serviceId;
  final String name;
  final double price;
  final bool isAvailable;

  Service({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'name': name,
      'price': price,
      'is_available': isAvailable,
    };
  }

  static Service fromJson(Map<String, dynamic> json) {
    // Безопасное преобразование типов
    int serviceId = 0;
    if (json['service_id'] != null) {
      serviceId = json['service_id'] is int 
          ? json['service_id'] 
          : int.tryParse(json['service_id'].toString()) ?? 0;
    }

    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is double) {
        price = json['price'];
      } else if (json['price'] is int) {
        price = (json['price'] as int).toDouble();
      } else {
        price = double.tryParse(json['price'].toString()) ?? 0.0;
      }
    }

    bool isAvailable = true;
    if (json['is_available'] != null) {
      if (json['is_available'] is bool) {
        isAvailable = json['is_available'];
      } else {
        isAvailable = json['is_available'].toString().toLowerCase() == 'true';
      }
    }

    return Service(
      serviceId: serviceId,
      name: json['name']?.toString() ?? '',
      price: price,
      isAvailable: isAvailable,
    );
  }
}