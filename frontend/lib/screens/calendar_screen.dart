import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/gadget.dart';
import '../services/api_service.dart';
import '../services/settings_provider.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Map<DateTime, List<_CalendarEvent>> _events = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final token = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).authToken;
      final gadgets = await _apiService.getGadgets(token);

      final events = <DateTime, List<_CalendarEvent>>{};

      for (final gadget in gadgets) {
        if (gadget.warrantyExpiryDate != null) {
          _addEvent(
            events,
            gadget.warrantyExpiryDate!,
            _CalendarEvent(
              title: 'Warranty Expiry',
              subtitle: '${gadget.name} warranty expires',
              type: _CalendarEventType.warranty,
            ),
          );
        }

        final maintenanceDate = _getNextMaintenanceDate(gadget);
        if (maintenanceDate != null) {
          _addEvent(
            events,
            maintenanceDate,
            _CalendarEvent(
              title: 'Scheduled Maintenance',
              subtitle: '${gadget.name} maintenance due',
              type: _CalendarEventType.maintenance,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _events
            ..clear()
            ..addAll(events);
          _loading = false;
        });
      }

      await NotificationService.syncSchedulesFromApi(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _getNextMaintenanceDate(Gadget gadget) {
    final customNext = gadget.customFields['nextMaintenanceDate'];
    if (customNext is String && customNext.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(customNext);
      if (parsed != null) return parsed;
    }

    if (gadget.logs.isNotEmpty) {
      final lastService = gadget.logs
          .map((log) => log.serviceDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return lastService.add(const Duration(days: 180));
    }

    return gadget.purchaseDate.add(const Duration(days: 180));
  }

  void _addEvent(
    Map<DateTime, List<_CalendarEvent>> events,
    DateTime date,
    _CalendarEvent event,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    events.putIfAbsent(day, () => []).add(event);
  }

  List<_CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _isDark
        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
        : [_scheme.surface, _scheme.primaryContainer.withOpacity(0.32)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCalendarData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar<_CalendarEvent>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        eventLoader: _getEventsForDay,
                        calendarFormat: CalendarFormat.month,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: _scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: _scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: _scheme.primary.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(
                            color: _scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          formatButtonVisible: false,
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: _scheme.onSurface,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: _scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildSelectedDayEvents()),
                ],
              ),
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No reminders on this day',
          style: TextStyle(color: _scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isWarranty = event.type == _CalendarEventType.warranty;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isWarranty ? Colors.orange : Colors.blue)
                  .withOpacity(0.15),
              child: Icon(
                isWarranty
                    ? Icons.verified_user_outlined
                    : Icons.build_circle_outlined,
                color: isWarranty ? Colors.orange : Colors.blue,
              ),
            ),
            title: Text(event.title),
            subtitle: Text(event.subtitle),
          ),
        );
      },
    );
  }
}

class _CalendarEvent {
  final String title;
  final String subtitle;
  final _CalendarEventType type;

  _CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum _CalendarEventType { warranty, maintenance }
