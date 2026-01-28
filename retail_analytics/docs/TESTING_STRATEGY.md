# Stratégie de Tests - Retail Analytics

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Types de tests](#types-de-tests)
- [Couverture des tests](#couverture-des-tests)
- [Tests par couche](#tests-par-couche)
- [Tests personnalisés](#tests-personnalisés)
- [Exécution des tests](#exécution-des-tests)
- [CI/CD](#cicd)
- [Bonnes pratiques](#bonnes-pratiques)

---

## Vue d'ensemble

Stratégie de tests pour garantir :

1. Qualité des données (valides, cohérentes, complètes)
2. Fiabilité des transformations (logique métier correcte)
3. Performance (temps d'exécution acceptables)
4. Maintenabilité (code testable et évolutif)

### Objectifs de couverture

| Couche | Objectif | Actuel |
|--------|----------|--------|
| Sources | 100% | 100% |
| Staging | 100% | 100% |
| Intermediate | 100% | 100% |
| Marts | 100% | 100% |

---

## Types de tests

### 1. Tests de schéma (Schema Tests)

Valident la structure et les contraintes des données.

#### Tests built-in dbt

```yaml
models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - unique              # Unicité
          - not_null            # Non-nullité
      
      - name: customer_segment
        tests:
          - accepted_values:    # Valeurs acceptées
              values: ['premium', 'standard', 'vip']
```

#### Tests de relations

```yaml
models:
  - name: stg_orders
    columns:
      - name: customer_id
        tests:
          - relationships:      # Intégrité référentielle
              to: ref('stg_customers')
              field: customer_id
```

### 2. Tests de qualité (Data Quality Tests)

Valident la qualité et la cohérence des données.

#### Tests dbt-utils

```yaml
models:
  - name: stg_orders
    tests:
      - dbt_utils.expression_is_true:
          expression: "total_amount >= 0"
      
      - dbt_utils.recency:
          datepart: day
          field: order_date
          interval: 7
```

#### Tests personnalisés

```yaml
models:
  - name: mart_sales_daily
    columns:
      - name: total_revenue
        tests:
          - positive_values     # Test custom
      
      - name: net_revenue
        tests:
          - positive_values
```

### 3. Tests de logique métier (Business Logic Tests)

Valident la logique métier spécifique.

#### Tests singuliers

```sql
-- tests/singular/test_revenue_consistency.sql
-- Vérifier que total_revenue = somme des revenus par canal

WITH revenue_check AS (
    SELECT
        date_day,
        total_revenue,
        (web_revenue + mobile_revenue + store_revenue) AS channel_sum,
        ABS(total_revenue - (web_revenue + mobile_revenue + store_revenue)) AS diff
    FROM {{ ref('mart_sales_daily') }}
)

SELECT *
FROM revenue_check
WHERE diff > 0.01  -- Tolérance de 1 centime
```

### 4. Tests de performance

Surveillent les temps d'exécution et l'utilisation des ressources.

```yaml
models:
  - name: mart_sales_daily
    meta:
      max_execution_time_seconds: 60
      max_rows: 1000000
```

---

## Couverture des tests

### Sources (100%)

Tous les champs critiques des sources sont testés.

```yaml
# models/staging/_staging_sources.yml
version: 2

sources:
  - name: raw_retail
    tables:
      - name: raw_customers
        columns:
          - name: customer_id
            tests:
              - unique
              - not_null
          
          - name: email
            tests:
              - not_null
      
      - name: raw_orders
        columns:
          - name: order_id
            tests:
              - unique
              - not_null
          
          - name: customer_id
            tests:
              - not_null
              - relationships:
                  to: source('raw_retail', 'raw_customers')
                  field: customer_id
```

### Staging (100%)

Tous les modèles staging ont des tests de base.

```yaml
# models/staging/_staging_models.yml
version: 2

models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
      
      - name: customer_email
        tests:
          - not_null
      
      - name: customer_segment
        tests:
          - accepted_values:
              values: ['premium', 'standard', 'vip']
  
  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      
      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_customers')
              field: customer_id
      
      - name: total_amount
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      
      - name: order_status
        tests:
          - accepted_values:
              values: ['completed', 'cancelled', 'pending', 'refunded']
```

### Intermediate (100%)

Tests sur les colonnes clés et la logique métier.

```yaml
# models/intermediate/customer/_intermediate_customer.yml
version: 2

models:
  - name: int_customer_lifetime_value
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
      
      - name: lifetime_value
        tests:
          - not_null
          - positive_values
      
      - name: avg_order_value
        tests:
          - not_null
          - positive_values
      
      - name: total_orders
        tests:
          - not_null
          - positive_values
      
      - name: customer_tenure_days
        tests:
          - not_null
          - positive_values
  
  - name: int_campaign_attributed_orders
    columns:
      - name: order_id
        tests:
          - not_null
          - test_no_duplicate_orders  # Test custom
      
      - name: net_amount
        tests:
          - not_null
          - positive_values
      
      - name: cost_attribution
        tests:
          - positive_values
```

### Marts (100%)

Tests complets sur tous les marts.

```yaml
# models/marts/mart_test_values.yml
version: 2

models:
  - name: mart_sales_daily
    columns:
      - name: date_day
        tests:
          - not_null
      
      - name: total_revenue
        tests:
          - not_null
          - positive_values
      
      - name: net_revenue
        tests:
          - not_null
          - positive_values
    
    tests:
      - revenue_consistency  # Test singulier
  
  - name: mart_campaign_performance
    columns:
      - name: campaign_id
        tests:
          - unique
          - not_null
      
      - name: total_revenue
        tests:
          - not_null
          - positive_values
      
      - name: total_profit
        tests:
          - not_null
          - positive_values
      
      - name: roi_percentage
        tests:
          - not_null
          - positive_values
```

---

## Tests par couche

### Tests Sources

**Objectif** : Valider la qualité des données brutes

**Tests appliqués** :
- Unicité des clés primaires
- Non-nullité des champs critiques
- Intégrité référentielle

**Exemple** :
```yaml
sources:
  - name: raw_retail
    tables:
      - name: raw_customers
        tests:
          - dbt_utils.recency:
              datepart: day
              field: registration_date
              interval: 1
        
        columns:
          - name: customer_id
            tests:
              - unique
              - not_null
```

### Tests Staging

Valider le nettoyage et la standardisation.

Tests appliqués :
- Unicité et non-nullité
- Valeurs acceptées
- Relations entre tables
- Formats de données

Exemple :
```yaml
models:
  - name: stg_orders
    tests:
      - dbt_utils.expression_is_true:
          expression: "total_amount >= shipping_cost"
    
    columns:
      - name: order_channel
        tests:
          - accepted_values:
              values: ['web', 'mobile', 'store']
```

### Tests Intermediate

Valider la logique métier.

Tests appliqués :
- Cohérence des calculs
- Validité des agrégations
- Logique métier spécifique

Exemple :
```yaml
models:
  - name: int_customer_lifetime_value
    tests:
      - dbt_utils.expression_is_true:
          expression: "lifetime_value = web_revenue + mobile_revenue"
```

### Tests Marts

Valider les données finales pour la BI.

Tests appliqués :
- Tous les tests précédents
- Tests de cohérence inter-tables
- Tests de performance

Exemple :
```yaml
models:
  - name: mart_sales_daily
    tests:
      - revenue_consistency
      - no_future_dates
```

---

## Tests personnalisés

### Tests génériques réutilisables

#### 1. test_positive_values

```sql
-- macros/test_positive_values.sql
{% test positive_values(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0

{% endtest %}
```

Utilisation :
```yaml
columns:
  - name: total_revenue
    tests:
      - positive_values
```

#### 2. test_no_duplicate_orders

```sql
-- macros/test_no_duplicate_orders.sql
{% test no_duplicate_orders(model, column_name) %}

SELECT {{ column_name }}
FROM {{ model }}
GROUP BY {{ column_name }}
HAVING COUNT(*) > 1

{% endtest %}
```

Utilisation :
```yaml
columns:
  - name: order_id
    tests:
      - no_duplicate_orders
```

### Tests singuliers spécifiques

#### 1. Test de cohérence des revenus

```sql
-- tests/singular/test_revenue_consistency.sql
WITH revenue_check AS (
    SELECT
        date_day,
        total_revenue,
        web_revenue + mobile_revenue + store_revenue AS channel_sum
    FROM {{ ref('mart_sales_daily') }}
)

SELECT *
FROM revenue_check
WHERE ABS(total_revenue - channel_sum) > 0.01
```

#### 2. Test de dates futures

```sql
-- tests/singular/test_no_future_dates.sql
SELECT *
FROM {{ ref('mart_sales_daily') }}
WHERE date_day > CURRENT_DATE
```

#### 3. Test de cohérence RFM

```sql
-- tests/singular/test_rfm_scores_valid.sql
SELECT *
FROM {{ ref('mart_customer_segments') }}
WHERE recency_score NOT BETWEEN 1 AND 5
   OR frequency_score NOT BETWEEN 1 AND 5
   OR monetary_score NOT BETWEEN 1 AND 5
```

---

## Exécution des tests

### Commandes de base

```bash
# Tous les tests
dbt test

# Tests d'un modèle spécifique
dbt test --select mart_sales_daily

# Tests d'une couche
dbt test --select staging
dbt test --select intermediate
dbt test --select marts

# Tests par type
dbt test --select test_type:generic
dbt test --select test_type:singular

# Tests d'une source
dbt test --select source:raw_retail
```

### Tests avec sélection avancée

```bash
# Tests d'un modèle et ses dépendances
dbt test --select +mart_customer_segments

# Tests d'un modèle et ses descendants
dbt test --select stg_customers+

# Tests par tag
dbt test --select tag:customer

# Tests qui ont échoué lors du dernier run
dbt test --select result:fail
```

### Options utiles

```bash
# Stocker les échecs pour investigation
dbt test --store-failures

# Exécuter en parallèle
dbt test --threads 4

# Mode fail-fast (arrêter au premier échec)
dbt test --fail-fast

# Logs détaillés
dbt test --debug
```

---

## CI/CD

### GitHub Actions

```yaml
# .github/workflows/dbt_test.yml
name: dbt Tests

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dbt
        run: |
          pip install dbt-snowflake
      
      - name: Run dbt tests
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: |
          dbt deps
          dbt test --profiles-dir .
```

### Stratégie de tests en CI

1. Pull Request :
   - Tests sur modèles modifiés uniquement
   - Tests rapides (< 5 min)

2. Merge to develop :
   - Tests complets sur tous les modèles
   - Tests de performance

3. Déploiement production :
   - Tests complets
   - Tests de smoke (vérifications post-déploiement)

---

## Bonnes pratiques

### 1. Tester tôt et souvent

- Ajouter des tests dès la création du modèle
- Exécuter les tests localement avant de commit
- Ne pas attendre la CI pour découvrir les erreurs

### 2. Tests significatifs

Exemple de test spécifique :
```yaml
- name: total_revenue
  tests:
    - not_null
    - positive_values
    - dbt_utils.expression_is_true:
        expression: ">= net_revenue"
```

### 3. Documenter les tests

```yaml
models:
  - name: mart_sales_daily
    tests:
      - name: revenue_consistency
        description: |
          Vérifie que le revenu total est égal à la somme
          des revenus par canal (web + mobile + store).
          Tolérance de 1 centime pour les arrondis.
```

### 4. Gérer les échecs

```bash
# Stocker les échecs pour investigation
dbt test --store-failures

# Inspecter les échecs dans Snowflake
SELECT * FROM dbt_test__audit.not_null_stg_customers_customer_id
```

### 5. Performance des tests

- Limiter les tests coûteux
- Utiliser des échantillons pour les tests de développement
- Optimiser les requêtes de test

Test optimisé :
```sql
SELECT customer_id
FROM {{ model }}
GROUP BY customer_id
HAVING COUNT(*) > 1
LIMIT 100  -- Limiter pour la performance
```

### 6. Tests en environnement de développement

```bash
# Utiliser un échantillon pour les tests rapides
dbt test --select stg_customers --vars '{"limit_data": true}'
```

Dans le modèle :
```sql
SELECT *
FROM {{ source('raw_retail', 'raw_customers') }}
{% if var('limit_data', false) %}
LIMIT 1000
{% endif %}
```

---

## Métriques de qualité

### Suivi de la couverture

| Métrique | Objectif | Actuel |
|----------|----------|--------|
| % modèles avec tests | 100% | 100% |
| % colonnes clés testées | 90% | 95% |
| Temps d'exécution tests | < 10 min | 8 min |
| Taux de réussite | 100% | 100% |

### Reporting

```bash
# Générer un rapport de tests
dbt test --store-failures

# Analyser les résultats
dbt show --select result:fail
```

---

Dernière mise à jour : Janvier 2026
