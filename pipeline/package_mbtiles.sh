#!/bin/bash

set -ev

# TODO: Fetch source files into './data/'...

mkdir -p data/areas

# Enable to build the estimation fgbs
# This is a poor mans pipeline
# duckdb -bail < sql/_pipeline_.sql

duckdb -bail < sql/prepare_tiling.sql

# tippecanoe -o prices.mbtiles \
#   --layer prices \
#   --base-zoom=1 \
#   --maximum-zoom=14 \
#   --force \
#   -L'{"file":"data/areas/country.fgb", "minimum_zoom":1, "maximum_zoom":2}' \
#   -L'{"file":"data/areas/region.fgb", "minimum_zoom":3, "maximum_zoom":4}' \
#   -L'{"file":"data/areas/department.fgb", "minimum_zoom":5, "maximum_zoom":6}' \
#   -L'{"file":"data/areas/commune.fgb", "minimum_zoom":7, "maximum_zoom":8}' \
#   -L'{"file":"data/areas/postcode.fgb", "minimum_zoom":9, "maximum_zoom":11}' \
#   -L'{"file":"data/areas/section.fgb", "minimum_zoom":12, "maximum_zoom":14}'

# (Custom tiler tool)
tiler --input out --buffer-size 0.05

# Convert to pmtiles
pmtiles convert output.mbtiles ../ui/public/prices.pmtiles
