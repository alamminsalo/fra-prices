# French Housing Prices Estimator

[Live page](https://alamminsalo.github.io/fra-prices/)

# Top 10 cities and their prices

|    name     | population | price_all | price_maison | price_appartement |
|-------------|-----------:|----------:|-------------:|------------------:|
| Paris       | 2133111    | 10685.0   | 17188.0      | 10682.0           |
| Lyon        | 522250     | 4711.0    | 6134.0       | 4708.5            |
| Toulouse    | 504078     | 3890.0    | 3841.5       | 3890.0            |
| Nice        | 348085     | 5223.0    | 5131.0       | 5223.0            |
| Nantes      | 323204     | 4000.0    | 4535.5       | 4000.0            |
| Montpellier | 302454     | 3750.0    | 3445.5       | 3750.0            |
| Bordeaux    | 261804     | 4225.0    | 4140.0       | 4225.0            |
| Lille       | 236710     | 3908.5    | 3438.0       | 3936.0            |

## Tech stack

- Maplibre UI
- DuckDB (spatial, h3 extensions)
- PMTiles (served via huggingface)

## Pipeline

See [pipeline/](./pipeline)
