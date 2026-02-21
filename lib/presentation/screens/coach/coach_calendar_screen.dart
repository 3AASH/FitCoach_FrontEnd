import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/appointment.dart';

class CoachCalendarScreen extends StatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  State<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends State<CoachCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  void _loadAppointments() {
    final authProvider = context.read<AuthProvider>();
    final coachProvider = context.read<CoachProvider>();

    if (authProvider.user?.id != null) {
      // Load appointments for the current month.
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      coachProvider.loadAppointments(
        coachId: authProvider.user!.id,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  List<Appointment> _getAppointmentsForDay(
    DateTime day,
    List<Appointment> appointments,
  ) {
    return appointments.where((appointment) {
      DateTime? scheduledDate;
      try {
        scheduledDate = DateTime.parse(appointment.scheduledAt);
      } catch (_) {
        return false;
      }
      return scheduledDate.year == day.year &&
          scheduledDate.month == day.month &&
          scheduledDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final coachProvider = context.watch<CoachProvider>();

    final selectedDayAppointments = _selectedDay != null
        ? _getAppointmentsForDay(_selectedDay!, coachProvider.appointments)
        : <Appointment>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_tab_calendar')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAppointmentDialog(authProvider, lang),
          ),
        ],
      ),
      body: coachProvider.isAppointmentsLoading
          ? const Center(child: CircularProgressIndicator())
          : coachProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        coachProvider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: Text(lang.t('retry')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Calendar
                    CustomCard(
                      margin: const EdgeInsets.all(16),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: _calendarFormat,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                          _loadAppointments();
                        },
                        eventLoader: (day) {
                          return _getAppointmentsForDay(
                            day,
                            coachProvider.appointments,
                          );
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                        ),
                      ),
                    ),

                    // Appointments for selected day
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDay != null
                                ? lang.t(
                                    'coach_calendar_appointments_on',
                                    args: {
                                      'date': _formatDate(_selectedDay!),
                                    },
                                  )
                                : lang.t('coach_calendar_appointments_title'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedDayAppointments.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: selectedDayAppointments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: AppColors.textDisabled,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    lang.t('coach_calendar_no_appointments_day'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: selectedDayAppointments.length,
                              itemBuilder: (context, index) {
                                final appointment =
                                    selectedDayAppointments[index];
                                return _buildAppointmentCard(
                                  appointment,
                                  authProvider,
                                  lang,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment,
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(appointment.type ?? '')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(DateTime.parse(appointment.scheduledAt)),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(appointment.type ?? ''),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.userName ??
                            appointment.coachName ??
                            lang.t('unknown'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getTypeIcon(appointment.type ?? ''),
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_getTypeDisplayName(appointment.type, lang)} - ${appointment.durationMinutes ?? '-'} ${lang.t('minute_short')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(appointment.status, lang),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (appointment.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                appointment.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.status == 'scheduled') ...[
                  TextButton.icon(
                    onPressed: () => _showUpdateAppointmentDialog(
                      appointment,
                      authProvider,
                      lang,
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(lang.t('coach_edit')),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _cancelAppointment(
                      appointment,
                      authProvider,
                      lang,
                    ),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text(lang.t('auth_cancel')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAppointmentDialog(
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    final coachProvider = context.read<CoachProvider>();

    // First, load clients to select from.
    if (coachProvider.clients.isEmpty) {
      coachProvider.loadClients(coachId: authProvider.user!.id);
    }

    String? selectedClientId;
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int duration = 30;
    String type = 'video';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.t('coach_calendar_create_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Client selection
                DropdownButtonFormField<String>(
                  value: selectedClientId,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_calendar_client_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: coachProvider.clients.map((client) {
                    return DropdownMenuItem(
                      value: client.id,
                      child: Text(client.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClientId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Date picker
                ListTile(
                  title: Text(lang.t('coach_schedule_date')),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),

                // Time picker
                ListTile(
                  title: Text(lang.t('coach_schedule_time')),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Duration
                DropdownButtonFormField<int>(
                  value: duration,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_schedule_duration_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [15, 30, 45, 60, 90].map((min) {
                    return DropdownMenuItem(
                      value: min,
                      child: Text('$min ${lang.t('minute_short')}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      duration = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_calendar_type_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'video',
                      child: Text(lang.t('video_call')),
                    ),
                    DropdownMenuItem(
                      value: 'chat',
                      child: Text(lang.t('chat')),
                    ),
                    DropdownMenuItem(
                      value: 'assessment',
                      child: Text(lang.t('assessment')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_schedule_notes_label'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('auth_cancel')),
            ),
            ElevatedButton(
              onPressed: selectedClientId == null
                  ? null
                  : () async {
                      Navigator.pop(context);

                      final scheduledAt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      final success = await coachProvider.createAppointment(
                        coachId: authProvider.user!.id,
                        userId: selectedClientId!,
                        scheduledAt: scheduledAt,
                        duration: duration,
                        type: type,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.t('coach_calendar_create_success'),
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadAppointments();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              coachProvider.error ??
                                  lang.t('coach_calendar_create_failed'),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: Text(lang.t('coach_calendar_create_action')),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateAppointmentDialog(
    Appointment appointment,
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    DateTime selectedDate = DateTime.parse(appointment.scheduledAt);
    TimeOfDay selectedTime =
        TimeOfDay.fromDateTime(DateTime.parse(appointment.scheduledAt));
    int duration = appointment.durationMinutes ?? 30;
    final notesController = TextEditingController(text: appointment.notes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.t('coach_calendar_update_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  title: Text(lang.t('coach_schedule_date')),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),

                // Time picker
                ListTile(
                  title: Text(lang.t('coach_schedule_time')),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Duration
                DropdownButtonFormField<int>(
                  value: duration,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_schedule_duration_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [15, 30, 45, 60, 90].map((min) {
                    return DropdownMenuItem(
                      value: min,
                      child: Text('$min ${lang.t('minute_short')}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      duration = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: lang.t('coach_schedule_notes_label'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('auth_cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final scheduledAt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final coachProvider = context.read<CoachProvider>();
                final success = await coachProvider.updateAppointment(
                  coachId: authProvider.user!.id,
                  appointmentId: appointment.id,
                  scheduledAt: scheduledAt,
                  duration: duration,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.t('coach_calendar_update_success')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadAppointments();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        coachProvider.error ??
                            lang.t('coach_calendar_update_failed'),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Text(lang.t('coach_calendar_update_action')),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelAppointment(
    Appointment appointment,
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('coach_calendar_cancel_title')),
        content: Text(lang.t('coach_calendar_cancel_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('auth_cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final coachProvider = context.read<CoachProvider>();
              final success = await coachProvider.updateAppointment(
                coachId: authProvider.user!.id,
                appointmentId: appointment.id,
                status: 'cancelled',
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('coach_calendar_cancel_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadAppointments();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      coachProvider.error ??
                          lang.t('coach_calendar_cancel_failed'),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(lang.t('coach_calendar_cancel_action')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'video':
        return AppColors.primary;
      case 'chat':
        return AppColors.success;
      case 'assessment':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'chat':
        return Icons.chat;
      case 'assessment':
        return Icons.assessment;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'missed':
        return AppColors.textSecondary;
      default:
        return AppColors.textDisabled;
    }
  }

  String _getTypeDisplayName(String? type, LanguageProvider lang) {
    switch (type) {
      case 'video':
        return lang.t('video_call');
      case 'chat':
        return lang.t('chat');
      case 'assessment':
        return lang.t('assessment');
      default:
        return lang.t('unknown');
    }
  }

  String _getStatusDisplayName(String? status, LanguageProvider lang) {
    switch (status) {
      case 'scheduled':
        return lang.t('coach_status_scheduled');
      case 'in_progress':
        return lang.t('coach_status_in_progress');
      case 'completed':
        return lang.t('coach_status_completed');
      case 'cancelled':
        return lang.t('coach_status_cancelled');
      case 'missed':
        return lang.t('coach_status_missed');
      default:
        return lang.t('unknown');
    }
  }
}
