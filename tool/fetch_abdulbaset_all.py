"""Download Abdul Basit Murattal + word timings for ALL short surahs in app."""
from __future__ import annotations

import json
import re
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_AUDIO = ROOT / "assets" / "audio" / "abdulbaset"
OUT_JSON = OUT_AUDIO / "timings.json"
RECITATION_ID = 2
AUDIO_BASE = "https://everyayah.com/data/Abdul_Basit_Murattal_64kbps"
API = "https://api.quran.com/api/v4"

# Official ayah counts for surahs we ship (<16)
AYAH_COUNTS = {
    1: 7,
    91: 15,
    93: 11,
    94: 8,
    95: 8,
    97: 5,
    98: 8,
    99: 8,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "ZekrApp/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read()


def parse_segments(raw_segs: list) -> list[list[int]]:
    """Normalize to [wordIndex0, startMs, endMs]."""
    out: list[list[int]] = []
    for s in raw_segs or []:
        if len(s) >= 4:
            # Quran.com: [tokenIndex, wordPosition1Based, startMs, endMs]
            out.append([int(s[1]) - 1, int(s[2]), int(s[3])])
        elif len(s) == 3:
            # already [wordIndex, start, end] OR [wordPos, start, end]
            a, b, c = int(s[0]), int(s[1]), int(s[2])
            if a >= 1 and (not out or a == out[-1][0] + 2):
                # likely 1-based word pos
                out.append([a - 1, b, c])
            else:
                out.append([a, b, c])
    return out


def main() -> None:
    OUT_AUDIO.mkdir(parents=True, exist_ok=True)
    existing = {}
    if OUT_JSON.exists():
        try:
            existing = json.loads(OUT_JSON.read_text(encoding="utf-8")).get(
                "ayahs", {}
            )
        except Exception:
            existing = {}

    timings: dict = {
        "reciter": "Abdul Basit Abdul Samad",
        "style": "Murattal",
        "ayahs": dict(existing),
    }

    for surah, n in sorted(AYAH_COUNTS.items()):
        for ayah in range(1, n + 1):
            key = f"{surah}:{ayah}"
            code = f"{surah:03d}{ayah:03d}"
            mp3_name = f"{code}.mp3"
            mp3_path = OUT_AUDIO / mp3_name

            if not mp3_path.exists() or mp3_path.stat().st_size < 1000:
                print("audio", key, flush=True)
                mp3_path.write_bytes(get(f"{AUDIO_BASE}/{mp3_name}"))
                time.sleep(0.12)

            need_timing = key not in timings["ayahs"] or not timings["ayahs"][
                key
            ].get("segments")
            if need_timing:
                print("timing", key, flush=True)
                raw = get(
                    f"{API}/verses/by_key/{key}?audio={RECITATION_ID}"
                    f"&words=true&word_fields=text_uthmani"
                )
                verse = json.loads(raw.decode("utf-8"))["verse"]
                words = [
                    w["text_uthmani"]
                    for w in verse["words"]
                    if w.get("char_type_name") == "word"
                    and w.get("text_uthmani")
                ]
                segs = parse_segments(verse.get("audio", {}).get("segments") or [])
                timings["ayahs"][key] = {
                    "file": mp3_name,
                    "words": words,
                    "segments": segs,
                }
                time.sleep(0.1)
            else:
                # keep file name in sync
                timings["ayahs"][key]["file"] = mp3_name

    OUT_JSON.write_text(
        json.dumps(timings, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    total = sum(p.stat().st_size for p in OUT_AUDIO.glob("*.mp3"))
    print(
        f"done: {len(timings['ayahs'])} ayahs, audio={total/1024/1024:.1f} MB",
        flush=True,
    )


if __name__ == "__main__":
    main()
