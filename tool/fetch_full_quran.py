"""Download full Quran (114 surahs, Uthmani) + juz map into assets/quran/."""
from __future__ import annotations

import json
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "quran" / "surahs.json"
JUZ_OUT = ROOT / "assets" / "quran" / "juz.json"
API = "https://api.quran.com/api/v4"

FA_NAMES = {
    1: "فاتحه", 2: "بقره", 3: "آل‌عمران", 4: "نساء", 5: "مائده",
    6: "انعام", 7: "اعراف", 8: "انفال", 9: "توبه", 10: "یونس",
    11: "هود", 12: "یوسف", 13: "رعد", 14: "ابراهیم", 15: "حجر",
    16: "نحل", 17: "إسراء", 18: "کهف", 19: "مریم", 20: "طه",
    21: "أنبیاء", 22: "حج", 23: "مؤمنون", 24: "نور", 25: "فرقان",
    26: "شعراء", 27: "نمل", 28: "قصص", 29: "عنکبوت", 30: "روم",
    31: "لقمان", 32: "سجده", 33: "احزاب", 34: "سبأ", 35: "فاطر",
    36: "یس", 37: "صافات", 38: "ص", 39: "زمر", 40: "غافر",
    41: "فصلت", 42: "شوری", 43: "زخرف", 44: "دخان", 45: "جاثیه",
    46: "احقاف", 47: "محمد", 48: "فتح", 49: "حجرات", 50: "ق",
    51: "ذاریات", 52: "طور", 53: "نجم", 54: "قمر", 55: "رحمن",
    56: "واقعه", 57: "حدید", 58: "مجادله", 59: "حشر", 60: "ممتحنه",
    61: "صف", 62: "جمعه", 63: "منافقون", 64: "تغابن", 65: "طلاق",
    66: "تحریم", 67: "ملک", 68: "قلم", 69: "حاقه", 70: "معارج",
    71: "نوح", 72: "جن", 73: "مزمل", 74: "مدثر", 75: "قیامه",
    76: "انسان", 77: "مرسلات", 78: "نبأ", 79: "نازعات", 80: "عبس",
    81: "تکویر", 82: "انفطار", 83: "مطففین", 84: "انشقاق", 85: "بروج",
    86: "طارق", 87: "أعلی", 88: "غاشیه", 89: "فجر", 90: "بلد",
    91: "شمس", 92: "لیل", 93: "ضحی", 94: "شرح", 95: "تین",
    96: "علق", 97: "قدر", 98: "بینه", 99: "زلزله", 100: "عادیات",
    101: "قارعه", 102: "تکاثر", 103: "عصر", 104: "همزه", 105: "فیل",
    106: "قریش", 107: "ماعون", 108: "کوثر", 109: "کافرون", 110: "نصر",
    111: "مسد", 112: "إخلاص", 113: "فلق", 114: "ناس",
}


def get(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "ZekrApp/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode("utf-8"))


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)

    # Chapters meta (verses_count, name)
    chapters = get(f"{API}/chapters?language=en")["chapters"]
    by_num = {c["id"]: c for c in chapters}

    # Juz list with verse mapping
    juzs_raw = get(f"{API}/juzs")["juzs"]
    juz_meta = []
    for j in juzs_raw:
        juz_meta.append(
            {
                "juz": j["juz_number"],
                "verse_mapping": j.get("verse_mapping") or {},
            }
        )
    JUZ_OUT.write_text(
        json.dumps(juz_meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("wrote", JUZ_OUT, flush=True)

    surahs = []
    for n in range(1, 115):
        print("surah", n, flush=True)
        verses = []
        page = 1
        while True:
            data = get(
                f"{API}/quran/verses/uthmani?chapter_number={n}&page={page}&per_page=50"
            )
            batch = data.get("verses") or []
            if not batch:
                break
            for v in batch:
                verses.append(v["text_uthmani"])
            pag = data.get("pagination") or {}
            if not pag.get("next_page"):
                break
            page = pag["next_page"]
            time.sleep(0.05)
        ch = by_num[n]
        # Starting juz: from first verse key in juz verse_mapping
        start_juz = 1
        for j in juz_meta:
            vm = j["verse_mapping"]
            if str(n) in vm:
                start_juz = j["juz"]
                break
        surahs.append(
            {
                "id": f"quran_s{n}",
                "number": n,
                "name_en": ch.get("name_simple") or ch.get("name_arabic"),
                "name_fa": FA_NAMES.get(n, ch.get("name_arabic", "")),
                "ayah_count": len(verses),
                "juz": start_juz,
                "ayahs": verses,
            }
        )
        time.sleep(0.08)

    OUT.write_text(json.dumps(surahs, ensure_ascii=False), encoding="utf-8")
    print(
        f"done {len(surahs)} surahs, "
        f"{sum(s['ayah_count'] for s in surahs)} ayahs, "
        f"{OUT.stat().st_size/1e6:.1f} MB",
        flush=True,
    )


if __name__ == "__main__":
    main()
