# Input Datasets

### Price data
https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres

### Country, Region, Department

- https://simplemaps.com
- https://www.data.gouv.fr/datasets/contours-administratifs

### Communes, Parcels 
- https://www.data.gouv.fr/datasets/parcelles-cadastrales-1

### Postcodes
- https://r.iresmi.net/posts/2024/codes_postaux/

# Price aggregation logic

1. For given resolutions, calculate H3 cell id for each transaction-linked parcel.
2. Do a precalculation run to aggregate (sparse) cell-level price estimation:
    - Filter the transactions using their nth parent (level - 2) p5 and p95 price bounds.
    - Create a weight parameter using transaction_date, giving more weight to newer transactions.
    - For each cell, calculate geometric weighted mean price_m2 using that weight parameter.
3. Using the precalculated cell table, find intersecting cells:
    - Propagate to parent if cell is not found
    - Calculate weighted geometric mean, where weight is the cell area intersection: `W = (cellGeom & inputGeom) / cellGeom`
    - Parent cells get naturally less weight as their proportional intersecting area is smaller.
4. Run the geom_agg calculation for each geometry in the area dataset.

# Running

See 'package_mbtiles.sh'

