import re
from pathlib import Path
t = Path('lib/data/quran_surahs_data.dart').read_text(encoding='utf-8')
blocks = re.findall(
    r"'number':\s*(\d+).*?'ayahs':\s*<String>\[\s*r\"\"\"(.*?)\"\"\"",
    t,
    re.S,
)
out = []
for num, first in blocks:
    has = 'بسم' in first or 'بِسْمِ' in first
    out.append(f"{num} {'HAS' if has else 'NO '} {first[:50]}")
Path('_bis.txt').write_text('\n'.join(out), encoding='utf-8')
print(len(blocks))
