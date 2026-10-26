# ALASKA FACTORY — CODEX MASTER TASK (EXTERIOR PHASE)

## Read this first
You are the accountable Godot 4 / 3D environment art / QA lead. **Finish the exterior phase as a whole**, not micro-edit a prototype. Repo: https://github.com/iliafreedive-del/gpt-factory ; Web: https://iliafreedive-del.github.io/gpt-factory/ . User also provides an archive named **Alaska_Factory_Codex_Handoff.zip** containing satellite/2GIS screenshots, building measurements, Excel site map, exterior photos and two target screenshots. You MUST inspect these assets. If the ZIP is not in this repository, ask the user to attach it to the Codex Cloud task. Do not pretend to have seen the archive.

## Required deliverable
A credible, visually polished, stylized isometric factory-simulation exterior matching the **quality of the two attached visual targets**, while matching the **actual Alaska trailer factory's** layout from 2GIS and Excel. **1 Godot unit = 1 real metre**. Camera zoom is visual only. The user wants this factory digital twin eventually to calculate site capacity, stock, logistics and movement, so geometry must be physically plausible. If site dimensions were inferred from map annotations rather than surveyed, label them PRELIMINARY and store uncertainty, never claim survey-grade accuracy.

## Complete outdoor scope
- Whole grounds, meaningful yard surfaces/roads/turning areas, footprint and entrance alignment, external property context, fences/gates, rail line, gantry crane track, treeline.
- All named roofs/buildings with distinguishable footprint/silhouette and reference-photo exteriors: active LGC (laser/bending shop), adjacent **unfinished workshop under construction**, red components warehouse, shop 1 and 2, paint, sandblast, assembly zones 1/2, canvas awnings, office 1/2, black welding/tube shop, garages/spare-parts and minor warehouses, and marked third-party building.
- Proper production visual language: realistic-looking stylized 3D corrugated sheet metal walls, roof ridges/slopes, structural framing, windows/skylights, large garage doors, personnel doors, docks, wall variations, storage fences. Avoid uniform boxes.
- Non-random outdoor objects: trailer bodies and frames at correct scale, metal stock, pallets, crates, containers, forklifts, trucks and planned parking/staging. Real logistics zones from Excel (awaiting sandblast/paint, zinc galvanizing, ready trailers, dealer shipping, repair/scrap, LGC to welding) must have coherent positions.
- Fixed visible **BUILD x.y** and **MAP x.y** in top-right using UI anchors (not hard-coded pixels). Readable names and zoom controls; whole area fits at first load. Scale bar and selectable footprint dimensions.
- Do NOT work on interiors in this phase.

## Workflow and acceptance (not optional)
1. Inspect all existing code, logs and current live site, plus every supplied real-world reference.
2. Rebuild exterior geometry coherently using data-defined site coordinates and reusable industrial assets. Use actual 2GIS length annotations to calibrate proportional geometry; compare multiple known anchors. Annotate ALL unverified estimates.
3. Run Godot 4.4.1 headless import and runtime; CI must fail on `SCRIPT ERROR`, `Parse Error`, `Failed to load script`, even if Godot process exits 0. Keep GL Compatibility / Web export templates.
4. Build Web, **open it in a browser**, inspect screenshots from several camera positions: full-site, LGC + new workshop, yards, other workshops. Compare each visually with reference quality. Correct material/roof/placement/label/viewport problems.
5. GitHub Actions success alone IS NOT acceptance. Deliver **real screenshot evidence** and browser link, commit/PR and build number; say which measurements remain provisional. If visual screenshot inspection cannot be performed, explicitly disclose that and do not claim final artistic quality is confirmed.
6. Do not halt after one container, a handful of boxes, or three decorative additions. Make major coherent iterations and test end-to-end. Don't ask user repeatedly to type “делай”; only request truly necessary missing inputs/permissions.
7. Preserve working web functionality. Ensure updated BUILD appears in the deployed browser view; no silent stale artifacts.

## Critical historical issues
Prior assistant shipped numerous boxy micro-updates as finished. Github Pages showed green despite **script parse errors in logs** (e.g. `scripts/main.gd` line 91). Strict log checks were subsequently added. Last known published/tested revision was commit **5e0b4caea89983bb18c5f97ec3f4cfaa03692222** (`BUILD 004`); it is NOT accepted as visually complete. User has explicit style benchmarks, and the current look is far below them.

## Ground-truth asset index
- User-supplied Excel: `схема завода.xlsx`, functional labels and flows, NOT a measured CAD survey.
- User-supplied 2GIS/satellite screenshots with scale/perimeter annotations. The attached handoff ZIP contains originals.
- Exterior photo: existing LGC on left, unfinished workshop in center, third-party building right.
- Two stylized 3D industrial/isometric game images: desired *art direction* (not geographic shape).
- Additional LGC photo album: https://disk.yandex.ru/a/mq-FWU53Ln0kFw (may be inaccessible; don't claim retrieved).

## Final report format
Status DONE / CHECKED / UNSURVEYED; version label and commit SHA; working web URL; screenshots from actual game; specific visual quality differences closed; remaining survey questions; interiors deliberately deferred.

## Strong instruction
**Do the development work, do not merely rewrite this prompt or declare future plans.** If the user supplied the archive to Codex, unpack and inspect. If not, halt only for access to those essential real-world references.