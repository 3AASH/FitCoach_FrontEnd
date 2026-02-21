import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const NotificationSettingsScreen({super.key, this.userRepository});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // User notifications
  bool _workoutReminders = true;
  bool _coachMessages = true;
  bool _nutritionTracking = false;
  bool _promotions = true;
  
  // Coach notifications
  bool _newClientAssignments = true;
  bool _clientMessages = true;
  bool _sessionReminders = true;
  bool _paymentAlerts = true;
  
  // Admin notifications
  bool _systemAlerts = true;
  bool _userReports = true;
  bool _coachApplications = true;
  bool _paymentIssues = true;
  bool _securityAlerts = true;
  
  // Notification channels
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  UserRepository get _userRepository => widget.userRepository ?? UserRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _userRepository.getNotificationSettings();
      
      if (mounted) {
        setState(() {
          _workoutReminders = settings['workout_reminders'] ?? true;
          _coachMessages = settings['coach_messages_notifications'] ?? true;
          _nutritionTracking = settings['nutrition_tracking_notifications'] ?? false;
          _promotions = settings['promotions_notifications'] ?? true;
          
          _newClientAssignments = settings['new_client_assignments'] ?? true;
          _clientMessages = settings['client_messages_notifications'] ?? true;
          _sessionReminders = settings['session_reminders'] ?? true;
          _paymentAlerts = settings['payment_alerts'] ?? true;
          
          _systemAlerts = settings['system_alerts'] ?? true;
          _userReports = settings['user_reports_notifications'] ?? true;
          _coachApplications = settings['coach_applications_notifications'] ?? true;
          _paymentIssues = settings['payment_issues_notifications'] ?? true;
          _securityAlerts = settings['security_alerts'] ?? true;
          
          _pushEnabled = settings['push_enabled'] ?? true;
          _emailEnabled = settings['email_enabled'] ?? true;
          _smsEnabled = settings['sms_enabled'] ?? false;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final t = languageProvider.t;
    final userRole = authProvider.user?.role ?? 'user';

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('notification_settings_title')),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification channels
          Text(
            t('notification_channels_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          CustomCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: t('notification_channel_push'),
                  subtitle: t('notification_channel_push_desc'),
                  icon: Icons.notifications_active,
                  value: _pushEnabled,
                  onChanged: (value) {
                    setState(() {
                      _pushEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: t('notification_channel_email'),
                  subtitle: t('notification_channel_email_desc'),
                  icon: Icons.email,
                  value: _emailEnabled,
                  onChanged: (value) {
                    setState(() {
                      _emailEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: t('notification_channel_sms'),
                  subtitle: t('notification_channel_sms_desc'),
                  icon: Icons.sms,
                  value: _smsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _smsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // User notifications
          if (userRole == 'user') ...[
            Text(
              t('notification_user_section'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            CustomCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: t('notification_workout_reminders'),
                    subtitle: t('notification_workout_reminders_desc'),
                    icon: Icons.fitness_center,
                    value: _workoutReminders,
                    onChanged: (value) {
                      setState(() {
                        _workoutReminders = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_coach_messages'),
                    subtitle: t('notification_coach_messages_desc'),
                    icon: Icons.chat_bubble,
                    value: _coachMessages,
                    onChanged: (value) {
                      setState(() {
                        _coachMessages = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_nutrition_tracking'),
                    subtitle: t('notification_nutrition_tracking_desc'),
                    icon: Icons.restaurant,
                    value: _nutritionTracking,
                    onChanged: (value) {
                      setState(() {
                        _nutritionTracking = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_promotions'),
                    subtitle: t('notification_promotions_desc'),
                    icon: Icons.local_offer,
                    value: _promotions,
                    onChanged: (value) {
                      setState(() {
                        _promotions = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Coach notifications
          if (userRole == 'coach') ...[
            Text(
              t('notification_coach_section'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            CustomCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: t('notification_new_clients'),
                    subtitle: t('notification_new_clients_desc'),
                    icon: Icons.person_add,
                    value: _newClientAssignments,
                    onChanged: (value) {
                      setState(() {
                        _newClientAssignments = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_client_messages'),
                    subtitle: t('notification_client_messages_desc'),
                    icon: Icons.message,
                    value: _clientMessages,
                    onChanged: (value) {
                      setState(() {
                        _clientMessages = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_session_reminders'),
                    subtitle: t('notification_session_reminders_desc'),
                    icon: Icons.videocam,
                    value: _sessionReminders,
                    onChanged: (value) {
                      setState(() {
                        _sessionReminders = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_payment_alerts'),
                    subtitle: t('notification_payment_alerts_desc'),
                    icon: Icons.account_balance_wallet,
                    value: _paymentAlerts,
                    onChanged: (value) {
                      setState(() {
                        _paymentAlerts = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Admin notifications
          if (userRole == 'admin') ...[
            Text(
              t('notification_admin_section'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            CustomCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: t('notification_system_alerts'),
                    subtitle: t('notification_system_alerts_desc'),
                    icon: Icons.warning,
                    value: _systemAlerts,
                    onChanged: (value) {
                      setState(() {
                        _systemAlerts = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_user_reports'),
                    subtitle: t('notification_user_reports_desc'),
                    icon: Icons.flag,
                    value: _userReports,
                    onChanged: (value) {
                      setState(() {
                        _userReports = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_coach_applications'),
                    subtitle: t('notification_coach_applications_desc'),
                    icon: Icons.how_to_reg,
                    value: _coachApplications,
                    onChanged: (value) {
                      setState(() {
                        _coachApplications = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_payment_issues'),
                    subtitle: t('notification_payment_issues_desc'),
                    icon: Icons.payment,
                    value: _paymentIssues,
                    onChanged: (value) {
                      setState(() {
                        _paymentIssues = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: t('notification_security_alerts'),
                    subtitle: t('notification_security_alerts_desc'),
                    icon: Icons.security,
                    value: _securityAlerts,
                    onChanged: (value) {
                      setState(() {
                        _securityAlerts = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      secondary: Icon(icon, color: AppColors.primary),
      activeThumbColor: AppColors.primary,
    );
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _userRepository.updateNotificationSettings({
        'workoutReminders': _workoutReminders,
        'coachMessagesNotifications': _coachMessages,
        'nutritionTrackingNotifications': _nutritionTracking,
        'promotionsNotifications': _promotions,
        'newClientAssignments': _newClientAssignments,
        'clientMessagesNotifications': _clientMessages,
        'sessionReminders': _sessionReminders,
        'paymentAlerts': _paymentAlerts,
        'systemAlerts': _systemAlerts,
        'userReportsNotifications': _userReports,
        'coachApplicationsNotifications': _coachApplications,
        'paymentIssuesNotifications': _paymentIssues,
        'securityAlerts': _securityAlerts,
        'pushEnabled': _pushEnabled,
        'emailEnabled': _emailEnabled,
        'smsEnabled': _smsEnabled,
      });
      
    } catch (e) {
      if (mounted) {
        final translator = context.read<LanguageProvider>().t;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translator('notification_save_error'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
