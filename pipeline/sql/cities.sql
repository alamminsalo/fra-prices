LOAD spatial;

LOAD h3;

LOAD httpfs;

SET
    s3_region = 'us-west-2';

CREATE
OR REPLACE TABLE cities AS WITH country_bbox AS (
    SELECT
        ST_XMin(geom) AS xmin,
        ST_XMax(geom) AS xmax,
        ST_YMin(geom) AS ymin,
        ST_YMax(geom) AS ymax,
        geom
    FROM
        country
    LIMIT
        1
)
SELECT
    NAMES.primary AS name,
    population,
    geom: st_transform(
        places.geometry,
        'EPSG:4326',
        'EPSG:3857',
        always_xy := TRUE
    ).st_buffer(2500).st_transform('EPSG:3857', 'EPSG:4326', always_xy := TRUE),
    price_all: geom_value_agg(geom, 7),
    price_house: geom_value_agg(
        geom,
        7,
        query_property_type := 'Maison'
    ),
    price_apartment: geom_value_agg(
        geom,
        7,
        query_property_type := 'Appartement'
    ),
FROM
    read_parquet(
        's3://overturemaps-us-west-2/release/2026-01-21.0/theme=divisions/type=division/*',
        hive_partitioning = TRUE
    ) places
    JOIN country_bbox AS cb ON (
        places.bbox.xmin <= cb.xmax
        AND places.bbox.xmax >= cb.xmin
        AND places.bbox.ymin <= cb.ymax
        AND places.bbox.ymax >= cb.ymin
    )
WHERE
    st_within(places.geometry, cb.geom)
    AND country = 'FR'
    AND subtype = 'locality'
    AND class = 'city'
ORDER BY
    population DESC
LIMIT
    10;

FROM
    cities;

COPY (
    SELECT
        * exclude (geom)
    FROM
        cities
) TO 'cities.csv';
