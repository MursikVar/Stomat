import 'package:flutter/material.dart';
import '../models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdit;

  const ServiceCard({Key? key, required this.service, this.onDeleted, this.onEdit}) : super(key: key);

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getServiceColor(service.name),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getServiceIcon(service.name),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${service.serviceId}',
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
                      _deleteService(context);
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
            Row(
              children: [
                _buildInfoChip(
                  Icons.attach_money,
                  '${service.price.toStringAsFixed(2)} руб.',
                  Colors.green,
                ),
                SizedBox(width: 8),
                _buildStatusChip(service.isAvailable),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(
      label: Text(text),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(fontSize: 12, color: color),
    );
  }

  Widget _buildStatusChip(bool isAvailable) {
    return Chip(
      label: Text(isAvailable ? 'Доступна' : 'Недоступна'),
      backgroundColor: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isAvailable ? Colors.green : Colors.red,
      ),
    );
  }

  Color _getServiceColor(String serviceName) {
    final colors = {
      'Консультация': Colors.blue,
      'Лечение': Colors.green,
      'Чистка': Colors.orange,
      'Рентген': Colors.purple,
      'Протезирование': Colors.teal,
    };
    
    for (var key in colors.keys) {
      if (serviceName.toLowerCase().contains(key.toLowerCase())) {
        return colors[key]!;
      }
    }
    
    return Colors.blue;
  }

  IconData _getServiceIcon(String serviceName) {
    final icons = {
      'Консультация': Icons.medical_information,
      'Лечение': Icons.healing,
      'Чистка': Icons.clean_hands,
      'Рентген': Icons.scanner,
      'Протезирование': Icons.engineering,
    };
    
    for (var key in icons.keys) {
      if (serviceName.toLowerCase().contains(key.toLowerCase())) {
        return icons[key]!;
      }
    }
    
    return Icons.medical_services;
  }

  Future<void> _deleteService(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить услугу?'),
        content: Text('Вы уверены, что хотите удалить услугу "${service.name}"?'),
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
      onDeleted?.call();
    }
  }
}