# Guide de Développement - Retail Analytics

## Table des matières

- [Configuration de l'environnement](#configuration-de-lenvironnement)
- [Workflow de développement](#workflow-de-développement)
- [Standards de code](#standards-de-code)
- [Conventions de nommage](#conventions-de-nommage)
- [Tests](#tests)
- [Documentation](#documentation)
- [Revue de code](#revue-de-code)
- [Débogage](#débogage)

---

## Configuration de l'environnement

### Prérequis

- Python 3.8+
- Git
- Accès Snowflake
- IDE recommandé : VSCode avec extensions dbt

### Installation initiale

1. **Cloner le repository**
```bash
git clone <repository-url>
cd retail_analytics
```

2. **Créer un environnement virtuel**
```bash
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

3. **Installer les dépendances**
```bash
pip install dbt-snowflake
dbt deps
```

4. **Configurer les credentials**

Créer `~/.dbt/profiles.yml` :
```yaml
retail_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      database: RETAIL_DB
      warehouse: COMPUTE_WH
      schema: dbt_dev
      threads: 4
```

5. **Variables d'environnement**

Créer un fichier `.env` :
```bash
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_USER="your-username"
export SNOWFLAKE_PASSWORD="your-password"
export SNOWFLAKE_ROLE="your-role"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="RETAIL_DB"
export SNOWFLAKE_SCHEMA="dbt_dev"
```

Charger les variables :
```bash
source .env
```

6. **Tester la connexion**
```bash
dbt debug
```

---

## Workflow de développement

### 1. Créer une branche feature

```bash
# Mettre à jour main/develop
git checkout develop
git pull origin develop

# Créer une nouvelle branche
git checkout -b feature/nom-de-la-feature
```

### Convention de nommage des branches

- `feature/` : Nouvelles fonctionnalités
- `fix/` : Corrections de bugs
- `refactor/` : Refactoring de code
- `docs/` : Mise à jour de documentation
- `test/` : Ajout de tests

Exemples :
- `feature/add-customer-churn-model`
- `fix/correct-revenue-calculation`
- `refactor/optimize-sales-daily`

### 2. Développer le modèle

#### Créer un nouveau modèle

```bash
# Créer le fichier SQL
touch models/marts/customer/mart_customer_churn.sql
```

#### Structure du modèle

```sql
{{
    config(
        materialized='table',
        schema='marts_customer',
        tags=['marts', 'customer', 'churn']
    )
}}

{%- set important_features = ['recency', 'frequency', 'monetary'] -%}

WITH customer_metrics AS (
    SELECT * FROM {{ ref('int_customer_lifetime_value') }}
),

churn_indicators AS (
    SELECT
        customer_id,
        
        -- Utiliser des boucles Jinja pour éviter la duplication
        {% for feature in important_features %}
        {{ feature }}_score,
        {% endfor %}
        
        CASE
            WHEN recency_days > 90 THEN 1
            ELSE 0
        END AS is_churned
        
    FROM customer_metrics
)

SELECT * FROM churn_indicators
```

### 3. Tester localement

```bash
# Compiler le modèle
dbt compile --select mart_customer_churn

# Exécuter le modèle
dbt run --select mart_customer_churn

# Tester le modèle
dbt test --select mart_customer_churn
```

### 4. Documenter

Créer/mettre à jour le fichier YAML :

```yaml
# models/marts/customer/_marts_customer.yml
version: 2

models:
  - name: mart_customer_churn
    description: >
      Modèle de prédiction du churn client basé sur les métriques RFM.
      Un client est considéré comme churné s'il n'a pas commandé depuis 90 jours.
    
    columns:
      - name: customer_id
        description: Identifiant unique du client
        tests:
          - unique
          - not_null
      
      - name: is_churned
        description: Indicateur de churn (1 = churné, 0 = actif)
        tests:
          - not_null
          - accepted_values:
              values: [0, 1]
      
      - name: recency_score
        description: Score de récence (1-5, 5 = très récent)
        tests:
          - not_null
          - accepted_values:
              values: [1, 2, 3, 4, 5]
```

### 5. Commit et Push

```bash
# Ajouter les fichiers
git add models/marts/customer/mart_customer_churn.sql
git add models/marts/customer/_marts_customer.yml

# Commit avec un message descriptif
git commit -m "feat(customer): add customer churn prediction model

- Add mart_customer_churn model
- Include RFM-based churn indicators
- Add tests for data quality
- Document model and columns"

# Push vers le repository
git push origin feature/add-customer-churn-model
```

### 6. Créer une Pull Request

1. Aller sur GitHub/GitLab
2. Créer une Pull Request de `feature/add-customer-churn-model` vers `develop`
3. Remplir le template de PR :

```markdown
## Description
Ajout d'un modèle de prédiction du churn client basé sur les métriques RFM.

## Type de changement
- [x] Nouvelle fonctionnalité
- [ ] Correction de bug
- [ ] Refactoring
- [ ] Documentation

## Checklist
- [x] Code testé localement
- [x] Tests ajoutés
- [x] Documentation mise à jour
- [x] dbt compile sans erreur
- [x] dbt test passe

## Modèles affectés
- Nouveau : `mart_customer_churn`
- Dépendances : `int_customer_lifetime_value`

## Captures d'écran / Résultats
[Ajouter des captures d'écran si pertinent]
```

---

## Standards de code

### SQL

#### Formatage

```sql
-- ✅ BON
SELECT
    customer_id,
    order_date,
    SUM(net_amount) AS total_revenue
FROM {{ ref('stg_orders') }}
WHERE order_status = 'completed'
GROUP BY 1, 2
ORDER BY order_date DESC

-- ❌ MAUVAIS
select customer_id,order_date,sum(net_amount) as total_revenue from {{ ref('stg_orders') }} where order_status='completed' group by 1,2 order by order_date desc
```

#### Conventions

1. **Mots-clés SQL en MAJUSCULES**
```sql
SELECT, FROM, WHERE, GROUP BY, ORDER BY
```

2. **Noms de colonnes en snake_case**
```sql
customer_id, order_date, total_revenue
```

3. **Indentation de 4 espaces**
```sql
SELECT
    column1,
    column2
FROM table
WHERE condition
```

4. **CTEs pour la lisibilité**
Exemple avec CTEs :
```sql
WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
)
SELECT
    o.order_id,
    c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
```

5. **Commentaires explicites**
```sql
-- Calculer le revenu total par client
-- en excluant les commandes annulées
SELECT
    customer_id,
    SUM(net_amount) AS total_revenue  -- Revenu hors frais de livraison
FROM {{ ref('stg_orders') }}
WHERE order_status != 'cancelled'
GROUP BY customer_id
```

### Jinja

#### Utiliser des boucles pour éviter la duplication

Éviter la duplication avec des boucles :
```sql
{%- set order_channels = ['web', 'mobile', 'store'] -%}

SELECT
    date_day,
    {% for channel in order_channels %}
    SUM(CASE WHEN order_channel = '{{ channel }}' THEN net_amount ELSE 0 END) AS {{ channel }}_revenue
    {%- if not loop.last %},{% endif %}
    {% endfor %}
FROM {{ ref('stg_orders') }}
GROUP BY date_day
```

#### Macros pour la logique réutilisable

```sql
-- macros/cents_to_euros.sql
{% macro cents_to_euros(column_name) %}
    (COALESCE({{ column_name }}, 0) / 100.0) * 0.85
{% endmacro %}

-- Utilisation
SELECT
    {{ cents_to_euros('total_amount_cents') }} AS total_amount
FROM {{ source('raw_retail', 'raw_orders') }}
```

---

## Conventions de nommage

### Modèles

| Type | Préfixe | Exemple |
|------|---------|---------|
| Staging | `stg_` | `stg_customers` |
| Intermediate | `int_` | `int_customer_lifetime_value` |
| Mart | `mart_` | `mart_sales_daily` |

### Colonnes

- **IDs** : `{entity}_id` (ex: `customer_id`, `order_id`)
- **Dates** : `{entity}_date` (ex: `order_date`, `registration_date`)
- **Montants** : `{description}_amount` (ex: `total_amount`, `net_amount`)
- **Booléens** : `is_{condition}` (ex: `is_churned`, `is_active`)
- **Compteurs** : `total_{entity}` ou `{entity}_count` (ex: `total_orders`)

### Fichiers

- **Modèles SQL** : `{prefix}_{entity}.sql`
- **Documentation** : `_{layer}_{domain}.yml`
- **Tests** : `test_{description}.sql`
- **Macros** : `{function_name}.sql`

---

## Tests

### Types de tests

#### 1. Tests génériques (built-in)

```yaml
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
```

#### 2. Tests de relations

```yaml
models:
  - name: stg_orders
    columns:
      - name: customer_id
        tests:
          - relationships:
              to: ref('stg_customers')
              field: customer_id
```

#### 3. Tests personnalisés

Créer un test générique :

```sql
-- tests/generic/test_positive_values.sql
{% test positive_values(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0

{% endtest %}
```

Utiliser le test :

```yaml
models:
  - name: mart_sales_daily
    columns:
      - name: total_revenue
        tests:
          - positive_values
```

#### 4. Tests singuliers

```sql
-- tests/singular/test_revenue_consistency.sql
-- Vérifier que le revenu total = somme des revenus par canal

WITH daily_totals AS (
    SELECT
        date_day,
        total_revenue,
        web_revenue + mobile_revenue + store_revenue AS channel_sum
    FROM {{ ref('mart_sales_daily') }}
)

SELECT *
FROM daily_totals
WHERE ABS(total_revenue - channel_sum) > 0.01
```

### Exécuter les tests

```bash
# Tous les tests
dbt test

# Tests d'un modèle spécifique
dbt test --select mart_sales_daily

# Tests par type
dbt test --select test_type:generic
dbt test --select test_type:singular

# Tests d'une source
dbt test --select source:raw_retail
```

---

## Documentation

### Documentation inline

```sql
{{
    config(
        materialized='table',
        schema='marts_customer'
    )
}}

-- Ce modèle calcule les métriques de segmentation RFM
-- pour identifier les clients à forte valeur

WITH customer_metrics AS (
    -- Récupérer les métriques de base
    SELECT * FROM {{ ref('int_customer_lifetime_value') }}
),

rfm_scores AS (
    -- Calculer les scores RFM (1-5)
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY total_orders) AS frequency_score,
        NTILE(5) OVER (ORDER BY lifetime_value) AS monetary_score
    FROM customer_metrics
)

SELECT * FROM rfm_scores
```

### Documentation YAML

```yaml
version: 2

models:
  - name: mart_customer_segments
    description: |
      # Segmentation RFM des clients
      
      Ce modèle segmente les clients selon la méthodologie RFM :
      - **Recency** : Récence de la dernière commande
      - **Frequency** : Fréquence des commandes
      - **Monetary** : Valeur monétaire totale
      
      ## Segments
      - Champions : R=5, F=5, M=5
      - Loyal Customers : R=4-5, F=4-5, M=4-5
      - At Risk : R=2-3, F=3-4, M=3-4
      - Lost : R=1, F=1-2, M=1-2
      
      ## Utilisation
      Ce modèle est utilisé pour :
      - Ciblage marketing personnalisé
      - Priorisation du service client
      - Analyse de la valeur client
    
    meta:
      owner: "data-team@company.com"
      refresh_frequency: "daily"
    
    columns:
      - name: customer_id
        description: Identifiant unique du client
        tests:
          - unique
          - not_null
      
      - name: rfm_score
        description: |
          Score RFM combiné (format: R-F-M)
          Exemple: "5-5-5" pour un champion
```

### Générer la documentation

```bash
# Générer la documentation
dbt docs generate

# Servir localement
dbt docs serve
```

---

## Revue de code

### Checklist du reviewer

- Code suit les standards
- Noms clairs et descriptifs
- Logique commentée si complexe
- Tests présents et pertinents
- Documentation complète
- Pas de duplication
- Performances optimales
- Dépendances correctes

### Checklist de l'auteur

Avant de soumettre une PR :
- `dbt compile` passe
- `dbt run --select {model}` réussit
- `dbt test --select {model}` passe
- Documentation YAML à jour
- Commit message descriptif
- Branche à jour avec develop

---

## Débogage

### Erreurs courantes

#### 1. Erreur de compilation

```bash
# Voir le SQL compilé
dbt compile --select model_name

# Vérifier le fichier compilé
cat target/compiled/retail_analytics/models/path/to/model.sql
```

#### 2. Erreur d'exécution

```bash
# Exécuter avec logs détaillés
dbt run --select model_name --debug

# Voir les logs
cat logs/dbt.log
```

#### 3. Tests qui échouent

```bash
# Voir les résultats des tests
dbt test --select model_name --store-failures

# Inspecter les échecs dans Snowflake
SELECT * FROM dbt_test__audit.{test_name}
```

### Outils de débogage

#### 1. dbt compile

Compile le code Jinja en SQL pur :

```bash
dbt compile --select model_name
```

#### 2. dbt run-operation

Exécuter une macro directement :

```bash
dbt run-operation {macro_name} --args '{arg1: value1}'
```

#### 3. Logs

```bash
# Logs détaillés
dbt run --debug

# Logs dans un fichier
dbt run --debug > debug.log 2>&1
```

---

## Bonnes pratiques

### 1. Commencer simple

- Créer d'abord une version simple qui fonctionne
- Optimiser ensuite si nécessaire
- Ne pas sur-ingénierer

### 2. Tester fréquemment

- Tester après chaque changement significatif
- Ne pas attendre la fin pour tester
- Utiliser `dbt run --select {model}` régulièrement

### 3. Documenter au fur et à mesure

- Documenter pendant le développement
- Ne pas attendre la fin
- La documentation aide à clarifier la logique

### 4. Demander de l'aide

- Poser des questions tôt
- Partager les blocages
- Collaborer avec l'équipe

---

Dernière mise à jour : Janvier 2026
