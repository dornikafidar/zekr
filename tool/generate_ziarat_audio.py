"""Generate Arabic ziarat audio + word timings via edge-tts WordBoundary.

ponytail: neural TTS stand-in until licensed human recitations are bundled.
Upgrade: replace assets/audio/ziarat/*.mp3 with real qari + real timings.
"""
from __future__ import annotations

import asyncio
import json
import re
from pathlib import Path

import edge_tts

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "ziarat"
VOICE = "ar-SA-HamedNeural"

# Keep in sync with lib/data/ziarat_places.dart texts.
ZIARAT = {
    "ashura": {
        "title": "زیارت عاشورا",
        "text": (
            "السَّلَامُ عَلَيْكَ يَا أَبَا عَبْدِ اللَّهِ، السَّلَامُ عَلَيْكَ يَا ابْنَ رَسُولِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ أَمِيرِ الْمُؤْمِنِينَ وَابْنَ سَيِّدِ الْوَصِيِّينَ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ فَاطِمَةَ سَيِّدَةِ نِسَاءِ الْعَالَمِينَ، "
            "السَّلَامُ عَلَيْكَ يَا ثَارَ اللَّهِ وَابْنَ ثَارِهِ وَالْوِتْرَ الْمَوْتُورَ، "
            "السَّلَامُ عَلَيْكَ وَعَلَى الْأَرْوَاحِ الَّتِي حَلَّتْ بِفِنَائِكَ، "
            "عَلَيْكُمْ مِنِّي جَمِيعاً سَلَامُ اللَّهِ أَبَداً مَا بَقِيتُ وَبَقِيَ اللَّيْلُ وَالنَّهَارُ. "
            "يَا أَبَا عَبْدِ اللَّهِ، لَقَدْ عَظُمَتِ الرَّزِيَّةُ وَجَلَّتْ وَعَظُمَتِ الْمُصِيبَةُ بِكَ عَلَيْنَا "
            "وَعَلَى جَمِيعِ أَهْلِ الْإِسْلَامِ، وَجَلَّتْ وَعَظُمَتْ مُصِيبَتُكَ فِي السَّمَاوَاتِ عَلَى جَمِيعِ أَهْلِ السَّمَاوَاتِ. "
            "فَلَعَنَ اللَّهُ أُمَّةً أَسَّسَتْ أَسَاسَ الظُّلْمِ وَالْجَوْرِ عَلَيْكُمْ أَهْلَ الْبَيْتِ، "
            "وَلَعَنَ اللَّهُ أُمَّةً دَفَعَتْكُمْ عَنْ مَقَامِكُمْ وَأَزَالَتْكُمْ عَنْ مَرَاتِبِكُمُ الَّتِي رَتَّبَكُمُ اللَّهُ فِيهَا."
        ),
    },
    "warith": {
        "title": "زیارت وارث",
        "text": (
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ آدَمَ صَفْوَةِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ نُوحٍ نَبِيِّ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ إِبْرَاهِيمَ خَلِيلِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ مُوسَى كَلِيمِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ عِيسَى رُوحِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ مُحَمَّدٍ حَبِيبِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَارِثَ أَمِيرِ الْمُؤْمِنِينَ عَلِيٍّ وَلِيِّ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ مُحَمَّدٍ الْمُصْطَفَى، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ عَلِيٍّ الْمُرْتَضَى، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ فَاطِمَةَ الزَّهْرَاءِ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ خَدِيجَةَ الْكُبْرَى، "
            "السَّلَامُ عَلَيْكَ يَا ثَارَ اللَّهِ وَابْنَ ثَارِهِ."
        ),
    },
    "aminullah": {
        "title": "زیارت امین‌الله",
        "text": (
            "السَّلَامُ عَلَيْكَ يَا أَمِينَ اللَّهِ فِي أَرْضِهِ، وَحُجَّتَهُ عَلَى عِبَادِهِ. "
            "السَّلَامُ عَلَيْكَ يَا أَمِيرَ الْمُؤْمِنِينَ. "
            "أَشْهَدُ أَنَّكَ جَاهَدْتَ فِي اللَّهِ حَقَّ جِهَادِهِ، وَعَمِلْتَ بِكِتَابِهِ، "
            "وَاتَّبَعْتَ سُنَنَ نَبِيِّهِ صَلَّى اللَّهُ عَلَيْهِ وَآلِهِ، "
            "حَتَّى دَعَاكَ اللَّهُ إِلَى جِوَارِهِ فَقَبَضَكَ إِلَيْهِ بِاخْتِيَارِهِ، "
            "وَأَلْزَمَ أَعْدَاءَكَ الْحُجَّةَ مَعَ مَا لَكَ مِنَ الْحُجَجِ الْبَالِغَةِ عَلَى جَمِيعِ خَلْقِهِ. "
            "اللَّهُمَّ فَاجْعَلْ نَفْسِي مُطْمَئِنَّةً بِقَدَرِكَ، رَاضِيَةً بِقَضَائِكَ، "
            "مُولَعَةً بِذِكْرِكَ وَدُعَائِكَ، مُحِبَّةً لِصَفْوَةِ أَوْلِيَائِكَ."
        ),
    },
    "imam_reza": {
        "title": "زیارت امام رضا",
        "text": (
            "أَشْهَدُ أَنَّكَ الْإِمَامُ الْهَادِي، وَالْوَلِيُّ الْمُرْشِدُ. "
            "السَّلَامُ عَلَيْكَ يَا عَلِيَّ بْنَ مُوسَى الرِّضَا، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ رَسُولِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ أَمِيرِ الْمُؤْمِنِينَ، "
            "السَّلَامُ عَلَيْكَ يَا ابْنَ فَاطِمَةَ الزَّهْرَاءِ، "
            "السَّلَامُ عَلَيْكَ يَا حُجَّةَ اللَّهِ عَلَى خَلْقِهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَلِيَّ اللَّهِ، "
            "أَشْهَدُ أَنَّكَ قَدْ أَقَمْتَ الصَّلَاةَ وَآتَيْتَ الزَّكَاةَ "
            "وَأَمَرْتَ بِالْمَعْرُوفِ وَنَهَيْتَ عَنِ الْمُنْكَرِ، "
            "وَعَبَدْتَ اللَّهَ مُخْلِصاً حَتَّى أَتَاكَ الْيَقِينُ."
        ),
    },
    "kazemayn_z": {
        "title": "زیارت کاظمین",
        "text": (
            "السَّلَامُ عَلَيْكُمَا يَا حُجَّتَيِ اللَّهِ، "
            "السَّلَامُ عَلَيْكُمَا يَا بَابَيِ اللَّهِ، "
            "السَّلَامُ عَلَيْكُمَا يَا نُورَيِ اللَّهِ فِي ظُلُمَاتِ الْأَرْضِ، "
            "السَّلَامُ عَلَيْكَ يَا مُوسَى بْنَ جَعْفَرٍ، "
            "السَّلَامُ عَلَيْكَ يَا مَظْلُومَ الْمَحْبُوسِ، "
            "السَّلَامُ عَلَيْكَ يَا مُحَمَّدَ بْنَ عَلِيٍّ، "
            "السَّلَامُ عَلَيْكَ يَا جَوَادَ الْأَئِمَّةِ، "
            "أَشْهَدُ أَنَّكُمَا أَقَمْتُمَا الصَّلَاةَ وَآتَيْتُمَا الزَّكَاةَ "
            "وَأَمَرْتُمَا بِالْمَعْرُوفِ وَنَهَيْتُمَا عَنِ الْمُنْكَرِ، "
            "وَعَبَدْتُمَا اللَّهَ مُخْلِصَيْنِ حَتَّى أَتَاكُمَا الْيَقِينُ."
        ),
    },
    "masumeh": {
        "title": "زیارت حضرت معصومه",
        "text": (
            "يَا فَاطِمَةُ ٱشْفَعِي لِي فِي الْجَنَّةِ، "
            "فَإِنَّ لَكِ عِنْدَ اللَّهِ شَأْناً مِنَ الشَّأْنِ. "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ رَسُولِ اللَّهِ، "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ فَاطِمَةَ وَخَدِيجَةَ، "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ أَمِيرِ الْمُؤْمِنِينَ، "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ الْحَسَنِ وَالْحُسَيْنِ، "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ وَلِيِّ اللَّهِ، "
            "السَّلَامُ عَلَيْكِ يَا أُخْتَ وَلِيِّ اللَّهِ، "
            "السَّلَامُ عَلَيْكِ يَا عَمَّةَ وَلِيِّ اللَّهِ، "
            "السَّلَامُ عَلَيْكِ يَا بِنْتَ مُوسَى بْنِ جَعْفَرٍ، "
            "وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ."
        ),
    },
    "shahcheragh": {
        "title": "زیارت شاه‌چراغ",
        "text": (
            "السَّلَامُ عَلَيْكَ يَا بْنَ رَسُولِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا بْنَ أَمِيرِ الْمُؤْمِنِينَ، "
            "السَّلَامُ عَلَيْكَ يَا بْنَ فَاطِمَةَ الزَّهْرَاءِ، "
            "السَّلَامُ عَلَيْكَ يَا بْنَ خَدِيجَةَ الْكُبْرَى، "
            "السَّلَامُ عَلَيْكَ يَا أَحْمَدَ بْنَ مُوسَى، "
            "السَّلَامُ عَلَيْكَ يَا شَاهْچِرَاغْ، "
            "أَشْهَدُ أَنَّكَ قَدْ أَقَمْتَ الصَّلَاةَ وَآتَيْتَ الزَّكَاةَ "
            "وَأَمَرْتَ بِالْمَعْرُوفِ وَنَهَيْتَ عَنِ الْمُنْكَرِ، "
            "وَجَاهَدْتَ فِي اللَّهِ حَقَّ جِهَادِهِ."
        ),
    },
    "alaeddin": {
        "title": "زیارت سید علاءالدین",
        "text": (
            "السَّلَامُ عَلَيْكَ يَا بْنَ رَسُولِ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا وَلِيَّ اللَّهِ، "
            "السَّلَامُ عَلَيْكَ يَا سَيِّدَ عَلَاءَ الدِّينِ حُسَيْن، "
            "السَّلَامُ عَلَيْكَ يَا بْنَ أَمِيرِ الْمُؤْمِنِينَ، "
            "السَّلَامُ عَلَيْكَ يَا بْنَ فَاطِمَةَ الزَّهْرَاءِ، "
            "أَشْهَدُ أَنَّكَ قَدْ أَقَمْتَ الصَّلَاةَ وَآتَيْتَ الزَّكَاةَ "
            "وَأَمَرْتَ بِالْمَعْرُوفِ وَنَهَيْتَ عَنِ الْمُنْكَرِ، "
            "وَعَبَدْتَ اللَّهَ مُخْلِصاً حَتَّى أَتَاكَ الْيَقِينُ."
        ),
    },
}


