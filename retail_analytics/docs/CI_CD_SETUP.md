# Configuration CI/CD - Retail Analytics

## Vue d'ensemble

Configuration CI/CD complète pour le projet Retail Analytics utilisant GitHub Actions et Snowflake.

## Workflows configurés

### 1. CI - Tests automatiques (`ci.yml`)

**Déclenchement** : Pull Request vers `dev` ou `main`

**Actions** :
- Installation de dbt et dépendances
- Compilation des modèles
- Exécution des modèles modifiés
- Tests sur les modèles modifiés
- Génération de la documentation
- Nettoyage du schéma CI

**Durée estimée** : 5-10 minutes

### 2. Deploy to Dev (`deploy-dev.yml`)

**Déclenchement** : Push sur la branche `dev`

**Actions** :
- Déploiement complet en environnement dev
- Exécution de tous les modèles
- Tests complets
- Génération de la documentation
- Sauvegarde des artefacts

**Durée estimée** : 10-15 minutes

### 3. Deploy to Production (`deploy-prod.yml`)

**Déclenchement** : Push sur la branche `main`

**Actions** :
- Backup de l'état actuel
- Déploiement en production
- Tests complets
- Smoke tests
- Création d'un tag de déploiement
- Sauvegarde des artefacts

**Durée estimée** : 15-20 minutes

### 4. Scheduled Run (`scheduled-run.yml`)

**Déclenchement** : 
- Quotidien à 6h00 UTC
- Manuel via workflow_dispatch

**Actions** :
- Refresh des modèles incrémentaux
- Full refresh hebdomadaire (dimanche)
- Tests
- Sauvegarde des résultats

**Durée estimée** : 10-15 minutes

## Configuration requise

### 1. Secrets GitHub

Configurer les secrets suivants dans GitHub :
Settings → Secrets and variables → Actions → New repository secret

```
SNOWFLAKE_ACCOUNT=your-account.region
SNOWFLAKE_USER=dbt_service_user
SNOWFLAKE_PASSWORD=your-secure-password
SNOWFLAKE_ROLE=DBT_ROLE
SNOWFLAKE_DATABASE=RETAIL_DB
SNOWFLAKE_WAREHOUSE=DBT_WH
```

### 2. Environnements GitHub

Créer les environnements suivants :
Settings → Environments → New environment

**dev** :
- Pas de protection requise
- Déploiement automatique

**production** :
- Protection requise
- Reviewers requis (optionnel)
- Déploiement avec approbation

### 3. Permissions Snowflake

Créer un utilisateur de service avec les permissions nécessaires :

```sql
-- Créer le rôle
CREATE ROLE DBT_ROLE;

-- Permissions sur la base de données
GRANT USAGE ON DATABASE RETAIL_DB TO ROLE DBT_ROLE;
GRANT CREATE SCHEMA ON DATABASE RETAIL_DB TO ROLE DBT_ROLE;

-- Permissions sur les schémas
GRANT ALL ON SCHEMA RETAIL_DB.dbt_dev TO ROLE DBT_ROLE;
GRANT ALL ON SCHEMA RETAIL_DB.dbt_prod TO ROLE DBT_ROLE;
GRANT ALL ON SCHEMA RETAIL_DB.raw_retail TO ROLE DBT_ROLE;

-- Permissions sur le warehouse
GRANT USAGE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;

-- Créer l'utilisateur de service
CREATE USER dbt_service_user
  PASSWORD = 'your-secure-password'
  DEFAULT_ROLE = DBT_ROLE
  DEFAULT_WAREHOUSE = DBT_WH;

-- Assigner le rôle
GRANT ROLE DBT_ROLE TO USER dbt_service_user;
```

## Workflow de développement

### Développement de nouvelles fonctionnalités

1. Créer une branche depuis `dev` :
```bash
git checkout dev
git pull origin dev
git checkout -b feature/nouvelle-fonctionnalite
```

2. Développer et tester localement :
```bash
dbt run --select +mon_modele
dbt test --select +mon_modele
```

3. Commit et push :
```bash
git add .
git commit -m "feat: ajout de nouvelle fonctionnalité"
git push origin feature/nouvelle-fonctionnalite
```

4. Créer une Pull Request vers `dev`
   - Les tests CI s'exécutent automatiquement
   - Vérifier que tous les tests passent
   - Demander une review

5. Après approbation, merger vers `dev`
   - Le déploiement en dev s'exécute automatiquement

6. Tester en environnement dev

7. Créer une Pull Request de `dev` vers `main`
   - Les tests CI s'exécutent à nouveau
   - Review requise

8. Merger vers `main`
   - Le déploiement en production s'exécute automatiquement

## Monitoring

### Vérifier l'état des workflows

1. Aller sur GitHub → Actions
2. Voir l'historique des exécutions
3. Consulter les logs détaillés

### Artefacts disponibles

Chaque déploiement sauvegarde :
- `manifest.json` : État complet du projet
- `catalog.json` : Métadonnées des tables
- `run_results.json` : Résultats d'exécution

Télécharger depuis : Actions → Workflow run → Artifacts

## Rollback

### En cas de problème en production

1. Identifier le dernier tag stable :
```bash
git tag -l "prod-*"
```

2. Créer une branche de rollback :
```bash
git checkout -b rollback/prod-issue tags/prod-20240126-120000
```

3. Push vers main :
```bash
git push origin rollback/prod-issue:main --force
```

4. Le déploiement automatique restaurera l'état précédent

### Rollback manuel

```bash
# Se connecter à Snowflake
snowsql -a your-account -u dbt_service_user

# Restaurer depuis le backup
USE DATABASE RETAIL_DB;
USE SCHEMA dbt_prod_backup;

-- Copier les tables depuis le backup
CREATE OR REPLACE TABLE dbt_prod.mart_sales_daily 
AS SELECT * FROM dbt_prod_backup.mart_sales_daily;
```

## Dépannage

### Les tests CI échouent

1. Vérifier les logs dans GitHub Actions
2. Reproduire localement :
```bash
dbt compile
dbt run --select state:modified+
dbt test --select state:modified+
```

### Problème de connexion Snowflake

1. Vérifier les secrets GitHub
2. Tester la connexion :
```bash
dbt debug --target prod
```

### Timeout des workflows

1. Augmenter la taille du warehouse
2. Optimiser les modèles lents
3. Utiliser des modèles incrémentaux

## Bonnes pratiques

1. **Toujours tester localement** avant de push
2. **Commits atomiques** : un changement = un commit
3. **Messages de commit clairs** : suivre conventional commits
4. **Reviews obligatoires** pour la production
5. **Monitoring régulier** des workflows
6. **Documentation à jour** des changements

## Améliorations futures

- [ ] Notifications Slack sur échec
- [ ] Tests de performance automatisés
- [ ] Déploiement blue/green
- [ ] Métriques de qualité des données
- [ ] Dashboard de monitoring
- [ ] Alertes sur anomalies de données

---

Dernière mise à jour : Janvier 2026
