# FitCoach — UI Unification Proposal

Follows the audit in [UX_AUDIT_THREE_ROLES.md](UX_AUDIT_THREE_ROLES.md).
Written after the P0 fixes landed; this is what comes next.

---

## The core finding

**FitCoach already has a design system. The screens just don't use it.**

`core/config/theme_config.dart` (375 lines) configures a full `TextTheme`,
`CardThemeData`, `InputDecorationTheme`, `ElevatedButtonThemeData` and more.
`core/theme/app_palette.dart` is a well-built `ThemeExtension` with proper
semantic tokens and a genuinely thoughtful dark mode.

Then the screens bypass all of it:

| Signal | Count |
|---|---|
| Hardcoded `TextStyle(` in screens | **866** |
| Hardcoded `fontSize:` in screens | **607** |
| `AppTextStyles.*` used instead | 52 |
| `Theme.of(context).textTheme` used | **2** |
| Distinct font sizes in use | **18** |
| Distinct corner radii in use | **17** |
| Raw `BoxDecoration(` in screens | 242 |

So the app looks slightly different on every screen not because anyone chose
that, but because 600+ independent decisions were made where one decision
should have been reused.

**This is the whole "make it look elegant and production" problem.** It is not
a redesign. It is adoption of what is already there.

---

## Proposal 1 — Adopt the type scale (highest visual impact)

18 font sizes is why the app reads as inconsistent. Collapse to 7 roles, all
already defined in `AppTextStyles`:

| Role | Size / weight | Today's equivalents |
|---|---|---|
| `displayLarge` | 32 / w700 | 48, 32, 28 |
| `headlineMedium` (h1) | 24 / w600 | 24, 22 |
| `titleLarge` (h2) | 20 / w600 | 20 |
| `titleMedium` (h3) | 18 / w600 | 18 |
| `bodyLarge` (body) | 16 / w400 | 16, 15 |
| `bodyMedium` (small) | 14 / w400 | 14, 13 |
| `labelSmall` | 12 / w500 | 12, 11, 10 |

Screens then write `style: Theme.of(context).textTheme.titleMedium` instead of
`TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ...)`.

**Why this also fixes accessibility:** `main.dart` currently clamps text scaling
to 1.5 (raised from 1.15 in this pass) because hardcoded sizes inside fixed-height
containers overflow when scaled. Theme-driven sizes scale predictably, which is
what unblocks raising the clamp to the WCAG-required 2.0.

**Effort:** mechanical but large — ~600 sites. Best done per-screen alongside
other work, with a lint banning new `fontSize:` in `presentation/screens/`.

---

## Proposal 2 — Three radii, four spacings

Today: 17 radii (including one-offs at 3, 22, 32, 36, 40) and 10 `EdgeInsets.all`
values.

Proposed tokens on the existing palette extension:

```dart
// radius
sm = 8    // chips, inputs, small controls
md = 12   // cards, sheets, buttons     <- already 129 of 258 uses
lg = 20   // modals, hero surfaces
pill = 999

// spacing
xs = 4 · sm = 8 · md = 16 · lg = 24
```

`EdgeInsets.all(16)` is already 123 of 226 uses, and `circular(12)` is already
the plurality. This mostly ratifies what the app already does and deletes the
long tail.

---

## Proposal 3 — Delete the duplicate component library

`presentation/widgets/` contains two parallel component families. One is used,
one is dead:

| Widget | Lines | Uses in screens |
|---|---|---|
| `CustomCard` | 83 | **146** |
| `EnhancedCard` | 199 | **0** |
| `CustomButton` | 296 | **43** |
| `EnhancedButton` | 278 | **0** |
| `EnhancedInput` | 342 | **0** |
| `EnhancedProgress` | 314 | **0** |

**1,133 lines across four files, with zero references in `lib/`, `test/`, or
`integration_test/`.**

Every time someone opens `widgets/` they have to work out which family is real.
Recommend: read the `enhanced_*` files once for anything worth keeping (the
input validation states look more complete than what `CustomCard` screens
hand-roll), port that into the `custom_*` family, then delete all four.

---

## Proposal 4 — Finish the dead-screen cleanup

Still unreferenced after this pass (`coach_earnings_screen` was wired in):

