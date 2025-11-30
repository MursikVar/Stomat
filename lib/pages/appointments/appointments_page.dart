import 'package:flutter/material.dart';

class AppointmentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и статистика
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Обзор записей',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  _buildStatCard('Сегодня', '8', Colors.blue),
                  SizedBox(width: 16),
                  _buildStatCard('На неделе', '24', Colors.green),
                  SizedBox(width: 16),
                  _buildStatCard('Ожидают', '3', Colors.orange),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          // Быстрые действия
          Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildQuickAction('Добавить запись', Icons.add, Colors.blue),
              SizedBox(width: 16),
              _buildQuickAction('Расписание', Icons.schedule, Colors.green),
              SizedBox(width: 16),
              _buildQuickAction('Статистика', Icons.analytics, Colors.purple),
            ],
          ),
          SizedBox(height: 32),
          // Список сегодняшних записей
          Expanded(
            child: Container(
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
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Сегодняшние записи',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Chip(
                          label: Text('8 записей'),
                          backgroundColor: Colors.blue[50],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getColorForIndex(index),
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPatientName(index),
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _getServiceName(index),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _getTime(index),
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4),
                                  Chip(
                                    label: Text(_getStatus(index)),
                                    backgroundColor: _getStatusColor(index),
                                    labelStyle: TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательные методы для демо-данных
  Color _getColorForIndex(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return colors[index % colors.length];
  }

  String _getPatientName(int index) {
    final names = ['Иванов А.П.', 'Петрова М.С.', 'Сидоров Д.И.', 'Козлова Е.В.'];
    return names[index % names.length];
  }

  String _getServiceName(int index) {
    final services = ['Консультация', 'Лечение кариеса', 'Чистка', 'Рентген'];
    return services[index % services.length];
  }

  String _getTime(int index) {
    final times = ['09:00', '10:30', '12:00', '14:00', '15:30', '17:00'];
    return times[index % times.length];
  }

  String _getStatus(int index) {
    final statuses = ['Ожидает', 'В процессе', 'Завершено'];
    return statuses[index % statuses.length];
  }

  Color _getStatusColor(int index) {
    final status = _getStatus(index);
    switch (status) {
      case 'Ожидает': return Colors.orange;
      case 'В процессе': return Colors.blue;
      case 'Завершено': return Colors.green;
      default: return Colors.grey;
    }
  }
}