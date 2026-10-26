# CODEX MASTER TASK — ALASKA FACTORY EXTERIOR, ACCEPTANCE-DRIVEN

Repository: https://github.com/iliafreedive-del/gpt-factory
Branch: main. Existing game: https://iliafreedive-del.github.io/gpt-factory/

## ROLE AND MISSION
You are the accountable technical lead, Godot 4 GDScript developer, environment artist, and QA engineer. Finish ONE WHOLE PHASE: a visually polished, spatially coherent 3D EXTERIOR of the real Alaska trailer factory, suitable as the foundation of a 1:1 logistics digital twin. The owner is frustrated with micro commits dressed up as progress. Execute a substantial end-to-end development cycle, not an explanatory conversation.

## FIRST ACTIONS (MANDATORY)
1. Clone/open the repo and inspect all source files, GitHub Actions workflows, commit history, and current website. Inspect this instruction file and all `handoff/` references if present; if not, ask for the ZIP archive supplied to the user (it includes satellite/2GIS screenshots, Excel, photographs, and previous browser screenshots). Read `02_CONTEXT` and `04_MEASUREMENTS` there.
2. Identify what the user sees today and why the current appearance is inadequate. Inspect old error history: web export succeeded despite `SCRIPT ERROR` GDScript parse errors. Preserve strict CI log validation.
3. Compare supplied real-site schematic against satellite screenshots (2GIS) and the two stylized factory game visual references. Extract a consistent 2D site plan with known measurement anchors. **Never describe approximate placements as survey-accurate**.
4. Implement a visually coherent scene, then ACTUALLY RUN Godot headless import and runtime, export Web, load the deployed page or locally serve the Web build in a browser and review real screenshots. Iterate until acceptable. Do not claim visual verification if no browser screenshot inspection was performed.

## WORK SCOPE — FINISH EXTERIOR ONLY
- Terrain footprint, perimeter fence, entry gates, internal roads and maneuvering surfaces, open storage, rail line, gantry-crane rails, vegetation buffers and adjacent context.
- ALL exterior buildings with geographically consistent footprints and relative positioning: LGC (laser/bending shop), new workshop under construction, red components warehouse, workshop 1, workshop 2, sandblast, paint, assembly 1/2, awnings, offices, spare-parts/axis/ramp storage, black shop for zinc-bound frames, third-party structure.
- True distinguishing industrial exterior detail: corrugated metal cladding, usable dimensional roofs/ridges/overhangs, garage doors, smaller personnel doors, windows/rooflights, gutters, framework, concrete aprons, loading lanes, asphalt/gravel transitions, fences with openings and gateposts. New workshop must appear **under construction**, visibly unfinished.
- High-quality *purposefully arranged* factory assets: accurate-size trailers and frames (not just blocks), stacks of steel, containers, crates, pallets, loading docks, simple forklifts/trucks, trailer parking patterns, concrete strips, stacks awaiting galvanizing. Aim for professional stylized/low-poly industrial simulation quality close to user images, not hyperrealism.
- Labels on request: main building names should be legible with contextual zoom, not overlapping densely; filters/toggles can hide small labels.
- No indoor machine-detail, worker animation, complex manufacturing simulation at this stage.

## EXACT SCALE AND SURVEY CONFIDENCE
1 Godot unit = 1 real-world metre; camera zoom only changes view, not dimensions. Store source and confidence for each measured anchor, estimated building footprint, and corridor width. Use the 2GIS length annotations as calibrated anchors; scale positions proportionally and document derivation/uncertainty. If screenshot labels or scale are ambiguous, flag them and keep estimates marked **PRELIMINARY**. Do NOT fabricate a supposedly accurate perimeter or storage capacities. All coordinates should be centrally editable in a map data file, not scattered across hundreds of function calls. Compute all building footprints from a shared coordinate system, allow later surveying corrections without rewriting scene code.

## ARCHITECTURE
- Use Godot 4.4.1 compatible with Web export / GL Compatibility and GDScript. Scene data as JSON, Resource or CSV for building footprints (non-rectangular polygons where needed), roads, zones, labels, metrics, and asset catalog.
- Modular separate building/procedural geometry, materials, props, camera, UI and mapping/data.
- Orthographic/isometric camera: orbit, zoom-to-cursor or zoom-to-selection, pan. Startup view fits full site and is oriented consistently with map. Hotkeys/mouse listed in UI.
- Add persistent readable `BUILD vX.Y.Z` and `MAP vX.Y.Z` in top-right at EVERY screen size using proper anchors, plus clear PRELIMINARY SCALE / unverified measurement legend. Don't hard-code x=1310 pixels.
- Expose selected building name, measured/estimated footprint and confidence. Do not break previously working selection/editor unless it blocks core quality.
- Add a basic scale bar (e.g. 10/25/50 m based on orthographic camera), direction north indicator if orientation known, otherwise clearly state orientation unverified.

## QUALITY GATES — NONNEGOTIABLE
1. Full repository test: `godot --headless --editor --import --quit` and scene startup. Capture stdout + stderr and FAIL CI if any `SCRIPT ERROR`, `Parse Error`, `Failed to load script`, or runtime-breaking `ERROR` entries appear even when process exit status is 0.
2. Export Web with matching Godot export templates; check `index.html`, `.wasm`, `.pck`, `.js` output and GitHub Pages success.
3. Launch the actual Web output and produce **screenshots**: full-site aerial, oblique/three-quarter close-up of LGC and new workshop, road/loading yard, workshop1/workshop2 side. Confirm latest BUILD label visible. Visually compare to the reference screenshots; correct overlapping roof parts, hidden elements, camera framing, silhouette quality, naming, and scale discrepancies. Screenshots constitute evidence; code-only success is NOT visual acceptance.
4. A scene with uniform boxes, flat untextured planes, fake-looking primitive trailers, or largely invisible changes is NOT accepted. Iterate until the exterior is materially better across the WHOLE FACTORY, with cohesive materials, proportions and recognizable industrial context.
5. Keep GitHub Pages functional. Prefer feature branch + PR if extensive rewrite; merge/publish when validated. If cannot publish because of permissions, give exact blocker with commit SHA and no claim of deployment.
6. Deliver a one-page comparison: reference / target vs screenshots of deployed game, exact build/commit/hash, footprint-assumption table and remaining measurement unknowns. Explicitly separate 'done', 'tested', 'needs field verification'.

## USER-SPECIFIC EXPECTATIONS
The user wants to shut down their laptop while cloud development happens. Do not request a local Godot installation. Do not ask repeatedly for permission after the instruction to proceed; use the available GitHub and Codex cloud environment to perform the work now. Avoid tiny, performative updates. Intermediate status only for actual blockers; final report only after a serious coherent delivered iteration. User will provide INTERIOR shop photographs only once EXTERIOR is convincingly finished.

## SOURCE-OF-TRUTH PRIORITY
1. User-supplied 2GIS and satellite screenshots, measured annotations, Excel plan and real photographs for site-specific spatial facts.
2. Existing repo and earlier implementation as reusable code, NOT as verified geometry.
3. Two stylized isometric factory screenshots as **quality/style targets**, NOT as geographic source.
4. Author estimates only for measurements missing, clearly flagged and adjustable.

## REQUIRED FINISH
Do not tell the user you 'will work later' or that a build is done when it is not. Execute while the current Codex task is active. Report with GitHub commit/PR, successful validation, URL, actual screenshots, and concise comparison to references. If time or compute prevents completion, deliver the highest-value working changes and state precisely what remains rather than pretending complete.
