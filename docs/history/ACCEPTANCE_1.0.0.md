# Exterior release 1.0.0 — acceptance record

**CHECKED:** Godot 4.4.1 import and 30-frame scene startup; strict stdout/stderr error scanning; Web release export; actual Chromium WebGL 2 rendering; four camera presets; geometry/scale consistency checks. **UNSURVEYED:** placement, heights, property outline and clearances beyond the two interpreted map anchors. **PUBLICATION:** independent of local validation; public Pages/API access was blocked by the cloud proxy (HTTP 403). No deployed-version verification is claimed.

## Visual evidence and comparison

| Scope | Actual game screenshot | Comparison against supplied sources |
|---|---|---|
| Entire grounds | [Full site](evidence/full-site.png) | Whole map fits; coherent road surfaces, perimeter openings, railway, tree buffer and east black shop replace the old six-box layout. Source plan is preliminary, not a surveyed twin. |
| LGC / new workshop | [Oblique close-up](evidence/lgc-construction.png) | Two metal-clad gables and red third-party neighbor follow photograph adjacency. The new shop has an open dark portal, scaffold and stored panels. No interior is modelled. |
| Logistics yard | [Zinc / loading yard](evidence/loading-yard.png) | Separate welded-frame rows, trailer groups, gantry rails, open twin-girder crane, container corridor and pallets. Counts are illustrative, not inventory/capacity assertions. |
| Other workshops | [Workshop side](evidence/workshops.png) | Distinct warm offices, annexes, awning, sandblast/paint and assembly footprints, corrugation, roof seams/skylights, personnel/loading doors, gutters and aprons. |
| Names / UI | [Labels](evidence/labels.png), [800×600](evidence/compact.png) | Anchored BUILD/MAP, estimated-plan warning, selection data, scale bar, orbit/pan/zoom and camera presets. Main names only at full-site zoom; smaller labels require closer view. |

The two [art targets](../handoff/source/03_REFERENCES/image(9).png) show compact, densely dressed, partly open industrial dioramas. This exterior adopts a restrained blue/steel/ochre palette, visible roof structure, detailed representative trailers, concrete/asphalt separation and purposeful storage arrangements. Its geographically larger open yards are deliberately less dense. It does **not** reproduce the targets' indoor machinery, cutaway walls, bespoke hand-painted assets or baked ambient occlusion, and exact artistic parity is not asserted. Roof seam shadow aliasing remains visible on the software renderer at some distances. This is a substantial coherent exterior release, not owner sign-off on final visual or surveying accuracy.

## Repeatable verification

`GODOT_BIN=/workspace/.godot-setup/bin/godot tools/validate.sh` runs the actual engine and independent data checks: 18 unique positive building footprints, no overlapping building envelopes, two perpendicular warehouse scales within 3%. It does not count a zero-test run as a test suite. There is no supplied unit-test suite.

`node tools/capture.cjs` opens the exported game, waits for its runtime BUILD/MAP identity, switches camera views and captures actual pixels. It also exercises actual ray picking and a reversible one-metre edit. Chromium uses software WebGL in this cloud environment; no hardware performance guarantee is implied. `evidence/web-artifacts.json` records the exact exported artifact hashes.

CI scans import/runtime/export logs for `SCRIPT ERROR`, `Parse Error`, `Failed to load script` and `ERROR:` even on exit zero. GitHub green status is not used as artistic acceptance.

See [MEASUREMENTS.md](MEASUREMENTS.md) for assumptions and field questions, and [SOURCE_REVIEW.md](SOURCE_REVIEW.md) for all supplied materials. Interiors are deferred. Local E/arrow sketch changes reset on reload; permanent map corrections belong in `data/site.json`.
