# Retail Analytics

Projet d'analyse de données e-commerce construit avec dbt et Snowflake. J'ai voulu structurer une pipeline de transformation de données propre en utilisant l'architecture médaillon (Bronze/Silver/Gold).

## C'est quoi ce projet ?

J'avais besoin d'analyser des données de ventes pour un contexte retail : commandes, clients, produits, campagnes marketing. Au lieu de faire des requêtes SQL dispersées, j'ai construit une vraie pipeline dbt avec :

- Segmentation client (RFM, lifetime value, cohortes de rétention)
- Analyse des ventes par région et canal
- Performance produits avec calculs de marges
- Attribution des campagnes marketing aux commandes

## Architecture

Le projet suit une architecture en trois couches :

**Staging (Bronze)** → Nettoyage des données brutes de Snowflake. Standardisation des noms de colonnes, typage, conversions basiques. Tout est en views parce que c'est juste de la transformation 1:1.

**Intermediate (Silver)** → C'est là que la vraie logique métier commence. Calculs de métriques clients (CLV, première commande), agrégation des performances produits, attribution marketing. Toujours en views pour garder ça flexible.

**Marts (Gold)** → Les tables finales prêtes pour le reporting. Matérialisées en tables parce qu'elles sont coûteuses à calculer et utilisées fréquemment. Organisées par domaine : core, customer, product, marketing.

## Installation

Vous avez besoin de Python 3.8+ et d'un compte Snowflake.

```bash
# Cloner et installer
git clone <repository-url>
cd retail_analytics
pip install dbt-snowflake
dbt deps
```

Configurez vos credentials Snowflake dans `~/.dbt/profiles.yml` :

```yaml
retail_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <votre-account>
      user: <votre-username>
      password: <votre-password>
      role: <votre-role>
      database: RETAIL_DB
      warehouse: COMPUTE_WH
      schema: dbt_dev
      threads: 4
```

Puis testez que tout fonctionne :

```bash
dbt debug
dbt run
dbt test
```

## Structure

```
models/
├── staging/              # Données brutes nettoyées
│   ├── stg_customers.sql
│   ├── stg_orders.sql
│   ├── stg_order_items.sql
│   ├── stg_products.sql
│   ├── stg_inventory.sql
│   ├── stg_marketing_campaigns.sql
│   └── stg_web_event.sql
│
├── intermediate/         # Calculs et enrichissements
│   ├── customer/
│   │   ├── int_customer_first_purchase.sql
│   │   ├── int_customer_lifetime_value.sql
│   │   └── int_customers_orders.sql
│   ├── product/
│   │   └── int_product_performance.sql
│   └── marketing/
│       └── int_campaign_attributed_orders.sql
│
└── marts/                # Tables finales
    ├── core/
    │   ├── mart_sales_daily.sql
    │   └── mart_sales_by_region.sql
    ├── customer/
    │   ├── mart_customer_segments.sql
    │   └── mart_customer_retention_cohort.sql
    ├── product/
    │   └── mart_product_catalog.sql
    └── marketing/
        └── mart_campaign_performance.sql

macros/                   # Fonctions réutilisables
├── cents_to_euros.sql
├── test_positive_values.sql
└── test_no_duplicate_orders.sql

docs/                     # Documentation technique détaillée
```

## Principaux modèles

**mart_sales_daily** - Ventes quotidiennes par canal (web, mobile, store). Utile pour les dashboards de suivi quotidien.

**mart_sales_by_region** - Agrégation mensuelle par pays. Pour comprendre quelles régions performent.

**mart_customer_segments** - Segmentation RFM (Recency, Frequency, Monetary). Je classe les clients en Champions, Loyal, At Risk, Lost, etc.

**mart_customer_retention_cohort** - Analyse de cohortes pour voir comment les clients reviennent acheter au fil du temps.

**mart_campaign_performance** - Attribution des commandes aux campagnes marketing. J'utilise une logique de "last touch" basée sur les événements web.

**mart_product_catalog** - Catalogue enrichi avec les métriques de vente, marges, et performance par produit.

## Documentation

Tous les modèles sont documentés avec dbt. Pour générer et consulter la doc interactive :

```bash
dbt docs generate
dbt docs serve  # http://localhost:8080
```

J'ai aussi écrit quelques docs plus détaillées dans le dossier `docs/` sur l'architecture, le dictionnaire de données, et la stratégie de tests.

## Tests

J'ai mis en place plusieurs types de tests :

- Tests génériques dbt (unique, not_null, relationships)
- Tests personnalisés (valeurs positives, pas de doublons de commandes)
- Tests de relations entre tables (foreign keys)

Tous les modèles ont au minimum des tests sur les clés primaires. Les modèles marts ont des tests supplémentaires sur les métriques calculées.

```bash
dbt test
dbt test --select staging        # Tests d'une couche spécifique
dbt test --select mart_sales_daily  # Tests d'un modèle
```

## Conventions

Je suis les conventions dbt standards :
- `stg_<table>` pour staging
- `int_<domaine>_<description>` pour intermediate
- `mart_<domaine>_<description>` pour les marts

Les modèles staging sont en views, les marts en tables incrémentales quand ça a du sens (comme `mart_sales_daily`).

## Ressources utiles

- [dbt documentation](https://docs.getdbt.com/)
- [dbt best practices](https://docs.getdbt.com/guides/best-practices)
- Consultez le dossier `docs/` pour plus de détails techniques

---

*Cherif Amanatoulha SY - Data Engineer Analyst*
*Projet sous licence MIT*
