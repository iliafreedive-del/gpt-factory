# Alaska Factory — exterior atlas

Godot **4.4.1**, GL Compatibility, Web. **BUILD 1.1.0 / MAP 1.1.0**.
One world unit = one metre. Exterior only. Map-derived anchors and provisional estimates are kept separate; this is not a surveyed digital twin.

## Develop

Open `project.godot` in Godot 4.4.1, or run:

```sh
GODOT_BIN=godot tools/validate.sh
mkdir -p build
godot --headless --path . --export-release Web build/index.html
python3 -m http.server 8765 --directory build
```

Export needs the matching official `4.4.1.stable` Web templates. Cloud setup has the verified engine at `/workspace/.godot-setup/bin/godot`, with writable XDG paths; the global engine is a different version. No API keys required. Use existing checkout, no extra worktree needed.

Mouse wheel zooms; right drag orbits; middle drag/WASD pans; L toggles labels; click selects a footprint; F focuses selection; E toggles temporary footprint sketching (arrow keys move 1 m, reload resets); 1–4 switch whole-site/LGC/yard/workshop views; 5 opens the traced plan (red fences / green road axes); 6 opens the eastern workshop. Buttons offer the same views. BUILD/MAP remain at the top-right. The scale bar adjusts to camera height. Coordinate orientation is supplied-map-up, not verified north.

## Data and evidence

- `data/site.json`: footprints, sources/confidence, roads, zones and boundaries.
- `scripts/world/industrial_kit.gd`: batched industrial building/prop/material kit.
- `scripts/main.gd`: site assembly, camera, picking and anchored UI.
- [Measurements and remaining survey questions](docs/MEASUREMENTS.md).
- [Visual acceptance and evidence](docs/ACCEPTANCE.md).
- `handoff/source/`: complete supplied handoff, original Excel and all 18 PNGs; excluded from game export using `.gdignore`.

Browser capture: with Chromium and Playwright available, serve the exported build and run `node tools/capture.cjs`. It checks the actual Web build identity and browser errors, then captures six camera presets, labels and an 800×600 viewport. `TARGET_URL` can point to the deployed site; `EVIDENCE_DIR` selects a separate capture folder. CI validates import/runtime and export logs even when Godot exits zero.

Published address: https://iliafreedive-del.github.io/gpt-factory/ (publication/version must be verified separately).
