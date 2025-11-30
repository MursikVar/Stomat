import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/patient.dart';
import '../services/api_service.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdit;

  const PatientCard({Key? key, required this.patient, this.onDeleted, this.onEdit}) : super(key: key);

  Future<void> _deletePatient(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить пациента?'),
        content: Text('Вы уверены, что хотите удалить пациента ${patient.fullName}?'),
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
        await ApiService.deletePatient(patient.medicalCardId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пациент удален'),
            backgroundColor: Colors.green,
          ),
        );
        onDeleted?.call();
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
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue[700]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Мед. карточка №: ${patient.medicalCardId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
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
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.cake, '${patient.age} лет'),
                _buildInfoChip(Icons.phone, patient.phone),
                if (patient.omsPolicy.isNotEmpty)
                  _buildInfoChip(Icons.credit_card, patient.omsPolicy),
                if (patient.snils.isNotEmpty)
                  _buildInfoChip(Icons.badge, patient.snils),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      label: Text(text),
      avatar: Icon(icon, size: 16),
      backgroundColor: Colors.grey[50],
      labelStyle: TextStyle(fontSize: 12),
    );
  }
}