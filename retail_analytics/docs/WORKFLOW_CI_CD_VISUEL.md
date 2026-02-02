# 🎨 Visualisation des workflows CI/CD

## 🔄 Vue d'ensemble du flux de travail

```
┌─────────────────────────────────────────────────────────────────┐
│                    DÉVELOPPEMENT LOCAL                           │
│                                                                  │
│  1. Créer une branche feature                                   │
│  2. Développer les modèles dbt                                  │
│  3. Tester localement (dbt run, dbt test)                       │
│  4. Commit et push                                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PULL REQUEST → dev                            │
│                                                                  │
│  ⚡ DÉCLENCHE : ci.yml (Tests automatiques)                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │  🔧 Installation (Python, dbt, packages)         │          │
│  │  🔐 Configuration Snowflake (secrets)            │          │
│  │  🗄️  Création schéma temporaire: dbt_ci_pr_123  │          │
│  │  ✅ Compilation des modèles                      │          │
│  │  🏃 Exécution des modèles                        │          │
│  │  🧪 Tests dbt                                    │          │
│  │  📚 Génération documentation                     │          │
│  │  🧹 Nettoyage du schéma temporaire               │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ✅ Tous les tests passent → Prêt à merger                     │
│  ❌ Tests échouent → Corriger et re-push                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ MERGE
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BRANCHE dev                                   │
│                                                                  │
│  ⚡ DÉCLENCHE : deploy-dev.yml (Déploiement Dev)               │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │  🔧 Installation (Python, dbt, packages)         │          │
│  │  🔐 Configuration Snowflake (environnement dev)  │          │
│  │  🗄️  Schéma: dbt_dev (permanent)                │          │
│  │  🏃 Exécution de TOUS les modèles                │          │
│  │  🧪 Tests complets                               │          │
│  │  📚 Génération documentation                     │          │
│  │  💾 Sauvegarde artefacts                         │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ✅ Déploiement réussi en DEV                                  │
│  🔍 Vérification manuelle dans Snowflake                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ Validation OK
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PULL REQUEST → main                           │
│                                                                  │
│  ⚡ DÉCLENCHE : ci.yml (Tests automatiques)                     │
│  (même processus que pour dev)                                  │
│                                                                  │
│  ✅ Tous les tests passent → Prêt à merger en PROD             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ MERGE (avec approbation si configuré)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BRANCHE main (PRODUCTION)                     │
│                                                                  │
│  ⚡ DÉCLENCHE : deploy-prod.yml (Déploiement Production)       │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │  🔧 Installation (Python, dbt, packages)         │          │
│  │  🔐 Configuration Snowflake (environnement prod) │          │
│  │  💾 Backup de l'état actuel                      │          │
│  │  🗄️  Schéma: dbt_prod (permanent)               │          │
│  │  🏃 Exécution de TOUS les modèles                │          │
│  │  🧪 Tests complets                               │          │
│  │  🔥 Smoke tests (tests critiques)                │          │
│  │  📚 Génération documentation                     │          │
│  │  🏷️  Création tag: prod-20240202-143000         │          │
│  │  💾 Sauvegarde artefacts (90 jours)              │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ✅ Déploiement réussi en PRODUCTION                           │
└─────────────────────────────────────────────────────────────────┘
                      │
                      │ Tous les jours à 6h00 UTC
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXÉCUTION PLANIFIÉE                           │
│                                                                  │
│  ⚡ DÉCLENCHE : scheduled-run.yml (Refresh quotidien)          │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │  🔧 Installation (Python, dbt, packages)         │          │
│  │  🔐 Configuration Snowflake (environnement prod) │          │
│  │  🏃 Exécution modèles incrémentaux (quotidien)   │          │
│  │  🔄 Full refresh (dimanche uniquement)           │          │
│  │  🧪 Tests                                        │          │
│  │  💾 Sauvegarde résultats                         │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ✅ Données rafraîchies automatiquement                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Schémas Snowflake utilisés

```
┌─────────────────────────────────────────────────────────────────┐
│                    SNOWFLAKE DATABASE: RETAIL_DB                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📁 raw_retail (Données sources)                                │
│     ├── customers                                               │
│     ├── orders                                                  │
│     ├── order_items                                             │
│     ├── products                                                │
│     ├── inventory                                               │
│     ├── marketing_campaigns                                     │
│     └── web_events                                              │
│                                                                  │
│  📁 dbt_ci_pr_123 (Temporaire - Tests CI)                       │
│     ├── stg_customers                                           │
│     ├── stg_orders                                              │
│     ├── int_customer_lifetime_value                             │
│     ├── mart_sales_daily                                        │
│     └── ... (tous les modèles)                                  │
│     ⚠️  Supprimé automatiquement après les tests                │
│                                                                  │
│  📁 dbt_dev (Environnement de développement)                    │
│     ├── stg_customers                                           │
│     ├── stg_orders                                              │
│     ├── int_customer_lifetime_value                             │
│     ├── mart_sales_daily                                        │
│     └── ... (tous les modèles)                                  │
│     ✅ Permanent - Mis à jour à chaque push sur dev             │
│                                                                  │
│  📁 dbt_prod (Production)                                       │
│     ├── stg_customers                                           │
│     ├── stg_orders                                              │
│     ├── int_customer_lifetime_value                             │
│     ├── mart_sales_daily                                        │
│     └── ... (tous les modèles)                                  │
│     ✅ Permanent - Mis à jour à chaque push sur main            │
│     ✅ Rafraîchi quotidiennement à 6h00 UTC                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Comparaison des workflows

