# Graph Report - frontend  (2026-10-03)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 5662 nodes · 8253 edges · 195 communities (180 shown, 15 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 19 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a768b386`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- admin_nutrition_templates_screen.dart
- lib/data/models/nutrition_plan.dart
- admin_repository.dart
- admin_provider.dart
- workout_plan.dart
- LanguageProvider
- auth_screen.dart
- messaging_provider.dart
- account_screen.dart
- coach_messaging_screen.dart
- workout_repository.dart
- progress_screen.dart
- inbody_model.dart
- colors.dart
- nutrition_provider.dart
- subscription_upgrade_screen.dart
- home_dashboard_screen.dart
- video_call_screen.dart
- admin_coaches_screen.dart
- GeneratedPluginRegistrant.swift
- admin_exercises_screen.dart
- admin_workout_templates_screen.dart
- messaging_repository.dart
- store_checkout_screen.dart
- nutrition_plan_editor_screen.dart
- main.dart
- nutrition_screen.dart
- notification_settings_screen.dart
- auth_repository.dart
- order.dart
- AuthProvider
- admin_coach.dart
- nutrition_preferences_intake_screen.dart
- inbody_input_screen.dart
- workout_provider.dart
- meal_swap_test.dart
- StatelessWidget
- subscription_management_screen.dart
- coach_dashboard_screen.dart
- VoidCallback
- store_screen.dart
- public_coach_profile_screen.dart
- workout_exercise_session_screen.dart
- coach_provider.dart
- video_booking_screen.dart
- user_profile.dart
- coach_client_detail_screen.dart
- exercise_library_screen.dart
- workout_screen.dart
- coach_client_checkin.dart
- store_provider.dart
- product.dart
- public_coach_profile.dart
- ../../core/config/api_config.dart
- CoachProvider
- workout_exercise_detail_screen.dart
- workout_calendar.dart
- auth_provider.dart
- exercise_catalog_service.dart
- onboarding_screen.dart
- store_order_detail_screen.dart
- app_palette.dart
- subscription_plan_provider.dart
- admin_templates_regression_test.dart
- message.dart
- admin_catalog_search_test.dart
- admin_users_screen.dart
- coach_client.dart
- account_management_screens_test.dart
- feature_flow_widget_test.dart
- plan_library_options.dart
- enhanced_input.dart
- workout_provider_test.dart
- app.dart
- signup_screen.dart
- coach_profile.dart
- quota_provider.dart
- my_application.cc
- api_config.dart
- store_repository.dart
- workout_plan_editor_screen.dart
- store_management_screen.dart
- admin_analytics.dart
- coach_repository.dart
- second_intake_screen.dart
- coach_nutrition_portion_test.dart
- package:flutter_test/flutter_test.dart
- meal_detail_screen.dart
- nutrition_plan_builder_screen.dart
- enhanced_button.dart
- admin_dashboard_screen.dart
- ../../widgets/custom_card.dart
- demo_data.dart
- workout_timer_screen.dart
- payment_management_screen.dart
- admin_exercise.dart
- user_repository.dart
- subscription_plan.dart
- package:provider/provider.dart
- messaging_provider_test.dart
- ../../core/theme/app_palette.dart
- appointment_detail_screen.dart
- admin_user.dart
- MaterialPageRoute
- workout_plan_builder_screen.dart
- nutrition_screen_test.dart
- animated_reveal.dart
- profile_edit_screen.dart
- workout_coach_e2e_test.dart
- custom_button.dart
- auth_screen_test.dart
- nutrition_repository.dart
- language_selection_screen.dart
- theme_provider.dart
- ../../core/constants/colors.dart
- push_notification_registration_service.dart
- coach_earnings.dart
- coach_schedule_session_sheet.dart
- auth_provider_test.dart
- dark_mode_contrast_test.dart
- coach_nutrition_plan_viewer_screen.dart
- ../../core/config/demo_config.dart
- first_intake_screen.dart
- store_product_detail_screen.dart
- change_password_screen.dart
- focus_wrapper.dart
- ../../providers/auth_provider.dart
- package:flutter/material.dart
- coach_workout_plan_viewer_screen.dart
- language_provider.dart
- catalog_search_field.dart
- enhanced_card.dart
- i18n_guard_test.dart
- FlutterWindow
- delete_account_screen.dart
- admin_audit_logs_screen.dart
- user_provider.dart
- win32_window.cpp
- phone_number_utils.dart
- subscription_plan_repository.dart
- crash_reporter.dart
- rating_modal.dart
- dart:convert
- appointment.dart
- custom_card.dart
- appointment_provider.dart
- List
- payment_repository.dart
- sheet_dismissal_test.dart
- demo_subscription_plan_repository.dart
- int?
- demo_messaging_repository.dart
- quota_status.dart
- String get
- ../../widgets/custom_button.dart
- otp_input.dart
- DateTime
- utils.cpp
- AuthRepositoryBase
- store_intro_screen.dart
- Win32Window
- NutritionProvider
- fix_color_alpha.py
- manifest.json
- theme_config_test.dart
- return
- demo_metrics_repository.dart
- .MessageHandler
- static const String
- TextEditingController
- coach_analytics.dart
- WorkoutProvider
- splash_screen.dart
- video_thumbnail_resolver.dart
- bidi_text.dart
- StoreProvider
- coach_message_thread_screen.dart
- @visibleForTesting
- bool get
- Point
- Size
- MainActivity.kt
- CustomPainter
- SocialAuthClient
- _PaymentManagementScreenState
- _EditCoachSheet
- _SliverAppBarDelegate

## God Nodes (most connected - your core abstractions)
1. `LanguageProvider` - 286 edges
2. `AuthProvider` - 153 edges
3. `AdminProvider` - 69 edges
4. `CoachProvider` - 64 edges
5. `NutritionProvider` - 27 edges
6. `Win32Window` - 21 edges
7. `UserProvider` - 20 edges
8. `WorkoutProvider` - 20 edges
9. `MessagingProvider` - 19 edges
10. `SubscriptionPlanProvider` - 18 edges

## Surprising Connections (you probably didn't know these)
- `MockAuthRepository` --implements--> `AuthRepositoryBase`  [EXTRACTED]
  test/providers/auth_provider_test.dart → lib/data/repositories/auth_repository.dart
