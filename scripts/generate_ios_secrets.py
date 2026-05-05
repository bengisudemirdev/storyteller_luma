#!/usr/bin/env python3
"""
Reads Luma/Config/.env and writes Luma/Config/Secrets.generated.swift.
Run automatically from Xcode (Build Phase) or: python3 scripts/generate_ios_secrets.py
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / "Luma" / "Config" / ".env"
OUT_PATH = ROOT / "Luma" / "Config" / "Secrets.generated.swift"

# env key -> Swift property name
KEYS = [
    ("SUPABASE_URL", "supabaseURL"),
    ("SUPABASE_ANON_KEY", "supabaseAnonKey"),
    ("BACKEND_BASE_URL", "backendBaseURL"),
    ("REVENUECAT_API_KEY", "revenueCatAPIKey"),
    ("REVENUECAT_SANDBOX_API_KEY", "revenueCatSandboxAPIKey"),
    ("REVENUECAT_USE_TEST_STORE", "revenueCatUseTestStore"),
    ("REVENUECAT_OFFERING_KEY", "revenueCatOfferingKey"),
    ("ELEVENLABS_API_KEY", "elevenLabsAPIKey"),
    ("ELEVENLABS_AGENT_ID", "elevenLabsAgentId"),
    ("ELEVENLABS_VOICE_ID", "elevenLabsVoiceId"),
    ("FEEDBACK_EMAIL", "feedbackEmail"),
    # İsteğe bağlı CDN tabanı .../classic-tales (sonunda / yok). Boşsa Supabase URL + bucket ile üretilir.
    ("CLASSIC_TALE_COVERS_BASE_URL", "classicTaleCoversBaseURL"),
]


def parse_env(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    if not path.is_file():
        return data
    text = path.read_text(encoding="utf-8")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()
        # Strip matching quotes
        if len(value) >= 2:
            if value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
        data[key] = value
    return data


def swift_string_literal(s: str) -> str:
    escaped = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r")
    return f'"{escaped}"'


def main() -> None:
    env = parse_env(ENV_PATH)
    lines = [
        "//",
        "//  Secrets.generated.swift",
        "//",
        "//  AUTO-GENERATED — do not edit. Source: Luma/Config/.env",
        "//  Regenerate: build in Xcode, or: python3 scripts/generate_ios_secrets.py",
        "//",
        "",
        "import Foundation",
        "",
        "enum Secrets {",
    ]
    for env_key, prop in KEYS:
        raw = env.get(env_key, "")
        lines.append(f"    static let {prop} = {swift_string_literal(raw)}")
    lines.extend(["}", ""])
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
