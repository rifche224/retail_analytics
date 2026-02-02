# Guide de Déploiement - Retail Analytics

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Environnements](#environnements)
- [Processus de déploiement](#processus-de-déploiement)
- [CI/CD](#cicd)
- [Rollback](#rollback)
- [Monitoring](#monitoring)
- [Checklist de déploiement](#checklist-de-déploiement)

---

## Vue d'ensemble

Processus de déploiement du projet Retail Analytics du développement vers la production.

### Principes

1. Automatisation via CI/CD
2. Tests complets avant déploiement
3. Rollback rapide possible
4. Logs et historique complets
5. Validation et approbation requises

---

## Environnements

### 1. Développement (dev)

Développement et tests individuels.

Configuration :
```yaml
# profiles.yml
retail_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: DEVELOPER
      database: RETAIL_DB
      warehouse: DEV_WH
      schema: dbt_dev
      threads: 4
```

Caractéristiques :
- Schéma personnel : `dbt_dev_{username}`
- Warehouse : `DEV_WH` (X-Small)
- Données limitées (échantillons)
- Refresh à la demande

### 2. Staging (stg)

Tests d'intégration et validation.

Configuration :
```yaml
    stg:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: DEVELOPER
      database: RETAIL_DB
      warehouse: STG_WH
      schema: dbt_stg
      threads: 8
```

Caractéristiques :
- Schéma partagé : `dbt_stg`
- Warehouse : `STG_WH` (Small)
- Données complètes (copie de production)
- Refresh quotidien

### 3. Production (prod)

Environnement de production.

Configuration :
```yaml
    prod:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_SERVICE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_SERVICE_PASSWORD') }}"
      role: TRANSFORMER
      database: RETAIL_DB
      warehouse: PROD_WH
      schema: dbt_prod
      threads: 16
```

Caractéristiques :
- Schéma : `dbt_prod`
- Warehouse : `PROD_WH` (Medium)
- Données production complètes
- Refresh selon schedule
- Haute disponibilité

---

## Processus de déploiement

### Workflow Git

```
develop ──> staging ──> main (production)
   │           │           │
   │           │           └─> Déploiement automatique en prod
   │           └─> Tests d'intégration
   └─> Développement et tests unitaires
```

### Étapes de déploiement

#### 1. Développement local

```bash
# Créer une branche feature
git checkout -b feature/new-model

# Développer et tester localement
dbt run --select new_model
dbt test --select new_model

# Commit et push
git add .
git commit -m "feat: add new model"
git push origin feature/new-model
```

#### 2. Pull Request vers develop

```markdown
## Description
[Description des changements]

## Type de changement
- [ ] Nouvelle fonctionnalité
- [ ] Correction de bug
- [ ] Refactoring
- [ ] Documentation

## Checklist
- [ ] Tests locaux passent
- [ ] Documentation mise à jour
- [ ] Pas de breaking changes
- [ ] Code review effectué
```

Validation automatique :
- Compilation dbt
- Tests unitaires
- Linting SQL
- Vérification documentation

#### 3. Merge vers develop

Après approbation de la PR :

```bash
git checkout develop
git merge feature/new-model
git push origin develop
```

Actions automatiques :
- Déploiement en dev partagé
- Tests complets
- Génération documentation

#### 4. Déploiement en staging

```bash
# Créer une PR de develop vers staging
git checkout staging
git merge develop
git push origin staging
```

Validation en staging :
- Tests d'intégration
- Tests de performance
- Validation données
- Smoke tests

#### 5. Déploiement en production

Après validation en staging :

```bash
# Créer une PR de staging vers main
git checkout main
git merge staging
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin main --tags
```

Actions automatiques :
- Backup état actuel
- Déploiement progressif
- Tests de smoke
- Notification équipe

---

## CI/CD

### GitHub Actions

#### Workflow de développement

```yaml
# .github/workflows/dbt_dev.yml
name: dbt Development

on:
  pull_request:
    branches: [develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dbt
        run: pip install dbt-snowflake
      
      - name: dbt deps
        run: dbt deps
      
      - name: dbt compile
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: dbt compile --target dev
      
      - name: dbt test
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: dbt test --target dev --select state:modified+
```

#### Workflow de staging

```yaml
# .github/workflows/dbt_staging.yml
name: dbt Staging

on:
  push:
    branches: [staging]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dbt
        run: pip install dbt-snowflake
      
      - name: dbt deps
        run: dbt deps
      
      - name: dbt run
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: dbt run --target stg
      
      - name: dbt test
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: dbt test --target stg
      
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Staging deployment completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

#### Workflow de production

```yaml
# .github/workflows/dbt_prod.yml
name: dbt Production

on:
  push:
    branches: [main]
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dbt
        run: pip install dbt-snowflake
      
      - name: dbt deps
        run: dbt deps
      
      - name: Backup current state
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_SERVICE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_SERVICE_PASSWORD }}
        run: |
          dbt run-operation backup_schemas --target prod
      
      - name: dbt run
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_SERVICE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_SERVICE_PASSWORD }}
        run: dbt run --target prod
      
      - name: dbt test
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_SERVICE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_SERVICE_PASSWORD }}
        run: dbt test --target prod
      
      - name: Smoke tests
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_SERVICE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_SERVICE_PASSWORD }}
        run: dbt test --target prod --select tag:smoke
      
      - name: Generate docs
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_SERVICE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_SERVICE_PASSWORD }}
        run: dbt docs generate --target prod
      
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Rollback

