# Rybnik Region Public Transport — interactive map

Interactive, poster-grade map of the bus network of the Rybnik region
(Subregion Zachodni): **Rybnik, Żory, Jastrzębie-Zdrój, Wodzisław Śląski and
the surrounding county**, ~123 lines / ~3 550 km of routes drawn along the
real street geometry.

## Live

**https://miqell24.github.io/rybnik-bus-map/** — GitHub Pages from `main:/docs`.

Four GTFS feeds merge into ONE network — shared corridors get a single stroke
with the union of lines, hubs fuse into one badge complex:

| feed | source | lines | shapes |
|---|---|---|---|
| KM Rybnik | km.rybnik.pl | 1–52, A, N6, N8, PR | none — matched from stop sequences |
| BKM Żory (free city network) | zory.pl | 01–09, ZL | none |
| Wodzisławska Komunikacja Powiatowa | files.girlc.at/gtfs (CC0) | W32–W59 (W prefix added by this map — plain numbers collide with KM Rybnik) | none |
| zbiorkom.live regional bundle | cdn.zbiorkom.live | MZK Jastrzębie (B/C/L/M/R/S/W codes), Wodzisław city 201–210, Czerwionka-Leszczyny 300–309 | full |

The bundle's copies of the Żory lines (01–09, ZL "Zielona Linia") are dropped
in favour of the official Żory feed. The Rybnik feed's "-->" route is depot
positioning runs, not passenger service — excluded.

## Pipeline

`npm run download` fetches the four feeds, OSM roadways (Overpass, bbox
49.85–50.22 N / 18.19–18.85 E) and MapLibre GL. `npm run build` map-matches
every line (HMM/Viterbi on the OSM road graph; feeds without shapes use their
stop sequences as observations) and writes GeoJSON to `data/out/`.
`npm run serve` hosts the map at http://localhost:8134.

Data: KM Rybnik, BKM Żory, Wodzisławska Komunikacja Powiatowa, zbiorkom.live ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
