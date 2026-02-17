LOAD spatial;

LOAD h3;

SET
    preserve_insertion_order = false;

-- Precalculated sparse cell value aggregates.
-- Calculate only the range of cells we need.
CREATE
OR REPLACE TABLE cell_values AS WITH base AS (
    SELECT
        r.unnest::int AS res,
        h3_latlng_to_cell(
            st_pointonsurface(geom).st_y(),
            st_pointonsurface(geom).st_x(),
            res
        ) AS cell,
        price_m2,
        property_type,
        transaction_date
    FROM
        transactions t
        JOIN parcel p USING (parcel_id)
        CROSS JOIN unnest(generate_series(2, 8)) AS r
),
bounds AS (
    SELECT
        cell,
        quantile_cont(price_m2, 0.05) AS p5,
        quantile_cont(price_m2, 0.95) AS p95
    FROM
        base
    GROUP BY
        ALL
),
-- Filter outliers and compute weights
filtered AS (
    SELECT
        b.cell,
        b.price_m2,
        b.property_type,
        -- Exponential date decay. Halving time is around 1 year(s).
        exp(
            -0.0019 * date_diff('day', transaction_date, current_date) * 0.5
        ) AS w,
    FROM
        base b
        -- Filter using bounds of nth parent cell
        SEMI JOIN bounds bb ON (
            bb.cell = h3_cell_to_parent(b.cell, greatest(2, b.res - 2))
            AND b.price_m2 BETWEEN bb.p5 AND bb.p95
        )
    ORDER BY
        transaction_date DESC
)
-- Take weighted geometric mean of cell price, this seems to work somewhat better than weighted avg.
SELECT
    cell,
    property_type,
    exp(weighted_avg(ln(price_m2), w)) AS price_m2,
    count() AS tx_count,
FROM
    filtered
GROUP BY
    ALL;

-- Returns propagated cells and their values for given geometry
CREATE
OR REPLACE FUNCTION geom_cell_values(query_geom, query_res,) AS TABLE (
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
            ).unnest() AS cell,
            -- Take polygon along, we can use it to add intersecting area to weight
            poly
        FROM
            polygons
        WHERE
            st_isvalid(poly)
            AND NOT st_isempty(poly)
            AND st_area_spheroid(poly) > 1
    ),
    -- Recursively find non-null value by traversing bottom-up the cell hierarchy.
    -- Make sure the cell is the parent key in the recursive part because otherwise cells leading to same parent will be duplicated.
    cell_agg AS (
        WITH recursive _cells USING KEY(cell) AS (
            -- Initial state
            SELECT
                cell,
                price_m2,
                tx_count,
                h3_get_resolution(cell) AS res,
                h3_cell_to_parent(cell, res - 1) AS parent_cell,
                poly,
                st_intersection(
                    poly,
                    -- The function has a misleading name -> it returns polygon, not the boundary linestring
                    h3_cell_to_boundary_wkt(cell)::geometry
                ).st_area_spheroid() / h3_cell_area(cell, 'm^2') AS w_isect,
            FROM
                query_cells
                LEFT JOIN cell_values USING (cell)
                -- Recursive ascension to parent
            UNION
            SELECT
                p.cell,
                p.price_m2,
                p.tx_count,
                c.res - 1,
                h3_cell_to_parent(p.cell, c.res -1),
                c.poly,
                st_intersection(
                    poly,
                    h3_cell_to_boundary_wkt(p.cell)::geometry
                ).st_area_spheroid() / h3_cell_area(p.cell, 'm^2'),
            FROM
                _cells c
                LEFT JOIN cell_values p ON (parent_cell = p.cell)
            WHERE
                -- Stops when reaching resolution 2 OR price is found on parent cell.
                res >= 2
                AND c.price_m2 IS NULL
        )
        FROM
            _cells
        WHERE
            price_m2 IS NOT NULL
            AND NOT isnan(w_isect)
            AND w_isect > 0
    )
    FROM
        cell_agg
);

-- Calculates value for given geometry and aggregation level:
-- Uses weighted geometric mean.
-- Weight is number of transactions multiplied with the overlapping fractional area of the cell.
-- This way we attempt to normalize the parent-children influence.
CREATE
OR REPLACE FUNCTION geom_value_agg(query_geom, query_res,) AS (
    SELECT
        exp(
            weighted_avg(
                ln(price_m2),
                sqrt(tx_count) * w_isect
            )
        )
    FROM
        geom_cell_values(
            query_geom,
            query_res,
        )
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

.print "Postcode...";

copy (
    SELECT
        code_postal AS id,
        nom_de_la_commune AS name,
        geom_value_agg(geom, 6) AS price_estimate,
        geom
    FROM
        postcode
) TO 'data/areas/postcode.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');

.print "Section...";

CREATE temp TABLE section_prices AS
SELECT
    s.id,
    s.nom AS name,
    geom_value_agg(s.geom, 7) AS price_estimate,
    s.geom
FROM
    section s;

COPY section_prices TO 'data/areas/section.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:4326');
