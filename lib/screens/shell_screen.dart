import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'schedules_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: widget.controller),
      SchedulesScreen(controller: widget.controller),
      ProgressScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.circle_outlined),
            selectedIcon: Icon(Icons.circle),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
