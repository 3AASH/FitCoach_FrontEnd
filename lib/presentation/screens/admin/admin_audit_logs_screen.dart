import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/audit_log.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  String? _actionFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  void _loadLogs() {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadAuditLogs(
      action: _actionFilter,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final lang = languageProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_audit_logs_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersBottomSheet(lang),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_actionFilter != null || _dateRange != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_actionFilter != null)
                          Chip(
                            label: Text(_actionFilter!),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _actionFilter = null;
                              });
                              _loadLogs();
                            },
                          ),
                        if (_dateRange != null)
                          Chip(
                            label: Text(
                              '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _dateRange = null;
                              });
                              _loadLogs();
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _actionFilter = null;
                        _dateRange = null;
                      });
                      _loadLogs();
                    },
                    child: Text(lang.t('admin_clear_all')),
                  ),
                ],
              ),
            ),

          // Logs list
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : adminProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              adminProvider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLogs,
                              child: Text(lang.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.auditLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: AppColors.textDisabled,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  lang.t('admin_no_logs'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadLogs(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: adminProvider.auditLogs.length,
                              itemBuilder: (context, index) {
                                final log = adminProvider.auditLogs[index];
                                return _buildLogCard(log, lang);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log, LanguageProvider lang) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showLogDetails(log, lang),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getActionColor(log.action).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getActionIcon(log.action),
                  color: _getActionColor(log.action),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Log info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActionDisplayName(log.action, lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (log.userName != null)
                      Text(
                        '${lang.t('admin_user_label')}: ${log.userName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(log.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (log.ipAddress != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              log.ipAddress!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetails(AuditLog log, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionDisplayName(log.action, lang)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                lang.t('admin_user_label'),
                log.userName ?? (lang.t('admin_system_label')),
              ),
              _buildDetailRow(
                lang.t('admin_action_label'),
                log.action,
              ),
              _buildDetailRow(
                lang.t('admin_time_label'),
                _formatDateTime(log.createdAt),
              ),
              if (log.ipAddress != null)
                _buildDetailRow(
                  lang.t('admin_ip_address'),
                  log.ipAddress!,
                ),
              if (log.userAgent != null) ...[
                const SizedBox(height: 8),
                Text(
                  lang.t('admin_user_agent'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.userAgent!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  lang.t('admin_additional_details'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.metadata.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.t('admin_filters_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Action filter
              Text(
                lang.t('admin_action_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _actionFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(lang.t('admin_filter_all')),
                  ),
                  DropdownMenuItem(
                    value: 'user_created',
                    child: Text(lang.t('admin_audit_user_created')),
                  ),
                  DropdownMenuItem(
                    value: 'user_updated',
                    child: Text(lang.t('admin_audit_user_updated')),
                  ),
                  DropdownMenuItem(
                    value: 'user_deleted',
                    child: Text(lang.t('admin_audit_user_deleted')),
                  ),
                  DropdownMenuItem(
                    value: 'coach_approved',
                    child: Text(lang.t('admin_audit_coach_approved')),
                  ),
                  DropdownMenuItem(
                    value: 'coach_suspended',
                    child: Text(lang.t('admin_audit_coach_suspended')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _actionFilter = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Date range
              Text(
                lang.t('admin_date_range'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (range != null) {
                    setState(() {
                      _dateRange = range;
                    });
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  _dateRange != null
                      ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                      : (lang.t('admin_select_range')),
                ),
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    this.setState(() {
                      // Update outer state
                    });
                    _loadLogs();
                  },
                  child: Text(lang.t('admin_apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getActionIcon(String action) {
    if (action.contains('created')) return Icons.add_circle;
    if (action.contains('updated')) return Icons.edit;
    if (action.contains('deleted')) return Icons.delete;
    if (action.contains('approved')) return Icons.check_circle;
    if (action.contains('suspended')) return Icons.block;
    if (action.contains('login')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    return Icons.info;
  }

  Color _getActionColor(String action) {
    if (action.contains('created') || action.contains('approved')) return AppColors.success;
    if (action.contains('deleted') || action.contains('suspended')) return AppColors.error;
    if (action.contains('updated')) return AppColors.warning;
    return AppColors.primary;
  }

  String _getActionDisplayName(String action, LanguageProvider lang) {
    final map = <String, String>{
      'user_created': 'admin_audit_user_created',
      'user_updated': 'admin_audit_user_updated',
      'user_deleted': 'admin_audit_user_deleted',
      'coach_approved': 'admin_audit_coach_approved',
      'coach_suspended': 'admin_audit_coach_suspended',
      'user_login': 'admin_audit_user_login',
      'user_logout': 'admin_audit_user_logout',
    };
    final key = map[action];
    return key != null ? lang.t(key) : action;
  }
}
