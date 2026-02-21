import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/models/coach_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/coach_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../subscription/subscription_manager_screen.dart';

class VideoBookingScreen extends StatefulWidget {
  const VideoBookingScreen({super.key});

  @override
  State<VideoBookingScreen> createState() => _VideoBookingScreenState();
}

class _VideoBookingScreenState extends State<VideoBookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  final CoachRepository _coachRepository = CoachRepository();
  final BookingRepository _bookingRepository = BookingRepository();

  CoachProfile? _coachProfile;
  bool _isCoachLoading = false;
  String? _coachError;

  final Map<String, List<String>> _availableSlotsByDate = {};
  bool _isSlotsLoading = false;
  String? _slotsError;
  bool _isBooking = false;

  // Assigned coach info (in real app, comes from user profile)
  final Map<String, dynamic> _assignedCoach = {
    'id': '1',
    'name': 'Ahmed Hassan',
    'nameAr': 'أحمد حسن',
    'specialties': ['Weight Loss', 'Strength Training', 'Nutrition'],
    'specialtiesAr': ['فقدان الوزن', 'تدريب القوة', 'التغذية'],
    'rating': 4.9,
    'yearsExperience': 8,
    'availableSlots': ['09:00', '10:00', '14:00', '16:00', '18:00'],
  };

  // All possible time slots
  final List<String> _allTimeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
    '19:00', '20:00', '21:00'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || DemoConfig.isDemo) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile(notify: false);
      if (!mounted) return;
      final coachId = authProvider.user?.coachId;
      if (coachId == null) return;
      _loadCoachProfile(coachId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = languageProvider.isArabic;
    final tier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final hasAssignedCoach =
        DemoConfig.isDemo || authProvider.user?.coachId != null;
    final coachData = _resolveCoachData(languageProvider, authProvider);

    final callsUsed = DemoConfig.isDemo ? 1 : 0;
    final callsLimit = _getCallsLimit(tier);
    final callsRemaining = callsLimit == -1 ? -1 : callsLimit - callsUsed;
    final hasCallsAvailable = callsLimit == -1 || callsRemaining > 0;

    return Scaffold(
      body: Column(
        children: [
          // Gradient header
          _buildHeader(languageProvider, isArabic, callsRemaining, callsLimit),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // No calls warning
                  if (!hasCallsAvailable)
                    _buildNoCallsWarning(languageProvider, isArabic),

                  // Assigned coach card
                  if (hasAssignedCoach)
                    _buildCoachCard(languageProvider, isArabic, coachData),
                  if (!hasAssignedCoach)
                    _buildNoCoachAssigned(languageProvider, isArabic),
                  const SizedBox(height: 20),

                  // Date selection
                  _buildDateSection(languageProvider, isArabic),
                  const SizedBox(height: 20),

                  // Time selection
                  if (_selectedDate != null)
                    _buildTimeSection(languageProvider, isArabic),

                  const SizedBox(height: 24),

                  // Book button
                  CustomButton(
                    text: isArabic ? 'تأكيد الحجز' : 'Confirm Booking',
                    onPressed: (_selectedDate != null && _selectedTime != null && hasCallsAvailable && hasAssignedCoach && !_isBooking)
                      ? () => _showConfirmDialog(context, isArabic, languageProvider)
                        : null,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                    icon: Icons.check_circle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang, bool isArabic, int callsRemaining, int callsLimit) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'حجز مكالمة فيديو' : 'Book Video Session',
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
                          ? 'جدولة مكالمة فيديو فردية مع مدربك'
                          : 'Schedule a 1-on-1 video call with your coach',
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

          // Quota display
          if (callsLimit != -1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'مكالمات الفيديو' : 'Video Calls',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '$callsRemaining / $callsLimit ${isArabic ? 'متبقية' : 'remaining'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoCallsWarning(LanguageProvider lang, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'لا توجد مكالمات متاحة' : 'No video calls available',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'قم بترقية اشتراكك لحجز جلسات فيديو مع المدربين'
                      : 'Upgrade your subscription to book video sessions with coaches',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: isArabic ? 'ترقية الآن' : 'Upgrade Now',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionManagerScreen()),
                  ),
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                  icon: Icons.workspace_premium,
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
      return _assignedCoach;
    }
    final coachName = _coachProfile?.name ?? lang.t('coach');
    final specializations = _coachProfile?.specializations ?? <String>[];
    final rating = _coachProfile?.stats.avgRating;
    final yearsExperience = _coachProfile?.yearsOfExperience;
    return {
      'id': authProvider.user?.coachId ?? 'coach',
      'name': coachName,
      'nameAr': coachName,
      'specialties': specializations,
      'specialtiesAr': specializations,
      'rating': rating == 0 ? null : rating,
      'yearsExperience': yearsExperience == 0 ? null : yearsExperience,
      'availableSlots': _allTimeSlots,
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
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
                isArabic ? 'جارٍ تحميل بيانات المدرب...' : 'Loading coach details...',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (_coachError != null && _coachProfile == null && !DemoConfig.isDemo) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Text(
          isArabic ? 'تعذر تحميل بيانات المدرب' : 'Unable to load coach details',
          style: const TextStyle(color: Color(0xFF9A3412)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                coachData['name'].toString().split(' ').map((n) => n[0]).join(''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
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
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
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
                  children: specialties.take(3).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(LanguageProvider lang, bool isArabic) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF9333EA)),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'اختر التاريخ' : 'Select Date',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
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
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
                _selectedTime = null; // Reset time when date changes
              });
              _loadSlotsForDate(selectedDay);
            },
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
    final dateKey = _selectedDate == null ? null : _formatDateKey(_selectedDate!);
    final availableSlots = DemoConfig.isDemo
      ? (_assignedCoach['availableSlots'] as List<String>)
      : (dateKey != null ? (_availableSlotsByDate[dateKey] ?? <String>[]) : <String>[]);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF9333EA)),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'اختر الوقت' : 'Select Time',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${isArabic ? 'الأوقات المتاحة في' : 'Available slots for'} ${DateFormat('MMM d', isArabic ? 'ar' : 'en').format(_selectedDate!)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isSlotsLoading && !DemoConfig.isDemo)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _allTimeSlots.length,
              itemBuilder: (context, index) {
                final slot = _allTimeSlots[index];
                final isAvailable = DemoConfig.isDemo
                    ? availableSlots.contains(slot)
                    : availableSlots.contains(slot);
                final isSelected = _selectedTime == slot;

                return GestureDetector(
                  onTap: isAvailable
                      ? () => setState(() => _selectedTime = slot)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF9333EA)
                          : isAvailable
                              ? Colors.white
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF9333EA)
                            : isAvailable
                                ? AppColors.border
                                : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!_isSlotsLoading && availableSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    _slotsError != null
                        ? (isArabic ? 'تعذر تحميل المواعيد المتاحة' : 'Unable to load available slots')
                        : (isArabic ? 'لا توجد أوقات متاحة لهذا التاريخ' : 'No slots available for this date'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, bool isArabic, LanguageProvider lang) {
    final coachName = DemoConfig.isDemo
      ? (isArabic ? (_assignedCoach['nameAr'] ?? _assignedCoach['name']) : _assignedCoach['name'])
      : (_coachProfile?.name ?? (isArabic ? 'المدرب' : 'Coach'));
    final specialties = DemoConfig.isDemo
      ? (isArabic
        ? (_assignedCoach['specialtiesAr'] as List<String>)
        : (_assignedCoach['specialties'] as List<String>))
      : (_coachProfile?.specializations ?? const <String>[]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isArabic ? 'تأكيد الحجز' : 'Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'يرجى مراجعة تفاصيل الحجز'
                  : 'Please review your booking details',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Coach info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      DemoConfig.isDemo
                          ? _assignedCoach['name'].toString().split(' ').map((n) => n[0]).join('')
                          : (coachName.isNotEmpty ? coachName.split(' ').map((n) => n[0]).join('') : 'C'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coachName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        specialties.isNotEmpty ? specialties.take(2).join(', ') : '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow(
              isArabic ? 'التاريخ' : 'Date',
              DateFormat('EEEE, MMM d, yyyy', isArabic ? 'ar' : 'en').format(_selectedDate!),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isArabic ? 'الوقت' : 'Time',
              _selectedTime!,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isArabic ? 'المدة' : 'Duration',
              '60 ${isArabic ? 'دقيقة' : 'minutes'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmBooking(context, isArabic);
            },
            icon: const Icon(Icons.videocam, size: 18),
            label: Text(isArabic ? 'احجز الآن' : 'Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _confirmBooking(BuildContext context, bool isArabic) async {
    if (_selectedDate == null || _selectedTime == null) return;
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
    });

    try {
      if (DemoConfig.isDemo) {
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        final authProvider = context.read<AuthProvider>();
        await _bookingRepository.createBooking(
          scheduledDate: _selectedDate!,
          scheduledTime: _selectedTime!,
          notes: _notesController.text,
          coachId: authProvider.user?.coachId,
        );
        final appointmentProvider = context.read<AppointmentProvider>();
        final userId = authProvider.user?.id;
        if (userId != null) {
          await appointmentProvider.loadUserAppointments(userId: userId, refresh: true);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم حجز جلسة الفيديو بنجاح'
                : 'Video session booked successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
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

  Widget _buildNoCoachAssigned(LanguageProvider lang, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF9A3412)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? 'لم يتم تعيين مدرب لك بعد. سيتم تفعيل الحجز بعد التعيين.'
                  : 'No coach is assigned yet. Booking will be available once assigned.',
              style: const TextStyle(color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCoachProfile(String coachId) async {
    if (_isCoachLoading) return;
    setState(() {
      _isCoachLoading = true;
      _coachError = null;
    });
    try {
      final profile = await _coachRepository.getCoachProfile(coachId: coachId);
      if (!mounted) return;
      setState(() {
        _coachProfile = profile;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _loadSlotsForDate(DateTime date) async {
    if (DemoConfig.isDemo || _isSlotsLoading) return;
    final dateKey = _formatDateKey(date);
    if (_availableSlotsByDate.containsKey(dateKey)) return;

    setState(() {
      _isSlotsLoading = true;
      _slotsError = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final slots = await _bookingRepository.getAvailableSlots(
        startDate: date,
        endDate: date,
        coachId: authProvider.user?.coachId,
      );
      if (!mounted) return;
      setState(() {
        _availableSlotsByDate.addAll(slots);
      });
    } catch (e) {
      if (!mounted) return;
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

  String _formatDateKey(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  int _getCallsLimit(String tier) {
    switch (tier) {
      case 'Smart Premium':
        return 4;
      case 'Premium':
        return 2;
      default:
        return 1;
    }
  }
}
