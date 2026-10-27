"""Download Abdul Basit Murattal (test surahs) + word timings offline."""
from __future__ import annotations

import json
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_AUDIO = ROOT / "assets" / "audio" / "abdulbaset"
OUT_JSON = OUT_AUDIO / "timings.json"

# Test set: Fatiha + Ikhlas + Falaq + Nas
SURAHS = {1: 7, 112: 4, 113: 5, 114: 6}
RECITATION_ID = 2  # AbdulBaset Murattal
AUDIO_BASE = "https://everyayah.com/data/Abdul_Basit_Murattal_64kbps"
API = "https://api.quran.com/api/v4"


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "ZekrApp/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    OUT_AUDIO.mkdir(parents=True, exist_ok=True)
    timings: dict[str, object] = {
        "reciter": "Abdul Basit Abdul Samad",
        "style": "Murattal",
        "ayahs": {},
    }

    for surah, n in SURAHS.items():
        for ayah in range(1, n + 1):
            key = f"{surah}:{ayah}"
            code = f"{surah:03d}{ayah:03d}"
            mp3_name = f"{code}.mp3"
            mp3_path = OUT_AUDIO / mp3_name

            if not mp3_path.exists() or mp3_path.stat().st_size < 1000:
                print("audio", key)
                data = get(f"{AUDIO_BASE}/{mp3_name}")
                mp3_path.write_bytes(data)
                time.sleep(0.15)

            print("timing", key)
            raw = get(f"{API}/verses/by_key/{key}?audio={RECITATION_ID}&words=true&word_fields=text_uthmani")
            verse = json.loads(raw.decode("utf-8"))["verse"]
            words = [
                w["text_uthmani"]
                for w in verse["words"]
                if w.get("char_type_name") == "word" and w.get("text_uthmani")
            ]
            segs = []
            for s in verse.get("audio", {}).get("segments") or []:
                # [i0, wordPos, startMs, endMs]
                if len(s) >= 4:
                    segs.append([int(s[1]) - 1, int(s[2]), int(s[3])])
                elif len(s) == 3:
                    segs.append([int(s[0]), int(s[1]), int(s[2])])

            timings["ayahs"][key] = {
                "file": mp3_name,
                "words": words,
                "segments": segs,
            }
            time.sleep(0.12)

    OUT_JSON.write_text(
        json.dumps(timings, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    total = sum(p.stat().st_size for p in OUT_AUDIO.glob("*.mp3"))
    print(f"done: {len(timings['ayahs'])} ayahs, audio={total/1024/1024:.1f} MB")


if __name__ == "__main__":
    main()
