"""Validate editable site geometry independently of the renderer."""
import json
from pathlib import Path
site = json.loads((Path(__file__).resolve().parents[1] / 'data/site.json').read_text())
assert site['units'] == 'metres'
ids = set()
for b in site['buildings']:
    assert b['id'] not in ids, b['id']
    ids.add(b['id'])
    assert all(b[k] > 0 for k in ('w', 'd', 'h')), b
    assert b['source'] and b['confidence'], b
for i, a in enumerate(site['buildings']):
    for b in site['buildings'][i+1:]:
        overlap_x = min(a['x']+a['w']/2,b['x']+b['w']/2)-max(a['x']-a['w']/2,b['x']-b['w']/2)
        overlap_z = min(a['z']+a['d']/2,b['z']+b['d']/2)-max(a['z']-a['d']/2,b['z']-b['d']/2)
        assert overlap_x <= 0.01 or overlap_z <= 0.01, (a['id'], b['id'], overlap_x, overlap_z)
scales = [a['pixels']/a['metres'] for a in site['anchors']]
assert max(scales)/min(scales) < 1.03, scales
print(f"Site checks: {len(ids)} unique positive building footprints; no building overlaps; two map axes agree within 3%.")