### Stratégie de rollback

#### 1. Rollback Git

```bash
# Identifier le commit à rollback
git log --oneline

# Créer un revert
git revert <commit-hash>
git push origin main
```

#### 2. Rollback Snowflake

```sql
-- Restaurer depuis un backup
CREATE OR REPLACE SCHEMA dbt_prod CLONE dbt_prod_backup_20260126;

-- Ou utiliser Time Travel
CREATE OR REPLACE TABLE mart_sales_daily CLONE mart_sales_daily
  AT(TIMESTAMP => '2026-01-26 10:00:00'::TIMESTAMP);
```

#### 3. Rollback dbt

```bash
# Revenir à une version précédente
git checkout v1.1.0
dbt run --target prod
```

### Procédure de rollback d'urgence

1. **Identifier le problème**
   - Vérifier les logs
   - Identifier les modèles affectés

2. **Communiquer**
   - Notifier l'équipe
   - Informer les stakeholders

3. **Exécuter le rollback**
   ```bash
   # Rollback Git
   git revert HEAD
   git push origin main
   
   # Ou restaurer depuis backup
   dbt run-operation restore_from_backup --args '{date: "2026-01-26"}'
   ```

4. **Vérifier**
   ```bash
   dbt test --target prod
   ```

5. **Post-mortem**
   - Documenter l'incident
   - Identifier la cause racine
   - Mettre en place des mesures préventives

---

## Monitoring

### Métriques à surveiller

#### 1. Performance

```sql
-- Temps d'exécution des modèles
SELECT
    model_name,
    AVG(execution_time_seconds) AS avg_time,
    MAX(execution_time_seconds) AS max_time
FROM dbt_run_results
WHERE run_date >= CURRENT_DATE - 7
GROUP BY model_name
ORDER BY avg_time DESC;
```

#### 2. Qualité des données

```sql
-- Taux de réussite des tests
SELECT
    DATE(run_started_at) AS run_date,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS passed_tests,
    (passed_tests / total_tests) * 100 AS success_rate
FROM dbt_test_results
GROUP BY run_date
ORDER BY run_date DESC;
```

#### 3. Freshness des données

```sql
-- Dernière mise à jour des marts
SELECT
    table_name,
    MAX(_dbt_updated_at) AS last_updated,
    DATEDIFF('hour', last_updated, CURRENT_TIMESTAMP) AS hours_since_update
FROM information_schema.tables
WHERE table_schema = 'DBT_PROD_MARTS_CORE'
ORDER BY hours_since_update DESC;
```

### Alertes

#### Configuration Slack

```yaml
# dbt_project.yml
on-run-end:
  - "{{ slack_alert_on_failure() }}"
```

