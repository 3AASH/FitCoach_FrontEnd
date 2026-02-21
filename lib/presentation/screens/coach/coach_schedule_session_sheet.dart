import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';

Future<void> showCoachScheduleSessionSheet(
  BuildContext context, {
  required String clientId,
  required String clientName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ScheduleSessionSheet(
      clientId: clientId,
      clientName: clientName,
    ),
  );
}

class _ScheduleSessionSheet extends StatefulWidget {
  final String clientId;
  final String clientName;

  const _ScheduleSessionSheet({
    required this.clientId,
    required this.clientName,
  });

  @override
  State<_ScheduleSessionSheet> createState() => _ScheduleSessionSheetState();
}

class _ScheduleSessionSheetState extends State<_ScheduleSessionSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _durationMinutes = 45;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(LanguageProvider lang) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: Locale(lang.isArabic ? 'ar' : 'en'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit(LanguageProvider lang) async {
    if (_isSubmitting) return;

    final coachId = context.read<AuthProvider>().user?.id;
    if (coachId == null) {
      Navigator.of(context).pop();
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSubmitting = true);
    final coachProvider = context.read<CoachProvider>();
    final success = await coachProvider.createAppointment(
      coachId: coachId,
      userId: widget.clientId,
      scheduledAt: scheduledAt,
      duration: _durationMinutes,
      type: 'video',
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_schedule_success', args: {'client': widget.clientName}),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_schedule_failure'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final formattedDate =
        DateFormat('EEE, MMM d', isArabic ? 'ar' : 'en').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lang.t('coach_schedule_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            lang.t('coach_schedule_subtitle', args: {'client': widget.clientName}),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(lang.t('coach_schedule_date')),
            subtitle: Text(formattedDate),
            trailing: TextButton(
              onPressed: () => _pickDate(lang),
              child: Text(lang.t('coach_schedule_change')),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(lang.t('coach_schedule_time')),
            subtitle: Text(formattedTime),
            trailing: TextButton(
              onPressed: _pickTime,
              child: Text(lang.t('coach_schedule_change')),
            ),
          ),
          const SizedBox(height: 12),
          Text(lang.t('coach_schedule_duration_label')),
          const SizedBox(height: 4),
          DropdownButton<int>(
            value: _durationMinutes,
            isExpanded: true,
            items: const [30, 45, 60]
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _durationMinutes = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: lang.t('coach_schedule_notes_label'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(lang),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.video_call),
              label: Text(
                lang.t('coach_schedule_confirm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
