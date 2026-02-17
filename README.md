# French Housing Prices Estimator

[Live page](https://alamminsalo.github.io/fra-prices/)

# Top 10 cities and their prices

|    name     | population | price_all | price_maison | price_appartement |
|-------------|-----------:|----------:|-------------:|------------------:|
| Paris       | 2133111    | 10655.0   | 15024.5      | 10652.0           |
| Lyon        | 522250     | 4612.5    | 6575.0       | 4601.0            |
| Toulouse    | 504078     | 3948.0    | 4429.0       | 3876.5            |
| Nice        | 348085     | 5000.0    | 7013.0       | 4959.0            |
| Nantes      | 323204     | 3885.0    | 4737.0       | 3812.0            |
| Montpellier | 302454     | 3674.5    | 4372.0       | 3603.5            |
| Bordeaux    | 261804     | 4722.0    | 4862.0       | 4643.0            |
| Lille       | 236710     | 3849.5    | 3276.5       | 4038.0            |

## Tech stack

- Maplibre UI
- DuckDB (spatial, h3 extensions)
- PMTiles (served via huggingface)
