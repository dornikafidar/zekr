"""Build word-level sync packs for Ashura stream reciters via faster-whisper.

ponytail: offline ASR alignment — upgrade: licensed qari packs with manual timings.
"""
from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

from faster_whisper import WhisperModel

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "ziarat" / "sync" / "ashura"
CACHE = ROOT / "tool" / "_ashura_audio_cache"
OUT.mkdir(parents=True, exist_ok=True)
CACHE.mkdir(parents=True, exist_ok=True)

HARAKAT = re.compile(r"[\u064B-\u065F\u0670\u0640]")

# Keep in sync with lib/data/ziarat_places.dart kAshuraAudioSources + _ashuraText.
SOURCES = [
    ("ansariyan", "https://file.erfan.ir/files/sound/mafatih/998_128631_ziarat%20ashoora.mp3?seed=10"),
    ("fani", "https://file.erfan.ir/files/sound/mafatih/1499_11.mp3?seed=10"),
    ("farahmand", "https://file.erfan.ir/files/sound/mafatih/887_744_2.mp3?seed=10"),
    ("hadadian", "https://file.erfan.ir/files/sound/mafatih/19_ziarat_ashura_hadadian.mp3?seed=10"),
    ("samavati", "https://file.erfan.ir/files/sound/mafatih/21_ziarat_ashura_samavati.mp3?seed=10"),
    ("taheri", "https://file.erfan.ir/files/sound/mafatih/23_ziarat_ashura_taheri.mp3?seed=10"),
    ("karimi1", "https://file.erfan.ir/files/sound/mafatih/888_744_3.mp3?seed=10"),
    ("karimi2", "https://file.erfan.ir/files/sound/mafatih/886_744_1.mp3?seed=10"),
    ("arzi", "https://file.erfan.ir/files/sound/mafatih/889_744_16.mp3?seed=10"),
    ("motiee", "https://file.erfan.ir/files/sound/mafatih/893_744_22.mp3?seed=10"),
    ("mansuri", "https://file.erfan.ir/files/sound/mafatih/20_ziarat_ashura_mansuri.mp3?seed=10"),
    ("ahangaran", "https://file.erfan.ir/files/sound/mafatih/891_744_18.mp3?seed=10"),
    ("khalaj", "https://file.erfan.ir/files/sound/mafatih/892_744_19.mp3?seed=10"),
    ("zamanian", "https://file.erfan.ir/files/sound/mafatih/18_ziarat-ashoora-zamanian.mp3?seed=10"),
    ("gharib", "https://file.erfan.ir/files/sound/mafatih/1529_gharib.mp3?seed=10"),
]


def load_ashura_words() -> list[str]:
    dart = (ROOT / "lib" / "data" / "ziarat_places.dart").read_text(encoding="utf-8")
    i = dart.index("const _ashuraText")
    j = dart.index("const _warithText")
    parts = re.findall(r"'([^']*)'", dart[i:j])
    text = "".join(parts)
    return [p for p in re.split(r"\s+", text) if p.strip()]


def norm(w: str) -> str:
    w = HARAKAT.sub("", w)
    for a, b in (
        ("أ", "ا"),
        ("إ", "ا"),
        ("آ", "ا"),
        ("ٱ", "ا"),
        ("ة", "ه"),
        ("ى", "ي"),
        ("ؤ", "و"),
        ("ئ", "ي"),
    ):
        w = w.replace(a, b)
    return re.sub(r"[^\w\u0600-\u06FF]+", "", w, flags=re.UNICODE)


def download(sid: str, url: str) -> Path:
    path = CACHE / f"{sid}.mp3"
    if path.exists() and path.stat().st_size > 50_000:
        return path
    print("  download", sid)
    urllib.request.urlretrieve(url, path)
    return path