def split_words(text: str) -> list[str]:
    parts = re.findall(r"\S+", text.replace("،", " ، ").replace(".", " . "))
    return [p for p in parts if p not in ("،", ".")]


async def synthesize(zid: str, title: str, text: str) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    mp3_path = OUT / f"{zid}.mp3"
    words_expected = split_words(text)
    communicate = edge_tts.Communicate(text, VOICE)
    audio = bytearray()
    boundaries: list[tuple[str, int]] = []  # (word, offset_ms)
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            audio.extend(chunk["data"])
        elif chunk["type"] == "WordBoundary":
            # offset is in 100-nanosecond units
            offset_ms = int(chunk["offset"] / 10_000)
            boundaries.append((chunk["text"], offset_ms))

    mp3_path.write_bytes(audio)

    # Map boundaries onto our display words; fall back to even split.
    words = words_expected
    segments: list[list[int]] = []
    if len(boundaries) >= max(3, len(words) // 2):
        # Use TTS boundaries; align by index when counts match, else by order.
        n = min(len(words), len(boundaries))
        for i in range(n):
            start = boundaries[i][1]
            end = boundaries[i + 1][1] if i + 1 < len(boundaries) else start + 400
            if end <= start:
                end = start + 300
            segments.append([i, start, end])
        # Extend last end a bit for trailing audio.
        if segments:
            segments[-1][2] = max(segments[-1][2], boundaries[-1][1] + 500)
        words = words[:n]
    else:
        # Char-weighted approximate timings from file duration estimate (~130ms/char).
        total_chars = sum(max(1, len(w)) for w in words) or 1
        # Rough duration from audio size (64kbps-ish) or char heuristic.
        dur_ms = max(3000, int(total_chars * 140))
        t = 0
        for i, w in enumerate(words):
            span = max(220, int(dur_ms * (len(w) / total_chars)))
            segments.append([i, t, t + span])
            t += span

    # Fit WordBoundary clock to real mp3 length (edge-tts offsets often ~2× long).
    try:
        import subprocess

        dur_s = float(
            subprocess.check_output(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-show_entries",
                    "format=duration",
                    "-of",
                    "default=noprint_wrappers=1:nokey=1",
                    str(mp3_path),
                ],
                text=True,
            ).strip()
        )
        dur_ms = int(dur_s * 1000)
        if segments and segments[-1][2] > 0 and dur_ms > 0:
            ratio = dur_ms / segments[-1][2]
            if abs(ratio - 1.0) >= 0.04:
                for s in segments:
                    s[1] = int(round(s[1] * ratio))
                    s[2] = int(round(s[2] * ratio))
                segments[-1][2] = dur_ms
    except Exception:
        pass

    return {
        "id": zid,
        "title": title,
        "file": f"{zid}.mp3",
        "voice": VOICE,
        "words": words,
        "segments": segments,
    }


async def main() -> None:
    catalog = {"voice": VOICE, "items": {}}
    for zid, meta in ZIARAT.items():
        print("generating", zid, "...")
        item = await synthesize(zid, meta["title"], meta["text"])
        catalog["items"][zid] = item
        print(" ", zid, "words", len(item["words"]), "segs", len(item["segments"]))
    (OUT / "timings.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print("done ->", OUT)


if __name__ == "__main__":
    asyncio.run(main())
