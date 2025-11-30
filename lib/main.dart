import 'package:flutter/material.dart';
import 'package:stomatology/pages/employees/employees_page.dart';
import 'package:stomatology/pages/inventory/inventory_page.dart';
import 'package:stomatology/pages/patients/patients_page.dart';
import 'package:stomatology/pages/services/services_page.dart';
import 'pages/appointments/appointments_page.dart';

void main() {
  runApp(StomatologyApp());
}

class StomatologyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Стоматологическая клиника',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[800],
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.blue[800]),
        ),
      ),
      home: MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    AppointmentsPage(),
    PatientsPage(),
    ServicesPage(),
    EmployeesPage(),
    InventoryPage(),
  ];

  final List<String> _pageTitles = [
    'Записи на прием',
    'Пациенты',
    'Услуги',
    'Сотрудники',
    'Склад'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentPageIndex],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                'В',
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // Боковое меню
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(1, 0),
                ),
              ],
            ),
            child: ListView(
              children: [
                SizedBox(height: 20),
                // Логотип/заголовок
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services, color: Colors.blue[800], size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Стоматология',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Пункты меню
                _buildMenuButton(0, Icons.calendar_today, 'Записи на прием'),
                _buildMenuButton(1, Icons.people, 'Пациенты'),
                _buildMenuButton(2, Icons.medical_services, 'Услуги'),
                _buildMenuButton(3, Icons.badge, 'Сотрудники'),
                _buildMenuButton(4, Icons.inventory, 'Склад'),
                SizedBox(height: 30),
                // Статистика/инфо
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сегодня',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '8 записей',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Основной контент
          Expanded(
            child: _pages[_currentPageIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(int index, IconData icon, String title) {
    final isSelected = _currentPageIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Colors.blue[200]!)
            : Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue[800] : Colors.grey[700],
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.blue[800] : Colors.grey[700],
          ),
        ),
        onTap: () {
          setState(() {
            _currentPageIndex = index;
          });
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 0,
      ),
    );
  }
}