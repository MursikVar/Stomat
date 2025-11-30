import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/service.dart';
import '../../services/api_service.dart';
import '../../widgets/service_card.dart';

class ServicesPage extends StatefulWidget {
  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Service> services = [];
  List<Service> filteredServices = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServices();
    searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchServices() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('🔄 Начинаем загрузку услуг...');
      final servicesList = await ApiService.getServices();
      print('✅ Услуги загружены: ${servicesList.length} шт.');
      
      setState(() {
        services = servicesList;
        filteredServices = servicesList;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка при загрузке услуг: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _filterServices() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredServices = services;
      });
    } else {
      setState(() {
        filteredServices = services.where((service) {
          final name = service.name.toLowerCase();
          final price = service.price.toString();
          return name.contains(query) || price.contains(query);
        }).toList();
      });
    }
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddServiceDialog(onServiceAdded: fetchServices);
      },
    );
  }

  void _showEditServiceDialog(Service service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditServiceDialog(
          service: service,
          onServiceUpdated: fetchServices,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Управление услугами',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 24),
            
            // Статистика в стиле твоего дизайна
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Всего услуг', services.length.toString()),
                  _buildStatItem('Доступно', 
                    services.where((s) => s.isAvailable).length.toString()),
                  _buildStatItem('Общая стоимость', 
                    '${_calculateAveragePrice().toStringAsFixed(2)} руб.'),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Панель поиска и добавления
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск услуг по названию или цене...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Найдено: ${filteredServices.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddServiceDialog,
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Добавить услугу'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Список услуг
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchServices,
                                child: Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : filteredServices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.medical_services, size: 80, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    services.isEmpty ? 'Нет услуг' : 'Услуги не найдены',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    services.isEmpty
                                        ? 'Добавьте первую услугу'
                                        : 'Попробуйте изменить поисковый запрос',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                  if (services.isEmpty) ...[
                                    SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _showAddServiceDialog,
                                      icon: Icon(Icons.add),
                                      label: Text('Добавить услугу'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = filteredServices[index];
                                return ServiceCard(
                                  service: service,
                                  onDeleted: () {
                                    _deleteService(service);
                                  },
                                  onEdit: () => _showEditServiceDialog(service),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  double _calculateAveragePrice() {
    if (services.isEmpty) return 0;
    final total = services.fold(0.0, (sum, service) => sum + service.price);
    return total;
  }

  Future<void> _deleteService(Service service) async {
    try {
      await ApiService.deleteService(service.serviceId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Услуга "${service.name}" удалена'),
          backgroundColor: Colors.green,
        ),
      );
      fetchServices();
    } catch (e) {
      print('❌ Ошибка при удалении услуги: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Диалоговые окна (оставляем без изменений, они уже хорошие)
class AddServiceDialog extends StatefulWidget {
  final VoidCallback onServiceAdded;

  const AddServiceDialog({Key? key, required this.onServiceAdded}) : super(key: key);

  @override
  _AddServiceDialogState createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isAvailable = true;
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final serviceData = {
          'name': _nameController.text,
          'price': double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0,
          'is_available': _isAvailable,
        };

        print('📤 Отправляем данные услуги: $serviceData');

        final response = await http.post(
          Uri.parse('http://localhost:8080/services'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(serviceData),
        );

        print('📥 Ответ сервера: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          Navigator.of(context).pop();
          widget.onServiceAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Услуга успешно добавлена!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          throw Exception('Ошибка сервера: ${response.statusCode} - ${errorData['error']}');
        }
      } catch (e) {
        print('❌ Ошибка при добавлении услуги: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении услуги: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Добавить услугу'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название услуги',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название услуги';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Цена (руб.)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену услуги';
                  }
                  final cleanedValue = value.replaceAll(',', '.');
                  if (double.tryParse(cleanedValue) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.contains(',')) {
                    _priceController.text = value.replaceAll(',', '.');
                    _priceController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _priceController.text.length),
                    );
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value ?? true;
                      });
                    },
                  ),
                  Text('Доступна для записи'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading 
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Добавить'),
        ),
      ],
    );
  }
}

class EditServiceDialog extends StatefulWidget {
  final Service service;
  final VoidCallback onServiceUpdated;

  const EditServiceDialog({Key? key, required this.service, required this.onServiceUpdated}) : super(key: key);

  @override
  _EditServiceDialogState createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late bool _isAvailable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _priceController = TextEditingController(text: widget.service.price.toString());
    _isAvailable = widget.service.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final serviceData = {
          'name': _nameController.text,
          'price': double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0,
          'is_available': _isAvailable,
        };

        print('📤 Отправляем данные для обновления услуги ${widget.service.serviceId}: $serviceData');

        final response = await http.put(
          Uri.parse('http://localhost:8080/services/${widget.service.serviceId}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(serviceData),
        );

        print('📥 Ответ сервера: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          Navigator.of(context).pop();
          widget.onServiceUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Услуга успешно обновлена!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          throw Exception('Ошибка сервера: ${response.statusCode} - ${errorData['error']}');
        }
      } catch (e) {
        print('❌ Ошибка при обновлении услуги: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении услуги: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Text('Редактировать услугу'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название услуги',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название услуги';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Цена (руб.)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену услуги';
                  }
                  final cleanedValue = value.replaceAll(',', '.');
                  if (double.tryParse(cleanedValue) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.contains(',')) {
                    _priceController.text = value.replaceAll(',', '.');
                    _priceController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _priceController.text.length),
                    );
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value ?? true;
                      });
                    },
                  ),
                  Text('Доступна для записи'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading 
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Сохранить'),
        ),
      ],
    );
  }
}