| Screen | Decision needed |
|---|---|
| `store_product_detail_screen` | Promote over the bottom sheet, or delete |
| `store_order_detail_screen` | Promote over the bottom sheet, or delete |
| `store_order_confirmation_screen` | Promote, or delete |
| `nutrition/meal_detail_screen` | Wire from the meal list, or delete |
| `workout/workout_timer_screen` | Wire into the session flow, or delete |
| `auth/signup_screen` | **Delete** — superseded by `auth_screen`, but port its password-reveal toggles and per-field validators first |
| `intro/feature_intro_screen` | Delete |

**Recommendation on the store three:** promote them. A product detail in a
bottom sheet caps the content at ~60% of screen height, which is why the store
feels thinner than the rest of the app. The full-screen versions are already
written.

---

## Proposal 5 — Client navigation: six tabs to five

`home · workout · nutrition · coach · store · account` — six fixed tabs each get
~16% of the width. Arabic labels (`الاشتراك`, `التغذية`) clip on a 360dp phone.

Material guidance is 3–5. Recommended: **fold Store into Account**, or into the
home grid where it already has a card. Store is a browse-occasionally surface,
not a daily one — it does not earn a permanent slot the way Workout and
Nutrition do.

Already fixed in this pass: `activeIcon` on every tab (selection was
colour-only, a WCAG 1.4.1 failure), real unread badges, and a lock glyph on
gated tabs.

---

## Proposal 6 — Role-aware account screen

`AccountScreen` is a 1,450-line client screen, and Admin and Coach both push it
(`admin_dashboard_screen.dart:129,:561`, `coach_dashboard_screen.dart:345`). An
admin opening it gets a subscription upsell for themselves.

Split the middle sections by role, keep the chrome shared:

| | Client | Coach | Admin |
|---|---|---|---|
| Shared | avatar, language, theme, password, logout, delete account | ← | ← |
| Role-specific | subscription, payments, progress | bio, specializations, availability, payout details | platform settings, audit shortcuts |

Coaches currently have **nowhere** to set a bio, rate, or availability.

---

## Proposal 7 — Accessibility pass

- **`tooltip:` on ~90 icon-only buttons.** 116 `IconButton`s, 26 tooltips.
  Screen readers announce nothing for the rest. Most keys already exist.
- **`Semantics(label:)` on custom tappable `Container`s** — the home nav grid
  and stat cards are `InkWell` over `Container`, invisible to assistive tech.
- **Raise the text-scale clamp to 2.0** once Proposal 1 lands.
- **39 `Alignment.centerLeft/topLeft` → `AlignmentDirectional.*`** so they mirror
  in Arabic. Padding is already RTL-clean (zero `EdgeInsets.only(left:)`), so
  this is the last RTL gap.

---

## Proposal 8 — Admin pagination

`hasMore` / `loadMore` appear **zero** times in `screens/admin/`. Hard caps
instead: `getProducts(limit: 100)`, `getAllOrdersAdmin(limit: 50)`. Order 51 is
unreachable.

Minimum viable: show "showing 50 of N" so truncation is visible. Proper:
`ScrollController` + `hasMore` infinite scroll.

---

## Proposal 9 — Undo for destructive template edits

Six call sites in the admin template builders remove a day / session / variant /
ingredient with an immediate `removeAt(index)` — no confirm, no undo. In a
2,830-line form, a mistyped tap costs real work.

One `removeWithUndo()` helper (stash → remove → 5s SnackBar with UNDO) covers
all six in ~20 lines.

---

## Suggested sequencing

**Now (visible, low risk)**
1. Delete the `enhanced_*` family (Proposal 3) — pure deletion, −1,133 lines
2. Radii and spacing tokens (Proposal 2) — mostly ratifies current practice
3. Tooltips (Proposal 7, first bullet) — mechanical, large a11y win

**Next (the look-and-feel change)**
4. Type scale adoption (Proposal 1), screen by screen, client screens first —
   they carry nearly all the hardcoded colour and type
5. Raise the text-scale clamp to 2.0 once 4 is done
6. Resolve the dead store screens (Proposal 4)

**Then (structural)**
7. Client nav to five tabs (Proposal 5)
8. Role-aware account screen (Proposal 6)
9. Admin pagination (Proposal 8) and undo (Proposal 9)

---

## What not to change

- **The palette.** `app_palette.dart` is well-reasoned — the `textOnBrand`
  token and the note about why dark mode uses dark-on-brand show someone
  actually checked contrast. Build on it.
- **The i18n catalogue.** 4,010 keys and a guard test enforcing both-language
  parity. Rare at this size.
- **`progress_screen` and the subscription screens.** These already do
  loading / empty / error properly. Use them as the pattern.
- **`widgets/otp_input.dart`.** Deliberate, documented, correct.
