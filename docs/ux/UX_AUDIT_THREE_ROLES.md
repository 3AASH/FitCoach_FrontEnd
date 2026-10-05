# FitCoach UX Audit — Client / Coach / Admin

Audit date: 2026-10-04
Scope: `lib/presentation/screens` (67 screens, ~51,900 lines), `lib/app.dart`, `lib/main.dart`, `lib/presentation/providers`
Method: static trace of every screen, its reachability, its state coverage (loading / empty / error), and its role entry point.

---

## Verdict

The app is **visually and linguistically mature** — 4,010 translation keys, near-zero hardcoded
strings, a real design token layer (`context.palette`), consistent bottom-nav shell across all
three roles. That part is better than most apps this size.

The problems are **structural and journey-level**, not cosmetic. Three categories:

1. **Dead ends** — ~5,000 lines of finished screens that nothing can navigate to.
2. **Silent failure** — errors are collected by providers and then dropped, or shown as raw
   `Exception:` text.
3. **Role asymmetry** — Admin and Coach got the polish pass (pull-to-refresh, theming,
   confirmations); the Client journey did not.

Counts below are exact, from the codebase.

---

## Severity key

| | Meaning |
|---|---|
| **P0** | Breaks a journey or misleads about money. Fix before next release. |
| **P1** | User hits a wall or loses work. Fix this cycle. |
| **P2** | Friction, inconsistency, accessibility. Schedule. |

---

# Cross-cutting (all three roles)

### P0 — No navigation stack at the root; no unsaved-work guard anywhere

`lib/app.dart` drives the entire app from a `String _currentScreen` switch inside an
`AnimatedSwitcher`. There is no `routes` table and no `onGenerateRoute` (`lib/main.dart:271-305`).

Consequences:
- No deep links. A push notification ("your coach sent a plan") cannot open that plan.
- No web URLs if the Flutter web target is ever used.
- Role switch after login is a `setState`, so the back stack is whatever each sub-screen pushes.

Worse, **`PopScope` / `WillPopScope` appears zero times in all 67 screens.**

So on Android:
- Back on any root dashboard exits the app immediately — no "press back again".
- A coach 20 minutes into `workout_plan_builder_screen` or `nutrition_plan_builder_screen`
  presses back and the plan is gone, no prompt.
- Same for `first_intake_screen`, `second_intake_screen`, `inbody_input_screen`,
  `store_checkout_screen`, `profile_edit_screen`, and every admin template editor.

**Fix:** `PopScope(canPop: !_isDirty, onPopInvokedWithResult: ...)` on every editor and
multi-step form — one shared `DirtyFormGuard` wrapper covers all of them. Separately, move the
root to a `Navigator` with named routes so notifications and deep links have somewhere to land.

---

### P0 — 103 providers store raw exceptions; screens print them to users

`grep -c "_error = e.toString()" lib/presentation/providers/` → **103**.
`grep -c "e.toString()" lib/presentation/` → **159**.

These surface directly, e.g.:

```
lib/presentation/screens/admin/store_management_screen.dart:925   content: Text(e.toString())
lib/presentation/screens/admin/store_management_screen.dart:990   content: Text(e.toString())
lib/presentation/screens/admin/store_management_screen.dart:1044  content: Text(e.toString())
lib/presentation/screens/admin/store_management_screen.dart:1133  content: Text(e.toString())
lib/presentation/screens/admin/store_management_screen.dart:1265  content: Text(e.toString())
lib/presentation/screens/progress/progress_screen.dart:311        Text(_error!)
lib/presentation/screens/auth/signup_screen.dart:705              Text(authProvider.error!)
```

A user with no signal sees `SocketException: Failed host lookup: 'api.fitcoach...'`.
An Arabic user sees it **in English** — this is the single largest i18n hole in an otherwise
fully-translated app.

**Fix:** one `AppError` type with a `messageKey`. Map `SocketException` → `error_offline`,
401 → `error_session_expired`, 5xx → `error_server`, default → `error_generic`. Providers store
the key; screens render `lang.t(error.messageKey)`. Keep `e.toString()` for logs only.