```sql
-- macros/slack_alert.sql
{% macro slack_alert_on_failure() %}
  {% if execute %}
    {% set results = run_query("SELECT COUNT(*) as failures FROM dbt_test_results WHERE status = 'fail'") %}
    {% if results.rows[0][0] > 0 %}
      {{ log("ALERT: " ~ results.rows[0][0] ~ " tests failed!", info=True) }}
    {% endif %}
  {% endif %}
{% endmacro %}
```

### Dashboards

Créer des dashboards dans votre outil BI pour suivre :

1. **Santé du pipeline**
   - Taux de réussite des runs
   - Temps d'exécution
   - Nombre de tests échoués

2. **Qualité des données**
   - Freshness des tables
   - Volume de données
   - Anomalies détectées

3. **Utilisation**
   - Requêtes par table
   - Utilisateurs actifs
   - Coûts Snowflake

---

## Checklist de déploiement

### Avant le déploiement

- [ ] Code review approuvé
- [ ] Tests locaux passent
- [ ] Tests en staging passent
- [ ] Documentation mise à jour
- [ ] Changelog mis à jour
- [ ] Backup créé
- [ ] Stakeholders notifiés

### Pendant le déploiement

- [ ] Déploiement lancé
- [ ] Logs surveillés
- [ ] Tests de smoke exécutés
- [ ] Métriques vérifiées

### Après le déploiement

- [ ] Tests de production passent
- [ ] Données vérifiées
- [ ] Performance acceptable
- [ ] Documentation générée
- [ ] Équipe notifiée
- [ ] Post-mortem si nécessaire

---

## Gestion des versions

### Semantic Versioning

Format : `MAJOR.MINOR.PATCH`

- **MAJOR** : Breaking changes
- **MINOR** : Nouvelles fonctionnalités (backward compatible)
- **PATCH** : Bug fixes

Exemples :
- `v1.0.0` : Release initiale
- `v1.1.0` : Ajout de nouveaux modèles
- `v1.1.1` : Correction de bug
- `v2.0.0` : Refonte majeure avec breaking changes

### Tagging

```bash
# Créer un tag
git tag -a v1.2.0 -m "Release v1.2.0: Add customer churn model"

# Pousser le tag
git push origin v1.2.0

# Lister les tags
git tag -l
```

### Changelog

Maintenir un fichier `CHANGELOG.md` :

```markdown
# Changelog

## [1.2.0] - 2026-01-26

### Added
- Customer churn prediction model
- New RFM segmentation logic

### Changed
- Optimized mart_sales_daily performance
- Updated documentation

### Fixed
- Corrected revenue calculation in mart_sales_by_region

## [1.1.0] - 2026-01-15

### Added
- Campaign attribution model
- Product performance metrics
```

---

## Sécurité

### Gestion des secrets

**Ne jamais** commiter de credentials dans Git.

Utiliser :
1. **Variables d'environnement**
2. **GitHub Secrets**
3. **Vault** (HashiCorp Vault, AWS Secrets Manager)

### Permissions Snowflake

```sql
-- Rôle de développement
GRANT USAGE ON WAREHOUSE DEV_WH TO ROLE DEVELOPER;
GRANT USAGE ON DATABASE RETAIL_DB TO ROLE DEVELOPER;
GRANT ALL ON SCHEMA dbt_dev TO ROLE DEVELOPER;

-- Rôle de production (service account)
GRANT USAGE ON WAREHOUSE PROD_WH TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE RETAIL_DB TO ROLE TRANSFORMER;
GRANT ALL ON SCHEMA dbt_prod TO ROLE TRANSFORMER;
```

---

## Troubleshooting

### Problèmes courants

#### 1. Échec de déploiement

```bash
# Vérifier les logs
cat logs/dbt.log

# Réexécuter avec debug
dbt run --target prod --debug
```

#### 2. Tests qui échouent

```bash
# Identifier les tests échoués
dbt test --target prod --store-failures

# Inspecter les échecs
SELECT * FROM dbt_test__audit.{test_name}
```

#### 3. Performance dégradée

```sql
-- Analyser les query profiles
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT LIKE '%dbt%'
ORDER BY EXECUTION_TIME DESC
LIMIT 10;
```

---

Dernière mise à jour : Janvier 2026
