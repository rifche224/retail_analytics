# Changelog

Ce fichier documente les changements notables du projet.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Versioning selon [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]

### En développement
- Modèle de prédiction du churn client
- Analyse de panier de marché
- Recommandations produits

## [1.0.0] - 2026-01-26

### Ajouté
- Documentation complète du projet
  - README.md avec vue d'ensemble et architecture
  - ARCHITECTURE.md avec détails techniques
  - DATA_DICTIONARY.md avec toutes les tables et colonnes
  - DEVELOPMENT_GUIDE.md avec standards de code
  - TESTING_STRATEGY.md avec stratégie de tests
  - DEPLOYMENT.md avec processus de déploiement

- Refactoring Jinja pour éviter la duplication
  - `int_customer_lifetime_value.sql` avec boucles pour les canaux
  - `int_customer_first_purchase.sql` avec boucles pour les canaux
  - `mart_sales_daily.sql` avec boucles pour les canaux

- Correction du modèle `mart_sales_by_region`
  - Jointure corrigée (stg_orders au lieu de mart_sales_daily)
  - Filtrage sur order_status = 'completed'
  - Calcul correct des ventes par pays et par mois

### Modifié
- Performance de `mart_sales_daily` améliorée
- Maintenabilité du code avec patterns réutilisables

### Corrigé
- Bug de jointure dans `mart_sales_by_region`
- Erreurs de syntaxe dans les modèles refactorisés

## [0.9.0] - 2026-01-20

### Ajouté
- Modèles Intermediate
  - `int_customers_orders` pour jointure clients-commandes
  - `int_campaign_attributed_orders` pour attribution marketing

- Tests personnalisés
  - `test_positive_values` pour validation des valeurs
  - `test_no_duplicate_orders` pour détection de doublons

- Modèle `mart_customer_retention_cohort` pour analyse de cohorte

### Modifié
- Standardisation des modèles staging
- Documentation YAML améliorée

## [0.8.0] - 2026-01-15

### Ajouté
- Modèles staging
  - `stg_inventory` pour données d'inventaire
  - `stg_marketing_campaigns` pour campagnes marketing

- Modèle `int_campaign_attributed_orders` pour attribution

### Modifié
- Optimisation des requêtes staging
- Tests de qualité supplémentaires

## [0.7.0] - 2026-01-10

### Ajouté
- Modèles Marts
  - `mart_customer_segments` pour segmentation RFM
  - `mart_campaign_performance` pour performance marketing
  - `mart_product_catalog` pour catalogue enrichi

- Modèles Intermediate
  - `int_customer_first_purchase` pour première commande
  - `int_customer_lifetime_value` pour métriques client
  - `int_product_performance` pour performance produits

### Modifié
- Structure des schémas Snowflake améliorée
- Matérialisations optimisées

## [0.6.0] - 2026-01-05

### Ajouté
- Modèle `mart_sales_daily` avec métriques quotidiennes
- Matérialisation incrémentale pour performance
- Macro `cents_to_euros` pour conversion monétaire

### Modifié
- Configuration des schémas par couche
- Tags pour sélection des modèles

## [0.5.0] - 2025-12-20

### Ajouté
- Modèles staging
  - `stg_customers`, `stg_orders`, `stg_order_items`
  - `stg_products`, `stg_web_event`

- Tests de sources
  - Tests d'unicité et non-nullité
  - Tests de relations entre tables

### Modifié
- Noms de colonnes standardisés (snake_case)
- Colonnes `_dbt_loaded_at` pour traçabilité

## [0.4.0] - 2025-12-15

### Ajouté
- Configuration dbt
  - `dbt_project.yml` et `packages.yml`
  - Structure des dossiers

- Sources Snowflake
  - 7 tables sources définies
  - Configuration dans `_staging_sources.yml`

### Modifié
- Profils multi-environnements (dev, stg, prod)

## [0.3.0] - 2025-12-10

### Ajouté
- Infrastructure Snowflake
  - Base de données `RETAIL_DB`
  - Schémas (raw_retail, staging, intermediate, marts)
  - Warehouses (DEV_WH, STG_WH, PROD_WH)
  - Rôles et permissions

### Modifié
- Tailles de warehouses optimisées

## [0.2.0] - 2025-12-05

### Ajouté
- Données de test synthétiques
- Scripts de chargement Snowflake

### Modifié
- Qualité des données de test améliorée

## [0.1.0] - 2025-12-01

### Ajouté
- Initialisation du projet
- Structure de base du repository
- README initial
- Configuration Git (.gitignore)
- Licence MIT

---

## Types de changements

- `Ajouté` - Nouvelles fonctionnalités
- `Modifié` - Changements dans les fonctionnalités existantes
- `Déprécié` - Fonctionnalités bientôt supprimées
- `Supprimé` - Fonctionnalités supprimées
- `Corrigé` - Corrections de bugs
- `Sécurité` - Corrections de vulnérabilités

---

Versioning : [Semantic Versioning](https://semver.org/lang/fr/)
- MAJOR : Changements incompatibles
- MINOR : Nouvelles fonctionnalités compatibles
- PATCH : Corrections de bugs
