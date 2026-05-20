import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/public_coach_profile.dart';
import '../../../data/repositories/coach_repository.dart';
import '../booking/video_booking_screen.dart';

class PublicCoachProfileScreen extends StatefulWidget {
  final String coachId;
  final VoidCallback? onMessage;
  final VoidCallback? onBookCall;

  const PublicCoachProfileScreen({
    super.key,
    required this.coachId,
    this.onMessage,
    this.onBookCall,
  });

  @override
  State<PublicCoachProfileScreen> createState() =>
      _PublicCoachProfileScreenState();
}

class _PublicCoachProfileScreenState extends State<PublicCoachProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PublicCoachProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  void _loadProfile() async {
    if (DemoConfig.isDemo) {
      setState(() {
        _profile = _getDemoProfile();
        _isLoading = false;
      });
      return;
    }

    try {
      final repo = CoachRepository();
      final profile = await repo.getCoachProfile(coachId: widget.coachId);
      setState(() {
        _profile = _publicFromComprehensive(profile);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Public coach profile load error: $e');
      }
      setState(() {
        // In production, show the error state. In dev/demo-like scenarios, fall back to demo.
        _profile = DemoConfig.isDemo ? _getDemoProfile() : null;
        _isLoading = false;
      });
    }
  }

  // Convert comprehensive CoachProfile to PublicCoachProfile for UI
  PublicCoachProfile _publicFromComprehensive(dynamic profile) {
    if (profile is PublicCoachProfile) {
      return profile;
    }

    final certificates = <Certificate>[];
    for (final raw in (profile.certificates as List? ?? const [])) {
      final item = _asMap(raw);
      if (item == null) {
        continue;
      }
      try {
        certificates.add(
          Certificate(
            id: _asString(item['id']) ??
                _asString(item['certificateId']) ??
                'certificate_${certificates.length}',
            name: _asString(item['name']) ?? _asString(item['title']) ?? '',
            issuingOrganization: _asString(item['issuing_organization']) ??
                _asString(item['issuer']) ??
                '',
            dateObtained: _parseDate(item['date_obtained']) ?? DateTime(1970),
            expiryDate: _parseDate(item['expiry_date']),
            certificateUrl:
                _asString(item['certificate_url']) ?? _asString(item['url']),
          ),
        );
      } catch (_) {}
    }

    final experiences = <WorkExperience>[];
    for (final raw in (profile.experiences as List? ?? const [])) {
      final item = _asMap(raw);
      if (item == null) {
        continue;
      }
      try {
        experiences.add(
          WorkExperience(
            id: _asString(item['id']) ??
                _asString(item['experienceId']) ??
                'experience_${experiences.length}',
            title: _asString(item['title']) ?? '',
            organization: _asString(item['organization']) ??
                _asString(item['company']) ??
                '',
            startDate: _parseDate(item['start_date']) ?? DateTime(1970),
            endDate: _parseDate(item['end_date']),
            isCurrent: _asBool(item['is_current']) ?? false,
            description: _asString(item['description']) ?? '',
          ),
        );
      } catch (_) {}
    }

    final achievements = <Achievement>[];
    for (final raw in (profile.achievements as List? ?? const [])) {
      final item = _asMap(raw);
      if (item == null) {
        continue;
      }
      try {
        achievements.add(
          Achievement(
            id: _asString(item['id']) ??
                _asString(item['achievementId']) ??
                'achievement_${achievements.length}',
            title: _asString(item['title']) ?? _asString(item['name']) ?? '',
            description: _asString(item['description']) ?? '',
            date: _parseDate(item['date']) ?? DateTime(1970),
            type: _asString(item['type']) ?? 'achievement',
          ),
        );
      } catch (_) {}
    }

    return PublicCoachProfile(
      id: _asString(profile.id) ?? '',
      fullName: _asString(profile.name) ?? '',
      email: _asString(profile.email) ?? '',
      phoneNumber: _asString(profile.phone),
      bio: _asString(profile.bio),
      yearsOfExperience: _asInt(profile.yearsOfExperience) ?? 0,
      specializations: (profile.specializations as List?)
              ?.map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toList() ??
          const [],
      isVerified: _asBool(profile.isVerified) ?? false,
      isApproved: true,
      averageRating: _asDouble(profile.stats.avgRating),
      totalClients: _asInt(profile.stats.totalClients) ?? 0,
      activeClients: _asInt(profile.stats.activeClients) ?? 0,
      completedSessions: _asInt(profile.stats.completedSessions) ?? 0,
      successRate: 0,
      profilePhotoUrl: _asString(profile.avatar),
      certificates: certificates,
      experiences: experiences,
      achievements: achievements,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final textValue = value.toString().trim();
    return textValue.isEmpty ? null : textValue;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    final textValue = _asString(value);
    if (textValue == null) {
      return null;
    }
    return DateTime.tryParse(textValue);
  }

  PublicCoachProfile _getDemoProfile() {
    return PublicCoachProfile(
      id: widget.coachId,
      fullName: 'Ahmed Hassan',
      email: 'ahmed.hassan@demo.com',
      phoneNumber: '+966 50 123 4567',
      bio:
          'Certified fitness professional with 8+ years of experience in strength training, bodybuilding, and sports nutrition. Specialized in helping clients achieve sustainable fitness transformations.',
      yearsOfExperience: 8,
      specializations: [
        'Strength Training',
        'Bodybuilding',
        'Sports Nutrition',
        'Weight Loss',
        'Muscle Gain'
      ],
      isVerified: true,
      isApproved: true,
      averageRating: 4.8,
      totalClients: 156,
      activeClients: 42,
      completedSessions: 1240,
      successRate: 92.5,
      certificates: [
        Certificate(
          id: '1',
          name: 'Certified Personal Trainer (CPT)',
          issuingOrganization: 'NASM',
          dateObtained: DateTime(2016, 3, 15),
        ),
        Certificate(
          id: '2',
          name: 'Sports Nutrition Specialist',
          issuingOrganization: 'ISSN',
          dateObtained: DateTime(2018, 7, 20),
          expiryDate: DateTime(2025, 7, 20),
        ),
        Certificate(
          id: '3',
          name: 'Corrective Exercise Specialist',
          issuingOrganization: 'NASM',
          dateObtained: DateTime(2019, 11, 10),
        ),
      ],
      experiences: [
        WorkExperience(
          id: '1',
          title: 'Senior Fitness Coach',
          organization: 'Elite Fitness Center',
          startDate: DateTime(2020, 1, 1),
          isCurrent: true,
          description:
              'Lead coach managing high-performance training programs for athletes and fitness enthusiasts.',
        ),
        WorkExperience(
          id: '2',
          title: 'Personal Trainer',
          organization: "Gold's Gym",
          startDate: DateTime(2016, 6, 1),
          endDate: DateTime(2019, 12, 31),
          isCurrent: false,
          description:
              'Provided personalized training and nutrition guidance to 50+ clients.',
        ),
      ],
      achievements: [
        Achievement(
          id: '1',
          title: 'Best Trainer Award 2023',
          description: 'Recognized for outstanding client results',
          date: DateTime(2023, 12, 15),
          type: 'award',
        ),
        Achievement(
          id: '2',
          title: 'Marathon Finisher',
          description: 'Completed Riyadh Marathon 2022',
          date: DateTime(2022, 10, 20),
          type: 'medal',
        ),
      ],
      createdAt: DateTime(2016, 1, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      bottomNavigationBar: (widget.onMessage != null ||
              widget.onBookCall != null)
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (widget.onMessage != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onMessage,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text(lang.t('messages')),
                        ),
                      ),
                    if (widget.onMessage != null && widget.onBookCall != null)
                      const SizedBox(width: 12),
                    if (widget.onBookCall != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onBookCall ??
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const VideoBookingScreen(),
                                  ),
                                );
                              },
                          icon: const Icon(Icons.videocam),
                          label: Text(lang.t('book_video_call')),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Text(
                    lang.t('public_coach_profile_failed'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        pinned: true,
                        elevation: 0,
                        backgroundColor:
                            AppColors.background.withValues(alpha: 0),
                        leading: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            isRtl ? Icons.arrow_forward : Icons.arrow_back,
                            color: AppColors.textWhite,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('public_coach_profile_title'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textWhite,
                              ),
                            ),
                            Text(
                              lang.t('public_coach_profile_subtitle'),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppColors.textWhite.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        flexibleSpace: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildProfileHeaderCard(lang),
                              const SizedBox(height: 12),
                              _buildQuickStatsRow(lang),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            tabs: [
                              Tab(
                                  text: lang
                                      .t('public_coach_profile_tab_overview')),
                              Tab(
                                  text: lang.t(
                                      'public_coach_profile_tab_certificates')),
                              Tab(
                                  text: lang.t(
                                      'public_coach_profile_tab_experience')),
                              Tab(
                                  text: lang.t(
                                      'public_coach_profile_tab_achievements')),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(lang),
                      _buildCertificatesTab(lang),
                      _buildExperienceTab(lang),
                      _buildAchievementsTab(lang),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeaderCard(LanguageProvider lang) {
    final rating = (_profile!.averageRating ?? 0).toStringAsFixed(1);
    final reviewsCount = _profile!.totalClients;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.4),
                  child: Text(
                    _profile!.initials,
                    style: const TextStyle(
                      color: AppColors.secondaryForeground,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _profile!.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_profile!.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium,
                                    size: 14,
                                    color: AppColors.secondaryForeground,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang.t('public_coach_profile_verified'),
                                    style: const TextStyle(
                                      color: AppColors.secondaryForeground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($reviewsCount ${lang.t('public_coach_profile_reviews')})',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '-',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_profile!.activeClients} ${lang.t('public_coach_profile_active_clients')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '-',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_profile!.yearsOfExperience} ${lang.t('public_coach_profile_years_exp')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.specializations
                  .map(
                    (spec) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(LanguageProvider lang) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.people,
            iconColor: AppColors.secondaryForeground,
            value: '${_profile!.totalClients}',
            label: lang.t('public_coach_profile_total_clients'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.videocam,
            iconColor: AppColors.primary,
            value: '${_profile!.completedSessions}',
            label: lang.t('public_coach_profile_sessions'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.trending_up,
            iconColor: AppColors.success,
            value: '${_profile!.successRate.toStringAsFixed(0)}%',
            label: lang.t('public_coach_profile_success_rate'),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          if (_profile!.bio != null) ...[
            Text(
              lang.t('public_coach_profile_about'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Text(
                _profile!.bio!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Specializations
          Text(
            lang.t('public_coach_profile_specializations'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile!.specializations.map((spec) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  spec,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Contact Info
          Text(
            lang.t('public_coach_profile_contact'),
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
                ListTile(
                  leading: const Icon(Icons.email, color: AppColors.primary),
                  title: Text(
                    _profile!.email,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                if (_profile!.phoneNumber != null)
                  ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.primary),
                    title: Text(
                      _profile!.phoneNumber!,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesTab(LanguageProvider lang) {
    return _profile!.certificates.isEmpty
        ? Center(
            child: Text(
              lang.t('public_coach_profile_no_certificates'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _profile!.certificates.length,
            itemBuilder: (context, index) {
              final cert = _profile!.certificates[index];
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    cert.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.issuingOrganization,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(cert.dateObtained)}${cert.expiryDate != null ? ' - ${_formatDate(cert.expiryDate!)}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: cert.certificateUrl != null
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () {
                            // Open certificate URL
                          },
                        )
                      : null,
                ),
              );
            },
          );
  }

  Widget _buildExperienceTab(LanguageProvider lang) {
    return _profile!.experiences.isEmpty
        ? Center(
            child: Text(
              lang.t('public_coach_profile_no_experience'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _profile!.experiences.length,
            itemBuilder: (context, index) {
              final exp = _profile!.experiences[index];
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: exp.isCurrent
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.work,
                      color: exp.isCurrent
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    exp.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.organization,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(exp.startDate)} - ${exp.isCurrent ? lang.t('public_coach_profile_present') : _formatDate(exp.endDate!)} (${exp.duration})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exp.description,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _buildAchievementsTab(LanguageProvider lang) {
    return _profile!.achievements.isEmpty
        ? Center(
            child: Text(
              lang.t('public_coach_profile_no_achievements'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _profile!.achievements.length,
            itemBuilder: (context, index) {
              final achievement = _profile!.achievements[index];
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAchievementColor(achievement.type)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAchievementIcon(achievement.type),
                      color: _getAchievementColor(achievement.type),
                    ),
                  ),
                  title: Text(
                    achievement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.description,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(achievement.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'medal':
        return Icons.emoji_events;
      case 'award':
        return Icons.workspace_premium;
      case 'recognition':
        return Icons.star;
      default:
        return Icons.workspace_premium;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'medal':
        return AppColors.warning;
      case 'award':
        return AppColors.secondaryForeground;
      case 'recognition':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