- `_StubAuthRepository` --implements--> `AuthRepositoryBase`  [EXTRACTED]
  test/screens/account_management_screens_test.dart → lib/data/repositories/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepositoryBase`  [EXTRACTED]
  test/screens/auth_screen_test.dart → lib/data/repositories/auth_repository.dart
- `_StubAuthRepository` --implements--> `AuthRepositoryBase`  [EXTRACTED]
  test/screens/coach_nutrition_portion_test.dart → lib/data/repositories/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepositoryBase`  [EXTRACTED]
  test/screens/nutrition_screen_test.dart → lib/data/repositories/auth_repository.dart

## Import Cycles
- None detected.

## Communities (195 total, 15 thin omitted)

### Community 0 - "admin_nutrition_templates_screen.dart"
Cohesion: 0.01
Nodes (134): active, _addAlternative, _addDay, _addIngredient, _addMeal, _addVariant, _AdminNutritionAction, _alternativeOptions (+126 more)

### Community 1 - "lib/data/models/nutrition_plan.dart"
Cohesion: 0.02
Nodes (98): access, action, answerableFields, asBool, _asDateTime, _asDouble, _asInt, _asList (+90 more)

### Community 2 - "admin_repository.dart"
Cohesion: 0.02
Nodes (79): admin, AdminCoachUpdatePayload, AdminCreationResult, AdminPage, approveCoach, _asList, _asMap, bio (+71 more)

### Community 3 - "admin_provider.dart"
Cohesion: 0.03
Nodes (73): _analytics, approveCoach, _auditLogs, clearError, _coaches, _coachesError, createAdmin, createCoach (+65 more)

### Community 4 - "workout_plan.dart"
Cohesion: 0.03
Nodes (77): alternatives, _asBool, _asDateTime, _asInt, _asList, _asMap, _asNullableBool, _asNullableDouble (+69 more)

### Community 5 - "LanguageProvider"
Cohesion: 0.06
Nodes (66): _AppState, AdminProvider, LanguageProvider, _AdminAuditLogsScreenState, build, AdminCoachesScreen, _AdminCoachesScreenState, build (+58 more)

### Community 6 - "auth_screen.dart"
Cohesion: 0.03
Nodes (66): _applyProviderPhoneError, _applySignupInlineError, AuthStep, _buildLabeledInput, _buildLoginModeButton, _buildLoginModeSelector, _clearAuthErrors, _clearPhoneErrors (+58 more)

### Community 7 - "messaging_provider.dart"
Cohesion: 0.03
Nodes (66): _activeConversation, activeConversationId, _appendMessageIfMissing, _bindSocketCallbacks, _captureError, clearChat, _clearError, connect (+58 more)

### Community 8 - "account_screen.dart"
Cohesion: 0.03
Nodes (58): _AccountTabOption, _activeTab, _adminCoachApplications, _adminDepartment, _adminEmployeeId, _adminPaymentIssues, _adminPermissions, _adminProfileData (+50 more)

### Community 9 - "coach_messaging_screen.dart"
Cohesion: 0.04
Nodes (57): MessagingProvider, QuotaProvider, _logout, _attachMessagingListener, build, _buildCoachInboxBody, _buildEmptyState, _buildHeader (+49 more)

### Community 10 - "workout_repository.dart"
Cohesion: 0.03
Nodes (59): _activePlanEndpoints, addToFavorites, _asBool, _asInt, _asList, _asMap, _asNullableDouble, _asNullableInt (+51 more)

### Community 11 - "progress_screen.dart"
Cohesion: 0.03
Nodes (57): _addProgress, backPhotoUrl, bicepsLeft, bicepsRight, bodyFatPercentage, build, _buildAchievements, _buildCaloriesChart (+49 more)

### Community 12 - "inbody_model.dart"
Cohesion: 0.03
Nodes (58): aiConfidenceScore, _asBool, _asDateTime, _asDouble, _asInt, _asString, basalMetabolicRate, bmi (+50 more)

### Community 13 - "colors.dart"
Cohesion: 0.03
Nodes (53): accent, accentGradient, accentLight, AppColors, AppRadius, AppTextStyles, background, backgroundDark (+45 more)

### Community 14 - "nutrition_provider.dart"
Cohesion: 0.04
Nodes (50): NutritionAccessStatus, NutritionIntakeRequirements, NutritionTodayProgress, accessMessage, _accessStatus, _activePlan, addCustomFood, _applyAccessTrialState (+42 more)

### Community 15 - "subscription_upgrade_screen.dart"
Cohesion: 0.05
Nodes (48): SubscriptionPlanProvider, UserProvider, build, _confirmDeletePlan, initState, build, _submitIntake, build (+40 more)

### Community 16 - "home_dashboard_screen.dart"
Cohesion: 0.04
Nodes (41): background, badge, _buildAccountTab, _buildActivityRow, _buildCoachTab, _buildHeaderStat, _buildHeroHeader, _buildHeroStat (+33 more)

### Community 17 - "video_call_screen.dart"
Cohesion: 0.04
Nodes (42): RatingRepository, appointmentId, autoInitialize, build, _buildControlButton, _buildControls, _callDuration, _callTimer (+34 more)

### Community 18 - "admin_coaches_screen.dart"
Cohesion: 0.04
Nodes (48): _addSpecialization, _bioController, _buildCoachCard, _buildDetailRow, _buildStatChip, _buildStatusChip, _canSubmit, coach (+40 more)

### Community 19 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (24): Cocoa, facebook_auth_desktop, file_picker, file_selector_macos, firebase_core, firebase_messaging, Flutter, flutter_secure_storage_macos (+16 more)

### Community 20 - "admin_exercises_screen.dart"
Cohesion: 0.04
Nodes (46): _alternativeLabels, availableExercises, background, _buildLocationSelector, _buildSwapSelector, _canonicalAlternativeKey, _category, createState (+38 more)

### Community 21 - "admin_workout_templates_screen.dart"
Cohesion: 0.04
Nodes (45): _addExercise, _addSession, _advancedProgramPaths, _asList, _asMap, availableExercises, _buildPlanEditor, _buildTemplate (+37 more)

### Community 22 - "messaging_repository.dart"
Cohesion: 0.04
Nodes (45): _asMap, connect, _dateValue, deleteConversationMessages, deleteMessage, _dio, disconnect, emitMarkRead (+37 more)

### Community 23 - "store_checkout_screen.dart"
Cohesion: 0.04
Nodes (46): StoreRepository, _addressController, build, _buildHeader, _buildOrderItems, _buildOrderSummary, _buildPaymentStep, _buildProductThumbnail (+38 more)

### Community 24 - "nutrition_plan_editor_screen.dart"
Cohesion: 0.04
Nodes (47): _addDay, _addMeal, _applyVariant, _asBool, _asInt, _asList, _asMap, _asNum (+39 more)

