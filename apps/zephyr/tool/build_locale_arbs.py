#!/usr/bin/env python3
"""Generate app_*.arb locale files from app_en.arb (and app_zh.arb for zh_TW).

Requires: pip install deep-translator opencc-python-reimplemented

Usage (from apps/zephyr):
  python tool/build_locale_arbs.py
  python tool/build_locale_arbs.py --locale ja ko   # subset only
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

from deep_translator import MyMemoryTranslator
from opencc import OpenCC

L10N_DIR = Path(__file__).resolve().parent.parent / "lib" / "l10n"

# MyMemory language pair names (see MyMemoryTranslator.get_supported_languages).
MYMEMORY_TARGETS: dict[str, tuple[str, str]] = {
    "ja": ("english", "japanese"),
    "ko": ("english", "korean"),
    "es": ("english", "spanish"),
    "fr": ("english", "french"),
    "de": ("english", "german"),
    "pt": ("english", "portuguese brazil"),
    "ru": ("english", "russian"),
    "ar": ("english", "arabic"),
    "hi": ("english", "hindi"),
    "it": ("english", "italian"),
}

# Do not machine-translate these message keys (brands / proper nouns).
SKIP_TRANSLATE_KEYS = frozenset(
    {
        "appTitle",
        "platformDefaultFont",
        "themePresetClaude",
        "themePresetHermes",
        "aboutGitHubTitle",
    }
)

# Picker shows endonyms; only title/subtitle/system line are localized.
_TRANSLATED_LANGUAGE_KEYS = frozenset(
    {"languageTitle", "languageSubtitle", "languageSystem"}
)


def keep_english_value(key: str) -> bool:
    if key in SKIP_TRANSLATE_KEYS:
        return True
    if key.startswith("language") and key not in _TRANSLATED_LANGUAGE_KEYS:
        return True
    return False

PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z_]+\}")


def load_arb(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def write_arb(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def protect_placeholders(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"⟦{len(tokens) - 1}⟧"

    protected = PLACEHOLDER_RE.sub(repl, text)
    return protected, tokens


def restore_placeholders(text: str, tokens: list[str]) -> str:
    for i, token in enumerate(tokens):
        text = text.replace(f"⟦{i}⟧", token)
    return text


def translate_text(translator: MyMemoryTranslator, text: str) -> str:
    if not text.strip():
        return text
    protected, tokens = protect_placeholders(text)
    # MyMemory has a per-request length limit; chunk long strings.
    max_len = 450
    if len(protected) <= max_len:
        out = translator.translate(protected)
        return restore_placeholders(out, tokens)
    parts: list[str] = []
    chunk = ""
    for line in protected.split("\n"):
        candidate = f"{chunk}\n{line}" if chunk else line
        if len(candidate) > max_len and chunk:
            parts.append(translator.translate(chunk))
            chunk = line
        else:
            chunk = candidate
    if chunk:
        parts.append(translator.translate(chunk))
    merged = "\n".join(parts)
    return restore_placeholders(merged, tokens)


def load_cache() -> dict[str, str]:
    path = L10N_DIR / ".translate_cache.json"
    if not path.exists():
        return {}
    return load_arb(path)  # type: ignore[return-value]


def save_cache(cache: dict[str, str]) -> None:
    path = L10N_DIR / ".translate_cache.json"
    write_arb(path, cache)


def build_from_english(
    locale: str,
    en: dict,
    cache: dict[str, str],
    *,
    resume: bool,
) -> dict:
    source, target = MYMEMORY_TARGETS[locale]
    translator = MyMemoryTranslator(source=source, target=target)
    out_path = L10N_DIR / f"app_{locale}.arb"
    existing: dict = {}
    if resume and out_path.exists():
        existing = load_arb(out_path)
    out: dict = {"@@locale": locale}
    keys = [k for k in en if not k.startswith("@") and k != "@@locale"]
    total = len(keys)
    for i, key in enumerate(keys, start=1):
        if keep_english_value(key):
            out[key] = en[key]
            continue
        value = en[key]
        if not isinstance(value, str):
            out[key] = value
            continue
        if resume and key in existing and isinstance(existing[key], str):
            out[key] = existing[key]
            meta_key = f"@{key}"
            if meta_key in en:
                out[meta_key] = en[meta_key]
            continue
        cache_key = f"{locale}\0{value}"
        cached = cache.get(cache_key)
        if cached is not None:
            out[key] = cached
            continue
        for attempt in range(4):
            try:
                translated = translate_text(translator, value)
                out[key] = translated
                cache[cache_key] = translated
                break
            except Exception as exc:  # noqa: BLE001
                message = str(exc).lower()
                if "too many requests" in message and attempt < 3:
                    time.sleep(12 * (attempt + 1))
                    continue
                if attempt == 3:
                    print(f"  [{locale}] {key}: failed ({exc}), keeping English", file=sys.stderr)
                    out[key] = value
                    cache[cache_key] = value
                else:
                    time.sleep(2 * (attempt + 1))
        if i % 25 == 0:
            print(f"  [{locale}] {i}/{total}…")
        time.sleep(1.0)
        meta_key = f"@{key}"
        if meta_key in en:
            out[meta_key] = en[meta_key]
    return out


def build_zh_tw(zh: dict, en: dict) -> dict:
    cc = OpenCC("s2t")
    out: dict = {"@@locale": "zh_TW"}
    for key, value in zh.items():
        if key == "@@locale":
            continue
        if key.startswith("@") or not isinstance(value, str):
            out[key] = value
        elif keep_english_value(key):
            out[key] = en.get(key, value) if key in en else value
        else:
            out[key] = cc.convert(value)
    return out


def merge_language_labels(en: dict) -> None:
    """Ensure new language picker labels exist in template."""
    labels = {
        "languageJapanese": "日本語",
        "languageKorean": "한국어",
        "languageSpanish": "Español",
        "languageFrench": "Français",
        "languageGerman": "Deutsch",
        "languagePortuguese": "Português",
        "languageRussian": "Русский",
        "languageArabic": "العربية",
        "languageHindi": "हिन्दी",
        "languageItalian": "Italiano",
        "languageChineseTraditional": "繁體中文",
    }
    for key, label in labels.items():
        en.setdefault(key, label)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--locale",
        nargs="*",
        choices=[*MYMEMORY_TARGETS.keys(), "zh_TW"],
        help="Locales to build (default: all)",
    )
    parser.add_argument(
        "--fresh",
        action="store_true",
        help="Ignore partial app_<locale>.arb when translating",
    )
    args = parser.parse_args()
    targets = args.locale or [*MYMEMORY_TARGETS.keys(), "zh_TW"]

    en_path = L10N_DIR / "app_en.arb"
    zh_path = L10N_DIR / "app_zh.arb"
    en = load_arb(en_path)
    merge_language_labels(en)
    write_arb(en_path, en)

    zh = load_arb(zh_path) if zh_path.exists() else None
    if zh:
        for key in en:
            if key.startswith("language") and key not in zh and isinstance(en.get(key), str):
                zh[key] = en[key]
        write_arb(zh_path, zh)

    cache = load_cache()
    for locale in targets:
        out_path = L10N_DIR / f"app_{locale}.arb"
        print(f"Building {out_path.name}…")
        if locale == "zh_TW":
            if zh is None:
                print("  skip zh_TW (app_zh.arb missing)", file=sys.stderr)
                continue
            data = build_zh_tw(zh, en)
        else:
            data = build_from_english(
                locale,
                en,
                cache,
                resume=not args.fresh,
            )
        write_arb(out_path, data)
        save_cache(cache)
        print(f"  wrote {out_path.name}")

    print("Done. Run: flutter gen-l10n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
