#!/bin/bash

set -ev

# Download data files
./download.sh

# Directory for the output areas before tiling
mkdir -p data/areas

# Enable to build the estimation fgbs
# This is a poor mans pipeline
duckdb data.db -bail < sql/_pipeline_.sql

tippecanoe -o prices.mbtiles \
  --layer prices \
  --base-zoom=1 \
  --maximum-zoom=14 \
  --force \
  -L'{"file":"data/areas/country.fgb", "minimum_zoom":1, "maximum_zoom":4}' \
  -L'{"file":"data/areas/region.fgb", "minimum_zoom":5, "maximum_zoom":6}' \
  -L'{"file":"data/areas/department.fgb", "minimum_zoom":7, "maximum_zoom":8}' \
  -L'{"file":"data/areas/commune.fgb", "minimum_zoom":9, "maximum_zoom":10}' \
  -L'{"file":"data/areas/postcode.fgb", "minimum_zoom":11, "maximum_zoom":12}' \
  -L'{"file":"data/areas/section.fgb", "minimum_zoom":13, "maximum_zoom":14}'

# Convert to pmtiles
pmtiles convert prices.mbtiles ../ui/public/prices.pmtiles

# Finally, print the cities in markdown format
duckdb data.db -bail < sql/cities.sql
