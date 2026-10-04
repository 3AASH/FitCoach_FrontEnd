import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import 'coach_client_detail_screen.dart';
import 'coach_message_thread_screen.dart';
import 'coach_schedule_session_sheet.dart';
import '../../../core/theme/app_palette.dart';

class CoachClientsScreen extends StatefulWidget {
  const CoachClientsScreen({super.key});

  @override
  State<CoachClientsScreen> createState() => _CoachClientsScreenState();
}

class _CoachClientsScreenState extends State<CoachClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
    });
  }

  void _loadClients() {
    final authProvider = context.read<AuthProvider>();
    final coachProvider = context.read<CoachProvider>();

    if (authProvider.user?.id != null) {
      coachProvider.loadClients(
        coachId: authProvider.user!.id,
        status: _statusFilter,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final coachProvider = context.watch<CoachProvider>();
        return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_clients_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: lang.t('coach_clients_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadClients();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _loadClients();
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Status filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText:
                              lang.t('coach_clients_status_label'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                                lang.t('coach_clients_status_all')),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(lang
                                .t('coach_clients_status_active')),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(lang
                                .t('coach_clients_status_inactive')),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                          _loadClients();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Client list
          Expanded(
            child: coachProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : coachProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              coachProvider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadClients,
                              child: Text(lang.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : coachProvider.clients.isEmpty
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
                                  lang.t('coach_clients_empty'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadClients(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: coachProvider.clients.length,
                              itemBuilder: (context, index) {
                                final client = coachProvider.clients[index];
                                return _buildClientCard(client, lang);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(
    client,
    LanguageProvider lang,
  ) {
    final checkInBadge = _buildCheckInBadge(client, lang);

    return CustomCard(
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CoachClientDetailScreen(clientId: client.id),
            ),
          );
          if (mounted) {
            _loadClients();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: client.profilePhotoUrl != null
                        ? NetworkImage(client.profilePhotoUrl!)
                        : null,
                    child: client.profilePhotoUrl == null
                        ? Text(
                            client.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (client.goal != null)
                          Text(
                            client.goal!,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTierColor(client.subscriptionTier),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                client.subscriptionTier,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(client.statusText),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                client.statusText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (checkInBadge != null) checkInBadge,
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (client.fitnessScore != null) ...[
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getScoreColor(client.fitnessScore!),
                          ),
                          child: Center(
                            child: Text(
                              '${client.fitnessScore}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('coach_clients_score_label'),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: context.palette.textDisabled,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(lang.t('coach_message')),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CoachMessageThreadScreen(
                              clientId: client.id,
                              clientName: client.fullName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: Text(lang.t('coach_schedule_call')),
                      onPressed: () {
                        showCoachScheduleSessionSheet(
                          context,
                          clientId: client.id,
                          clientName: client.fullName,
                        );
                      },
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

  Widget? _buildCheckInBadge(client, LanguageProvider lang) {
    final label = _checkInBadgeText(client, lang);
    if (label == null) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _checkInBadgeText(client, LanguageProvider lang) {
    final referenceDate = client.latestInbodyScanDate ?? client.lastActivity;
    if (referenceDate == null) {
      return null;
    }

    final daysAgo = DateTime.now().difference(referenceDate).inDays;
    if (client.latestInbodyScanDate != null) {
      if (daysAgo <= 0) {
        return lang.t('coach_clients_checked_in_today');
      }
      return lang.t('coach_clients_last_inbody_daysago',
          args: {'days': '$daysAgo'});
    }

    if (daysAgo <= 0) {
      return lang.t('coach_clients_active_today');
    }
    return lang.t('coach_clients_last_activity_daysago',
        args: {'days': '$daysAgo'});
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'smart premium':
        return AppColors.accent;
      case 'premium':
        return AppColors.primary;
      case 'freemium':
      default:
        return AppColors.textSecondary; // fill under a pinned-white label: the
        // theme token lightens in dark mode and left white on light grey
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'recent':
        return AppColors.warning;
      case 'inactive':
        return AppColors.error;
      case 'new':
        return AppColors.info;
      default:
        return AppColors.textSecondary; // fill under a pinned-white label: the
        // theme token lightens in dark mode and left white on light grey
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
