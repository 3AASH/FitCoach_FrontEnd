import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/coach_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/coach_repository.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class VideoBookingScreen extends StatefulWidget {
  const VideoBookingScreen({super.key});

  @override
  State<VideoBookingScreen> createState() => _VideoBookingScreenState();
}

class _VideoBookingScreenState extends State<VideoBookingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final CoachRepository _coachRepository = CoachRepository();
  final BookingRepository _bookingRepository = BookingRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  int _selectedDuration = 60;

  CoachProfile? _coachProfile;
  bool _isCoachLoading = false;
  String? _coachError;
  String? _loadedCoachId;

  final Map<String, List<String>> _availableSlotsByDate = {};
  bool _isSlotsLoading = false;
  String? _slotsError;
  bool _isBooking = false;

  final Map<String, dynamic> _demoCoach = {
    'id': 'demo-coach',
    'name': 'Ahmed Hassan',
    'nameAr': 'أحمد حسن',
    'specialties': ['Weight Loss', 'Strength Training', 'Nutrition'],
    'specialtiesAr': ['فقدان الوزن', 'تدريب القوة', 'التغذية'],
    'rating': 4.9,
    'yearsExperience': 8,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (DemoConfig.isDemo) {
        await _loadDemoSlots();
        return;
      }
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile(notify: false);
      if (!mounted) {
        return;
      }
      final coachId = authProvider.user?.coachId;
      if (coachId == null || coachId.isEmpty) {
        return;
      }
      await _syncAssignedCoach(coachId, forceReload: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DemoConfig.isDemo) {
      return;
    }
    final coachId = context.watch<AuthProvider>().user?.coachId;
    if (coachId == null || coachId.isEmpty || coachId == _loadedCoachId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncAssignedCoach(coachId, forceReload: true);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = lang.isArabic;
    final hasAssignedCoach =
        DemoConfig.isDemo || ((authProvider.user?.coachId ?? '').isNotEmpty);
    final coachData = _resolveCoachData(lang, authProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(lang, isArabic),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAssignedCoach)
                    _buildCoachCard(lang, isArabic, coachData)
                  else
                    _buildNoCoachAssigned(isArabic),
                  const SizedBox(height: 20),
                  _buildDateSection(lang, isArabic, hasAssignedCoach),
                  const SizedBox(height: 20),
                  if (_selectedDate != null) _buildTimeSection(lang, isArabic),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 20),
                    _buildBookingDetailsSection(isArabic),
                  ],
                  const SizedBox(height: 24),
                  CustomButton(
                    text: isArabic ? 'تأكيد الحجز' : 'Confirm Booking',
                    onPressed: (_selectedDate != null &&
                            _selectedTime != null &&
                            hasAssignedCoach &&
                            !_isBooking)
                        ? () => _showConfirmDialog(lang, isArabic)
                        : null,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    icon: Icons.check_circle,
                    isLoading: _isBooking,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang, bool isArabic) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'حجز جلسة فيديو' : 'Book Video Session',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'احجز جلسة فردية مع مدربك'
                      : 'Reserve a 1-on-1 session with your coach',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _resolveCoachData(
    LanguageProvider lang,
    AuthProvider authProvider,
  ) {
    if (DemoConfig.isDemo) {
      return _demoCoach;
    }
    final coachName = _coachProfile?.name ?? lang.t('coach');
    final specializations = _coachProfile?.specializations ?? const <String>[];
    final rating = _coachProfile?.stats.avgRating;
    final yearsExperience = _coachProfile?.yearsOfExperience;
    return {
      'id': authProvider.user?.coachId ?? '',
      'name': coachName,
      'nameAr': coachName,
      'specialties': specializations,
      'specialtiesAr': specializations,
      'rating': rating == 0 ? null : rating,
      'yearsExperience': yearsExperience == 0 ? null : yearsExperience,
    };
  }

  Widget _buildCoachCard(
    LanguageProvider lang,
    bool isArabic,
    Map<String, dynamic> coachData,
  ) {
    final coachName = isArabic
        ? (coachData['nameAr'] ?? coachData['name'])
        : coachData['name'];
    final specialties = isArabic
        ? (coachData['specialtiesAr'] as List<String>)
        : (coachData['specialties'] as List<String>);
    final rating = coachData['rating'] as num?;
    final yearsExperience = coachData['yearsExperience'] as num?;

    if (_isCoachLoading && _coachProfile == null && !DemoConfig.isDemo) {
      return _buildInfoCard(
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic
                    ? 'جارٍ تحميل بيانات المدرب...'
                    : 'Loading coach details...',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (_coachError != null && _coachProfile == null && !DemoConfig.isDemo) {
      return _buildInfoCard(
        child: Text(
          isArabic
              ? 'تعذر تحميل بيانات المدرب'
              : 'Unable to load coach details',
          style: const TextStyle(color: Color(0xFF9A3412)),
        ),
      );
    }

    return _buildInfoCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                coachData['name']
                    .toString()
                    .split(' ')
                    .where((part) => part.isNotEmpty)
                    .map((part) => part[0])
                    .take(2)
                    .join(''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'المدرب المعين لك' : 'Your Assigned Coach',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coachName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (rating != null || yearsExperience != null)
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star,
                            color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (yearsExperience != null) ...[
                        if (rating != null) const SizedBox(width: 12),
                        Text(
                          '$yearsExperience ${isArabic ? 'سنوات خبرة' : 'years exp'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: specialties.take(3).map((specialty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        specialty,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCoachAssigned(bool isArabic) {
    return _buildInfoCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF9A3412)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? 'لم يتم تعيين مدرب لك بعد. سيتم تفعيل الحجز بعد التعيين.'
                  : 'No coach is assigned yet. Booking will be available once a coach is assigned.',
              style: const TextStyle(color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(
    LanguageProvider lang,
    bool isArabic,
    bool hasAssignedCoach,
  ) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 20, color: Color(0xFF9333EA)),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'اختر التاريخ' : 'Select Date',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: isArabic ? 'ar' : 'en',
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF9333EA),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            onDaySelected: hasAssignedCoach
                ? (selectedDay, focusedDay) async {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedTime = null;
                    });
                    await _loadSlotsForDate(selectedDay);
                  }
                : null,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimeSection(LanguageProvider lang, bool isArabic) {
    final dateKey = _selectedDate?.toIso8601String().split('T').first;
    final availableSlots = DemoConfig.isDemo
        ? <String>['09:00', '10:00', '11:00', '16:00']
        : (dateKey == null
            ? const <String>[]
            : (_availableSlotsByDate[dateKey] ?? const <String>[]));

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF9333EA)),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الأوقات المتاحة' : 'Available Slots',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isArabic ? 'التاريخ' : 'Date'}: ${DateFormat('EEE, MMM d', isArabic ? 'ar' : 'en').format(_selectedDate!)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isSlotsLoading && !DemoConfig.isDemo)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (availableSlots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _slotsError != null
                      ? (isArabic
                          ? 'تعذر تحميل المواعيد المتاحة'
                          : 'Unable to load available slots')
                      : (isArabic
                          ? 'لا توجد أوقات متاحة'
                          : 'No available slots'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSlots.map((slot) {
                final isSelected = _selectedTime == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTime = slot),
                  selectedColor: const Color(0xFF9333EA),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        isSelected ? const Color(0xFF9333EA) : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsSection(bool isArabic) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تفاصيل الجلسة' : 'Session Details',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'المدة' : 'Duration',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 45, 60, 90].map((duration) {
              final isSelected = _selectedDuration == duration;
              return ChoiceChip(
                label: Text('$duration ${isArabic ? 'د' : 'min'}'),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDuration = duration),
                selectedColor: const Color(0xFF9333EA),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color:
                      isSelected ? const Color(0xFF9333EA) : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'ملاحظات إضافية' : 'Notes (optional)',
              hintText: isArabic
                  ? 'مثال: أحتاج مراجعة فورم التمرين'
                  : 'Example: Need form check',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(LanguageProvider lang, bool isArabic) {
    final coachName = DemoConfig.isDemo
        ? (isArabic
            ? (_demoCoach['nameAr'] ?? _demoCoach['name'])
            : _demoCoach['name'])
        : (_coachProfile?.name ?? (isArabic ? 'المدرب' : 'Coach'));

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isArabic ? 'تأكيد الحجز' : 'Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coachName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                isArabic ? 'التاريخ' : 'Date',
                DateFormat('EEEE, MMM d, yyyy', isArabic ? 'ar' : 'en')
                    .format(_selectedDate!),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                isArabic ? 'الوقت' : 'Time',
                _selectedTime!,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                isArabic ? 'المدة' : 'Duration',
                '$_selectedDuration ${isArabic ? 'دقيقة' : 'minutes'}',
              ),
              if (_notesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  isArabic ? 'ملاحظات' : 'Notes',
                  _notesController.text.trim(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmBooking(isArabic);
              },
              icon: const Icon(Icons.videocam, size: 18),
              label: Text(isArabic ? 'احجز الآن' : 'Book Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmBooking(bool isArabic) async {
    if (_selectedDate == null || _selectedTime == null || _isBooking) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      if (DemoConfig.isDemo) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      } else {
        final authProvider = context.read<AuthProvider>();
        final appointmentProvider = context.read<AppointmentProvider>();
        await _bookingRepository.createBooking(
          scheduledDate: _selectedDate!,
          scheduledTime: _selectedTime!,
          durationMinutes: _selectedDuration,
          notes: _notesController.text,
          coachId: authProvider.user?.coachId,
        );
        final userId = authProvider.user?.id;
        if (userId != null && userId.isNotEmpty) {
          await appointmentProvider.loadUserAppointments(
            userId: userId,
            refresh: true,
          );
        }
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم حجز الجلسة بنجاح'
                : 'Video session booked successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      if (e.response?.statusCode == 409 && _selectedDate != null) {
        await _loadSlotsForDate(_selectedDate!, forceRefresh: true);
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedTime = null;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'هذا الموعد لم يعد متاحًا. تم تحديث الأوقات.'
                  : 'Selected time slot is no longer available. Slots were refreshed.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        final message = e.response?.data is Map<String, dynamic>
            ? ((e.response?.data['message'] as String?) ??
                (isArabic
                    ? 'تعذر إتمام الحجز. حاول مرة أخرى.'
                    : 'Unable to complete booking. Please try again.'))
            : (isArabic
                ? 'تعذر إتمام الحجز. حاول مرة أخرى.'
                : 'Unable to complete booking. Please try again.');
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر إتمام الحجز. حاول مرة أخرى.'
                : 'Unable to complete booking. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Future<void> _loadCoachProfile(String coachId) async {
    if (_isCoachLoading) {
      return;
    }
    setState(() {
      _isCoachLoading = true;
      _coachError = null;
    });
    try {
      final profile = await _coachRepository.getCoachProfile(coachId: coachId);
      if (!mounted) {
        return;
      }
      setState(() {
        _coachProfile = profile;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coachError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCoachLoading = false;
        });
      }
    }
  }

  Future<void> _syncAssignedCoach(
    String coachId, {
    bool forceReload = false,
  }) async {
    if (!forceReload && coachId == _loadedCoachId) {
      return;
    }

    setState(() {
      _loadedCoachId = coachId;
      _coachProfile = null;
      _coachError = null;
      _availableSlotsByDate.clear();
      _selectedDate = null;
      _selectedTime = null;
      _slotsError = null;
    });

    await _loadCoachProfile(coachId);
    if (!mounted) {
      return;
    }
    await _prefetchInitialSlots(coachId);
  }

  Future<void> _prefetchInitialSlots(String coachId) async {
    final today = DateTime.now();
    await _loadSlotsRange(
      startDate: today,
      endDate: today.add(const Duration(days: 14)),
      coachId: coachId,
    );
  }

  Future<void> _loadDemoSlots() async {
    final today = DateTime.now();
    for (var i = 0; i < 7; i += 1) {
      final date = today.add(Duration(days: i));
      _availableSlotsByDate[_formatDateKey(date)] = switch (i % 3) {
        0 => ['09:00', '10:00', '11:00'],
        1 => ['14:00', '16:00'],
        _ => ['18:00'],
      };
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSlotsRange({
    required DateTime startDate,
    required DateTime endDate,
    required String coachId,
  }) async {
    setState(() {
      _isSlotsLoading = true;
      _slotsError = null;
    });
    try {
      final slots = await _bookingRepository.getAvailableSlots(
        startDate: startDate,
        endDate: endDate,
        coachId: coachId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _availableSlotsByDate.addAll(slots);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _slotsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSlotsLoading = false;
        });
      }
    }
  }

  Future<void> _loadSlotsForDate(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    if (DemoConfig.isDemo) {
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final coachId = authProvider.user?.coachId;
    if (coachId == null || coachId.isEmpty) {
      return;
    }
    final key = _formatDateKey(date);
    if (!forceRefresh && _availableSlotsByDate.containsKey(key)) {
      return;
    }
    await _loadSlotsRange(
      startDate: date,
      endDate: date,
      coachId: coachId,
    );
  }

  String _formatDateKey(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