def transcribe_words(
    model: WhisperModel, mp3: Path, prompt: str
) -> list[tuple[str, int, int]]:
    segs, _ = model.transcribe(
        str(mp3),
        language="ar",
        word_timestamps=True,
        vad_filter=False,
        beam_size=3,
        best_of=3,
        condition_on_previous_text=True,
        initial_prompt=prompt[:800],
    )
    out: list[tuple[str, int, int]] = []
    for seg in segs:
        if not seg.words:
            continue
        for w in seg.words:
            t = (w.word or "").strip()
            if not t:
                continue
            start = int(round((w.start or 0) * 1000))
            end = int(round((w.end or (w.start or 0) + 0.2) * 1000))
            if end <= start:
                end = start + 120
            out.append((t, start, end))
    return out


def align(display: list[str], asr: list[tuple[str, int, int]]) -> list[list[int]]:
    """Sequence-match display words onto ASR tokens, then fill gaps."""
    from difflib import SequenceMatcher

    a = [norm(w) for w in display]
    b = [norm(w) for w, _, _ in asr]
    segments: list[list[int]] = [[i, -1, -1] for i in range(len(display))]
    if not b:
        return []

    sm = SequenceMatcher(a=a, b=b, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for di, aj in zip(range(i1, i2), range(j1, j2)):
                segments[di][1] = asr[aj][1]
                segments[di][2] = asr[aj][2]
        elif tag == "replace" and (i2 - i1) > 0 and (j2 - j1) > 0:
            # Distribute ASR span across display words in this block.
            span_start = asr[j1][1]
            span_end = asr[j2 - 1][2]
            n = i2 - i1
            for k, di in enumerate(range(i1, i2)):
                s = int(span_start + (span_end - span_start) * k / n)
                e = int(span_start + (span_end - span_start) * (k + 1) / n)
                segments[di][1] = s
                segments[di][2] = max(s + 60, e)

    known = [i for i, s in enumerate(segments) if s[1] >= 0]
    if not known:
        return []
    for i, s in enumerate(segments):
        if s[1] >= 0:
            continue
        prev = next((x for x in reversed(known) if x < i), None)
        nxt = next((x for x in known if x > i), None)
        if prev is not None and nxt is not None:
            p, n = segments[prev], segments[nxt]
            ratio = (i - prev) / (nxt - prev)
            start = int(p[1] + (n[1] - p[1]) * ratio)
            end = int(p[2] + (n[2] - p[2]) * ratio)
            s[1], s[2] = start, max(start + 80, end)
        elif prev is not None:
            s[1] = segments[prev][2]
            s[2] = s[1] + 180
        elif nxt is not None:
            s[2] = segments[nxt][1]
            s[1] = max(0, s[2] - 180)

    t = 0
    for s in segments:
        if s[1] < t:
            s[1] = t
        if s[2] <= s[1]:
            s[2] = s[1] + 90
        t = s[2]
    return segments


def main() -> None:
    words = load_ashura_words()
    print("display words", len(words))
    print("loading whisper model (small/int8)…")
    model = WhisperModel("small", device="cpu", compute_type="int8")

    import sys

    args = [a for a in sys.argv[1:] if a != "--force"]
    force = "--force" in sys.argv[1:]
    only = set(args) if args else None

    for sid, url in SOURCES:
        if only and sid not in only:
            continue
        out_path = OUT / f"{sid}.json"
        if out_path.exists() and not force:
            print("skip existing", sid)
            continue
        print("align", sid)
        mp3 = download(sid, url)
        prompt = " ".join(words[:120])
        asr = transcribe_words(model, mp3, prompt)
        print("  asr tokens", len(asr))
        segs = align(words, asr)
        matched = sum(1 for s in segs if s[1] >= 0)
        print(
            "  matched",
            matched,
            "/",
            len(words),
            "span_ms",
            segs[0][1] if segs else None,
            "->",
            segs[-1][2] if segs else None,
        )
        if matched < max(20, len(words) // 5):
            print("  SKIP weak alignment")
            continue
        payload = {
            "id": sid,
            "ziaratId": "ashura",
            "words": words,
            "segments": segs,
            "engine": "faster-whisper-small-seq",
        }
        out_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print("  ->", out_path)


if __name__ == "__main__":
    main()
