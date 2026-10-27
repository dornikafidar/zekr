"""Fetch missing verse audio: bismillah, 2:255-257, 68:51-52."""
from __future__ import annotations

import json
import shutil
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "abdulbaset"
JSON_PATH = OUT / "timings.json"
AUDIO_BASE = "https://everyayah.com/data/Abdul_Basit_Murattal_64kbps"
API = "https://api.quran.com/api/v4"
RECITATION_ID = 2

EXTRA_KEYS = ["2:255", "2:256", "2:257", "68:51", "68:52"]


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "ZekrApp/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read()


def parse_segments(raw_segs: list) -> list[list[int]]:
    out = []
    for s in raw_segs or []:
        if len(s) >= 4:
            out.append([int(s[1]) - 1, int(s[2]), int(s[3])])
        elif len(s) == 3:
            out.append([int(s[0]), int(s[1]), int(s[2])])
    return out


def fetch_verse(key: str) -> dict:
    surah, ayah = key.split(":")
    code = f"{int(surah):03d}{int(ayah):03d}"
    mp3 = f"{code}.mp3"
    path = OUT / mp3
    if not path.exists() or path.stat().st_size < 1000:
        print("audio", key, flush=True)
        path.write_bytes(get(f"{AUDIO_BASE}/{mp3}"))
        time.sleep(0.12)
    print("timing", key, flush=True)
    raw = get(
        f"{API}/verses/by_key/{key}?audio={RECITATION_ID}"
        f"&words=true&word_fields=text_uthmani"
    )
    verse = json.loads(raw.decode("utf-8"))["verse"]
    words = [
        w["text_uthmani"]
        for w in verse["words"]
        if w.get("char_type_name") == "word" and w.get("text_uthmani")
    ]
    return {
        "file": mp3,
        "words": words,
        "segments": parse_segments(verse.get("audio", {}).get("segments") or []),
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    ayahs = data.setdefault("ayahs", {})

    # Shared bismillah = Fatiha 1:1
    src = ayahs.get("1:1")
    if src:
        src_file = OUT / src["file"]
        dst_file = OUT / "bismillah.mp3"
        if src_file.exists():
            shutil.copyfile(src_file, dst_file)
        ayahs["bismillah"] = {
            "file": "bismillah.mp3",
            "words": list(src["words"]),
            "segments": [list(s) for s in src["segments"]],
        }
        print("bismillah ready", flush=True)

    for key in EXTRA_KEYS:
        ayahs[key] = fetch_verse(key)
        time.sleep(0.1)

    JSON_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("keys", len(ayahs), flush=True)


if __name__ == "__main__":
    main()