---

### P0 — No connectivity awareness

`connectivity|offline|SocketException` appears **10 times app-wide**, and 7 of those are inside
`messaging_provider.dart` for socket state. There is no app-level offline detection and no
offline banner.

Every other screen handles "no network" identically to "no data": a spinner that resolves into
an empty state with no explanation and usually no retry. Only **12 of 67 screens** have any
retry affordance.

**Fix:** a `ConnectivityProvider` + a persistent `MaterialBanner` at the app shell. Offline
should look different from empty.

---

### P1 — Accessibility: 1 of 67 screens uses `Semantics`

- `Semantics(` appears in exactly one file: `onboarding_screen.dart`.
- **116 `IconButton`s, 26 `tooltip:`** → ~90 icon-only buttons announce nothing to TalkBack /
  VoiceOver. Includes the admin header's account and refresh buttons
  (`admin_dashboard_screen.dart:123-139`).
- `lib/main.dart:290-298` clamps `textScaler` to **max 1.15**:

```dart
textScaler: mediaQuery.textScaler.clamp(
  minScaleFactor: 0.9,
  maxScaleFactor: 1.15,
),
```

  WCAG 1.4.4 requires text to scale to 200% without loss of function. A user who has set 200%
  system text gets 115%. The clamp is clearly there to stop overflow — the right fix is to make
  the layouts survive the scale, not to cap it.

**Fix:** `tooltip:` on every `IconButton` (mechanical, ~90 edits, keys already exist for most);
`Semantics(label:)` on custom tappable `Container`s; raise the clamp to 1.6–2.0 and fix the
overflows it exposes.

---

### P1 — No autofill on login or signup

`AutofillHints` appears **once** in the whole app — `lib/presentation/widgets/otp_input.dart`
(the OTP field, which was a deliberate, documented decision and is correct).

But `auth_screen.dart` — the live login/signup screen — has **no `AutofillGroup` and no
`autofillHints`** on any of: email (`:877`, `:989`, `:1348`), phone (`:886`, `:998`), password
(`:906`, `:1019`, `:1361`), confirm password (`:1031`), name (`:981`, `:1337`).

Password managers cannot save or fill credentials. On a fitness app people open daily, that's
a measurable drop-off at the login screen.

This is a **different gap from the OTP decision**, which only covered SMS code retrieval.

**Fix:** wrap the login and signup field groups in `AutofillGroup`, add
`AutofillHints.email` / `.telephoneNumber` / `.password` / `.newPassword` / `.name`, and call
`TextInput.finishAutofillContext()` on successful submit. Half a day.

---

### P1 — The live auth screen is the weaker of the two that exist

`auth/signup_screen.dart` (711 lines) has `_obscurePassword` / `_obscureConfirmPassword`
visibility toggles (`:301-356`) and proper `validator:` functions.

`auth/auth_screen.dart` — the one actually wired into `app.dart` — has `obscureText: true` with
**no reveal toggle** and ad-hoc manual validation that returns a *single combined* error string
for the whole form (`:235-251`), shown in a SnackBar rather than inline under the offending
field. Email validation is `email.contains('@')` (`:251`, `:461`, `:502`).

**And `SignupScreen` is dead code** — zero references in `lib/`, `test/`, or `integration_test/`.

**Fix:** port the reveal toggles and per-field inline errors from `signup_screen.dart` into
`auth_screen.dart`, then delete `signup_screen.dart`.

---

### P2 — RTL mirroring is incomplete

Locale and delegates are configured correctly (`main.dart:275-285`), so Flutter supplies RTL
`Directionality` for Arabic. But:

| Directional (mirrors) | Physical (does not mirror) |
|---|---|
| `AlignmentDirectional` — **9** | `Alignment.centerLeft/centerRight/topLeft/topRight` — **39** |
| `EdgeInsetsDirectional` — **15** | — |

