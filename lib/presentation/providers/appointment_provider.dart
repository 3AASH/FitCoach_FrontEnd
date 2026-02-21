import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _repository;

  AppointmentProvider(this._repository);

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _sorted(
      _appointments.where((appointment) {
        final date = _parseDate(appointment);
        return date != null && date.isAfter(now.subtract(const Duration(minutes: 1)));
      }),
    );
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _sorted(
      _appointments.where((appointment) {
        final date = _parseDate(appointment);
        return date != null && date.isBefore(now);
      }),
    );
  }

  Appointment? get nextVideoCall {
    final videos = upcomingAppointments.where(_supportsVideoSession);
    return videos.isNotEmpty ? videos.first : null;
  }

  List<Appointment> get upcomingVideoCalls =>
      upcomingAppointments.where(_supportsVideoSession).toList();

  Future<void> loadUserAppointments({
    required String userId,
    bool refresh = false,
  }) async {
    if (_isLoading) return;
    if (_hasLoaded && !refresh) return;

    if (DemoConfig.isDemo) {
      _appointments = DemoData
          .coachAppointments(coachId: 'demo-coach', userId: userId)
          .where((appointment) => appointment.userId == userId)
          .toList();
      _appointments = _sorted(_appointments);
      _error = null;
      _hasLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _repository.getUserAppointments(userId: userId);
      _appointments = _sorted(results);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _appointments = [];
    _isLoading = false;
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }

  bool canJoin(Appointment appointment) {
    if (!_supportsVideoSession(appointment)) return false;

    final status = appointment.status.toLowerCase();
    const allowedStatuses = {'confirmed', 'in_progress', 'scheduled'};
    if (!allowedStatuses.contains(status)) return false;

    final scheduledDate = _parseDate(appointment);
    if (scheduledDate == null) return false;

    final now = DateTime.now();
    final joinWindowStart = scheduledDate.subtract(const Duration(minutes: 10));
    final meetingLength = appointment.durationMinutes ?? 45;
    final joinWindowEnd = scheduledDate.add(Duration(minutes: meetingLength + 15));

    return now.isAfter(joinWindowStart) && now.isBefore(joinWindowEnd);
  }

  DateTime? _parseDate(Appointment appointment) {
    try {
      return DateTime.parse(appointment.scheduledAt);
    } catch (_) {
      return null;
    }
  }

  bool _supportsVideoSession(Appointment appointment) {
    final type = (appointment.type ?? 'video').toLowerCase();
    return type == 'video';
  }

  List<Appointment> _sorted(Iterable<Appointment> source) {
    final list = List<Appointment>.from(source);
    list.sort((a, b) {
      final aDate = _parseDate(a);
      final bDate = _parseDate(b);
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });
    return list;
  }
}
