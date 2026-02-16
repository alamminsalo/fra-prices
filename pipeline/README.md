# Input Datasets

Prices are aggregated using H3 cells.

Currently there is no weighting implemented, prices are median historical values based on proximity.

Unfortunately, I was having out-of-memory issues with the parcel level aggregation, and as a workaround used sections instead.

### Price data
https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres

### Country, Region, Department

- https://simplemaps.com
- https://www.data.gouv.fr/datasets/contours-administratifs

### Communes, Parcels 
- https://www.data.gouv.fr/datasets/parcelles-cadastrales-1

### Postcodes
- https://r.iresmi.net/posts/2024/codes_postaux/

# Running

See 'package_mbtiles.sh'