Good news: `EdgeInsets.only(left:/right:)` count is **0**, and `TextAlign.left/right` is **0**.
So padding is already RTL-clean; it's only the 39 `Alignment.*` constants that stay physically
left in Arabic.

**Fix:** mechanical swap to `AlignmentDirectional.centerStart` / `.centerEnd` / `.topStart` /
`.topEnd`. Add a lint so it doesn't regress.

---

### P2 — Only 3 `SnackBarAction`s app-wide; no undo on destructive edits

`SnackBarAction|undo` → 8 hits, 5 of which are translation strings. Two are "retry"
(`inbody_input_screen.dart:864,883`), one is in messaging.

Meanwhile these remove user work instantly with no confirm and no undo:

```
admin_nutrition_templates_screen.dart:1245  _variants.removeAt(index)
admin_nutrition_templates_screen.dart:1611  _removeIngredient(index)
admin_nutrition_templates_screen.dart:1969  _removeDay(dayIndex)
admin_nutrition_templates_screen.dart:2537  _days.removeAt(index)
admin_workout_templates_screen.dart:653     _removeSession(dayIndex)
admin_workout_templates_screen.dart:922     _sessions.removeAt(index)
```

In a 2,830-line template builder, deleting day 5 by mistyping a tap costs real work.

**Fix:** a shared `removeWithUndo()` helper — stash the item, remove, show a 5-second
SnackBar with UNDO. ~20 lines, covers all six call sites.

---

### P2 — Dark mode is clean in Admin/Coach, inconsistent in Client

`Colors.white` / `Colors.black` occurrences by area:

| Area | Count | | Area | Count |
|---|---|---|---|---|
| store | 35 | | account | 10 |
| nutrition | 29 | | auth | 10 |
| messaging | 22 | | booking | 8 |
| workout | 20 | | subscription | 4 |
| **admin** | **1** | | **coach** | **0** |

Admin and Coach screens went through a theming pass and use `context.palette` throughout
(651 uses app-wide). The Client journey did not. Most instances are white-on-colored-surface
(fine), but some are real defects — e.g. `auth_screen.dart:860` renders the Apple sign-in icon
`Colors.black`, invisible on a dark background.

**Fix:** sweep the four client areas; add `context.palette.onPrimary`-style tokens for the
legitimate on-color cases so the lint can ban bare `Colors.white`.

---

# Role 1 — Client

### P0 — Payment management is a mockup wearing a real screen's clothes

`lib/presentation/screens/account/payment_management_screen.dart`

**Billing addresses are hardcoded and the Edit buttons are decorative** — and unlike the payment
methods card, this is **not** behind `DemoConfig.isDemo`. Production users see this:

```dart
// :235
subtitle: const Text('Prince Turki St, Riyadh 12345'),
trailing: TextButton(
  onPressed: () => _showSnack(lang.t('save')),   // shows a toast, saves nothing
  child: Text(lang.t('edit')),
),
// :247
subtitle: const Text('Remote Office Hub, Dammam 12211'),
```

**Auto-pay toggle never persists** (`:88-94`):

```dart
value: _autoPayEnabled,
onChanged: (value) => setState(() => _autoPayEnabled = value),
```

A user who switches auto-renew off, leaves the screen and returns, finds it on — and will still
be charged. On a paid subscription product this is a billing-trust and arguably
consumer-protection issue, not a UX nit.

**Fix:** either wire both to `PaymentRepository` (addresses: real CRUD; auto-pay: real
subscription flag with optimistic update + rollback on failure), or hide both sections until
they are real. Do not ship a toggle that lies about billing.

---

### P1 — The entire store post-browse flow exists but is unreachable

Three finished screens with **zero references** anywhere in `lib/`, `test/`, or
`integration_test/`:

| Dead screen | Lines |
|---|---|
| `store/store_product_detail_screen.dart` | ~600 |
| `store/store_order_detail_screen.dart` | ~400 |
| `store/store_order_confirmation_screen.dart` | ~300 |

