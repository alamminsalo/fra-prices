LOAD spatial;

-- Dynamic simplification by zoom level
CREATE FUNCTION simplify(geom, z, zmax := 14, factor := 2) AS st_simplifypreservetopology(geom, factor ** (zmax - z));

-- Table function that assembles data that goes into zoom level
CREATE FUNCTION zlayer(
    src,
    z,
    out_crs := 'EPSG:3857',
    layer_name := 'prices'
) AS TABLE
SELECT
    -- Layer data
    1 AS layer_index,
    layer_name AS layer,
    -- Feature data
    st_makevalid(
        simplify(
            st_transform(geom, 'EPSG:4326', out_crs, always_xy := TRUE),
            z
        )
    ) AS geom,  -- properties struct
    { 'id': (row_number() over ())::text,
    'name': coalesce(name, ''),
    'price_estimate': price_estimate::int }::json AS properties,
FROM
    st_read(src);

copy (
    FROM
        zlayer('data/areas/country.fgb', 3)
) TO 'out/z3.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/country.fgb', 4)
) TO 'out/z4.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/region.fgb', 5)
) TO 'out/z5.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/region.fgb', 6)
) TO 'out/z6.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/department.fgb', 7)
) TO 'out/z7.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/department.fgb', 8)
) TO 'out/z8.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/commune.fgb', 9)
) TO 'out/z9.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/commune.fgb', 10)
) TO 'out/z10.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/postcode.fgb', 11)
) TO 'out/z11.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/postcode.fgb', 12)
) TO 'out/z12.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/section.fgb', 13)
) TO 'out/z13.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');

copy (
    FROM
        zlayer('data/areas/section.fgb', 14)
) TO 'out/z14.fgb' (format gdal, driver FlatGeobuf, srs 'EPSG:3857');
