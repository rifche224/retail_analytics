# Dictionnaire de Données - Retail Analytics

## Vue d'ensemble

Documentation complète des tables, colonnes et métriques du projet.

## Table des matières

- [Sources](#sources)
- [Staging](#staging)
- [Intermediate](#intermediate)
- [Marts](#marts)
- [Métriques clés](#métriques-clés)

---

## Sources

### raw_customers

Informations clients brutes.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `customer_id` | INTEGER | Identifiant unique du client | PK, NOT NULL |
| `email` | VARCHAR | Email du client | NOT NULL, UNIQUE |
| `first_name` | VARCHAR | Prénom | |
| `last_name` | VARCHAR | Nom | |
| `country` | VARCHAR | Pays de résidence | |
| `registration_date` | TIMESTAMP | Date d'inscription | |
| `customer_segment` | VARCHAR | Segment client (premium, standard, vip) | |

### raw_orders

Commandes brutes.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `order_id` | INTEGER | Identifiant unique de la commande | PK, NOT NULL |
| `customer_id` | INTEGER | Référence au client | FK, NOT NULL |
| `order_date` | TIMESTAMP | Date de la commande | NOT NULL |
| `order_channel` | VARCHAR | Canal (web, mobile, store) | |
| `order_status` | VARCHAR | Statut (completed, cancelled, pending, refunded) | |
| `total_amount_cents` | INTEGER | Montant total en centimes | |
| `shipping_cost_cents` | INTEGER | Frais de livraison en centimes | |

### raw_order_items

Lignes de commande brutes.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `item_id` | INTEGER | Identifiant unique de la ligne | PK, NOT NULL |
| `order_id` | INTEGER | Référence à la commande | FK, NOT NULL |
| `product_id` | INTEGER | Référence au produit | FK, NOT NULL |
| `quantity` | INTEGER | Quantité commandée | |
| `unit_price_cents` | INTEGER | Prix unitaire en centimes | |

### raw_products

Produits bruts.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `product_id` | INTEGER | Identifiant unique du produit | PK, NOT NULL |
| `product_name` | VARCHAR | Nom du produit | |
| `category` | VARCHAR | Catégorie principale | |
| `sub_category` | VARCHAR | Sous-catégorie | |
| `brand` | VARCHAR | Marque | |
| `cost_price_cents` | INTEGER | Prix de revient en centimes | |
| `retail_price_cents` | INTEGER | Prix de vente en centimes | |

### raw_inventory

Inventaire brut.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `inventory_id` | INTEGER | Identifiant unique | PK |
| `product_id` | INTEGER | Référence au produit | FK |
| `warehouse_location` | VARCHAR | Localisation de l'entrepôt | |
| `quantity_on_hand` | INTEGER | Quantité en stock | |
| `last_updated` | TIMESTAMP | Dernière mise à jour | |

### raw_marketing_campaigns

Campagnes marketing brutes.

| Colonne | Type | Description | Contraintes |
|---------|------|-------------|-------------|
| `campaign_id` | INTEGER | Identifiant unique de la campagne | PK |
| `campaign_name` | VARCHAR | Nom de la campagne | |
| `campaign_type` | VARCHAR | Type (email, social, display) | |
| `start_date` | DATE | Date de début | |
| `end_date` | DATE | Date de fin | |
| `budget_cents` | INTEGER | Budget en centimes | |

---

## Staging

### stg_customers

Clients nettoyés et standardisés.

| Colonne | Type | Description | Transformation |
|---------|------|-------------|----------------|
| `customer_id` | INTEGER | ID client | Aucune |
| `customer_email` | VARCHAR | Email | Renommé de `email` |
| `first_name` | VARCHAR | Prénom | Aucune |
| `last_name` | VARCHAR | Nom | Aucune |
| `full_name` | VARCHAR | Nom complet | `CONCAT(first_name, ' ', last_name)` |
| `country` | VARCHAR | Pays | Aucune |
| `customer_registration_date` | DATE | Date d'inscription | Cast en DATE |
| `customer_segment` | VARCHAR | Segment | `LOWER(customer_segment)` |
| `_dbt_loaded_at` | TIMESTAMP | Timestamp de chargement | `CURRENT_TIMESTAMP` |

Tests :
- `customer_id` - unique, not_null
- `customer_email` - not_null
- `customer_segment` - accepted_values (premium, standard, vip)

### stg_orders

Commandes nettoyées et standardisées.

| Colonne | Type | Description | Transformation |
|---------|------|-------------|----------------|
| `order_id` | INTEGER | ID commande | Aucune |
| `customer_id` | INTEGER | ID client | Aucune |
| `order_date` | DATE | Date commande | Cast en DATE |
| `order_channel` | VARCHAR | Canal | `LOWER(order_channel)` |
| `order_status` | VARCHAR | Statut | `LOWER(order_status)` |
| `total_amount` | DECIMAL | Montant total en € | `cents_to_euros(total_amount_cents)` |
| `shipping_cost` | DECIMAL | Frais livraison en € | `cents_to_euros(shipping_cost_cents)` |
| `net_amount` | DECIMAL | Montant net en € | `total_amount - shipping_cost` |
| `_dbt_loaded_at` | TIMESTAMP | Timestamp de chargement | `CURRENT_TIMESTAMP` |

Macro utilisée :
```sql
{% macro cents_to_euros(column_name) %}
    (COALESCE({{ column_name }}, 0) / 100.0) * 0.85
{% endmacro %}
```

Tests :
- `order_id` - unique, not_null
- `customer_id` - not_null, relationships (stg_customers)
- `total_amount` - positive_values
- `order_status` - accepted_values (completed, cancelled, pending, refunded)

### stg_order_items

Lignes de commande nettoyées.

| Colonne | Type | Description | Transformation |
|---------|------|-------------|----------------|
| `item_id` | INTEGER | ID ligne | Aucune |
| `order_id` | INTEGER | ID commande | Aucune |
| `product_id` | INTEGER | ID produit | Aucune |
| `quantity` | INTEGER | Quantité | Aucune |
| `unit_price` | DECIMAL | Prix unitaire en € | `cents_to_euros(unit_price_cents)` |
| `line_total` | DECIMAL | Total ligne en € | `unit_price * quantity` |
| `_dbt_loaded_at` | TIMESTAMP | Timestamp de chargement | `CURRENT_TIMESTAMP` |

Tests :
- `item_id` - unique, not_null
- `order_id` - relationships (stg_orders)
- `product_id` - relationships (stg_products)

### stg_products

Produits nettoyés et enrichis.

| Colonne | Type | Description | Transformation |
|---------|------|-------------|----------------|
| `product_id` | INTEGER | ID produit | Aucune |
| `product_name` | VARCHAR | Nom produit | Aucune |
| `category` | VARCHAR | Catégorie | Aucune |
| `sub_category` | VARCHAR | Sous-catégorie | Aucune |
| `brand` | VARCHAR | Marque | Aucune |
| `cost_price` | DECIMAL | Prix de revient en € | `cents_to_euros(cost_price_cents)` |
| `retail_price` | DECIMAL | Prix de vente en € | `cents_to_euros(retail_price_cents)` |
| `margin_per_unit` | DECIMAL | Marge unitaire en € | `retail_price - cost_price` |
| `margin_percentage` | DECIMAL | Marge en % | `((retail_price - cost_price) / retail_price) * 100` |
| `_dbt_loaded_at` | TIMESTAMP | Timestamp de chargement | `CURRENT_TIMESTAMP` |

Tests :
- `product_id` - unique, not_null

---

## Intermediate

### int_customers_orders

Jointure clients-commandes avec enrichissements.

| Colonne | Type | Description | Source |
|---------|------|-------------|--------|
| `customer_id` | INTEGER | ID client | stg_customers |
| `order_id` | INTEGER | ID commande | stg_orders |
| `order_date` | DATE | Date commande | stg_orders |
| `order_channel` | VARCHAR | Canal | stg_orders |
| `order_status` | VARCHAR | Statut | stg_orders |
| `net_amount` | DECIMAL | Montant net | stg_orders |
| `customer_segment` | VARCHAR | Segment client | stg_customers |
| `country` | VARCHAR | Pays | stg_customers |

Tests :
- `customer_id` - not_null

### int_customer_lifetime_value

Métriques de valeur vie client.

| Colonne | Type | Description | Calcul |
|---------|------|-------------|--------|
| `customer_id` | INTEGER | ID client | - |
| `total_orders` | INTEGER | Nombre total de commandes | `COUNT(DISTINCT order_id)` |
| `web_orders` | INTEGER | Commandes web | `COUNT(DISTINCT CASE WHEN order_channel = 'web' THEN order_id END)` |
| `mobile_orders` | INTEGER | Commandes mobile | `COUNT(DISTINCT CASE WHEN order_channel = 'mobile' THEN order_id END)` |
| `lifetime_value` | DECIMAL | Valeur vie client | `SUM(net_amount)` |
| `avg_order_value` | DECIMAL | Panier moyen | `AVG(net_amount)` |
| `web_revenue` | DECIMAL | Revenu web | `SUM(CASE WHEN order_channel = 'web' THEN net_amount ELSE 0 END)` |
| `mobile_revenue` | DECIMAL | Revenu mobile | `SUM(CASE WHEN order_channel = 'mobile' THEN net_amount ELSE 0 END)` |
| `first_order_date` | DATE | Date première commande | `MIN(order_date)` |
| `last_order_date` | DATE | Date dernière commande | `MAX(order_date)` |
| `customer_tenure_days` | INTEGER | Ancienneté en jours | `DATEDIFF('day', first_order_date, last_order_date)` |

Tests :
- `customer_id` - unique, not_null
- `lifetime_value` - positive_values
- `avg_order_value` - positive_values
- `total_orders` - positive_values

### int_customer_first_purchase

Première commande par canal.

| Colonne | Type | Description | Calcul |
|---------|------|-------------|--------|
| `customer_id` | INTEGER | ID client | - |
| `first_order_date` | DATE | Date première commande globale | `MIN(order_date)` |
| `first_web_order_date` | DATE | Date première commande web | `MIN(CASE WHEN order_channel = 'web' THEN order_date END)` |
| `first_mobile_order_date` | DATE | Date première commande mobile | `MIN(CASE WHEN order_channel = 'mobile' THEN order_date END)` |

### int_campaign_attributed_orders

Attribution des commandes aux campagnes marketing.

| Colonne | Type | Description | Logique |
|---------|------|-------------|---------|
| `order_id` | INTEGER | ID commande | - |
| `campaign_id` | INTEGER | ID campagne | Attribution basée sur la fenêtre temporelle |
| `order_date` | DATE | Date commande | - |
| `net_amount` | DECIMAL | Montant net | - |
| `campaign_cost` | DECIMAL | Coût campagne | - |
| `cost_attribution` | DECIMAL | Coût attribué | `campaign_cost / nombre_commandes_attribuées` |

Tests :
- `order_id` - not_null, no_duplicate_orders
- `net_amount` - not_null, positive_values
- `cost_attribution` - positive_values

---

## Marts

### mart_sales_daily

Métriques de ventes quotidiennes par canal.

| Colonne | Type | Description | Agrégation |
|---------|------|-------------|------------|
| `date_day` | DATE | Date | - |
| `total_orders` | INTEGER | Nombre total de commandes | `COUNT(DISTINCT order_id)` |
| `unique_customers` | INTEGER | Clients uniques | `COUNT(DISTINCT customer_id)` |
| `web_orders` | INTEGER | Commandes web | Agrégation par canal |
| `mobile_orders` | INTEGER | Commandes mobile | Agrégation par canal |
| `store_orders` | INTEGER | Commandes magasin | Agrégation par canal |
| `total_revenue` | DECIMAL | Revenu total | `SUM(total_amount)` |
| `net_revenue` | DECIMAL | Revenu net | `SUM(net_amount)` |
| `total_shipping_revenue` | DECIMAL | Revenu livraison | `SUM(shipping_cost)` |
| `avg_order_value` | DECIMAL | Panier moyen | `AVG(net_amount)` |
| `web_revenue` | DECIMAL | Revenu web | Agrégation par canal |
| `mobile_revenue` | DECIMAL | Revenu mobile | Agrégation par canal |
| `store_revenue` | DECIMAL | Revenu magasin | Agrégation par canal |
| `_dbt_updated_at` | TIMESTAMP | Dernière mise à jour | `CURRENT_TIMESTAMP` |

Matérialisation : `incremental` (unique_key: `date_day`)

Tests :
- `date_day` - not_null
- `total_revenue` - not_null, positive_values
- `net_revenue` - not_null, positive_values

Cas d'usage :
- Tableaux de bord de performance quotidienne
- Analyse des tendances de ventes
- Comparaison des canaux

### mart_sales_by_region

Ventes agrégées par région (pays) et mois.

| Colonne | Type | Description | Agrégation |
|---------|------|-------------|------------|
| `region` | VARCHAR | Pays du client | - |
| `sales_month` | DATE | Mois de vente | `DATE_TRUNC('month', order_date)` |
| `total_sales` | DECIMAL | Ventes totales | `SUM(total_amount)` |
| `total_orders` | INTEGER | Nombre de commandes | `COUNT(DISTINCT order_id)` |
| `_dbt_updated_at` | TIMESTAMP | Dernière mise à jour | `CURRENT_TIMESTAMP` |

Matérialisation : `incremental` (unique_key: `['region', 'sales_month']`)

Cas d'usage :
- Analyse géographique des ventes
- Identification des marchés performants
- Planification régionale

### mart_customer_segments

Segmentation RFM des clients.

| Colonne | Type | Description | Calcul |
|---------|------|-------------|--------|
| `customer_id` | INTEGER | ID client | - |
| `recency_days` | INTEGER | Jours depuis dernière commande | `DATEDIFF('day', last_order_date, CURRENT_DATE)` |
| `frequency` | INTEGER | Nombre de commandes | `total_orders` |
| `monetary_value` | DECIMAL | Valeur totale | `lifetime_value` |
| `rfm_score` | VARCHAR | Score RFM | Combinaison R, F, M |
| `customer_segment` | VARCHAR | Segment | Champions, Loyal, At Risk, Lost |

Segments :
- Champions - R=5, F=5, M=5
- Loyal Customers - R=4-5, F=4-5, M=4-5
- Potential Loyalists - R=4-5, F=2-3, M=2-3
- At Risk - R=2-3, F=3-4, M=3-4
- Lost Customers - R=1, F=1-2, M=1-2

### mart_customer_retention_cohort

Analyse de cohorte pour la rétention client.

| Colonne | Type | Description |
|---------|------|-------------|
| `cohort_month` | DATE | Mois de la cohorte (première commande) |
| `period_number` | INTEGER | Numéro de période depuis la cohorte |
| `customers_in_cohort` | INTEGER | Nombre de clients dans la cohorte |
| `active_customers` | INTEGER | Clients actifs dans la période |
| `retention_rate` | DECIMAL | Taux de rétention (%) |

### mart_campaign_performance

Performance des campagnes marketing.

| Colonne | Type | Description | Calcul |
|---------|------|-------------|--------|
| `campaign_id` | INTEGER | ID campagne | - |
| `campaign_name` | VARCHAR | Nom campagne | - |
| `campaign_type` | VARCHAR | Type campagne | - |
| `total_attributed_orders` | INTEGER | Commandes attribuées | `COUNT(DISTINCT order_id)` |
| `total_revenue` | DECIMAL | Revenu généré | `SUM(net_amount)` |
| `total_cost` | DECIMAL | Coût total | `SUM(campaign_cost)` |
| `total_profit` | DECIMAL | Profit | `total_revenue - total_cost` |
| `roi_percentage` | DECIMAL | ROI en % | `((total_revenue - total_cost) / total_cost) * 100` |

Tests :
- `campaign_id` - unique, not_null
- `total_revenue` - not_null, positive_values
- `total_profit` - not_null, positive_values
- `roi_percentage` - not_null, positive_values

### mart_product_catalog

Catalogue produits enrichi avec métriques de performance.

| Colonne | Type | Description |
|---------|------|-------------|
| `product_id` | INTEGER | ID produit |
| `product_name` | VARCHAR | Nom produit |
| `category` | VARCHAR | Catégorie |
| `sub_category` | VARCHAR | Sous-catégorie |
| `brand` | VARCHAR | Marque |
| `retail_price` | DECIMAL | Prix de vente |
| `margin_percentage` | DECIMAL | Marge en % |
| `total_quantity_sold` | INTEGER | Quantité totale vendue |
| `total_revenue` | DECIMAL | Revenu total généré |
| `avg_quantity_per_order` | DECIMAL | Quantité moyenne par commande |

---

## Métriques clés

### Métriques de vente

| Métrique | Définition | Formule |
|----------|------------|---------|
| **Total Revenue** | Revenu total incluant livraison | `SUM(total_amount)` |
| **Net Revenue** | Revenu hors frais de livraison | `SUM(net_amount)` |
| **Average Order Value (AOV)** | Panier moyen | `SUM(net_amount) / COUNT(DISTINCT order_id)` |
| **Orders per Customer** | Commandes par client | `COUNT(DISTINCT order_id) / COUNT(DISTINCT customer_id)` |

### Métriques client

| Métrique | Définition | Formule |
|----------|------------|---------|
| **Customer Lifetime Value (CLV)** | Valeur vie client | `SUM(net_amount) par customer_id` |
| **Customer Acquisition Cost (CAC)** | Coût d'acquisition | `Total marketing cost / New customers` |
| **Retention Rate** | Taux de rétention | `(Customers retained / Total customers) * 100` |
| **Churn Rate** | Taux d'attrition | `(Customers lost / Total customers) * 100` |

### Métriques marketing

| Métrique | Définition | Formule |
|----------|------------|---------|
| **Return on Investment (ROI)** | Retour sur investissement | `((Revenue - Cost) / Cost) * 100` |
| **Cost Per Acquisition (CPA)** | Coût par acquisition | `Campaign cost / Attributed orders` |
| **Conversion Rate** | Taux de conversion | `(Orders / Visits) * 100` |

### Métriques produit

| Métrique | Définition | Formule |
|----------|------------|---------|
| **Margin Percentage** | Marge en % | `((Retail price - Cost price) / Retail price) * 100` |
| **Inventory Turnover** | Rotation des stocks | `Units sold / Average inventory` |
| **Sell-Through Rate** | Taux d'écoulement | `(Units sold / Units received) * 100` |

---

Dernière mise à jour : Janvier 2026
