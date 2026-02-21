import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/admin_user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _tierFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers() {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadUsers(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      subscriptionTier: _tierFilter,
      status: _statusFilter,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_users_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
                              _loadUsers();
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
                        _loadUsers();
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
                        value: _tierFilter,
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
                          _loadUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _statusFilter,
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
                          _loadUsers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User list
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
                              onPressed: _loadUsers,
                              child: Text(lang.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: AppColors.textDisabled,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  lang.t('admin_users_empty'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadUsers(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
                            color: user.isActive ? AppColors.success : AppColors.error,
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
                              style: const TextStyle(
                                fontSize: 10,
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
                        const Icon(Icons.delete, size: 18, color: AppColors.error),
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
              _buildDetailRow(lang.t('email'), user.email ?? lang.t('not_available')),
              _buildDetailRow(lang.t('admin_phone_label'), user.phoneNumber ?? lang.t('not_available')),
              _buildDetailRow(lang.t('admin_users_filter_tier'), user.subscriptionTier),
              _buildDetailRow(
                lang.t('admin_users_filter_status'),
                user.isActive ? (lang.t('admin_status_active')) : (lang.t('admin_status_inactive')),
              ),
              _buildDetailRow(lang.t('admin_coach_label'), user.coachName ?? (lang.t('admin_not_assigned'))),
              _buildDetailRow(lang.t('admin_created_label'), _formatDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow(lang.t('admin_last_login_label'), _formatDate(user.lastLogin!)),
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
        builder: (context, setState) => AlertDialog(
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
                  value: selectedTier,
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
                  value: selectedCoachId,
                  decoration: InputDecoration(
                    labelText: lang.t('admin_coach_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(lang.t('admin_not_assigned')),
                    ),
                    ...context
                        .watch<AdminProvider>()
                        .coaches
                        .map(
                          (coach) => DropdownMenuItem(
                            value: coach.id,
                            child: Text(coach.fullName),
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
                Navigator.pop(context);

                final adminProvider = context.read<AdminProvider>();
                final success = await adminProvider.updateUser(
                  user.id,
                  fullName: nameController.text,
                  email: emailController.text,
                  subscriptionTier: selectedTier,
                  isActive: isActive,
                  coachId: selectedCoachId,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.t('admin_user_updated_success')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadUsers();
                }
              },
              child: Text(lang.t('save')),
            ),
          ],
        ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_suspend_reason_required')),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.suspendUser(user.id, reasonController.text);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_user_suspended_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadUsers();
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
              Navigator.pop(context);

              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.deleteUser(user.id);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.t('admin_user_deleted_success')),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadUsers();
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
        return AppColors.textSecondary;
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
