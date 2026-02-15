LOAD spatial;

LOAD h3;

SET
    preserve_insertion_order = false;

-- Index table linking transactions to h3 cells
CREATE TABLE IF NOT EXISTS transactions_h3_index AS
SELECT
    t.transaction_id,
    ref: st_pointonsurface(geom),
    cell: h3_latlng_to_cell_string(
        ref.st_y(),
        ref.st_x(),
        10
    )
FROM
    parcel p
    JOIN transactions t USING (parcel_id);

-- Precalculated cell value aggregates.
-- Recursively calculates (bottom-up) cell values using median price.
-- Stops at cell resolution 2.
CREATE
OR REPLACE TABLE cell_values AS WITH recursive cell_agg AS (
    SELECT
        cell,
        median(price_m2) AS price_m2,
        h3_get_resolution(cell) AS resolution
    FROM
        transactions t
        JOIN transactions_h3_index i USING (transaction_id)
    GROUP BY
        ALL
    UNION
    SELECT
        h3_cell_to_parent(cell, resolution - 1),
        median(price_m2),
        resolution - 1,
    FROM
        cell_agg
    WHERE
        resolution >= 2
    GROUP BY
        ALL
)
SELECT
    cell,
    price_m2
FROM
    cell_agg;

-- Computes value for given geometry at given cell resolution.
CREATE
OR REPLACE FUNCTION price_estimate_h3(query_geom, query_res) AS (
    -- Collect unique h3 cells intersecting the query geometry
    WITH query_cells AS (
        -- Normalize to polygons
        WITH polygons AS (
            SELECT
                unnest(st_dump(query_geom)).geom AS poly
        )
        SELECT
            DISTINCT h3_polygon_wkb_to_cells_string(
                st_aswkb(poly),
                query_res
            ).unnest() AS cell
        FROM
            polygons
    ),
    -- Recursively ascend to parent cell until valuation is found
    cell_agg AS (
        WITH recursive _cells USING KEY(cell) AS (
            -- Initial state
            SELECT
                cell,
                price_m2,
                h3_get_resolution(cell) AS res,
                h3_cell_to_parent(cell, res - 1) AS parent_cell,
            FROM
                query_cells
                LEFT JOIN cell_values USING (cell)
            UNION
            -- Recursive select
            SELECT
                c.cell,
                coalesce(c.price_m2, p.price_m2) AS price,
                c.res - 1,
                h3_cell_to_parent(c.parent_cell, c.res - 1),
            FROM
                _cells c
                LEFT JOIN cell_values p ON (c.parent_cell = p.cell)
            WHERE
                c.price_m2 IS NULL
                AND res >= 2
        )
        FROM
            _cells
    )
    SELECT
        median(price_m2)
    FROM
        cell_agg
);

.print "Creating area aggregates...";

copy (
    SELECT
        id,
        name,
        price_estimate_h3(geom, 3) AS price_estimate,
        geom
    FROM
        country
) TO 'data/areas/country.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

copy (
    SELECT
        id,
        name,
        price_estimate_h3(geom, 4) AS price_estimate,
        geom
    FROM
        region
) TO 'data/areas/region.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

copy (
    SELECT
        id,
        name,
        price_estimate_h3(geom, 5) AS price_estimate,
        geom
    FROM
        department
) TO 'data/areas/department.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

copy (
    SELECT
        id,
        nom AS name,
        price_estimate_h3(geom, 6) AS price_estimate,
        geom
    FROM
        commune
) TO 'data/areas/commune.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

copy (
    SELECT
        code_postal AS id,
        nom_de_la_commune AS name,
        price_estimate_h3(geom, 7) AS price_estimate,
        geom
    FROM
        postcode
) TO 'data/areas/postcode.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');
