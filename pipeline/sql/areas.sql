LOAD spatial;

-- area geometries used for the aggregations
CREATE
OR REPLACE TABLE country AS
FROM
    st_read ('data/country.json')
WHERE
    geom IS NOT NULL;

CREATE
OR REPLACE TABLE region AS
FROM
    st_read ('data/region.json')
WHERE
    geom IS NOT NULL;

CREATE
OR REPLACE TABLE department AS
FROM
    st_read ('data/department.json')
WHERE
    geom IS NOT NULL;

CREATE
OR REPLACE TABLE commune AS
SELECT
    id,
    nom,
    st_transform(
        geometry,
        'EPSG:2154',
        'EPSG:4326',
        always_xy := TRUE
    ) AS geom
FROM
    'data/cadastre.parquet'
WHERE
    type_objet = 'communes'
    AND geom_srid = 2154;

CREATE
OR REPLACE TABLE postcode AS
FROM
    'data/postcodes.parquet'
WHERE
    NOT st_isempty(geom);
