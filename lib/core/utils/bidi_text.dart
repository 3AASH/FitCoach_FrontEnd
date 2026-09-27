/// Numbers and units inside Arabic sentences.
///
/// Arabic runs right-to-left, but Latin digits and unit letters (`30g`,
/// `220 cal`) run left-to-right. When both appear in one string, the Unicode
/// bidirectional algorithm has to decide where each run ends, and it decides
/// using the characters around it. Spaces, hyphens and bullets are all
/// *neutral* — they have no direction of their own — so in a line like
///
/// ```
/// 'بروتين 30g - كربوهيدرات 40g - دهون 10g'
/// ```
///
/// every separator is up for grabs. The numbers bleed across them and the
/// line renders in an order nobody wrote: the macros appear shuffled, and a
/// value can end up next to the wrong label.
///
/// [bidiIsolate] wraps a run in a *first-strong isolate*. The run's own
/// direction is then resolved on its own, and to everything outside it the
/// run is a single opaque character that cannot swap places with its
/// neighbours. The surrounding Arabic keeps its right-to-left order and each
/// value stays with its label.
///
/// Use it on any value interpolated into translated text — a weight, a
/// calorie count, a percentage, a date — not on the sentence as a whole.
library;

// Built from code points rather than written as literals: the analyzer warns
// about direction-changing characters in string literals, and it is right to
// — hidden bidi marks in source are how code gets made to read differently
// than it runs. Here they are the payload, so they are named instead.

/// U+2068 FIRST STRONG ISOLATE: start an independently-resolved run.
final String _firstStrongIsolate = String.fromCharCode(0x2068);

/// U+2069 POP DIRECTIONAL ISOLATE: end it.
final String _popDirectionalIsolate = String.fromCharCode(0x2069);

/// [value] as one opaque run that the bidi algorithm will not reorder.
///
/// Returns the value unchanged when it is empty, so callers do not have to
/// guard against a missing measurement.
String bidiIsolate(String value) =>
    value.isEmpty ? value : '$_firstStrongIsolate$value$_popDirectionalIsolate';

/// A measurement ready to drop into a translated sentence, e.g. `30g`.
///
/// The unit sits against the number with no space, matching how the app has
/// always written these, and the pair is isolated as one unit.
String measurement(Object value, String unit) => bidiIsolate('$value$unit');

/// Strips the isolate marks again, for tests and for anywhere a plain string
/// is needed (a semantics label, a value sent to the backend).
String stripBidiIsolates(String value) => value
    .replaceAll(_firstStrongIsolate, '')
    .replaceAll(_popDirectionalIsolate, '');