### Community 25 - "main.dart"
Cohesion: 0.06
Nodes (17): DemoModeConfig, AdminRepository, AppointmentRepository, CoachRepository, MessagingRepository, SubscriptionPlanRepository, PushNotificationRegistrationService, build (+9 more)

### Community 26 - "nutrition_screen.dart"
Cohesion: 0.04
Nodes (42): _buildCalorieCounter, _buildIntakeGate, _buildLockedFeatureRow, _buildMacroBreakdownGrid, _buildMacroProgress, _buildMacroRing, _buildMealsList, _buildMealsTab (+34 more)

### Community 27 - "notification_settings_screen.dart"
Cohesion: 0.04
Nodes (44): UserRepository, _loadRoleProfile, build, ChangeMobileScreen, _ChangeMobileScreenState, _codeSent, _confirm, createState (+36 more)

### Community 28 - "auth_repository.dart"
Cohesion: 0.04
Nodes (42): _authBasePath, AuthRepositoryException, AuthResponse, _buildAuthException, checkPhone, completeRegistration, _dio, _extractField (+34 more)

### Community 29 - "order.dart"
Cohesion: 0.04
Nodes (45): _addressString, canCancel, cancellationReason, cancelledAt, createdAt, deliveredAt, discount, discountedPrice (+37 more)

### Community 30 - "AuthProvider"
Cohesion: 0.06
Nodes (42): _completeSplashAsync, AppointmentProvider, AuthProvider, ThemeProvider, AccountScreen, _AccountScreenState, build, build (+34 more)

### Community 31 - "admin_coach.dart"
Cohesion: 0.04
Nodes (44): AdminCoach, approvedAt, _asBool, _asDateTime, _asDouble, _asInt, _asMap, _asNullableDateTime (+36 more)

### Community 32 - "nutrition_preferences_intake_screen.dart"
Cohesion: 0.05
Nodes (43): _ageController, _allFields, build, _buildBodyAndTrainingSection, _buildDailyMovementSection, _buildDietaryExclusionsSection, _buildMealsPerDaySection, _buildMedicalSafetySection (+35 more)

### Community 33 - "inbody_input_screen.dart"
Cohesion: 0.05
Nodes (37): _applyExtractedDataAndContinue, _bmiController, _bmrController, _bodyFatController, _bodyWaterController, _buildAiHintRow, _buildAiIntro, _buildAiPreview (+29 more)

### Community 34 - "workout_provider.dart"
Cohesion: 0.05
Nodes (38): _activePlan, _activePlanLoadToken, _applyCatalogToExercise, _applyCatalogToPlan, _calendar, _calendarError, _calendarLoadToken, calendarPlan (+30 more)

