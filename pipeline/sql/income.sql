-- COM income 2021
CREATE
OR REPLACE TABLE income AS
SELECT
    geo AS commune,
    obs_value AS median_income
FROM
    'data/src/DS_FILOSOFI_AGE_TP_NIVVIE.csv'
WHERE
    unit_measure = 'EUR_YR'
    AND geo_object = 'COM'
    AND obs_value IS NOT NULL
    AND age_rf = '_T';