`store_screen.dart` instead uses modal bottom sheets — `_showProductDetail` (`:1484`),
`_showOrderDetails` (`:942`, `:1237`). So the funnel *works*, but through a cramped sheet, while
the richer full-screen versions sit dead. Two competing implementations; the worse one shipped.

Also dead, same check:

| Dead screen | Impact |
|---|---|
| `coach/coach_earnings_screen.dart` (1 of 15 coach screens) | **Coaches cannot see their earnings at all** |
| `nutrition/meal_detail_screen.dart` | Client can't drill into a meal |
| `workout/workout_timer_screen.dart` | Rest timer unreachable |
| `intro/feature_intro_screen.dart` | — |
| `auth/signup_screen.dart` | superseded (see above) |

~5,000 lines total.

**Fix:** decide per screen — promote the full-screen version and delete the sheet, or delete the
dead screen. `coach_earnings_screen` is the urgent one: wire it into the Coach dashboard now.

---

### P1 — Six bottom-nav tabs, no badges, no selected icons

`home_dashboard_screen.dart:116-156` — six `BottomNavigationBarItem`s with
`type: BottomNavigationBarType.fixed`:

`home · workout · nutrition · coach · store · account`

Material guidance is 3–5. At six, each label gets ~16% of the width. In Arabic the labels are
longer (`التغذية`, `الاشتراك`) and will clip or ellipsize on a 360dp phone.

Also:
- No `activeIcon` — selection is communicated by **color alone**, which fails for
  colorblind users and is a WCAG 1.4.1 (Use of Color) problem.
- **No unread badge on the Coach tab.** The data exists —
  `coach_dashboard_screen.dart:407` reads `analytics.unreadMessages` for a stat card — it just
  never reaches the nav. The client-side grid card fakes it:
  `home_dashboard_screen.dart` → `badge: DemoConfig.isDemo ? '1' : null`, a hardcoded demo value.

**Fix:** collapse to 5 by folding Store into Account or into the home grid; add `activeIcon`;
wire a real unread `Badge` on the Coach tab.

---

### P2 — Two different answers to the same paywall

Tapping Nutrition as a Freemium user does two different things depending on where you tap:

| Entry point | Behavior |
|---|---|
| Home grid card (`home_dashboard_screen.dart:922-932`) | `locked: isFreemium` → pushes `SubscriptionManagerScreen` immediately |
| Bottom nav tab 2 (`:100`, `:141`) | No lock → opens `NutritionScreen`, which renders `_buildLockedAccess` (`nutrition_screen.dart:962`) |

Both are defensible; having both is not. The nav tab also gives no advance signal that the tab
is locked.

**Fix:** pick one. Recommend the in-screen locked state (it sells the feature with
`_buildLockedFeatureRow` benefits before asking for money) and make the grid card route there
too. Add a lock glyph to the nav icon.

---

### P2 — Client lists have no pull-to-refresh

`RefreshIndicator` coverage:

| Role | Coverage |
|---|---|
| **Admin** | 9 of 10 screens |
| **Coach** | 6 of 15 |
| **Client** | missing on `nutrition_screen`, `workout_screen`, `store_screen`, `progress_screen`, `exercise_library_screen`, `account_screen` |

The client's most-visited surfaces are the ones that can't be refreshed. The workaround is a
hidden gesture: re-tapping the already-selected Workout tab triggers a reload
(`home_dashboard_screen.dart:118-128`) — undiscoverable.

**Fix:** `RefreshIndicator` on the six client screens.

---

# Role 2 — Coach

### P0 — Quick actions silently target an arbitrary client

`coach_dashboard_screen.dart:70-87`:

```dart
({String id, String name})? _resolveDefaultClient(LanguageProvider lang) {
  ...
  final coachProvider = context.read<CoachProvider>();
  if (coachProvider.clients.isNotEmpty) {
    final client = coachProvider.clients.first;   // <-- whoever happens to be first
    return (id: client.id, name: client.fullName);
  }
  return null;
}
```

This feeds **three** dashboard quick actions:

