import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/admin_user.dart';
import '../../../data/models/admin_coach.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_coaches_screen.dart';
import '../../../core/theme/app_palette.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    this.initialRole = 'customers',
  });

  final String initialRole;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _roleFilter;
  String? _tierFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _roleFilter = widget.initialRole;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDirectory();
    });
  }

  void _loadDirectory() {
    final adminProvider = context.read<AdminProvider>();
    if (_roleFilter == 'coaches') {
      adminProvider.loadCoaches(
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        status: _statusFilter,
      );
      return;
    }

    adminProvider.loadUsers(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      subscriptionTier: _roleFilter == 'customers' ? _tierFilter : null,
      status: _statusFilter,
      role: _roleFilter,
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
    final directoryError = _roleFilter == 'coaches'
        ? adminProvider.coachesError
        : adminProvider.usersError;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_users_title')),
        actions: [
          IconButton(
            tooltip: lang.t('admin_create_admin_action'),
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _roleFilter == 'admins'
                ? () => _showCreateAdminDialog(lang)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: lang.t('admin_users_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadDirectory();
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
                        _loadDirectory();
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: _roleFilter == 'customers',
                        label: Text(lang.t('admin_user_role_customers')),
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'customers';
                          });
                          _loadDirectory();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        selected: _roleFilter == 'coaches',
                        label: Text(lang.t('admin_user_role_coaches')),
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'coaches';
                            _tierFilter = null;
                          });
                          _loadDirectory();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        selected: _roleFilter == 'admins',
                        label: Text(lang.t('admin_user_role_admins')),
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'admins';
                            _tierFilter = null;
                          });
                          _loadDirectory();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Filters
                Row(
                  children: [
                    if (_roleFilter == 'customers') ...[
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _tierFilter,
                          decoration: InputDecoration(
                            labelText: lang.t('admin_users_filter_tier'),
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
                              value: 'freemium',
                              child: Text(lang.t('admin_tier_freemium')),
                            ),
                            DropdownMenuItem(
                              value: 'premium',
                              child: Text(lang.t('admin_tier_premium')),
                            ),
                            DropdownMenuItem(
                              value: 'smart_premium',
                              child: Text(lang.t('admin_tier_smart_premium')),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _tierFilter = value;
                            });
                            _loadDirectory();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
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
                            value: 'active',
                            child: Text(lang.t('admin_status_active')),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(lang.t('admin_status_inactive')),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                          _loadDirectory();
                        },
                      ),
                    ),
                  ],
                ),
                if (_roleFilter == 'admins') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCreateAdminDialog(lang),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: Text(lang.t('admin_create_admin_action')),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // User list
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : directoryError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              directoryError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDirectory,
                              child: Text(lang.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : _roleFilter == 'coaches'
                        ? _buildCoachDirectory(adminProvider, lang)
                        : adminProvider.users.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: context.palette.textDisabled,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      lang.t('admin_users_empty'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: context.palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async => _loadDirectory(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: adminProvider.users.length,
                                  itemBuilder: (context, index) {
                                    final user = adminProvider.users[index];
                                    return _buildUserCard(user, lang);
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachDirectory(
      AdminProvider adminProvider, LanguageProvider lang) {
    if (adminProvider.coaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_outlined,
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
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDirectory(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: adminProvider.coaches.length,
        itemBuilder: (context, index) {
          final coach = adminProvider.coaches[index];
          return _buildCoachCard(coach, lang);
        },
      ),
    );
  }

  Widget _buildCoachCard(AdminCoach coach, LanguageProvider lang) {
    final status = coach.effectiveStatus;
    final statusColor = status == 'active'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : AppColors.error;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          backgroundImage: coach.profilePhotoUrl != null
              ? NetworkImage(coach.profilePhotoUrl!)
              : null,
          child: coach.profilePhotoUrl == null
              ? Text(
                  coach.initials,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          coach.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coach.email != null)
              Text(
                coach.email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMiniBadge(
                  coach.isApproved
                      ? lang.t('admin_status_approved')
                      : lang.t('admin_status_pending'),
                  coach.isApproved ? AppColors.success : AppColors.warning,
                ),
                _buildMiniBadge(status, statusColor),
                _buildMiniBadge(
                  '${coach.clientCount} ${lang.t('admin_clients_label')}',
                  AppColors.primary,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCoachesScreen()),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser user, LanguageProvider lang) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(user, lang),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.profilePhotoUrl != null
                    ? NetworkImage(user.profilePhotoUrl!)
                    : null,
                child: user.profilePhotoUrl == null
                    ? Text(
                        user.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Tier badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(user.subscriptionTier),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.subscriptionTier,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.isActive
                                ? (lang.t('admin_status_active'))
                                : (lang.t('admin_status_inactive')),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (user.coachName != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lang.t('admin_coach_prefix')} ${user.coachName}',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.palette.textSecondary,
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

              // Action menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditUserDialog(user, lang);
                      break;
                    case 'suspend':
                      _showSuspendUserDialog(user, lang);
                      break;
                    case 'delete':
                      _showDeleteUserDialog(user, lang);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(lang.t('admin_action_edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18),
                        const SizedBox(width: 8),
                        Text(lang.t('admin_action_suspend')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('admin_action_delete'),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(AdminUser user, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  lang.t('email'), user.email ?? lang.t('not_available')),
              _buildDetailRow(lang.t('admin_phone_label'),
                  user.phoneNumber ?? lang.t('not_available')),
              _buildDetailRow(
                  lang.t('admin_users_filter_tier'), user.subscriptionTier),
              _buildDetailRow(
                lang.t('admin_users_filter_status'),
                user.isActive
                    ? (lang.t('admin_status_active'))
                    : (lang.t('admin_status_inactive')),
              ),
              _buildDetailRow(lang.t('admin_coach_label'),
                  user.coachName ?? (lang.t('admin_not_assigned'))),
              _buildDetailRow(
                  lang.t('admin_created_label'), _formatDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow(lang.t('admin_last_login_label'),
                    _formatDate(user.lastLogin!)),
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

  void _showEditUserDialog(AdminUser user, LanguageProvider lang) {
    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.coaches.isEmpty) {
      adminProvider.loadCoaches();
    }
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    String selectedTier = _normalizeTier(user.subscriptionTier);
    bool isActive = user.isActive;
    String? selectedCoachId = user.coachId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final coaches = context.watch<AdminProvider>().coaches;
          final coachOptions = _buildCoachDropdownOptions(coaches);
          final optionValues = coachOptions.map((o) => o.value).toSet();
          if (selectedCoachId != null &&
              !optionValues.contains(selectedCoachId)) {
            selectedCoachId =
                _resolveStableCoachValue(selectedCoachId!, coaches);
          }
          if (selectedCoachId != null &&
              !optionValues.contains(selectedCoachId)) {
            selectedCoachId = null;
          }
          if (kDebugMode) {
            debugPrint(
              '[AdminUsers] selectedCoachId=$selectedCoachId, dropdownItems=${coachOptions.length}',
            );
          }

          return AlertDialog(
            title: Text(lang.t('admin_edit_user_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: lang.t('admin_name_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: lang.t('email'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTier,
                    decoration: InputDecoration(
                      labelText: lang.t('admin_users_filter_tier'),
                      border: const OutlineInputBorder(),
                    ),
                    items: const ['Freemium', 'Premium', 'Smart Premium']
                        .map(
                          (tier) => DropdownMenuItem(
                            value: tier,
                            child: Text(_formatTierLabel(tier, lang)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTier = value ?? selectedTier;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedCoachId,
                    decoration: InputDecoration(
                      labelText: lang.t('admin_coach_label'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(lang.t('admin_not_assigned')),
                      ),
                      if (coachOptions.isNotEmpty)
                        ...coachOptions.map(
                          (option) => DropdownMenuItem<String?>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCoachId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(lang.t('admin_status_active')),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final adminProvider = this.context.read<AdminProvider>();
                  final messenger = ScaffoldMessenger.of(this.context);
                  Navigator.pop(context);

                  final success = await adminProvider.updateUser(
                    user.id,
                    fullName: nameController.text,
                    email: emailController.text,
                    subscriptionTier: selectedTier,
                    isActive: isActive,
                    coachId: selectedCoachId,
                  );

                  if (success && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(lang.t('admin_user_updated_success')),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    await adminProvider.loadCoaches();
                    _loadDirectory();
                  }
                },
                child: Text(lang.t('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_CoachDropdownOption> _buildCoachDropdownOptions(
      List<AdminCoach> rawCoaches) {
    final options = <_CoachDropdownOption>[];
    final seen = <String>{};
    final duplicates = <String>{};

    for (final coach in rawCoaches) {
      final value =
          (coach.userId.trim().isNotEmpty ? coach.userId : coach.id).trim();
      if (value.isEmpty) {
        continue;
      }
      if (!seen.add(value)) {
        duplicates.add(value);
        continue;
      }
      options.add(_CoachDropdownOption(
        value: value,
        label: coach.fullName,
      ));
    }

    if (kDebugMode) {
      debugPrint(
        '[AdminUsers] coaches before=${rawCoaches.length}, after=${options.length}, duplicates=${duplicates.toList()}',
      );
    }

    return options;
  }

  String? _resolveStableCoachValue(
      String selectedId, List<AdminCoach> coaches) {
    for (final coach in coaches) {
      if (coach.id == selectedId || coach.userId == selectedId) {
        return coach.userId.trim().isNotEmpty ? coach.userId : coach.id;
      }
    }
    return null;
  }

  void _showCreateAdminDialog(LanguageProvider lang) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(lang.t('admin_create_admin_title')),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: lang.t('admin_full_name_label'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? lang.t('admin_full_name_required')
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: lang.t('email'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return lang.t('admin_email_required');
                        }
                        if (!email.contains('@') || !email.contains('.')) {
                          return lang.t('admin_invalid_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: lang.t('admin_phone_optional'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: lang.t('admin_password_optional'),
                        helperText: lang.t('admin_password_optional_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        final password = value?.trim() ?? '';
                        if (password.isNotEmpty && password.length < 6) {
                          return lang.t('admin_password_min');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(lang.t('cancel')),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        setDialogState(() => saving = true);
                        final dialogNavigator = Navigator.of(dialogContext);
                        final messenger = ScaffoldMessenger.of(context);
                        final adminProvider = context.read<AdminProvider>();
                        final result = await adminProvider.createAdmin(
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                        if (!mounted) return;
                        dialogNavigator.pop();
                        if (result == null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(adminProvider.error ??
                                  lang.t('admin_create_admin_failed')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        _loadDirectory();
                        _showAdminCredentialsDialog(result, lang);
                      },
                child: Text(saving
                    ? lang.t('admin_sending')
                    : lang.t('admin_create_admin_action')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminCredentialsDialog(
      AdminCreationResult result, LanguageProvider lang) {
    final credentials = result.credentials;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('admin_admin_created_success')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${lang.t('email')}: ${credentials?.email ?? result.admin.email ?? ''}'),
            const SizedBox(height: 8),
            Text(
                '${lang.t('password')}: ${credentials?.defaultPassword ?? '123456'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('ok')),
          ),
        ],
      ),
    );
  }

  void _showSuspendUserDialog(AdminUser user, LanguageProvider lang) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('admin_suspend_user_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('admin_suspend_prompt', args: {'name': user.fullName}),
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
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_suspend_reason_required')),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final adminProvider = this.context.read<AdminProvider>();
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);

              final success = await adminProvider.suspendUser(
                  user.id, reasonController.text);

              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_user_suspended_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadDirectory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(lang.t('admin_action_suspend')),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(AdminUser user, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('admin_delete_user_title')),
        content: Text(
          lang.t('admin_delete_prompt', args: {'name': user.fullName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider = this.context.read<AdminProvider>();
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);

              final success = await adminProvider.deleteUser(user.id);

              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_user_deleted_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadDirectory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(lang.t('admin_action_delete')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'smart premium':
      case 'smart_premium':
        return AppColors.accent;
      case 'premium':
        return AppColors.primary;
      case 'freemium':
      default:
        return context.palette.textSecondary;
    }
  }

  String _normalizeTier(String tier) {
    switch (tier.trim().toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'smart premium':
      case 'smart_premium':
        return 'Smart Premium';
      default:
        return 'Freemium';
    }
  }

  String _formatTierLabel(String tier, LanguageProvider lang) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return lang.t('admin_tier_premium');
      case 'smart premium':
        return lang.t('admin_tier_smart_premium');
      default:
        return lang.t('admin_tier_freemium');
    }
  }
}

class _CoachDropdownOption {
  final String value;
  final String label;

  const _CoachDropdownOption({
    required this.value,
    required this.label,
  });
}
