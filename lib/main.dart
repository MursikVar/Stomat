import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(StomatologyApp());
}

class StomatologyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Стоматология',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PatientListScreen(),
    );
  }
}

class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<dynamic> patients = [];
  List<dynamic> filteredPatients = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
    searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPatients() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(Uri.parse('http://localhost:8080/patients'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          patients = data is List ? data : [];
          filteredPatients = patients;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Ошибка сервера: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка подключения: $e';
      });
    }
  }

  void _filterPatients() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredPatients = patients;
      });
    } else {
      setState(() {
        filteredPatients = patients.where((patient) {
          final fullName = patient['full_name']?.toString().toLowerCase() ?? '';
          final phone = patient['phone']?.toString().toLowerCase() ?? '';
          final omsPolicy = patient['oms_policy']?.toString().toLowerCase() ?? '';
          return fullName.contains(query) || 
                 phone.contains(query) || 
                 omsPolicy.contains(query);
        }).toList();
      });
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPatientDialog(onPatientAdded: fetchPatients);
      },
    );
  }

  void _showEditPatientDialog(dynamic patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPatientDialog(
          patient: patient,
          onPatientUpdated: fetchPatients,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пациенты стоматологии'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchPatients,
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Поиск пациентов по ФИО, телефону или полису...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Информация о количестве
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Найдено пациентов: ${filteredPatients.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      searchController.clear();
                    },
                    child: Text('Очистить'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Загрузка данных...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Произошла ошибка',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchPatients,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : filteredPatients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  patients.isEmpty ? 'Нет пациентов' : 'Пациенты не найдены',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  patients.isEmpty 
                                      ? 'Добавьте первого пациента' 
                                      : 'Попробуйте изменить поисковый запрос',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                if (patients.isEmpty) ...[
                                  SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _showAddPatientDialog,
                                    icon: Icon(Icons.person_add),
                                    label: Text('Добавить пациента'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
                              return PatientCard(
                                patient: patient,
                                onDeleted: fetchPatients,
                                onEdit: () => _showEditPatientDialog(patient),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        child: Icon(Icons.person_add),
        backgroundColor: Colors.blue[700],
        tooltip: 'Добавить пациента',
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  final dynamic patient;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdit;

  const PatientCard({Key? key, required this.patient, this.onDeleted, this.onEdit}) : super(key: key);

  Future<void> _deletePatient(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить пациента?'),
        content: Text('Вы уверены, что хотите удалить пациента ${patient['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://localhost:8080/patients/${patient['medical_card_id']}'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пациент удален'),
              backgroundColor: Colors.green,
            ),
          );
          onDeleted?.call();
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue[700]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patient['full_name']?.toString() ?? 'Не указано',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      _deletePatient(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            PatientInfoRow(icon: Icons.cake, text: 'Возраст: ${patient['age'] ?? 'Не указан'}'),
            PatientInfoRow(icon: Icons.phone, text: 'Телефон: ${patient['phone'] ?? 'Не указан'}'),
            PatientInfoRow(icon: Icons.credit_card, text: 'Полис ОМС: ${patient['oms_policy'] ?? 'Не указан'}'),
            PatientInfoRow(icon: Icons.badge, text: 'СНИЛС: ${patient['snils'] ?? 'Не указан'}'),
          ],
        ),
      ),
    );
  }
}

class PatientInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const PatientInfoRow({Key? key, required this.icon, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPatientDialog extends StatefulWidget {
  final VoidCallback onPatientAdded;

  const AddPatientDialog({Key? key, required this.onPatientAdded}) : super(key: key);

  @override
  _AddPatientDialogState createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _omsPolicyController = TextEditingController();
  final TextEditingController _snilsController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final patientData = {
          'full_name': _fullNameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'phone': _phoneController.text,
          'oms_policy': _omsPolicyController.text,
          'snils': _snilsController.text,
        };

        final response = await http.post(
          Uri.parse('http://localhost:8080/patients'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(patientData),
        );

        if (response.statusCode == 200) {
          Navigator.of(context).pop();
          widget.onPatientAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пациент успешно добавлен!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          throw Exception('Ошибка сервера: ${errorData['error']}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении пациента: $e'),
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
          Icon(Icons.person_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Добавить пациента'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ФИО пациента';
                  }
                  if (value.length > 100) {
                    return 'ФИО не должно превышать 100 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Возраст',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите возраст пациента';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Введите корректный возраст';
                  }
                  final age = int.parse(value);
                  if (age < 0 || age > 150) {
                    return 'Введите возраст от 0 до 150';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите телефон пациента';
                  }
                  if (value.length > 20) {
                    return 'Телефон не должен превышать 20 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _omsPolicyController,
                decoration: InputDecoration(
                  labelText: 'Полис ОМС',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                  helperText: 'Максимум 20 символов',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер полиса';
                  }
                  if (value.length > 20) {
                    return 'Полис ОМС не должен превышать 20 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _snilsController,
                decoration: InputDecoration(
                  labelText: 'СНИЛС',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  helperText: 'Максимум 15 символов',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите СНИЛС пациента';
                  }
                  if (value.length > 15) {
                    return 'СНИЛС не должен превышать 15 символов';
                  }
                  return null;
                },
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

class EditPatientDialog extends StatefulWidget {
  final dynamic patient;
  final VoidCallback onPatientUpdated;

  const EditPatientDialog({Key? key, required this.patient, required this.onPatientUpdated}) : super(key: key);

  @override
  _EditPatientDialogState createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _omsPolicyController;
  late TextEditingController _snilsController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.patient['full_name']?.toString() ?? '');
    _ageController = TextEditingController(text: widget.patient['age']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.patient['phone']?.toString() ?? '');
    _omsPolicyController = TextEditingController(text: widget.patient['oms_policy']?.toString() ?? '');
    _snilsController = TextEditingController(text: widget.patient['snils']?.toString() ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _omsPolicyController.dispose();
    _snilsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final patientData = {
          'full_name': _fullNameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'phone': _phoneController.text,
          'oms_policy': _omsPolicyController.text,
          'snils': _snilsController.text,
        };

        final response = await http.put(
          Uri.parse('http://localhost:8080/patients/${widget.patient['medical_card_id']}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(patientData),
        );

        if (response.statusCode == 200) {
          Navigator.of(context).pop();
          widget.onPatientUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Данные пациента обновлены!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          throw Exception('Ошибка сервера: ${errorData['error']}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении пациента: $e'),
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
          Text('Редактировать пациента'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'ФИО',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ФИО пациента';
                  }
                  if (value.length > 100) {
                    return 'ФИО не должно превышать 100 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Возраст',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите возраст пациента';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Введите корректный возраст';
                  }
                  final age = int.parse(value);
                  if (age < 0 || age > 150) {
                    return 'Введите возраст от 0 до 150';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите телефон пациента';
                  }
                  if (value.length > 20) {
                    return 'Телефон не должен превышать 20 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _omsPolicyController,
                decoration: InputDecoration(
                  labelText: 'Полис ОМС',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                  helperText: 'Максимум 20 символов',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер полиса';
                  }
                  if (value.length > 20) {
                    return 'Полис ОМС не должен превышать 20 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _snilsController,
                decoration: InputDecoration(
                  labelText: 'СНИЛС',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  helperText: 'Максимум 15 символов',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите СНИЛС пациента';
                  }
                  if (value.length > 15) {
                    return 'СНИЛС не должен превышать 15 символов';
                  }
                  return null;
                },
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