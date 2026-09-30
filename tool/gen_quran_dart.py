# -*- coding: utf-8 -*-
import json
from pathlib import Path

raw = json.loads(Path("assets/quran/surahs.json").read_text(encoding="utf-8"))
lines = [
    "// Generated — do not edit by hand.",
    "const quranSurahsRaw = <Map<String, Object>>[",
]
for s in raw:
    lines.append("  {")
    lines.append(f"    'id': '{s['id']}',")
    lines.append(f"    'number': {s['number']},")
    lines.append(f"    'name_en': r'''{s['name_en']}''',")
    lines.append("    'ayahs': <String>[")
    for a in s["ayahs"]:
        # raw triple-quoted strings
        safe = a.replace('"""', r"\"\"\"")
        lines.append(f'      r"""{safe}""",')
    lines.append("    ],")
    lines.append("  },")
lines.append("];")
path = Path("lib/data/quran_surahs_data.dart")
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("wrote", path, "bytes", path.stat().st_size)
