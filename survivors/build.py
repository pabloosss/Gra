"""Build a self-contained offline HTML game; Python 3, no dependencies."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent
assets = json.loads((ROOT / 'assets.json').read_text(encoding='utf-8'))
source = (ROOT / 'game.template.html').read_text(encoding='utf-8')
assert source.count('__ASSETS__') == 1
(ROOT / 'index.html').write_text(source.replace('__ASSETS__', json.dumps(assets)), encoding='utf-8')
print('Built index.html:', (ROOT / 'index.html').stat().st_size, 'bytes')