| Workflow | Déclencheur | Schéma | Durée | Objectif |
|----------|-------------|--------|-------|----------|
| **ci.yml** | Pull Request | `dbt_ci_pr_<num>` | 5-10 min | Tester avant merge |
| **deploy-dev.yml** | Push sur `dev` | `dbt_dev` | 10-15 min | Déployer en dev |
| **deploy-prod.yml** | Push sur `main` | `dbt_prod` | 15-20 min | Déployer en prod |
| **scheduled-run.yml** | Quotidien 6h UTC | `dbt_prod` | 10-15 min | Rafraîchir données |

---

## 🔐 Secrets utilisés

Tous les workflows utilisent les mêmes secrets GitHub :

```yaml
secrets:
  SNOWFLAKE_ACCOUNT: "xy12345.us-east-1"
  SNOWFLAKE_USER: "dbt_service_user"
  SNOWFLAKE_PASSWORD: "***********"
  SNOWFLAKE_ROLE: "DBT_ROLE"
  SNOWFLAKE_DATABASE: "RETAIL_DB"
  SNOWFLAKE_WAREHOUSE: "DBT_WH"
```

Ces secrets sont configurés dans :
**Settings → Secrets and variables → Actions**

---

## 🎬 Exemple de scénario complet

### Jour 1 : Développement d'une nouvelle fonctionnalité

```
09:00 - Créer branche feature/new-metric
        git checkout -b feature/new-metric

10:00 - Développer le modèle
        models/marts/customer/mart_customer_churn.sql

11:00 - Tester localement
        dbt run --select mart_customer_churn
        dbt test --select mart_customer_churn

12:00 - Push et créer PR vers dev
        git push origin feature/new-metric
        → CI se déclenche automatiquement ⚡

12:05 - CI en cours...
        ✅ Compilation OK
        ✅ Exécution OK
        ✅ Tests OK
        → Tous les checks passent ✅

14:00 - Review et merge vers dev
        → deploy-dev.yml se déclenche ⚡

14:10 - Déploiement en dev terminé
        → Vérification dans Snowflake (schéma dbt_dev)

15:00 - Tests manuels en dev
        → Tout fonctionne ✅
```

### Jour 2 : Mise en production

```
09:00 - Créer PR de dev vers main
        → CI se déclenche automatiquement ⚡

09:05 - CI en cours...
        ✅ Tous les checks passent

10:00 - Review et approbation
        → Merge vers main
        → deploy-prod.yml se déclenche ⚡

10:15 - Déploiement en production terminé
        ✅ Backup créé
        ✅ Modèles déployés
        ✅ Tests passés
        ✅ Tag créé: prod-20240202-101500

11:00 - Vérification en production
        → Tout fonctionne ✅
```

### Jour 3 et suivants : Automatisation

```
06:00 UTC - Exécution automatique quotidienne
            → scheduled-run.yml se déclenche ⚡
            → Rafraîchissement des données incrémentales
            → Tests automatiques
            ✅ Données à jour pour la journée
```

---

## 🚨 Gestion des erreurs

### Si le CI échoue ❌

```
Pull Request
    ↓
CI se déclenche
    ↓
❌ Tests échouent
    ↓
1. Lire les logs d'erreur
2. Corriger le code localement
3. Commit et push
    ↓
CI se re-déclenche automatiquement
    ↓
✅ Tests passent
    ↓
Merge autorisé
```

### Si le déploiement prod échoue ❌

```
Merge vers main
    ↓
deploy-prod.yml se déclenche
    ↓
❌ Déploiement échoue
    ↓
1. Vérifier les logs
2. Option A: Fix forward (corriger et re-déployer)
3. Option B: Rollback (revenir au tag précédent)
    ↓
git checkout tags/prod-20240201-120000
git push origin main --force
    ↓
✅ État précédent restauré
```

---

## 📈 Métriques de succès

### Indicateurs à surveiller

- ✅ **Taux de succès CI** : % de PR qui passent du premier coup
- ✅ **Temps de déploiement** : Durée moyenne des workflows
- ✅ **Fréquence de déploiement** : Nombre de déploiements par semaine
- ✅ **Taux d'échec prod** : % de déploiements qui échouent
- ✅ **Temps de récupération** : Temps pour corriger un problème

### Objectifs

- 🎯 Taux de succès CI > 80%
- 🎯 Temps de déploiement < 15 minutes
- 🎯 Déploiements quotidiens en dev
- 🎯 Déploiements hebdomadaires en prod
- 🎯 Temps de récupération < 1 heure

---

*Ce document est un guide visuel pour comprendre le flux CI/CD de votre projet.*
