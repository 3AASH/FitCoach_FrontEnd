import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/admin_coach.dart';
import '../../../core/theme/app_palette.dart';

class AdminCoachesScreen extends StatefulWidget {
  const AdminCoachesScreen({super.key});

  @override
  State<AdminCoachesScreen> createState() => _AdminCoachesScreenState();
}

class _AdminCoachesScreenState extends State<AdminCoachesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  bool _showPendingOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoaches();
    });
  }

  void _loadCoaches() {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadCoaches(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _statusFilter,
      approved: _showPendingOnly ? 'false' : null,
    );
  }

  void _showCreateCoachSheet(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final messenger = ScaffoldMessenger.of(context);
        return _CreateCoachSheet(
          lang: lang,
          onSubmit: (payload) async {
            final adminProvider = context.read<AdminProvider>();
            final result = await adminProvider.createCoach(
              fullName: payload.fullName,
              email: payload.email,
              phoneNumber: payload.phoneNumber,
              specializations: payload.specializations,
            );

            if (!mounted || !sheetContext.mounted) return null;

            if (result != null) {
              Navigator.of(sheetContext).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    lang.t('admin_coach_created_success'),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadCoaches();
              if (result.credentials != null) {
                _showCredentialsDialog(lang, result.credentials!);
              }
            }
            return result;
          },
        );
      },
    );
  }

  void _showCredentialsDialog(
    LanguageProvider lang,
    CoachCredentials credentials,
  ) {
    final textToCopy =
        'Email: ${credentials.email}\nPassword: ${credentials.defaultPassword}';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('admin_coach_credentials_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lang.t('email')}: ${credentials.email}'),
            const SizedBox(height: 8),
            Text('${lang.t('auth_password')}: ${credentials.defaultPassword}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(lang.t('close')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: textToCopy));
              if (!mounted || !dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(lang.t('admin_credentials_copied'))),
              );
            },
            icon: const Icon(Icons.copy),
            label: Text(lang.t('admin_copy_credentials')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final lang = languageProvider;
    final coachesError = adminProvider.coachesError;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_coaches_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoaches,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pending approvals banner
          if (adminProvider.pendingCoaches.isNotEmpty && !_showPendingOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.t(
                        'admin_coaches_pending_banner',
                        args: {
                          'count': '${adminProvider.pendingCoaches.length}',
                        },
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPendingOnly = true;
                      });
                      _loadCoaches();
                    },
                    child: Text(lang.t('admin_view')),
                  ),
                ],
              ),
            ),

          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: lang.t('admin_coaches_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadCoaches();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _loadCoaches();
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText: lang.t('admin_users_filter_status'),
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
                            value: 'approved',
                            child: Text(lang.t('admin_status_approved')),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text(lang.t('admin_status_pending')),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text(lang.isArabic ? 'معلّق' : 'Suspended'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                          _loadCoaches();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilterChip(
                        label: Text(lang.t('admin_pending_only')),
                        selected: _showPendingOnly,
                        onSelected: (value) {
                          setState(() {
                            _showPendingOnly = value;
                          });
                          _loadCoaches();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Coach list
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : coachesError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              coachesError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCoaches,
                              child: Text(lang.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.coaches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: context.palette.textDisabled,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  lang.t('admin_coaches_empty'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadCoaches(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: adminProvider.coaches.length,
                              itemBuilder: (context, index) {
                                final coach = adminProvider.coaches[index];
                                return _buildCoachCard(coach, lang);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCoachSheet(lang),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(lang.t('admin_add_coach')),
      ),
    );
  }

  Widget _buildCoachCard(AdminCoach coach, LanguageProvider lang) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCoachDetailsDialog(coach, lang),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: coach.profilePhotoUrl != null
                        ? NetworkImage(coach.profilePhotoUrl!)
                        : null,
                    child: coach.profilePhotoUrl == null
                        ? Text(
                            coach.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Coach info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                coach.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusChip(coach, lang),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (coach.email != null)
                          Text(
                            coach.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.people,
                              '${coach.clientCount}',
                              lang.t('admin_clients_label'),
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              Icons.attach_money,
                              '\$${coach.totalEarnings.toStringAsFixed(0)}',
                              lang.t('admin_earned_label'),
                            ),
                            if (coach.averageRating != null) ...[
                              const SizedBox(width: 8),
                              _buildStatChip(
                                Icons.star,
                                coach.averageRating!.toStringAsFixed(1),
                                lang.t('admin_rating_label'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'approve':
                          _showApproveCoachDialog(coach, lang);
                          break;
                        case 'edit':
                          _showEditCoachSheet(coach, lang);
                          break;
                        case 'suspend':
                          _showSuspendCoachDialog(coach, lang);
                          break;
                        case 'delete':
                          _showDeleteCoachDialog(coach, lang);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!coach.isApproved && !coach.isSuspended)
                        PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(lang.t('admin_approve')),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(lang.t('admin_edit_user_title')),
                          ],
                        ),
                      ),
                      if (!coach.isSuspended)
                        PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              const Icon(Icons.block,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(lang.t('admin_action_suspend')),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_forever,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(lang.t('admin_delete_user_title')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (coach.specializations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coach.specializations.map((spec) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AdminCoach coach, LanguageProvider lang) {
    final colors = _statusColors(coach.effectiveStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(coach, lang),
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status) {
      case 'approved':
        return (AppColors.success, AppColors.success);
      case 'suspended':
        return (AppColors.error, AppColors.error);
      case 'pending':
      default:
        return (AppColors.warning, AppColors.warning);
    }
  }

  String _statusLabel(AdminCoach coach, LanguageProvider lang) {
    switch (coach.effectiveStatus) {
      case 'approved':
        return lang.t('admin_status_approved');
      case 'suspended':
        return lang.isArabic ? 'معلّق' : 'Suspended';
      case 'pending':
      default:
        return lang.t('admin_status_pending');
    }
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCoachDetailsDialog(AdminCoach coach, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(coach.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  lang.t('email'), coach.email ?? lang.t('not_available')),
              _buildDetailRow(lang.t('admin_phone_label'),
                  coach.phoneNumber ?? lang.t('not_available')),
              _buildDetailRow(
                  lang.t('admin_clients_label'), '${coach.clientCount}'),
              _buildDetailRow(lang.t('admin_earnings_label'),
                  '\$${coach.totalEarnings.toStringAsFixed(2)}'),
              if (coach.averageRating != null)
                _buildDetailRow(
                  lang.t('admin_rating_label'),
                  '${coach.averageRating!.toStringAsFixed(1)} / 5',
                ),
              _buildDetailRow(
                lang.t('admin_users_filter_status'),
                _statusLabel(coach, lang),
              ),
              if (coach.fullNameAr != null)
                _buildDetailRow(
                  lang.isArabic ? 'الاسم بالعربية' : 'Arabic name',
                  coach.fullNameAr!,
                ),
              if (coach.bio != null)
                _buildDetailRow(
                  lang.isArabic ? 'نبذة' : 'Bio',
                  coach.bio!,
                ),
              if (coach.experienceYears != null)
                _buildDetailRow(
                  lang.isArabic ? 'سنوات الخبرة' : 'Experience',
                  '${coach.experienceYears}',
                ),
              _buildDetailRow(
                  lang.t('admin_created_label'), _formatDate(coach.createdAt)),
              if (coach.approvedAt != null)
                _buildDetailRow(lang.t('admin_status_approved'),
                    _formatDate(coach.approvedAt!)),
              if (coach.specializations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lang.t('admin_specializations_label'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coach.specializations.map((spec) {
                    return Chip(
                      label: Text(spec, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.t('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.palette.textSecondary,
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

  void _showApproveCoachDialog(AdminCoach coach, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('admin_approve_coach_title')),
        content: Text(
          lang.t('admin_approve_coach_prompt', args: {'name': coach.fullName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final messenger = ScaffoldMessenger.of(context);
              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.approveCoach(coach.id);

              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_coach_approved_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadCoaches();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(lang.t('admin_approve')),
          ),
        ],
      ),
    );
  }

  void _showSuspendCoachDialog(AdminCoach coach, LanguageProvider lang) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('admin_suspend_coach_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('admin_suspend_coach_prompt',
                  args: {'name': coach.fullName}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: lang.t('admin_reason_label'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_suspend_reason_required')),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final messenger = ScaffoldMessenger.of(context);
              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.suspendCoach(
                  coach.id, reasonController.text);

              if (!mounted) {
                return;
              }

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? lang.t('admin_coach_suspended_success')
                        : (adminProvider.error ??
                            (lang.isArabic
                                ? 'فشل تعليق المدرب'
                                : 'Failed to suspend coach')),
                  ),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ),
              );

              if (success) {
                _loadCoaches();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(lang.t('admin_action_suspend')),
          ),
        ],
      ),
    );
  }

  void _showEditCoachSheet(AdminCoach coach, LanguageProvider lang) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final messenger = ScaffoldMessenger.of(context);
        return _EditCoachSheet(
          coach: coach,
          lang: lang,
          onSubmit: (payload) async {
            final adminProvider = context.read<AdminProvider>();
            final success = await adminProvider.updateCoach(coach.id, payload);
            if (!mounted || !sheetContext.mounted) {
              return false;
            }
            if (success) {
              Navigator.of(sheetContext).pop();
              messenger.showSnackBar(
                SnackBar(
                  content:
                      Text(lang.isArabic ? 'تم تحديث المدرب' : 'Coach updated'),
                  backgroundColor: AppColors.success,
                ),
              );
              return true;
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  adminProvider.error ??
                      (lang.isArabic
                          ? 'فشل تحديث المدرب'
                          : 'Failed to update coach'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
            return false;
          },
        );
      },
    );
  }

  void _showDeleteCoachDialog(AdminCoach coach, LanguageProvider lang) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('admin_delete_user_title')),
        content: Text(
          lang.isArabic
              ? 'هل تريد حذف المدرب ${coach.fullName}؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Delete coach ${coach.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.deleteCoach(coach.id);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? (lang.isArabic ? 'تم حذف المدرب' : 'Coach deleted')
                        : (adminProvider.error ??
                            (lang.isArabic
                                ? 'فشل حذف المدرب'
                                : 'Failed to delete coach')),
                  ),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(lang.t('admin_delete_user_title')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateCoachSheet extends StatefulWidget {
  final LanguageProvider lang;
  final Future<CoachCreationResult?> Function(_CoachCreatePayload payload)
      onSubmit;

  const _CreateCoachSheet({
    required this.lang,
    required this.onSubmit,
  });

  @override
  State<_CreateCoachSheet> createState() => _CreateCoachSheetState();
}

class _CreateCoachSheetState extends State<_CreateCoachSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final List<String> _specializations = [];
  bool _isSubmitting = false;
  bool _canSubmit = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_handleRequiredFieldsChanged);
    _emailController.addListener(_handleRequiredFieldsChanged);
    _phoneController.addListener(_handleRequiredFieldsChanged);
    _handleRequiredFieldsChanged();
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_handleRequiredFieldsChanged);
    _emailController.removeListener(_handleRequiredFieldsChanged);
    _phoneController.removeListener(_handleRequiredFieldsChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.palette.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                lang.t('admin_create_coach_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lang.t('admin_create_coach_subtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: lang.t('admin_full_name_label'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.t('admin_full_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang.t('email'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.t('admin_email_required');
                  }
                  if (!value.contains('@')) {
                    return lang.t('admin_invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: lang.t('admin_phone_label'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('admin_specializations_label'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _specializationController,
                      decoration: InputDecoration(
                        hintText: lang.t('admin_add_specialty_hint'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _addSpecialization(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addSpecialization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: Text(lang.t('admin_add')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_specializations.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specializations.map((spec) {
                    return Chip(
                      label: Text(spec),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeSpecialization(spec),
                    );
                  }).toList(),
                )
              else
                Text(
                  lang.t('admin_no_specializations'),
                  style: TextStyle(
                      color: context.palette.textSecondary, fontSize: 12),
                ),
              if (_submitError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _submitError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: _isSubmitting
                    ? (lang.t('admin_sending'))
                    : (lang.t('admin_create_coach_action')),
                onPressed:
                    (!_canSubmit || _isSubmitting) ? null : _handleSubmit,
                fullWidth: true,
                size: ButtonSize.large,
                icon: Icons.person_add_alt_1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSpecialization() {
    final value = _specializationController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _specializations.add(value);
      _specializationController.clear();
    });
  }

  void _handleRequiredFieldsChanged() {
    final canSubmit = _fullNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
    if (_canSubmit == canSubmit && _submitError == null) {
      return;
    }
    setState(() {
      _canSubmit = canSubmit;
      _submitError = null;
    });
  }

  void _removeSpecialization(String spec) {
    setState(() {
      _specializations.remove(spec);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final payload = _CoachCreatePayload(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      specializations: List<String>.from(_specializations),
    );

    final result = await widget.onSubmit(payload);

    if (mounted && result == null) {
      final providerError = context.read<AdminProvider>().error;
      setState(() {
        _isSubmitting = false;
        _submitError = _normalizeSubmitError(providerError);
      });
    }
  }

  String _normalizeSubmitError(String? error) {
    final message = (error ?? widget.lang.t('admin_create_coach_failed'))
        .replaceFirst('Exception: ', '')
        .trim();
    if (message.isEmpty) {
      return widget.lang.t('admin_create_coach_failed');
    }
    return message;
  }
}

class _EditCoachSheet extends StatefulWidget {
  final AdminCoach coach;
  final LanguageProvider lang;
  final Future<bool> Function(AdminCoachUpdatePayload payload) onSubmit;

  const _EditCoachSheet({
    required this.coach,
    required this.lang,
    required this.onSubmit,
  });

  @override
  State<_EditCoachSheet> createState() => _EditCoachSheetState();
}

class _EditCoachSheetState extends State<_EditCoachSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _fullNameArController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _bioController;
  late final TextEditingController _experienceYearsController;
  late final TextEditingController _specializationController;
  late List<String> _specializations;
  late bool _isApproved;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final coach = widget.coach;
    _fullNameController = TextEditingController(text: coach.fullName);
    _fullNameArController = TextEditingController(text: coach.fullNameAr ?? '');
    _emailController = TextEditingController(text: coach.email ?? '');
    _phoneController = TextEditingController(text: coach.phoneNumber ?? '');
    _photoUrlController =
        TextEditingController(text: coach.profilePhotoUrl ?? '');
    _bioController = TextEditingController(text: coach.bio ?? '');
    _experienceYearsController = TextEditingController(
      text: coach.experienceYears?.toString() ?? '',
    );
    _specializationController = TextEditingController();
    _specializations = List<String>.from(coach.specializations);
    _isApproved = coach.isApproved;
    _isActive = coach.isActive && !coach.isSuspended;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fullNameArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    _experienceYearsController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.palette.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                lang.isArabic ? 'تعديل بيانات المدرب' : 'Edit coach',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: lang.t('admin_full_name_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.t('admin_full_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameArController,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'الاسم بالعربية' : 'Arabic name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang.t('email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.t('admin_email_required');
                  }
                  if (!value.contains('@')) {
                    return lang.t('admin_invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: lang.t('admin_phone_label'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: lang.isArabic
                      ? 'رابط الصورة الشخصية'
                      : 'Profile photo URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceYearsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      lang.isArabic ? 'سنوات الخبرة' : 'Years of experience',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: lang.isArabic ? 'نبذة' : 'Bio',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('admin_specializations_label'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _specializationController,
                      decoration: InputDecoration(
                        hintText: lang.t('admin_add_specialty_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _addSpecialization(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _addSpecialization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Text(lang.t('admin_add')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_specializations.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specializations.map((spec) {
                    return Chip(
                      label: Text(spec),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _isSubmitting
                          ? null
                          : () => _removeSpecialization(spec),
                    );
                  }).toList(),
                )
              else
                Text(
                  lang.t('admin_no_specializations'),
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(lang.t('admin_status_approved')),
                subtitle: Text(
                  lang.isArabic
                      ? 'تحديد ما إذا كان المدرب معتمدًا'
                      : 'Whether the coach is approved',
                ),
                value: _isApproved,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _isApproved = value;
                        });
                      },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(lang.isArabic ? 'نشط' : 'Active'),
                subtitle: Text(
                  lang.isArabic
                      ? 'تعطيل هذا الخيار سيجعل حالة المدرب معلّقة'
                      : 'Turning this off will mark the coach as suspended',
                ),
                value: _isActive,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isSubmitting
                    ? (lang.isArabic ? 'جارٍ الحفظ...' : 'Saving...')
                    : (lang.isArabic ? 'حفظ التغييرات' : 'Save changes'),
                onPressed: _isSubmitting ? null : _handleSubmit,
                fullWidth: true,
                size: ButtonSize.large,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSpecialization() {
    final value = _specializationController.text.trim();
    if (value.isEmpty) {
      return;
    }
    if (_specializations.contains(value)) {
      _specializationController.clear();
      return;
    }
    setState(() {
      _specializations = [..._specializations, value];
      _specializationController.clear();
    });
  }

  void _removeSpecialization(String spec) {
    setState(() {
      _specializations =
          _specializations.where((item) => item != spec).toList();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final yearsText = _experienceYearsController.text.trim();
    final years = yearsText.isEmpty ? null : int.tryParse(yearsText);
    final payload = AdminCoachUpdatePayload(
      fullName: _fullNameController.text.trim(),
      fullNameAr: _nullIfEmpty(_fullNameArController.text),
      email: _emailController.text.trim(),
      phoneNumber: _nullIfEmpty(_phoneController.text),
      profilePhotoUrl: _nullIfEmpty(_photoUrlController.text),
      bio: _nullIfEmpty(_bioController.text),
      yearsOfExperience: years,
      specializations: List<String>.from(_specializations),
      isApproved: _isApproved,
      isActive: _isActive,
    );

    final success = await widget.onSubmit(payload);
    if (mounted && !success) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _CoachCreatePayload {
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<String> specializations;

  const _CoachCreatePayload({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.specializations = const [],
  });
}