### Community 35 - "meal_swap_test.dart"
Cohesion: 0.05
Nodes (35): NutritionPlan, NutritionRepository, main, _buildPlan, dailyMealPlan, FakeNutritionRepository, getActivePlan, getCurrentMacros (+27 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.05
Nodes (42): _Badge, _ExerciseAdminCard, _ExerciseThumb, _EmptyList, _InlineError, _MetaText, _NutritionEngineImportCard, _NutritionEnginePlanCard (+34 more)

### Community 37 - "subscription_management_screen.dart"
Cohesion: 0.05
Nodes (43): _accentColorController, _addFeatureField, _badgeController, _buildHeader, _buildPlanCard, _buildRequestCard, createState, _currencyController (+35 more)

### Community 38 - "coach_dashboard_screen.dart"
Cohesion: 0.05
Nodes (37): activityDaysAgo, _buildClientSpotlight, _buildFilterPill, _buildMessagesTab, _buildSessionItem, _buildTodaySchedule, _buildUpcomingFilterChips, _buildUpcomingSessions (+29 more)

### Community 39 - "VoidCallback"
Cohesion: 0.05
Nodes (35): build, CoachIntroScreen, color, description, icon, iconColor, _IntroFeatureCard, _IntroIcon (+27 more)

### Community 40 - "store_screen.dart"
Cohesion: 0.05
Nodes (40): _addToCart, _buildBackendCartTab, _buildBackendCategoryFilters, _buildBackendOrdersTab, _buildBackendProductCard, _buildBackendProductsTab, _buildBackendStore, _buildCartTab (+32 more)

### Community 41 - "public_coach_profile_screen.dart"
Cohesion: 0.05
Nodes (37): _asBool, _asDouble, _asInt, _asMap, _asString, _buildAchievementsTab, _buildCertificatesTab, _buildExperienceTab (+29 more)

### Community 42 - "workout_exercise_session_screen.dart"
Cohesion: 0.05
Nodes (40): _applyDelta, _buildExerciseDemo, child, color, controller, createState, currentExercise, _currentIndex (+32 more)

### Community 43 - "coach_provider.dart"
Cohesion: 0.05
Nodes (31): _analytics, _appointments, assignFitnessScore, _buildDemoCheckIns, clearError, _clientCheckIns, _clients, createAppointment (+23 more)

### Community 44 - "video_booking_screen.dart"
Cohesion: 0.05
Nodes (38): _availableSlotsByDate, _bookingRepository, _buildBookingDetailsSection, _buildCoachCard, _buildDateSection, _buildDetailRow, _buildHeader, _buildInfoCard (+30 more)

### Community 45 - "user_profile.dart"
Cohesion: 0.05
Nodes (36): hashCode, operator, read, typeId, UserProfileAdapter, write, age, canAccessSecondIntake (+28 more)

### Community 46 - "coach_client_detail_screen.dart"
Cohesion: 0.05
Nodes (37): _buildActivitySection, _buildChangeChips, _buildCheckInCard, _buildCheckInEmptyState, _buildCheckInTimelineSection, _buildClientActions, _buildClientHeader, _buildContactSection (+29 more)

### Community 47 - "exercise_library_screen.dart"
Cohesion: 0.05
Nodes (37): build, _buildBadge, _buildExerciseCard, _buildSection, _buildThumbnail, _catalogService, _categories, createState (+29 more)

### Community 48 - "workout_screen.dart"
Cohesion: 0.05
Nodes (35): _buildCalendarDayCard, _buildCalendarSection, _buildExerciseCard, _buildExerciseList, _buildExerciseThumbnail, _buildPromptOption, _buildSecondIntakeBanner, _buildSummaryItem (+27 more)

### Community 49 - "coach_client_checkin.dart"
Cohesion: 0.05
Nodes (39): _asDateTime, _asDouble, _asInt, _asList, _asMap, _asNullableString, bmi, bodyFatPercentage (+31 more)

### Community 50 - "store_provider.dart"
Cohesion: 0.05
Nodes (34): Order, addToCart, applyPromoCode, calculateShipping, cancelOrder, _cart, CartItem, cartItemCount (+26 more)

### Community 51 - "product.dart"
Cohesion: 0.05
Nodes (38): _assetUrl, _bool, category, categoryAr, categoryEn, createdAt, currency, _date (+30 more)

### Community 52 - "public_coach_profile.dart"
Cohesion: 0.05
Nodes (38): Achievement, achievements, activeClients, averageRating, bio, Certificate, certificates, certificateUrl (+30 more)

### Community 53 - "../../core/config/api_config.dart"
Cohesion: 0.07
Nodes (29): _dio, _getAuthOptions, getUserAppointments, _secureStorage, _tokenKey, cancelBooking, createBooking, _dateOnly (+21 more)

### Community 54 - "CoachProvider"
Cohesion: 0.07
Nodes (34): CoachProvider, build, _buildAppointmentCard, _calendarFormat, _cancelAppointment, CoachCalendarScreen, _CoachCalendarScreenState, _confirmAppointment (+26 more)

### Community 55 - "workout_exercise_detail_screen.dart"
Cohesion: 0.05
Nodes (34): Exercise, _Badge, _buildAlternativeThumbnail, _catalogService, createState, description, _DifficultyBadge, _dismissTutorial (+26 more)

### Community 56 - "workout_calendar.dart"
Cohesion: 0.05
Nodes (36): 0, allDays, _asBool, _asDateTime, _asDouble, _asInt, _asList, _asMap (+28 more)

### Community 57 - "auth_provider.dart"
Cohesion: 0.05
Nodes (34): _checkAuthStatus, checkPhone, clearError, clearErrors, completeRegistration, _demoRoleForCredential, _enableDemoUser, _error (+26 more)

### Community 58 - "exercise_catalog_service.dart"
Cohesion: 0.06
Nodes (33): byId, _catalog, commonMistakesAr, commonMistakesEn, defaultReps, defaultRestSeconds, defaultSets, equip (+25 more)

### Community 59 - "onboarding_screen.dart"
Cohesion: 0.06
Nodes (35): accentColor, _BlurAccent, build, color, _controller, createState, _currentPage, _descFade (+27 more)

### Community 60 - "store_order_detail_screen.dart"
Cohesion: 0.06
Nodes (32): StoreCheckoutResult, build, _buildMiniList, _buildSummaryCard, icon, _MiniInfoRow, onContinueShopping, onTrackOrder (+24 more)

### Community 61 - "app_palette.dart"
Cohesion: 0.06
Nodes (26): AppThemeConfig, _build, getDarkTheme, getLightTheme, accent, AppPalette, AppPaletteContext, background (+18 more)

### Community 62 - "subscription_plan_provider.dart"
Cohesion: 0.06
Nodes (29): _config, DemoModeProvider, isDemo, cancelRequest, decideRequest, deletePlan, _demoConfig, _demoRepository (+21 more)

### Community 63 - "admin_templates_regression_test.dart"
Cohesion: 0.06
Nodes (30): byWidgetPredicate, createdIngredients, createNutritionIngredient, _englishLanguageProvider, exercises, getExercises, getNutritionEngineImports, getNutritionEnginePlan (+22 more)

### Community 64 - "message.dart"
Cohesion: 0.06
Nodes (34): attachmentType, attachmentUrl, _boolValue, coachId, content, Conversation, conversationId, copyWith (+26 more)

### Community 65 - "admin_catalog_search_test.dart"
Cohesion: 0.06
Nodes (30): _english, enterText, _exercise, exercises, exerciseSearches, exerciseTotal, getExercises, getNutritionEngineImports (+22 more)

### Community 66 - "admin_users_screen.dart"
Cohesion: 0.06
Nodes (29): AdminUsersScreen, _buildCoachDirectory, _buildCoachDropdownOptions, _buildDetailRow, _buildMiniBadge, _buildUserCard, _CoachDropdownOption, createState (+21 more)

### Community 67 - "coach_client.dart"
Cohesion: 0.06
Nodes (33): _asDateTime, _asDouble, _asInt, _asMap, _asNullableString, assignedDate, coachAssignmentActive, CoachClient (+25 more)

### Community 68 - "account_management_screens_test.dart"
Cohesion: 0.06
Nodes (28): authProvider, button, changedNumber, changedOtp, changedPasswordFrom, changePassword, confirmMobileChange, deleteAccount (+20 more)

### Community 69 - "feature_flow_widget_test.dart"
Cohesion: 0.06
Nodes (29): appointmentId, checkPhone, coachId, completeRegistration, feedback, getLastActiveAt, getNotificationSettings, getStoredToken (+21 more)

### Community 70 - "plan_library_options.dart"
Cohesion: 0.06
Nodes (31): calories, carbs, cuisine, detail, fat, _firstString, fromRow, fromRows (+23 more)

### Community 71 - "enhanced_input.dart"
Cohesion: 0.07
Nodes (28): autovalidateMode, build, controller, createState, dispose, enabled, EnhancedDropdown, _EnhancedDropdownState (+20 more)

### Community 72 - "workout_provider_test.dart"
Cohesion: 0.07
Nodes (19): WorkoutCalendarResponse, WorkoutPlan, WorkoutRepository, main, buildPlan, calendarRequests, FakeWorkoutRepository, getActivePlan (+11 more)

### Community 73 - "app.dart"
Cohesion: 0.06
Nodes (15): App, build, _buildCurrentScreen, _completeOnboarding, _completeSplash, createState, _currentScreen, _handlePostAuthNavigation (+7 more)

### Community 74 - "signup_screen.dart"
Cohesion: 0.06
Nodes (31): _agreeToTerms, _buildSocialButton, _confirmPasswordController, createState, dispose, _emailController, _formKey, _handleSignup (+23 more)

### Community 75 - "coach_profile.dart"
Cohesion: 0.06
Nodes (29): achievements, activeClients, _asBool, _asDouble, _asInt, _asMap, _asString, avatar (+21 more)

### Community 76 - "quota_provider.dart"
Cohesion: 0.06
Nodes (27): _callPercentage, _callWarning, canMakeVideoCall, canSendMessage, clearError, _error, hasMessagesRemaining, hasVideoCallsRemaining (+19 more)

### Community 77 - "my_application.cc"
Cohesion: 0.08
Nodes (13): fl_register_plugins(), main(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 78 - "api_config.dart"
Cohesion: 0.06
Nodes (28): adminEndpoint, ApiConfig, apiVersion, authEndpoint, _baseUrls, bookingsEndpoint, coachesEndpoint, connectTimeout (+20 more)

### Community 79 - "store_repository.dart"
Cohesion: 0.06
Nodes (28): applyPromoCode, calculateShipping, cancelOrder, checkAvailability, createCategoryAdmin, createOrder, createProductAdmin, deleteCategoryAdmin (+20 more)

### Community 80 - "workout_plan_editor_screen.dart"
Cohesion: 0.07
Nodes (30): _addDay, _addExercise, _asBool, _asInt, _asList, _asMap, _asString, build (+22 more)

### Community 81 - "store_management_screen.dart"
Cohesion: 0.07
Nodes (27): _addNew, build, _buildCategoriesList, _buildOrdersList, _buildProductsList, _buildStatItem, _buildStatusBadge, _buildTab (+19 more)

### Community 82 - "admin_analytics.dart"
Cohesion: 0.07
Nodes (29): active, AdminAnalytics, _asDouble, _asInt, _asList, _asMap, _asString, coaches (+21 more)

### Community 83 - "coach_repository.dart"
Cohesion: 0.07
Nodes (27): _asList, _asMap, assignFitnessScore, createAppointment, _dio, _extractPlanPayload, _findFirstRawMeal, _findFirstRawWorkoutExercise (+19 more)

### Community 84 - "second_intake_screen.dart"
Cohesion: 0.07
Nodes (29): _ageController, _buildCurrentStep, _buildInjuryOption, _buildRadioOption, _canProceedToNext, children, createState, _currentStep (+21 more)

### Community 85 - "coach_nutrition_portion_test.dart"
Cohesion: 0.07
Nodes (26): _addMealRow, auth, _coachAuth, _englishLanguage, enterText, getClientNutritionPlan, getExerciseLibrary, getRecipeLibrary (+18 more)

### Community 86 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (11): main, fsi, main, pdi, main, main, main, main (+3 more)

### Community 87 - "meal_detail_screen.dart"
Cohesion: 0.07
Nodes (26): Meal, _alternatives, _applyingVariantId, build, carbs, createState, _error, fats (+18 more)

### Community 88 - "nutrition_plan_builder_screen.dart"
Cohesion: 0.07
Nodes (28): _addFood, _addFromTemplate, _applyTemplate, build, _buildMacroInput, _buildMealCard, _caloriesController, _carbsController (+20 more)

### Community 89 - "enhanced_button.dart"
Cohesion: 0.07
Nodes (28): build, _buildButtonContent, ButtonSize, ButtonVariant, createState, dispose, EnhancedButton, _EnhancedButtonState (+20 more)

### Community 90 - "admin_dashboard_screen.dart"
Cohesion: 0.07
Nodes (17): AdminDashboardScreen, build, _buildActivityItem, _buildAdminActionTile, _buildBusinessHub, _buildDashboardTab, _buildFitnessHub, _buildHubTab (+9 more)

### Community 91 - "../../widgets/custom_card.dart"
Cohesion: 0.08
Nodes (22): AdminRevenueScreen, _buildStatItem, createState, _getMaxRevenue, _getTierColor, _getTierIcon, initState, _loadRevenue (+14 more)

### Community 92 - "demo_data.dart"
Cohesion: 0.07
Nodes (20): adminAnalytics, adminCoaches, adminUsers, auditLogs, chatMessages, coachAnalytics, coachAppointments, coachClients (+12 more)

### Community 93 - "workout_timer_screen.dart"
Cohesion: 0.07
Nodes (26): _adjustRest, build, _completeSet, _confirmExit, createState, _currentSet, dispose, exerciseName (+18 more)

### Community 94 - "payment_management_screen.dart"
Cohesion: 0.07
Nodes (25): _autoPayEnabled, brand, build, _buildBillingCard, _buildHistoryCard, _buildMethodsCard, _buildProductionMethodsCard, createState (+17 more)

### Community 95 - "admin_exercise.dart"
Cohesion: 0.07
Nodes (26): AdminExercise, alternatives, alternativesCount, category, copyWith, descriptionAr, descriptionEn, difficulty (+18 more)

### Community 96 - "user_repository.dart"
Cohesion: 0.07
Nodes (24): changePassword, confirmMobileChange, deleteAccount, _dio, getAdminProfileSettings, _getAuthOptions, getCoachProfileSettings, getNotificationSettings (+16 more)

### Community 97 - "subscription_plan.dart"
Cohesion: 0.08
Nodes (24): accentColor, _asDouble, badge, category, copyWith, currency, description, effectiveYearlyPrice (+16 more)

### Community 98 - "package:provider/provider.dart"
Cohesion: 0.10
Nodes (9): main, main, main, _buildCheckout, cartItems, main, createEnglishLanguageProvider, main (+1 more)

### Community 99 - "messaging_provider_test.dart"
Cohesion: 0.08
Nodes (19): main, connect, _connected, _conversations, deleteConversationMessages, deleteMessage, disconnect, getConversation (+11 more)

### Community 100 - "../../core/theme/app_palette.dart"
Cohesion: 0.08
Nodes (20): build, controller, _CountrySelector, enabled, errorText, hint, InternationalPhoneInput, label (+12 more)

### Community 101 - "appointment_detail_screen.dart"
Cohesion: 0.10
Nodes (21): BookingRepository, VideoCallProvider, _accessMessage, appointment, AppointmentDetailScreen, _AppointmentDetailScreenState, build, _buildDetailCard (+13 more)

### Community 102 - "admin_user.dart"
Cohesion: 0.08
Nodes (24): AdminUser, _asBool, _asDateTime, _asMap, _asNullableDateTime, _asNullableString, _asString, coachId (+16 more)

### Community 103 - "MaterialPageRoute"
Cohesion: 0.08
Nodes (24): _buildHealthSection, _buildProfileSection, _buildSettingsSection, _buildSubscriptionSection, _buildCoachCard, _openMessageThread, _openNutritionEditor, _openNutritionViewer (+16 more)

### Community 104 - "workout_plan_builder_screen.dart"
Cohesion: 0.08
Nodes (22): ExerciseLibraryOption, _addExercise, _addFromTemplate, _applyTemplate, build, _buildWorkoutDayCard, clientId, clientName (+14 more)

### Community 105 - "nutrition_screen_test.dart"
Cohesion: 0.08
Nodes (22): checkPhone, completeRegistration, getAccessStatus, getActivePlan, getLastActiveAt, getNutritionHistory, getStoredToken, getTrialStatus (+14 more)

### Community 106 - "animated_reveal.dart"
Cohesion: 0.09
Nodes (21): AnimatedReveal, _AnimatedRevealState, build, child, createState, curve, delay, _delayStarted (+13 more)

### Community 107 - "profile_edit_screen.dart"
Cohesion: 0.08
Nodes (20): _ageController, build, _buildGenderOption, createState, dispose, _emailController, _formKey, _heightController (+12 more)

### Community 108 - "workout_coach_e2e_test.dart"
Cohesion: 0.09
Nodes (18): main, _completeOnboardingIfNeeded, _dismissSecondIntakePromptIfNeeded, _dismissWorkoutIntroIfNeeded, _hasCredentials, kE2EEmail, kE2EPassword, _launchApp (+10 more)

### Community 109 - "custom_button.dart"
Cohesion: 0.09
Nodes (20): build, _buildButton, ButtonSize, ButtonVariant, createState, CustomButton, _CustomButtonState, fullWidth (+12 more)

### Community 110 - "auth_screen_test.dart"
Cohesion: 0.09
Nodes (21): PhoneStatus, buildTestWidget, checkPhone, completeRegistration, getLastActiveAt, getStoredToken, getUserProfile, lastOtpPurpose (+13 more)

### Community 111 - "nutrition_repository.dart"
Cohesion: 0.09
Nodes (21): _asList, _asMap, _dio, _extractNutritionPayload, _findFirstRawMeal, generatePlan, getAccessStatus, getActivePlan (+13 more)

### Community 112 - "language_selection_screen.dart"
Cohesion: 0.09
Nodes (19): build, _controller, createState, dispose, flag, _footerFade, _headerFade, _headerSlide (+11 more)

### Community 113 - "theme_provider.dart"
Cohesion: 0.09
Nodes (18): _cachedDarkMode, currentTheme, getBackgroundColor, getCardColor, getDarkTheme, getLightTheme, getPrimaryColor, getSecondaryColor (+10 more)

### Community 114 - "../../core/constants/colors.dart"
Cohesion: 0.09
Nodes (18): actions, build, dialogCancelAction, lang, onClose, SheetCloseButton, SheetDragHandle, SheetHeader (+10 more)

### Community 115 - "push_notification_registration_service.dart"
Cohesion: 0.10
Nodes (11): _dio, _messaging, registerCurrentDevice, _registerToken, _resolveMessaging, _secureStorage, _tokenKey, _tokenRefreshListenerRegistered (+3 more)

### Community 116 - "coach_earnings.dart"
Cohesion: 0.09
Nodes (21): amount, clientName, coachCommission, CoachEarnings, createdAt, earnings, EarningsSummary, fromJson (+13 more)

### Community 117 - "coach_schedule_session_sheet.dart"
Cohesion: 0.10
Nodes (20): build, clientId, clientName, context, createState, dispose, _durationMinutes, initState (+12 more)

### Community 118 - "auth_provider_test.dart"
Cohesion: 0.09
Nodes (18): main, checkPhone, completeRegistration, getLastActiveAt, getStoredToken, getUserProfile, loginWithEmailOrPhone, logout (+10 more)

### Community 119 - "dark_mode_contrast_test.dart"
Cohesion: 0.09
Nodes (21): channel, contrast, darker, _dartSources, depth, _enclosingCall, inLineComment, inString (+13 more)

### Community 120 - "coach_nutrition_plan_viewer_screen.dart"
Cohesion: 0.10
Nodes (17): build, _buildDayMeals, _buildEmptyState, _buildMacroChip, _buildSummaryCard, _calculateProgress, clientId, clientName (+9 more)

### Community 121 - "../../core/config/demo_config.dart"
Cohesion: 0.10
Nodes (14): accessToken, email, _facebookAuth, _getGoogleSignIn, _googleSignIn, name, profilePhoto, provider (+6 more)

### Community 122 - "first_intake_screen.dart"
Cohesion: 0.10
Nodes (20): _buildCurrentStep, _buildGenderStep, _buildGoalStep, _buildLocationStep, _buildRadioOption, _canProceedToNext, children, createState (+12 more)

### Community 123 - "store_product_detail_screen.dart"
Cohesion: 0.10
Nodes (20): badges, build, _buildHeader, data, description, highlights, id, imageUrl (+12 more)

### Community 124 - "change_password_screen.dart"
Cohesion: 0.11
Nodes (17): build, _buildForm, _buildNoPasswordNotice, ChangePasswordScreen, _ChangePasswordScreenState, _confirmController, createState, _currentController (+9 more)

### Community 125 - "focus_wrapper.dart"
Cohesion: 0.11
Nodes (17): borderRadius, build, child, createState, dispose, enabled, focusColor, focusNode (+9 more)

### Community 126 - "../../providers/auth_provider.dart"
Cohesion: 0.11
Nodes (15): build, _buildCheckInBadge, _buildClientCard, _checkInBadgeText, CoachClientsScreen, _CoachClientsScreenState, createState, dispose (+7 more)

### Community 127 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (12): build, color, CustomInfoCard, CustomStatCard, icon, iconColor, onTap, subtitle (+4 more)

### Community 128 - "coach_workout_plan_viewer_screen.dart"
Cohesion: 0.11
Nodes (17): build, _buildDayCards, _buildEmptyState, _buildStatChip, _buildSummaryCard, _calculateProgress, clientId, clientName (+9 more)

### Community 129 - "language_provider.dart"
Cohesion: 0.10
Nodes (16): _arabicTranslations, _currentLanguage, _englishTranslations, hasKey, _hasSelectedLanguage, _humanizeKey, isArabic, isEnglish (+8 more)

### Community 130 - "catalog_search_field.dart"
Cohesion: 0.11
Nodes (18): args, build, catalogResultLabel, CatalogSearchField, _CatalogSearchFieldState, _clear, _controller, createState (+10 more)

### Community 131 - "enhanced_card.dart"
Cohesion: 0.11
Nodes (19): borderRadius, build, CardContent, CardFooter, CardHeader, child, color, createState (+11 more)

### Community 132 - "i18n_guard_test.dart"
Cohesion: 0.10
Nodes (19): arabic, arabicKeys, _dartSources, depth, english, englishKeys, _entries, _entry (+11 more)

### Community 133 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 134 - "delete_account_screen.dart"
Cohesion: 0.11
Nodes (17): build, _buildList, _codeSent, _confirmationTyped, _confirmController, createState, DeleteAccountScreen, _DeleteAccountScreenState (+9 more)

### Community 135 - "admin_audit_logs_screen.dart"
Cohesion: 0.11
Nodes (14): _actionFilter, AdminAuditLogsScreen, _buildDetailRow, _buildLogCard, createState, _dateRange, _formatDateTime, _getActionColor (+6 more)

### Community 136 - "user_provider.dart"
Cohesion: 0.11
Nodes (14): _asMap, clearError, _error, _extractProfileMap, _isLoading, loadProfile, _profile, _repository (+6 more)

### Community 137 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 138 - "phone_number_utils.dart"
Cohesion: 0.11
Nodes (15): CountryPhoneOption, defaultCountry, dialCode, dialCodeDigits, isoCode, isValid, looksLikeEmail, name (+7 more)

### Community 139 - "subscription_plan_repository.dart"
Cohesion: 0.11
Nodes (17): approveRequest, cancelRequest, createPlan, _debugLog, deletePlan, _dio, _errorMessage, _getAuthOptions (+9 more)

### Community 140 - "crash_reporter.dart"
Cohesion: 0.11
Nodes (12): _client, CrashReporter, _dedupeWindow, _dio, guard, install, _installed, _recent (+4 more)

### Community 141 - "rating_modal.dart"
Cohesion: 0.12
Nodes (17): build, createState, dispose, _feedbackController, _forceShowAllBorders, _getRatingColor, _getRatingLabelKey, _getTitleKey (+9 more)

### Community 142 - "dart:convert"
Cohesion: 0.12
Nodes (12): expiryOf, inactivityWindow, kInactivitySignOutAfter, SessionPolicy, SessionVerdict, verdict, claims, main (+4 more)

### Community 143 - "appointment.dart"
Cohesion: 0.12
Nodes (16): Appointment, coachId, coachName, copyWith, createdAt, durationMinutes, fromJson, id (+8 more)

### Community 144 - "custom_card.dart"
Cohesion: 0.12
Nodes (11): border, borderRadius, build, child, color, CustomCard, elevation, margin (+3 more)

### Community 145 - "appointment_provider.dart"
Cohesion: 0.12
Nodes (12): _appointments, canJoin, clear, _error, _hasLoaded, _isLoading, loadUserAppointments, _parseDate (+4 more)

### Community 146 - "List"
Cohesion: 0.12
Nodes (14): byPeriod, byTier, count, fromJson, period, revenue, RevenueAnalytics, RevenuePeriod (+6 more)

### Community 147 - "payment_repository.dart"
Cohesion: 0.12
Nodes (15): applyPromoCode, cancelSubscription, checkTapPaymentStatus, confirmStripePayment, createStripePayment, createTapPayment, _dio, _getAuthOptions (+7 more)

### Community 148 - "sheet_dismissal_test.dart"
Cohesion: 0.12
Nodes (14): buffer, _callText, _classBodies, _dartSources, declaration, _delegate, depth, _exits (+6 more)

### Community 149 - "demo_subscription_plan_repository.dart"
Cohesion: 0.13
Nodes (10): createPlan, deletePlan, DemoSubscriptionPlanRepository, getPlans, updatePlan, DemoWorkoutRepository, _fallbackExercise, getActivePlan (+2 more)

### Community 150 - "int?"
Cohesion: 0.13
Nodes (13): AdminWorkoutTemplate, fromJson, goal, _int, location, nameAr, nameEn, planId (+5 more)

### Community 151 - "demo_messaging_repository.dart"
Cohesion: 0.13
Nodes (10): catalogLabel, catalogLabels, hasKey, key, raw, buildConversation, buildOutgoingMessage, DemoMessagingRepository (+2 more)

### Community 152 - "quota_status.dart"
Cohesion: 0.14
Nodes (13): callPercentage, callQuota, callWarning, fromJson, messagePercentage, messageQuota, messagesSentThisMonth, messageWarning (+5 more)

### Community 153 - "String get"
Cohesion: 0.14
Nodes (11): _authToken, _buildHeaders, canJoinCall, clearError, endCall, _errorMessage, getCallStatus, getCallToken (+3 more)

### Community 154 - "../../widgets/custom_button.dart"
Cohesion: 0.15
Nodes (11): build, _buildSlide, createState, _currentPage, dispose, feature, FeatureIntroScreen, _FeatureIntroScreenState (+3 more)

### Community 155 - "otp_input.dart"
Cohesion: 0.15
Nodes (12): build, _completionFired, controller, createState, dispose, enabled, focusNode, initState (+4 more)

### Community 156 - "DateTime"
Cohesion: 0.15
Nodes (11): action, AuditLog, createdAt, fromJson, id, ipAddress, metadata, toJson (+3 more)

### Community 157 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 158 - "AuthRepositoryBase"
Cohesion: 0.15
Nodes (10): AuthRepository, AuthRepositoryBase, MockAuthRepository, main, signIn, _StubAuthRepository, MockAuthRepository, _StubAuthRepository (+2 more)

### Community 159 - "store_intro_screen.dart"
Cohesion: 0.15
Nodes (12): build, color, description, icon, iconColor, _IntroFeatureCard, _IntroIcon, isArabic (+4 more)

### Community 160 - "Win32Window"
Cohesion: 0.19
Nodes (5): RegisterPlugins(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 162 - "NutritionProvider"
Cohesion: 0.18
Nodes (11): NutritionProvider, _buildTodayNutrition, _apply, _load, _buildLockedAccess, _buildMealCard, _buildNoPlan, _completePreferences (+3 more)

### Community 163 - "fix_color_alpha.py"
Cohesion: 0.24
Nodes (4): _apply(), main(), extract_map(), main()

### Community 164 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 165 - "theme_config_test.dart"
Cohesion: 0.20
Nodes (6): _contrast, dark, la, lb, light, main

### Community 166 - "return"
Cohesion: 0.20
Nodes (6): _dartSources, _glyphTransform, lib, main, _manualFlip, transforms

### Community 167 - "demo_metrics_repository.dart"
Cohesion: 0.20
Nodes (8): _buildScan, _buildScans, DemoMetricsRepository, getAllInBodyScans, getInBodyProgress, getInBodyStatistics, getInBodyTrends, getLatestInBodyScan

### Community 169 - "static const String"
Cohesion: 0.22
Nodes (5): demoAdminId, demoCoachId, DemoConfig, demoUserId, isDemo

### Community 170 - "TextEditingController"
Cohesion: 0.22
Nodes (4): controller, focusNode, main, pumpOtp

### Community 171 - "coach_analytics.dart"
Cohesion: 0.22
Nodes (8): activeClients, CoachAnalytics, fromJson, monthEarnings, todayEarnings, toJson, unreadMessages, upcomingAppointments

### Community 172 - "WorkoutProvider"
Cohesion: 0.22
Nodes (9): WorkoutProvider, build, _buildTodayWorkout, build, build, _logSet, build, _buildWorkoutHeroHeader (+1 more)

### Community 173 - "splash_screen.dart"
Cohesion: 0.22
Nodes (8): build, createState, dispose, initState, onStart, _orbController, _showContent, SplashScreen

### Community 174 - "video_thumbnail_resolver.dart"
Cohesion: 0.25
Nodes (6): assetUrl, fromVideoUrl, resolve, resolveDemo, VideoThumbnailResolver, _youtubeThumbnail

### Community 176 - "bidi_text.dart"
Cohesion: 0.33
Nodes (5): bidiIsolate, _firstStrongIsolate, measurement, _popDirectionalIsolate, stripBidiIsolates

### Community 177 - "StoreProvider"
Cohesion: 0.33
Nodes (6): StoreProvider, _tryGetStoreProvider, build, initState, StoreScreen, _StoreScreenState

### Community 178 - "coach_message_thread_screen.dart"
Cohesion: 0.33
Nodes (4): build, clientId, clientName, CoachMessageThreadScreen

### Community 179 - "@visibleForTesting"
Cohesion: 0.50
Nodes (3): configureForTest, removePhotoForTest, submitRatingForTest

### Community 181 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 182 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 185 - "SocialAuthClient"
Cohesion: 0.67
Nodes (3): DefaultSocialAuthClient, SocialAuthClient, _FakeSocialAuthClient

## Knowledge Gaps
- **4239 isolated node(s):** `active`, `_addAlternative`, `_addDay`, `_addIngredient`, `_addMeal` (+4234 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 4542 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **15 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LanguageProvider` connect `LanguageProvider` to `admin_nutrition_templates_screen.dart`, `language_provider.dart`, `coach_workout_plan_viewer_screen.dart`, `auth_screen.dart`, `admin_audit_logs_screen.dart`, `account_screen.dart`, `coach_messaging_screen.dart`, `delete_account_screen.dart`, `progress_screen.dart`, `rating_modal.dart`, `subscription_upgrade_screen.dart`, `home_dashboard_screen.dart`, `video_call_screen.dart`, `admin_coaches_screen.dart`, `admin_exercises_screen.dart`, `admin_workout_templates_screen.dart`, `store_checkout_screen.dart`, `nutrition_plan_editor_screen.dart`, `main.dart`, `../../widgets/custom_button.dart`, `nutrition_screen.dart`, `notification_settings_screen.dart`, `AuthProvider`, `store_intro_screen.dart`, `nutrition_preferences_intake_screen.dart`, `inbody_input_screen.dart`, `NutritionProvider`, `StatelessWidget`, `subscription_management_screen.dart`, `coach_dashboard_screen.dart`, `VoidCallback`, `store_screen.dart`, `public_coach_profile_screen.dart`, `workout_exercise_session_screen.dart`, `video_booking_screen.dart`, `WorkoutProvider`, `coach_client_detail_screen.dart`, `exercise_library_screen.dart`, `splash_screen.dart`, `StoreProvider`, `workout_screen.dart`, `CoachProvider`, `workout_exercise_detail_screen.dart`, `_PaymentManagementScreenState`, `onboarding_screen.dart`, `store_order_detail_screen.dart`, `admin_users_screen.dart`, `app.dart`, `signup_screen.dart`, `workout_plan_editor_screen.dart`, `store_management_screen.dart`, `second_intake_screen.dart`, `meal_detail_screen.dart`, `nutrition_plan_builder_screen.dart`, `admin_dashboard_screen.dart`, `../../widgets/custom_card.dart`, `workout_timer_screen.dart`, `payment_management_screen.dart`, `appointment_detail_screen.dart`, `MaterialPageRoute`, `workout_plan_builder_screen.dart`, `profile_edit_screen.dart`, `language_selection_screen.dart`, `../../core/constants/colors.dart`, `coach_schedule_session_sheet.dart`, `coach_nutrition_plan_viewer_screen.dart`, `first_intake_screen.dart`, `store_product_detail_screen.dart`, `change_password_screen.dart`, `../../providers/auth_provider.dart`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **Why does `AuthProvider` connect `AuthProvider` to `coach_workout_plan_viewer_screen.dart`, `LanguageProvider`, `auth_screen.dart`, `delete_account_screen.dart`, `account_screen.dart`, `coach_messaging_screen.dart`, `subscription_upgrade_screen.dart`, `home_dashboard_screen.dart`, `nutrition_plan_editor_screen.dart`, `nutrition_screen.dart`, `notification_settings_screen.dart`, `inbody_input_screen.dart`, `NutritionProvider`, `coach_dashboard_screen.dart`, `video_booking_screen.dart`, `coach_client_detail_screen.dart`, `workout_screen.dart`, `CoachProvider`, `workout_exercise_detail_screen.dart`, `auth_provider.dart`, `app.dart`, `signup_screen.dart`, `workout_plan_editor_screen.dart`, `second_intake_screen.dart`, `nutrition_plan_builder_screen.dart`, `../../widgets/custom_card.dart`, `MaterialPageRoute`, `workout_plan_builder_screen.dart`, `profile_edit_screen.dart`, `auth_screen_test.dart`, `coach_schedule_session_sheet.dart`, `coach_nutrition_plan_viewer_screen.dart`, `first_intake_screen.dart`, `change_password_screen.dart`, `../../providers/auth_provider.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `UserRepository` connect `notification_settings_screen.dart` to `user_repository.dart`, `delete_account_screen.dart`, `user_provider.dart`, `account_screen.dart`, `profile_edit_screen.dart`, `quota_provider.dart`, `main.dart`, `change_password_screen.dart`, `AuthProvider`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `active`, `_addAlternative`, `_addDay` to the rest of the system?**
  _4239 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `admin_nutrition_templates_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.014598540145985401 - nodes in this community are weakly interconnected._
- **Should `lib/data/models/nutrition_plan.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020202020202020204 - nodes in this community are weakly interconnected._
- **Should `admin_repository.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.024390243902439025 - nodes in this community are weakly interconnected._