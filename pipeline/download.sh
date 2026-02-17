#!/bin/bash

set -euo pipefail

DATA_DIR="data"

mkdir -p "${DATA_DIR}"
cd $DATA_DIR

# Array of URLs
ZIP_URLS=(
  "https://www.data.gouv.fr/api/1/datasets/r/4d741143-8331-4b59-95c2-3b24a7bdbe3c"
  "https://www.data.gouv.fr/api/1/datasets/r/cc8a50e4-c8d1-4ac2-8de2-c1e4b3c44c86"
  "https://www.data.gouv.fr/api/1/datasets/r/8c8abe23-2a82-4b95-8174-1c1e0734c921"
  "https://www.data.gouv.fr/api/1/datasets/r/e117fe7d-f7fb-4c52-8089-231e755d19d3"
  "https://www.data.gouv.fr/api/1/datasets/r/8d771135-57c8-480f-a853-3d1d00ea0b69"
)

URLS=(
  "https://huggingface.co/datasets/doao2/map-data/resolve/main/country.json"
  "https://r.iresmi.net/posts/2024/codes_postaux/codes_postaux_fr_2025.gpkg"
  "https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geoparquet/france/cadastre.parquet"
)

echo "Downloading files..."

for url in "${ZIP_URLS[@]}"; do
  echo "Downloading → ${url}"
  filename=$(basename "${url}")
  curl -L -H "User-Agent: Mozilla/5.0" --fail --progress-bar -o "${filename}.zip" "${url}"
  unzip -o "${filename}.zip"
done

for url in "${URLS[@]}"; do
  echo "Downloading → ${url}"
  filename=$(basename "${url}")
  curl -L -H "User-Agent: Mozilla/5.0" --fail --progress-bar -o "${filename}" "${url}"
done

# Cleanup
rm -f *.zip

echo "Done."

