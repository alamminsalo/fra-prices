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
    geom: st_transform(places.geometry, 'EPSG:4326', 'EPSG:2154').st_buffer(5000).st_transform('EPSG:2154', 'EPSG:4326'),
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

copy (
    SELECT
        name,
        population,
        price_all: median(price_m2),
        price_maison: median(price_m2) filter (property_type = 'Maison'),
        price_appartement: median(price_m2) filter (property_type = 'Appartement'),
    FROM
        transactions t
        JOIN parcel p USING (parcel_id)
        JOIN cities c ON st_contains(c.geom, p.geom)
    WHERE
        date_diff('day', transaction_date, current_date) < 365
    GROUP BY
        ALL
    ORDER BY
        population DESC
) TO 'cities.md';
