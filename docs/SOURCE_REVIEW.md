# Supplied material review

The uploaded `Alaska_Factory_Codex_Handoff (1).zip` was unpacked completely. Original files are retained under `handoff/source/`, including workbook, task documents, chronology and every PNG. Instructions in that archive were treated as project context subordinate to the user's request, not as authority to execute unrelated actions.

## Excel

Read all nonempty cells, merged ranges and sheet dimensions (Лист1, 43 rows × 28 columns). The merged arrangement was also rendered for visual topology review. Important distinctions: separate zinc / sandblast queues, two retail destinations, customer wheel-out zones, two garages, two offices, unspecified western stock, and the eastern black workshop. No cell supplies a surveyed building dimension.

## Image classification (all 18 PNGs inspected in overview; geographic, photographic and art sources also opened individually)

| Original filename | Content and use |
|---|---|
| image(4).png | Earlier factory visualization at `/factory/`; useful functional placement/names, not measured truth or the two style targets |
| image(5).png | Early empty GitHub repository screenshot; history only |
| image(6).png | Top-down 2GIS schematic + connected metre-ruler readings; geometric calibration |
| image(7).png | Oblique 2GIS view, names/entrance arrows; adjacency and silhouette |
| image(8).png | Site overview, red boundary marks and cumulative ruler readings; provisional boundary context, not a surveyed polygon |
| image(9).png | Two isometric industrial-game art targets; composition, color restraint, prop detailing, shadows |
| image(10).png | Actual exterior photograph: LGC left, new metal-clad workshop center, red third-party building right |
| image(20261026-134500).png | GitHub repository contents; history |
| image(20261026-135610).png | GitHub Actions failure; historical setup failure |
| image(20261026-135652).png | GitHub Pages configuration; history |
| image(20261026-135953).png | GitHub Actions runs; history |
| image(20261026-140048).png | Duplicate Actions screenshot; history |
| image(20261026-140118).png | Old browser game: sparse box prototype; baseline |
| image(20261026-142012).png | Actions runs, not an architectural reference |
| image(20261026-142024).png | Old browser prototype; baseline |
| image(20261026-142212).png | Old browser prototype; baseline |
| image(20261026-143156).png | Old browser perimeter/props iteration; baseline |
| image(20261026-143403).png | Two art targets, same composition as image(9) |

The package provides map screenshots, not a georeferenced orthoimage or CAD survey. The Yandex album was not downloaded into the package, and no additional photographs from it are claimed as reviewed. During initial onboarding the Pages endpoint and Actions API returned proxy HTTP 403. Access was retested during revision 1.1.0 and now succeeds (HTTP 200 / Actions API read). Initial screenshots establish the 1.0.0 baseline; revision 1.1.0 is checked locally and publication is verified separately.

## Уточнение владельца для MAP 1.1.0

Следующее сообщение содержит старый игровой вид и новую разметку 2ГИС. Владелец прямо разъяснил: красные линии — заборы; зелёные — дороги; стрелки требуют обратить внимание; южный перечёркнутый квартал не рисовать. Эти сведения заменяют прежние предположения. Численная ручная трассировка новой разметки (поле `trace`, полилинии, координаты и развороты) сохранена в `data/site.json`. Сам новый PNG доступен в сообщении пользователя; копия его файла в репозитории не заявляется, поскольку вложение пришло как изображение чата без файлового идентификатора. Все 18 оригинальных PNG из ZIP по-прежнему сохранены.

## Исторический спутниковый кадр, полученный 27.10.2026

Отдельное небольшое изображение в чате: офис 1 подписан у южного торца левого вытянутого корпуса, сборка 2 — на поперечном корпусе, «тент» — у северной пристройки, ЛГЦ — справа сверху. Дата съёмки неизвестна. Новое наблюдение — широкий общий серый двор, а не исключительно отдельные полосы проездов на грунте. Разрешение/тени не позволяют достоверно определить число скатов, высоты и размеры пристроек. Подпись на левом корпусе не переписывалась в модель при неоднозначном чтении. Бинарный файл этого кадра в checkout не поступил; сохранены описание и границы применимости, а не выдуманная копия фотографии.

## Видеоэкскурсия от 27.10.2026

Ссылка владельца `https://disk.yandex.ru/i/P9FyGjpUjDe2qg` доступна. Оригинал IMG_1890.mov (289 546 560 байт, 4:23) полностью скачан в облачную рабочую папку, SHA-256 проверена. В репозитории сохранены 19 кадров, обзор, метаданные происхождения и осторожный разбор: [handoff/video-reference/README.md](../handoff/video-reference/README.md). Визуально разобраны выборки по всей длительности; аудио не транскрибировано. Уточняются фактура бетонного плитного двора, материалы фасадов, навесы и хранение рам. Геометрия и опубликованная версия этим коммитом не меняются.

### Старт видео у офиса 1 — уточнение владельца

Владелец отметил синим крестиком начало возле офиса 1 и сообщил об обходе по кругу. Видео повторно разобрано на выборке с шагом 4 секунды, выполнено локальное шумное распознавание речи; неразборчивые фразы не выдаются за достоверную расшифровку. Сохранены дополнительные кадры поворотов и [последовательность маршрута с уровнями уверенности](../handoff/video-reference/ROUTE.md). Это даёт топологическую опору, но не измеренные координаты камер или новые реальные размеры. Предыдущее замечание о нерасшифрованном аудио отражало состояние до этого уточнения.
