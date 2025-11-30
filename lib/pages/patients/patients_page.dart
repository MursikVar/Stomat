import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../models/patient.dart';
import '../../widgets/patient_card.dart';

class PatientsPage extends StatefulWidget {
  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Patient> patients = [];
  List<Patient> filteredPatients = [];
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

      final patientsList = await ApiService.getPatients();
      setState(() {
        patients = patientsList;
        filteredPatients = patientsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
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
          final fullName = patient.fullName.toLowerCase();
          final phone = patient.phone.toLowerCase();
          final omsPolicy = patient.omsPolicy.toLowerCase();
          return fullName.contains(query) || phone.contains(query) || omsPolicy.contains(query);
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

  void _showEditPatientDialog(Patient patient) {
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
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и кнопка добавления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Управление пациентами',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPatientDialog,
                icon: Icon(Icons.person_add, size: 18),
                label: Text('Добавить пациента'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Поиск и статистика
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск пациентов...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Всего: ${patients.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                if (searchController.text.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Найдено: ${filteredPatients.length}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          searchController.clear();
                        },
                        child: Text('Очистить'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),
          // Список пациентов
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                onEdit: () {
                                  _showEditPatientDialog(patient);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// Классы диалогов добавления и редактирования пациентов
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
  final Patient patient;
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
    _fullNameController = TextEditingController(text: widget.patient.fullName);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phone);
    _omsPolicyController = TextEditingController(text: widget.patient.omsPolicy);
    _snilsController = TextEditingController(text: widget.patient.snils);
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
          Uri.parse('http://localhost:8080/patients/${widget.patient.medicalCardId}'),
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