- `_openWorkoutPlanBuilder` (`:89`) → `WorkoutPlanBuilderScreen(clientId: ...)`
- `_openNutritionPlanBuilder` (`:118`) → `NutritionPlanBuilderScreen(clientId: ...)`
- `_openQuickSchedule` (`:136`) → `showCoachScheduleSessionSheet(clientId: ...)`

A coach taps "Create workout plan" on the dashboard and lands in a builder already bound to
`clients.first` — with no picker and no confirmation step. They can author and assign an entire
training plan to the wrong person. For a nutrition plan with allergy constraints, that is a
safety issue, not just an annoyance.

**Fix:** show a client picker sheet first. Required, not defaulted. If there is exactly one
client, pre-select but still show the name prominently in the builder header.

---

### P1 — Coaches cannot see their earnings

`coach_earnings_screen.dart` is fully built (charts, `periodBreakdown`, fl_chart) and has
**zero callers**. `grep -rni "earning|payout|revenue" lib/presentation/screens/coach/` excluding
that file returns **nothing** — no entry point exists anywhere in the coach UI.

For a marketplace product, "how much have I made" is a top-three coach question.

**Fix:** add it to the Coach dashboard header or as a fifth tab. The screen is done; this is a
navigation wire-up.

---

### P1 — Coach has no unread-message indicator

`coach_dashboard_screen.dart:237-262` — four tabs, none badged. `analytics.unreadMessages` is
already loaded and rendered as a stat card at `:407`. A coach who opens straight to Clients or
Calendar has no signal that a client is waiting.

**Fix:** `Badge` on the Messages tab, same data source.

---

### P2 — Only Clients has search; Calendar and Messages do not

`grep -l "searchQuery\|Icons.search" lib/presentation/screens/coach/` → `coach_clients_screen.dart` only.

A coach with 40 clients cannot search their message threads or jump to a date in the calendar.
Compare Admin, where 6 of 10 screens have search.

---

### P2 — Plan builders have no loading state

`coach/workout_plan_builder_screen.dart`, `coach/nutrition_plan_builder_screen.dart`, and
`coach/plan_library_options.dart` contain no `CircularProgressIndicator`, `isLoading`, or
shimmer. Loading a template library or saving a plan shows a frozen UI.

---

# Role 3 — Admin

### P0 — Dashboard fails to a blank panel

`admin_dashboard_screen.dart:146-148`:

```dart
if (isLoading)
  const Center(child: CircularProgressIndicator())
else if (analytics != null) ...[
  // every metric card
]
// no else
```

`AdminProvider` **does** track the failure — `_error` is declared at `:20`, exposed at `:54`,
and set from `catch (e)` at `:119`, `:164`, and elsewhere. But the dashboard reads only
`.analytics` and `.isLoading` (`:85-86`) and **never reads `.error`**.

When `loadDashboardAnalytics()` throws: spinner stops, `analytics` stays null, the entire
metrics section vanishes. No message, no retry, no explanation. The admin assumes the platform
has zero users.

**Fix:** add the `else if (adminProvider.error != null)` branch with a mapped message and a
Retry button. The `RefreshIndicator` is already there (`:89`) — it just isn't discoverable when
the body is empty.

---

### P1 — No pagination on any admin list

`hasMore|loadMore` across `lib/presentation/screens/admin/` → **0**.

Hard caps instead:

```
store_management_screen.dart:119  getProducts(limit: 100, offset: 0)
store_management_screen.dart:121  getAllOrdersAdmin(limit: 50, offset: 0)
```

Order 51 is unreachable from the admin UI. As the platform grows, every admin list silently
truncates — the worst kind of failure, because it looks like success.

**Fix:** infinite scroll with a `ScrollController` + `hasMore`, or explicit paging controls.
At minimum, show "showing 50 of N" so truncation is visible.

---

### P1 — Admin and Coach get the Client account screen

Both roles reach account management by pushing `AccountScreen`:

```
admin_dashboard_screen.dart:129,  :561
coach_dashboard_screen.dart:345
```

