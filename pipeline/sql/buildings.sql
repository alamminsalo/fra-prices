LOAD spatial;

ATTACH 'data/bdnb.gpkg' (TYPE SQLITE, READ_ONLY);

CREATE
OR REPLACE TABLE building AS
SELECT
    bg.batiment_groupe_id AS building_id,
    bg.code_iris AS neighborhood_id,
    bg.s_geom_groupe::FLOAT AS building_area,
    pa.total_parcel_area AS parcel_area,
    -- Construction Year (Prioritizing ffo_bat over dpe)
    COALESCE(
        bg.ffo_bat_annee_construction,
        bg.dpe_mix_arrete_annee_construction_dpe,
    )::INT AS construction_year,
    -- Energy Score (A=6 to G=0)
    CASE
        bg.dpe_mix_arrete_classe_bilan_dpe
        WHEN 'A' THEN 6
        WHEN 'B' THEN 5
        WHEN 'C' THEN 4
        WHEN 'D' THEN 3
        WHEN 'E' THEN 2
        WHEN 'F' THEN 1
        WHEN 'G' THEN 0
        ELSE 3 -- Default to 'D' (median)
    END AS energy_score,
    -- House vs Apartment
    CASE
        WHEN bg.usage_principal_bdnb_open LIKE '%individuel%' THEN 1
        ELSE 0
    END AS is_house
FROM
    st_read(
        'data/bdnb.gpkg',
        layer = 'batiment_groupe_compile'
    ) bg
    JOIN bdnb.rel_batiment_groupe_parcelle rel USING (batiment_groupe_id);
