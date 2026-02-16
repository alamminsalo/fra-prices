load spatial;

CREATE
OR REPLACE TABLE parcel AS
SELECT
    id AS parcel_id,
    departement,
    commune,
    section,
    prefixe,
    contenance AS land_area_sqm,
    -- convert geometry to 4326
    st_transform(
        st_simplifypreservetopology(geometry, 1),
        'EPSG:2154',
        'EPSG:4326',
        always_xy := TRUE
    ) AS geom,
FROM
    'data/cadastre.parquet'
WHERE
    type_objet = 'parcelles'
    AND geom_srid = 2154;