`AccountScreen` is a 1,450-line **client** screen — subscription tier, plan upgrade, payment
methods, progress, workout history. An admin opening it sees a subscription upsell for
themselves.

Logout *is* reachable (`account_screen.dart:809`), so this is not a dead end — but it's the
wrong screen. Coaches have no profile/bio/availability/rate settings anywhere; admins have no
platform settings.

**Fix:** a `RoleAwareAccountScreen` that swaps the middle sections by role — client keeps
subscription + payments; coach gets profile, bio, specializations, availability, payout details;
admin gets platform settings and audit shortcuts. Shared chrome: avatar, language, theme,
password, logout, delete account.

---

### P2 — Destructive template edits are immediate and silent

Covered in cross-cutting above; it lands hardest in Admin because
`admin_nutrition_templates_screen.dart` is 2,830 lines of form state with four separate
remove-without-confirm paths.

Note the *user*-facing destructive actions are done well — `admin_users_screen` and
`admin_coaches_screen` have 6 and 5 `showDialog` confirmations respectively, with proper
"cannot be undone" copy (`language_provider.dart:289`, `:2249`). The template builders just
never got the same treatment.

---

## Scorecard

| Dimension | Client | Coach | Admin |
|---|---|---|---|
| Screens | 30 | 15 | 10 |
| Pull-to-refresh | 2/30 | 6/15 | 9/10 |
| Dark-mode themed | partial (201 raw colors) | clean (0) | clean (1) |
| Error states | partial | partial | **dashboard: none** |
| Search / filter | n/a | 1/15 | 6/10 |
| Pagination | — | — | **none** |
| Dead screens | 4 | 2 | 0 |
| Unsaved-work guard | none | none | none |
| `Semantics` | 1 screen | 0 | 0 |

---

## Suggested order

**Sprint 1 — trust and correctness**
1. Payment: wire or hide billing addresses + auto-pay toggle *(P0, client)*
2. Coach quick actions: require a client picker *(P0, coach)*
3. Admin dashboard: add the error branch + retry *(P0, admin)*
4. `PopScope` dirty-guard on all editors and multi-step forms *(P0, all)*

**Sprint 2 — reach what's already built**
5. Wire `coach_earnings_screen` into the Coach dashboard *(P1)*
6. Resolve the three dead store screens vs. the bottom sheets *(P1)*
7. `AppError` + message keys; stop printing `e.toString()` *(P0)*
8. `ConnectivityProvider` + offline banner *(P0)*

**Sprint 3 — polish and a11y**
9. `autofillHints` + `AutofillGroup` on login/signup; port the password reveal toggle *(P1)*
10. `tooltip:` on ~90 icon buttons; raise the `textScaler` clamp and fix the overflows *(P1)*
11. Collapse client nav to 5 tabs; add `activeIcon` + real unread badges *(P1)*
12. 39 `Alignment.*` → `AlignmentDirectional.*`; client dark-mode sweep *(P2)*
13. `removeWithUndo()` helper for the six admin template remove paths *(P2)*
14. Admin pagination *(P1)*
15. Role-aware account screen *(P1)*

---

## What's already good — don't regress it

- **i18n.** 4,010 keys, 17 hardcoded strings total (mostly numeric interpolation). Rare at this
  size.
- **RTL padding.** Zero `EdgeInsets.only(left:/right:)`, zero `TextAlign.left/right`.
  `auth_screen` even mirrors its reveal animations (`isRTL ? -0.25 : 0.25`).
- **Design tokens.** 651 `context.palette` uses; Admin and Coach are fully themed.
- **Admin confirmations** on user and coach deletion, with correct irreversibility copy.
- **`progress_screen` and the subscription screens** are the reference implementations — loading,
  empty, and error states all handled. Use them as the pattern for the rest.
- **The OTP input** (`widgets/otp_input.dart`) is correct and intentional. The single-field +
  `AutofillHints.oneTimeCode` + `AutofillGroup` design is the right ceiling; leave it alone.
