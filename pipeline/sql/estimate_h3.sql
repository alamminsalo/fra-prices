LOAD spatial;

LOAD h3;

SET
    preserve_insertion_order = false;

-- Precalculated sparse cell value aggregates.
-- Recursively calculates (bottom-up) cell values using median of child cell (median) prices.
-- Stops at cell resolution 2.
-- Granularity can be increased by increasing the index resolution.
CREATE
OR REPLACE TABLE cell_values AS WITH recursive cell_agg USING KEY (cell) AS (
    -- Index linking transactions to h3 cells
    WITH tx_cell_index AS (
        SELECT
            transaction_id,
            ref: st_pointonsurface(geom),
            cell: h3_latlng_to_cell(
                ref.st_y(),
                ref.st_x(),
                8
            )
        FROM
            transactions t
            JOIN parcel p USING (parcel_id)
    )
    SELECT
        cell,
        median(price_m2) AS price_m2,
        h3_get_resolution(cell) AS resolution
    FROM
        tx_cell_index
        JOIN transactions t USING (transaction_id)
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
        resolution > 1
    GROUP BY
        ALL
)
SELECT
    cell,
    price_m2
FROM
    cell_agg;

-- Calculates value for given geometry and aggregation level
CREATE
OR REPLACE FUNCTION geom_value_agg(query_geom, query_res) AS (
    -- Collect unique h3 cells intersecting the query geometry
    WITH query_cells AS (
        -- Normalize to polygons
        WITH polygons AS (
            SELECT
                unnest(st_dump(query_geom)).geom AS poly
        )
        SELECT
            h3_polygon_wkb_to_cells_experimental(
                st_aswkb(poly),
                query_res,
                'overlap'
            ).unnest() AS cell
        FROM
            polygons
    ),
    -- Recursively find non-null value by traversing bottom-up the cell hierarchy
    cell_agg AS (
        WITH recursive _cells USING KEY (cell) AS (
            -- Initial state
            SELECT
                cell,
                price_m2,
                h3_get_resolution(cell) AS res,
                h3_cell_to_parent(cell, res - 1) AS parent_cell,
            FROM
                query_cells
                LEFT JOIN cell_values USING (cell)
                -- Recursive ascension to parent
            UNION
            SELECT
                c.cell,
                coalesce(c.price_m2, p.price_m2),
                c.res - 1 AS res,
                h3_cell_to_parent(c.cell, c.res - 1),
            FROM
                _cells c
                LEFT JOIN cell_values p ON (c.parent_cell = p.cell)
            WHERE
                -- Stops when reaching resolution 1 OR price is found on parent cell.
                res > 1
                AND c.price_m2 IS NULL
        )
        FROM
            _cells
    )
    -- Find cell value for each queried cell
    SELECT
        median(price_m2)
    FROM
        cell_agg
);

.print "Creating area aggregates...";

.print "Country...";

copy (
    SELECT
        id,
        name,
        geom_value_agg(geom, 3) AS price_estimate,
        geom
    FROM
        country
) TO 'data/areas/country.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/country.fgb'
GROUP BY
    ALL;

.print "Region...";

copy (
    SELECT
        id,
        name,
        geom_value_agg(geom, 4) AS price_estimate,
        geom
    FROM
        region
) TO 'data/areas/region.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/region.fgb'
GROUP BY
    ALL;

.print "Department...";

copy (
    SELECT
        id,
        name,
        geom_value_agg(geom, 5) AS price_estimate,
        geom
    FROM
        department
) TO 'data/areas/department.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/department.fgb'
GROUP BY
    ALL;

.print "Commune...";

copy (
    SELECT
        id,
        nom AS name,
        geom_value_agg(geom, 6) AS price_estimate,
        geom
    FROM
        commune
) TO 'data/areas/commune.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/commune.fgb'
GROUP BY
    ALL;

.print "Postcode...";

copy (
    SELECT
        code_postal AS id,
        nom_de_la_commune AS name,
        geom_value_agg(geom, 7) AS price_estimate,
        geom
    FROM
        postcode
) TO 'data/areas/postcode.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/postcode.fgb'
GROUP BY
    ALL;

-- Need to do sections in multiple runs because my workstation is running out of memory.
-- Lets use regions to help us splitting the inserts.
.print "Section...";

CREATE temp TABLE section_prices AS
SELECT
    s.id,
    s.nom AS name,
    geom_value_agg(s.geom, 8) AS price_estimate,
    s.geom
FROM
    section s
    JOIN postcode p ON (st_within(st_pointonsurface(s.geom), p.geom))
    SEMI JOIN region r ON (
        st_within(st_pointonsurface(s.geom), r.geom)
        AND r.id::int IN (11, 24, 27, 28)
    );

INSERT INTO
    section_prices
SELECT
    id,
    nom AS name,
    geom_value_agg(geom, 8) AS price_estimate,
    geom
FROM
    section s
    SEMI JOIN region r ON (
        st_within(st_pointonsurface(s.geom), r.geom)
        AND r.id::int IN (32, 44, 52, 53)
    );

INSERT INTO
    section_prices
SELECT
    id,
    nom AS name,
    geom_value_agg(geom, 8) AS price_estimate,
    geom
FROM
    section s
    SEMI JOIN region r ON (
        st_within(st_pointonsurface(s.geom), r.geom)
        AND r.id::int IN (75, 76, 84, 93, 94)
    );

COPY section_prices TO 'data/areas/section.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

SELECT
    count(),
    price_estimate IS NULL
FROM
    'data/areas/section.fgb'
GROUP BY
    ALL;
