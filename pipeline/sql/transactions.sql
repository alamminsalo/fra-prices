-- Input datasets: cadastre geoparquet, valeus foncieres parquet (combined csv files)
CREATE
OR REPLACE MACRO fmt_number (x) AS regexp_replace (x::text, '[^0-9,]', '').replace (',', '.');

CREATE
OR REPLACE TABLE transactions AS WITH valeurs AS (
    SELECT
        row_number() over () AS transaction_id,
        lpad ("Code departement"::text, 2, '0') AS departement,
        lpad ("Code commune"::text, 3, '0') AS commune,
        "Commune"::text AS commune_name,
        "Code postal"::text AS postcode,
        upper (trim ("Section"::text)) AS section,
        trim ("No plan"::text) AS no_plan,
        lpad (
            coalesce ("Prefixe de section"::text, '000'),
            3,
            '0'
        ) AS prefixe,
        try_cast ("Date mutation" AS date) AS transaction_date,
        try_cast (fmt_number ("Valeur fonciere") AS int) AS price_eur,
        try_cast (fmt_number ("Surface reelle bati") AS int) AS built_area_m2,
        try_cast (fmt_number ("Surface terrain") AS int) AS land_area_m2,
        try_cast (fmt_number ("Nombre pieces principales") AS int) AS main_rooms,
        try_cast((price_eur / built_area_m2) AS int) AS price_m2,
        "Type local" AS property_type,
    FROM
        'data/valeurs.parquet'
    WHERE
        TRUE
        AND "Nature mutation" = 'Vente'
        AND transaction_date IS NOT NULL
        AND price_eur BETWEEN 1000 AND 1000000000
        AND property_type IS NOT NULL
        AND main_rooms IS NOT NULL
        AND departement IS NOT NULL
        AND commune IS NOT NULL
        AND postcode IS NOT NULL
        AND price_m2 IS NOT NULL
)
SELECT
    transaction_id,
    departement || commune || prefixe || section || lpad (no_plan, 4, '0') AS parcel_id,
    transaction_date,
    price_eur,
    price_m2,
    built_area_m2,
    land_area_m2,
    main_rooms,
    property_type,
FROM
    valeurs;
