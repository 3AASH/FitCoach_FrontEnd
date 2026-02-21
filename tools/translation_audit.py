import re
from pathlib import Path

LANG_PROVIDER = Path(r"D:\mobile applicatio\Git_Repo\FitCoach\mobile\lib\presentation\providers\language_provider.dart")


def extract_map(text: str, map_name: str) -> dict[str, str]:
    match = re.search(rf"static const Map<String, String> {re.escape(map_name)}\s*=\s*\{{", text)
    if not match:
        raise SystemExit(f"Map not found: {map_name}")

    start = match.end()
    depth = 1
    i = start

    while i < len(text) and depth:
        ch = text[i]
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        i += 1

    body = text[start : i - 1]

    # Handles simple single-quoted Dart strings. (Good enough for this translation file.)
    pairs = re.findall(r"'([^']+)'\s*:\s*'((?:\\'|[^'])*)'\s*,", body)
    return dict(pairs)


def main() -> None:
    text = LANG_PROVIDER.read_text(encoding="utf-8")
    eng = extract_map(text, "_englishTranslations")
    ar = extract_map(text, "_arabicTranslations")

    eng_keys = set(eng)
    ar_keys = set(ar)

    missing_ar = sorted(eng_keys - ar_keys)
    missing_en = sorted(ar_keys - eng_keys)

    arabic_re = re.compile(r"[\u0600-\u06FF]")
    english_with_arabic = [k for k, v in eng.items() if arabic_re.search(v)]

    latin_only = re.compile(r"^[\x00-\x7F]+$")
    arabic_latin_only = [k for k, v in ar.items() if latin_only.match(v) and k in eng]

    print(f"English keys: {len(eng_keys)}")
    print(f"Arabic keys:  {len(ar_keys)}")
    print(f"Missing Arabic for English keys: {len(missing_ar)}")
    print(f"Missing English for Arabic keys: {len(missing_en)}")
    print()

    if missing_ar:
        print("First 50 missing Arabic keys:")
        for k in missing_ar[:50]:
            print(" -", k)
        print()

    if english_with_arabic:
        print(f"English values containing Arabic chars: {len(english_with_arabic)}")
        for k in english_with_arabic[:50]:
            print(" -", k, "=>", eng[k])
        print()

    if arabic_latin_only:
        print(f"Arabic values that look Latin-only: {len(arabic_latin_only)}")
        for k in arabic_latin_only[:50]:
            print(" -", k, "=>", ar[k])
        print()


if __name__ == "__main__":
    main()
