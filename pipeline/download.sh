#!/usr/bin/env bash
# Downloads input data: four GTFS feeds of the Rybnik region, OSM roadways
# (Overpass), MapLibre GL. Everything is cached — re-running only fetches what
# is missing.
#
# Feeds (checked 6.08.2026):
#   KM Rybnik        — km.rybnik.pl "pliki do pobrania" (gtfs_01082026.zip)
#   BKM Żory         — zory.pl (GTFS_31.07.2026.zip); free city network
#   Powiat wodzisławski (WKP) — files.girlc.at/gtfs (CC0)
#   MZK Jastrzębie + region  — zbiorkom.live open-data bundle (also carries the
#                              Wodzisław 20x shuttles and Czerwionka 30x lines)
# NOTE: the Rybnik download URL embeds the release date — when the feed rots,
# grab the fresh link from https://km.rybnik.pl/435/pliki-do-pobrania.html
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs-rybnik data/gtfs-zory data/gtfs-wodzislaw data/gtfs-jastrzebie data/osm web/vendor

# A downloaded extract is only accepted if it PARSES and carries a plausible
# number of elements. `grep -q '"elements"'` — the guard this family used
# everywhere — passes on a truncated response too: Brașov's roads arrived as a
# 65 kB fragment that still contained the string, was taken for complete, and
# silently skipped the city (16.08.2026).
# The floor is passed by the caller rather than shared, because it depends on
# the extract: a road network runs to tens of thousands of ways, a city rail
# network to a few hundred.
# A rejected file is deleted rather than left behind — the `[ ! -f … ]` gate
# below only asks whether the file exists, so a fragment on disk would be taken
# for a finished download on the next run.
ok_json () { # $1=file  $2=minimum element count
  python3 - "$1" "$2" <<'PYEOF' 2>/dev/null
import json, sys
try:
    sys.exit(0 if len(json.load(open(sys.argv[1])).get("elements", [])) >= int(sys.argv[2]) else 1)
except Exception:
    sys.exit(1)
PYEOF
}

fetch_gtfs() { # dir url
  if [ ! -f "$1/routes.txt" ]; then
    echo "== GTFS $1 =="
    curl -fL --retry 3 --max-time 300 -o "$1.zip" "$2"
    unzip -o "$1.zip" -d "$1"
    rm -f "$1.zip"
  fi
}
fetch_gtfs data/gtfs-rybnik     "https://km.rybnik.pl/download/attachment/629/gtfs_01082026.zip"
fetch_gtfs data/gtfs-zory       "https://www.zory.pl/fileadmin/user-files/dla-mieszkancow/BKM/GTFS_31.07.2026.zip"
fetch_gtfs data/gtfs-wodzislaw  "https://files.girlc.at/gtfs/powiat_wodzislawski.zip"
fetch_gtfs data/gtfs-jastrzebie "https://cdn.zbiorkom.live/gtfs/rybnik-jastrzebie.zip"

# OSM — roadways over the whole region (2121 GTFS stops: 49.871–50.198 N,
# 18.225–18.811 E, plus margin: Rudy in the north-west, Strumień in the
# south-east, Zebrzydowice in the south)
if [ ! -f data/osm/rybnik.json ]; then
  echo "== Overpass (roads) =="
  Q='[out:json][timeout:600];way(49.85,18.19,50.22,18.85)["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|busway|construction|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"];out geom;'
  ok=0
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 600 -o data/osm/rybnik.json --data-urlencode "data=$Q" "$EP" \
       && ok_json "data/osm/rybnik.json" 2000; then
      ok=1; break
    fi
  done
  [ "$ok" = 1 ] || { rm -f data/osm/rybnik.json; echo "Overpass: all mirrors failed" >&2; exit 1; }
fi

# MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs-*/ data/osm/rybnik.json 2>/dev/null || true
