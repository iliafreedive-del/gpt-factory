# Map 1.0.0 — sources and uncertainty

Coordinates and dimensions are editable in `data/site.json`. X points right and Z down on the supplied top-down 2GIS plan. One unit is one metre. True north, elevations, cadastral limits and capacities are **not surveyed**. The board edge is a presentation device, not the property boundary.

## Calibration, not a cadastral survey

`handoff/source/03_REFERENCES/image(6).png` shows cumulative ruler readings. Interpreted sequence: 0 → 12 → 50 → 80 → 129 → 143 → 192 → 200 m. It is a connected ruler path, **not** a list of building lengths. In particular 129/143/192 are not 129/143/192-m warehouses.

| Feature | Ruler difference | Pixel check on original PNG | Implemented footprint | Status |
|---|---:|---:|---:|---|
| Red warehouse length | 192−143 = 49 m | 307/49 = 6.27 px/m | 49 × 14 m | map-derived anchor, author tolerance ±2 m |
| Red warehouse depth | 143−129 = 14 m | 87/14 = 6.21 px/m | same | independent perpendicular axis, within 0.9% |
| LGC length | 50−12 = 38 m | 242/38 = 6.37 px/m | 38 × 12 m | map-derived, author tolerance ±2 m |
| LGC depth | 12−0 = 12 m | 73/12 = 6.08 px/m | same | screenshot perspective/edge picking limits accuracy |

Pixel measurements are approximate edge picks. ±2 m is a conservative modelling tolerance assigned by the author, **not** accuracy certified by 2GIS or the owner. LGC's independent axes differ about 4.7%; roof overhang and perspective are unresolved. The previous 51×19 / 62×22 m footprints were not retained as measured dimensions.

`image(7)` is oblique and used for adjacency and facade context, not a second metric scale. `image(8)` is an annotated boundary overview with cumulative, partly obscured readings; it does not justify a claimed exact site perimeter. No numeric site capacity or perimeter is presented.

## Functional mapping

Excel is a functional topology, not a metric floor plan. Its complete cell text is retained in the original workbook. The scene preserves the principal relationships: rail and tree buffer north; zinc frames and retail staging north of red warehouse; LGC east of red warehouse; new shop south of LGC and third-party building south again; workshop 1 west of workshop 2; paint and sandblast on the west end of workshop 2; offices, spares and dealer dispatch south; black workshop to the east beyond container corridor. Sites and entrances are provisional proportional estimates. The main workshop silhouettes follow 2GIS, with functional sections sharing a building envelope where appropriate.

| Other footprints (m) | Source / confidence |
|---|---|
| New shop 38×13; third-party 39×20 | Excel adjacency, 2GIS proportions; photo verifies metal-clad gables, not dimensions |
| Shop 1 45×23; shop 2 47×14 | 2GIS outline estimate; annex geometry and exact subdivision unverified |
| Paint 16×14; blast 14×12; awning 9×10 | Excel process zones + 2GIS relative layout, estimates |
| Offices 20×7 and 11×14 | Excel labels / map proportions, estimates |
| Black workshop 29×44 | Excel eastern location and boundary overview, estimated footprint |
| Garages 27×8 each; spares 26×8; LGC welding store 12×8; axes 10×6; mini-store 8×6 | Excel topology only, estimated |
| Heights 3.5–8 m; roads 7–10 m | modelling assumptions; no measured clearances |
| Trailer approximately 4.3×2.1 m overall, 2.9×1.7 m body | representative kit, not a factory SKU CAD model |
| Rail gauge 1.52 m in this model | assumed Russian broad gauge; confirm onsite track layout and rail profile before logistics use |
| Gantry rail spacing 25 m, span/height and placement | Excel confirms rails/loading zone; dimensions estimated |

## Field verification required

Confirm ruler-path interpretation against original 2GIS measurement session; survey exterior corners, heights and road clear widths; exact factory property/gate outline; new-shop footprint and current construction state; black-shop/garage locations; crane span and rail extent; rail gauge and access constraints; precise subzones inside the combined workshop envelopes; true north; trailer product envelopes and stock counts. Excel itself marks the far-west trailer storage mix as unknown; this remains explicitly unknown in the map.

There are no interior models and no calculated storage capacities. Selection, orbit, pan, zoom and focus are supported. E toggles a local sketch mode: select a building and move it in one-metre steps with the arrow keys. Collision, roof, batch instances and its label move together. These are temporary edits, reset on reload; permanent surveyed corrections belong in the central JSON.
