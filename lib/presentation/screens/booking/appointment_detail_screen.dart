import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/video_call_provider.dart';
import '../../widgets/custom_button.dart';
import '../video_call/video_call_screen.dart';
import '../../../core/constants/colors.dart';

/// Appointment Detail Screen
/// Shows appointment details and allows joining video call
class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isCheckingAccess = false;
  bool _isActionInProgress = false;
  String? _accessMessage;
  bool _canJoin = false;

  @override
  void initState() {
    super.initState();
    _checkCanJoin();
  }

  Future<void> _checkCanJoin() async {
    setState(() {
      _isCheckingAccess = true;
    });

    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final result = await provider.canJoinCall(widget.appointment.id);

    if (result != null && result['canJoin'] == true) {
      setState(() {
        _canJoin = true;
        _accessMessage = null;
        _isCheckingAccess = false;
      });
    } else {
      setState(() {
        _canJoin = false;
        _accessMessage =
            result?['reason'] ?? languageProvider.t('cannot_join_call');
        _isCheckingAccess = false;
      });
    }
  }

  Future<void> _joinCall() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          appointmentId: widget.appointment.id,
          coachId: widget.appointment.coachId,
          coachName:
              widget.appointment.coachName ?? languageProvider.t('coach'),
          isCoach: false,
        ),
      ),
    );
  }

  Future<void> _cancelAppointment() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('cancel_appointment')),
        content: Text(lang.t('cancel_appointment_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(lang.t('cancel_appointment'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);

    try {
      await context
          .read<BookingRepository>()
          .cancelBooking(widget.appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('cancel_appointment_success')),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('cancel_appointment_failed')),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _rescheduleAppointment() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final currentScheduledAt =
        DateTime.parse(widget.appointment.scheduledAt).toLocal();
    DateTime selectedDate = currentScheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(currentScheduledAt);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lang.t('reschedule_appointment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(lang.t('date')),
                subtitle:
                    Text(DateFormat('EEEE, MMM d, y').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(lang.t('time')),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'date': selectedDate,
                'time': selectedTime,
              }),
              child: Text(lang.t('confirm')),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final newDate = result['date'] as DateTime;
    final newTime = result['time'] as TimeOfDay;
    // Backend stores schedules in UTC; convert the picked local time
    final utcDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    ).toUtc();
    final timeStr =
        '${utcDateTime.hour.toString().padLeft(2, '0')}:${utcDateTime.minute.toString().padLeft(2, '0')}';

    setState(() => _isActionInProgress = true);

    try {
      await context.read<BookingRepository>().updateBooking(
            widget.appointment.id,
            scheduledDate: utcDateTime,
            scheduledTime: timeStr,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('reschedule_appointment_success')),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('reschedule_appointment_failed')),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    final scheduledTime =
        DateTime.parse(widget.appointment.scheduledAt).toLocal();
    final now = DateTime.now();
    final tenMinutesBefore =
        scheduledTime.subtract(const Duration(minutes: 10));
    final canJoinSoon = now.isAfter(tenMinutesBefore) &&
        widget.appointment.status == 'confirmed';

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('appointment_details')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.appointment.status)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(widget.appointment.status),
                  width: 1,
                ),
              ),
              child: Text(
                languageProvider.t(widget.appointment.status),
                style: TextStyle(
                  color: _getStatusColor(widget.appointment.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Coach info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('coach'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.appointment.coachName ??
                                languageProvider.t('coach'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time
            _buildDetailCard(
              icon: Icons.calendar_today,
              title: languageProvider.t('date_time'),
              value:
                  DateFormat('EEEE, MMM d, y - h:mm a').format(scheduledTime),
            ),

            const SizedBox(height: 16),

            // Duration
            _buildDetailCard(
              icon: Icons.timer,
              title: languageProvider.t('duration'),
              value:
                  '${widget.appointment.durationMinutes ?? 30} ${languageProvider.t('minutes')}',
            ),

            const SizedBox(height: 16),

            // Type
            if (widget.appointment.type != null)
              _buildDetailCard(
                icon: Icons.category,
                title: languageProvider.t('type'),
                value: widget.appointment.type!,
              ),

            const SizedBox(height: 16),

            // Notes
            if (widget.appointment.notes != null &&
                widget.appointment.notes!.isNotEmpty)
              _buildDetailCard(
                icon: Icons.note,
                title: languageProvider.t('notes'),
                value: widget.appointment.notes!,
              ),

            const SizedBox(height: 24),

            // Join call button or message
            if (widget.appointment.status == 'confirmed')
              Column(
                children: [
                  if (_isCheckingAccess)
                    const Center(child: CircularProgressIndicator())
                  else if (_canJoin && canJoinSoon)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  languageProvider.t('can_join_now'),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: languageProvider.t('join_video_call'),
                          onPressed: _joinCall,
                          icon: Icons.videocam,
                          variant: ButtonVariant.primary,
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _accessMessage ??
                                  languageProvider.t('cannot_join_yet'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

            // Cancel/reschedule actions for active appointments
            if (widget.appointment.status == 'confirmed' ||
                widget.appointment.status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (widget.appointment.status == 'confirmed')
                      Expanded(
                        child: CustomButton(
                          text: languageProvider.t('reschedule_appointment'),
                          onPressed: _isActionInProgress
                              ? null
                              : _rescheduleAppointment,
                          icon: Icons.calendar_month,
                          variant: ButtonVariant.secondary,
                        ),
                      ),
                    if (widget.appointment.status == 'confirmed')
                      const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: languageProvider.t('cancel_appointment'),
                        onPressed:
                            _isActionInProgress ? null : _cancelAppointment,
                        icon: Icons.cancel,
                        variant: ButtonVariant.danger,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
