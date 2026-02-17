LOAD spatial;

-- Area geometry tables
CREATE
OR REPLACE TABLE country AS
SELECT
    1 AS id,
    'France' AS name,
    geom,
FROM
    st_read('data/country.json');

CREATE
OR REPLACE TABLE region AS
SELECT
    code AS id,
    nom AS name,
    geom
FROM
    st_read(
        'https://object.data.gouv.fr/contours-administratifs/2025/geojson/regions-100m.geojson'
    ) r
    SEMI JOIN country c ON st_intersects(c.geom, r.geom);

CREATE
OR REPLACE TABLE department AS
SELECT
    code AS id,
    nom AS name,
    geom
FROM
    st_read(
        'https://object.data.gouv.fr/contours-administratifs/2025/geojson/departements-100m.geojson'
    ) d
    SEMI JOIN country c ON st_intersects(c.geom, d.geom);

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
    'data/codes_postaux_fr_2025_v2.gpkg'
    SEMI JOIN department d ON (st_intersects(d.geom, p.geom))
WHERE
    NOT st_isempty(geom);

CREATE
OR REPLACE TABLE section AS
SELECT
    id,
    nom,
    st_transform(
        geometry,
        'EPSG:2154',
        'EPSG:4326',
        always_xy := TRUE
    ) AS geom,
FROM
    'data/cadastre.parquet'
WHERE
    type_objet = 'sections'
    AND geom_srid = 2154;
