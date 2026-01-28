# Architecture du Projet Retail Analytics

## Vue d'ensemble

Architecture technique du projet Retail Analytics basée sur dbt et Snowflake, suivant le pattern médaillon (Lakehouse).

## Table des matières

- [Principes architecturaux](#principes-architecturaux)
- [Architecture médaillon](#architecture-médaillon)
- [Flux de données](#flux-de-données)
- [Modèles de matérialisation](#modèles-de-matérialisation)
- [Stratégie de nommage](#stratégie-de-nommage)
- [Gestion des dépendances](#gestion-des-dépendances)
- [Performance et optimisation](#performance-et-optimisation)

## Principes architecturaux

### 1. Séparation des couches

Trois couches distinctes :
- **Bronze (Staging)** - Nettoyage et standardisation
- **Silver (Intermediate)** - Logique métier et enrichissements
- **Gold (Marts)** - Tables analytiques pour la BI

### 2. Modularité

- Un modèle = Une transformation
- Réutilisation via `{{ ref() }}`
- Macros pour logique partagée

### 3. Testabilité

- Tests de schéma sur les sources
- Tests de qualité sur les modèles
- Tests personnalisés pour la logique métier

### 4. Documentation

- Documentation inline
- Métadonnées YAML
- Génération automatique avec `dbt docs`

## Architecture médaillon

### Couche Bronze (Staging)

Nettoyage et standardisation des données brutes.

Caractéristiques :
- Matérialisation : `view`
- Schéma : `staging`
- Transformations simples
- Renommage et typage
- Filtrage des données invalides

**Modèles** :
```
staging/
├── stg_customers.sql          # Clients
├── stg_orders.sql             # Commandes
├── stg_order_items.sql        # Lignes de commande
├── stg_products.sql           # Produits
├── stg_inventory.sql          # Inventaire
├── stg_marketing_campaigns.sql # Campagnes marketing
└── stg_web_event.sql          # Événements web
```

Exemple :
```sql
SELECT
    customer_id,
    email AS customer_email,
    lower(customer_segment) AS customer_segment,
    registration_date::date AS customer_registration_date
FROM {{ source('raw_retail', 'raw_customers') }}
WHERE customer_id IS NOT NULL
  AND email IS NOT NULL
```

### Couche Silver (Intermediate)

Logique métier et agrégations intermédiaires.

Caractéristiques :
- Matérialisation : `view`
- Schéma : `intermediate`
- Jointures complexes
- Calculs métier
- Enrichissements

**Organisation par domaine** :
```
intermediate/
├── customer/
│   ├── int_customer_first_purchase.sql    # Première commande par client
│   ├── int_customer_lifetime_value.sql    # LTV et métriques client
│   └── int_customers_orders.sql           # Jointure clients-commandes
├── product/
│   └── int_product_performance.sql        # Performance produits
└── marketing/
    └── int_campaign_attributed_orders.sql # Attribution marketing
```

Exemple :
```sql
WITH customer_orders AS (
    SELECT * FROM {{ ref('int_customers_orders') }}
)
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(net_amount) AS lifetime_value,
    AVG(net_amount) AS avg_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM customer_orders
GROUP BY customer_id
```

### Couche Gold (Marts)

Tables finales optimisées pour l'analyse.

Caractéristiques :
- Matérialisation : `table` ou `incremental`
- Schémas par domaine
- Dénormalisées pour performance
- Prêtes pour la BI

**Organisation par domaine** :
```
marts/
├── core/
│   ├── mart_sales_daily.sql           # Ventes quotidiennes
│   └── mart_sales_by_region.sql       # Ventes par région
├── customer/
│   ├── mart_customer_segments.sql     # Segmentation RFM
│   └── mart_customer_retention_cohort.sql # Analyse de cohorte
├── product/
│   └── mart_product_catalog.sql       # Catalogue enrichi
└── marketing/
    └── mart_campaign_performance.sql  # Performance campagnes
```

## Flux de données

### Diagramme de flux

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCES SNOWFLAKE                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │raw_      │  │raw_      │  │raw_      │  │raw_      │   │
│  │customers │  │orders    │  │products  │  │campaigns │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   BRONZE LAYER (Staging)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │stg_      │  │stg_      │  │stg_      │  │stg_      │   │
│  │customers │  │orders    │  │products  │  │campaigns │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│  Nettoyage, standardisation, typage                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 SILVER LAYER (Intermediate)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │int_customer_ │  │int_product_  │  │int_campaign_ │      │
│  │lifetime_value│  │performance   │  │attributed    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  Jointures, calculs métier, enrichissements                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GOLD LAYER (Marts)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │mart_sales_   │  │mart_customer_│  │mart_campaign_│      │
│  │daily         │  │segments      │  │performance   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  Tables dénormalisées, optimisées pour BI                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  Outils BI    │
                    │  (Tableau,    │
                    │   Looker...)  │
                    └───────────────┘
```

### Ordre d'exécution

1. Sources - Validation des données brutes
2. Staging - Nettoyage et standardisation
3. Intermediate - Logique métier
4. Marts - Agrégations finales

## Modèles de matérialisation

### Views (Staging & Intermediate)

Avantages :
- Toujours à jour
- Pas de stockage supplémentaire
- Facile à maintenir

Inconvénients :
- Performance variable
- Recalculé à chaque requête

Utilisation :
```sql
{{ config(materialized='view') }}
```

### Tables (Marts)

Avantages :
- Performance optimale
- Données persistées
- Indexation possible

Inconvénients :
- Stockage supplémentaire
- Nécessite des refreshes

Utilisation :
```sql
{{ config(materialized='table') }}
```

### Incremental (Marts avec historique)

Avantages :
- Performance sur gros volumes
- Traite uniquement les nouvelles données
- Historique complet

Configuration :
```sql
{{
    config(
        materialized='incremental',
        unique_key='date_day',
        on_schema_change='append_new_columns'
    )
}}

SELECT ...
FROM {{ ref('stg_orders') }}
{% if is_incremental() %}
WHERE order_date >= (SELECT MAX(date_day) FROM {{ this }})
{% endif %}
```

## Stratégie de nommage

### Conventions

| Type | Préfixe | Exemple |
|------|---------|---------|
| Source | `raw_` | `raw_customers` |
| Staging | `stg_` | `stg_customers` |
| Intermediate | `int_` | `int_customer_lifetime_value` |
| Mart | `mart_` | `mart_sales_daily` |
| Test | `test_` | `test_positive_values` |
| Macro | - | `cents_to_euros` |

### Schémas Snowflake

| Couche | Schéma | Exemple complet |
|--------|--------|-----------------|
| Source | `raw_retail` | `RETAIL_DB.raw_retail.raw_customers` |
| Staging | `staging` | `RETAIL_DB.dbt_dev_staging.stg_customers` |
| Intermediate | `intermediate` | `RETAIL_DB.dbt_dev_intermediate.int_customer_lifetime_value` |
| Marts Core | `marts_core` | `RETAIL_DB.dbt_dev_marts_core.mart_sales_daily` |
| Marts Customer | `marts_customer` | `RETAIL_DB.dbt_dev_marts_customer.mart_customer_segments` |

## Gestion des dépendances

### Graphe de dépendances (DAG)

dbt construit le graphe automatiquement via `{{ ref() }}` :

```
stg_customers ─┐
               ├─→ int_customers_orders ─→ int_customer_lifetime_value ─→ mart_customer_segments
stg_orders ────┘                                                        └─→ mart_customer_retention_cohort
```

### Sélection de modèles

```bash
# Exécuter un modèle et ses dépendances
dbt run --select +mart_customer_segments

# Exécuter un modèle et ses descendants
dbt run --select stg_customers+

# Exécuter par tag
dbt run --select tag:customer

# Exécuter par couche
dbt run --select staging
dbt run --select intermediate
dbt run --select marts
```

## Performance et optimisation

### 1. Clustering

Clustering Snowflake pour grandes tables :

```sql
{{
    config(
        materialized='table',
        cluster_by=['date_day', 'region']
    )
}}
```

### 2. Partitionnement temporel

Modèles incrémentaux pour données temporelles :

```sql
{{
    config(
        materialized='incremental',
        unique_key='date_day'
    )
}}
```

### 3. Optimisation des jointures

- Filtrer avant de joindre
- Utiliser les CTEs pour la lisibilité
- Éviter les jointures cartésiennes

### 4. Gestion de la mémoire

- Limiter les `SELECT *`
- Sélectionner uniquement les colonnes nécessaires
- Utiliser `DISTINCT` avec parcimonie

### 5. Monitoring

```bash
# Voir les temps d'exécution
dbt run --profiles-dir . --profile retail_analytics

# Analyser les performances
dbt compile --profiles-dir .
```

## Sécurité et gouvernance

### 1. Contrôle d'accès

- Schémas par environnement (dev, prod)
- Rôles Snowflake dédiés
- Permissions granulaires

### 2. Qualité des données

- Tests sur les sources
- Tests de qualité sur modèles clés
- Alertes sur échecs

### 3. Audit et traçabilité

- Colonnes `_dbt_loaded_at` et `_dbt_updated_at`
- Logs conservés
- Historique des runs

## Évolution et maintenance

### Ajout d'un nouveau modèle

1. Créer le fichier SQL dans le bon dossier
2. Ajouter la documentation YAML
3. Ajouter les tests
4. Exécuter et valider
5. Documenter les changements

### Modification d'un modèle existant

1. Créer une branche feature
2. Modifier le modèle
3. Tester localement
4. Mettre à jour la documentation
5. Pull Request et review
6. Merge et déploiement

### Dépréciation d'un modèle

1. Marquer comme deprecated dans la doc
2. Notifier les utilisateurs
3. Période de transition
4. Suppression du modèle

---

Dernière mise à jour : Janvier 2026
