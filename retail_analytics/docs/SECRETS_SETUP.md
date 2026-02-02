# Configuration des Secrets - Guide Étape par Étape

## Vue d'ensemble

Guide pour configurer les secrets GitHub nécessaires au CI/CD du projet Retail Analytics.

## Prérequis

- Accès administrateur au repository GitHub
- Compte Snowflake avec permissions appropriées
- Informations de connexion Snowflake

## Étape 1 : Récupérer les informations Snowflake

### 1.1 Account Identifier

Se connecter à Snowflake et exécuter :
```sql
SELECT CURRENT_ACCOUNT();
SELECT CURRENT_REGION();
```

Format du account : `account.region`
Exemple : `xy12345.us-east-1`

### 1.2 Créer un utilisateur de service

```sql
-- Créer le rôle pour dbt
CREATE ROLE IF NOT EXISTS DBT_ROLE;

-- Permissions sur la base de données
GRANT USAGE ON DATABASE RETAIL_DB TO ROLE DBT_ROLE;
GRANT CREATE SCHEMA ON DATABASE RETAIL_DB TO ROLE DBT_ROLE;

-- Permissions sur les schémas existants
GRANT ALL ON SCHEMA RETAIL_DB.raw_retail TO ROLE DBT_ROLE;
GRANT ALL ON SCHEMA RETAIL_DB.dbt_dev TO ROLE DBT_ROLE;
GRANT ALL ON SCHEMA RETAIL_DB.dbt_prod TO ROLE DBT_ROLE;

-- Permissions sur les futurs schémas
GRANT ALL ON ALL SCHEMAS IN DATABASE RETAIL_DB TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE RETAIL_DB TO ROLE DBT_ROLE;

-- Permissions sur les tables
GRANT ALL ON ALL TABLES IN SCHEMA RETAIL_DB.raw_retail TO ROLE DBT_ROLE;
GRANT ALL ON FUTURE TABLES IN SCHEMA RETAIL_DB.raw_retail TO ROLE DBT_ROLE;

-- Créer le warehouse si nécessaire
CREATE WAREHOUSE IF NOT EXISTS DBT_WH
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Permissions sur le warehouse
GRANT USAGE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;

-- Créer l'utilisateur de service
CREATE USER IF NOT EXISTS dbt_service_user
  PASSWORD = 'VotreMotDePasseSecurise123!'
  DEFAULT_ROLE = DBT_ROLE
  DEFAULT_WAREHOUSE = DBT_WH
  MUST_CHANGE_PASSWORD = FALSE;

-- Assigner le rôle
GRANT ROLE DBT_ROLE TO USER dbt_service_user;
```

### 1.3 Tester la connexion

```bash
# Tester avec dbt
dbt debug --profiles-dir . --target prod
```

## Étape 2 : Configurer les secrets GitHub

### 2.1 Accéder aux secrets

1. Aller sur votre repository GitHub
2. Cliquer sur **Settings**
3. Dans le menu de gauche, cliquer sur **Secrets and variables** → **Actions**
4. Cliquer sur **New repository secret**

### 2.2 Ajouter les secrets

Créer les secrets suivants un par un :

#### SNOWFLAKE_ACCOUNT
```
Nom : SNOWFLAKE_ACCOUNT
Valeur : xy12345.us-east-1
```
(Remplacer par votre account identifier)

#### SNOWFLAKE_USER
```
Nom : SNOWFLAKE_USER
Valeur : dbt_service_user
```

#### SNOWFLAKE_PASSWORD
```
Nom : SNOWFLAKE_PASSWORD
Valeur : VotreMotDePasseSecurise123!
```
⚠️ Utiliser un mot de passe fort et unique

#### SNOWFLAKE_ROLE
```
Nom : SNOWFLAKE_ROLE
Valeur : DBT_ROLE
```

#### SNOWFLAKE_DATABASE
```
Nom : SNOWFLAKE_DATABASE
Valeur : RETAIL_DB
```

#### SNOWFLAKE_WAREHOUSE
```
Nom : SNOWFLAKE_WAREHOUSE
Valeur : DBT_WH
```

### 2.3 Vérifier les secrets

Après ajout, vous devriez voir 6 secrets :
- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_USER
- SNOWFLAKE_PASSWORD
- SNOWFLAKE_ROLE
- SNOWFLAKE_DATABASE
- SNOWFLAKE_WAREHOUSE

## Étape 3 : Configurer les environnements GitHub

### 3.1 Créer l'environnement Dev

1. Settings → Environments → **New environment**
2. Nom : `dev`
3. Pas de protection requise
4. Cliquer sur **Configure environment**
5. Sauvegarder

### 3.2 Créer l'environnement Production

1. Settings → Environments → **New environment**
2. Nom : `production`
3. Cocher **Required reviewers** (optionnel)
4. Ajouter des reviewers si nécessaire
5. Cocher **Wait timer** : 0 minutes (ou selon besoin)
6. Cliquer sur **Configure environment**
7. Sauvegarder

## Étape 4 : Tester la configuration

### 4.1 Test manuel du workflow

1. Aller sur **Actions**
2. Sélectionner **Deploy to Dev**
3. Cliquer sur **Run workflow**
4. Sélectionner la branche `dev`
5. Cliquer sur **Run workflow**

### 4.2 Vérifier l'exécution

1. Suivre l'exécution en temps réel
2. Vérifier que toutes les étapes passent
3. Consulter les logs en cas d'erreur

### 4.3 Vérifier dans Snowflake

```sql
-- Vérifier que les schémas existent
SHOW SCHEMAS IN DATABASE RETAIL_DB;

-- Vérifier les tables créées
SHOW TABLES IN SCHEMA RETAIL_DB.dbt_dev;

-- Vérifier les données
SELECT COUNT(*) FROM RETAIL_DB.dbt_dev.mart_sales_daily;
```

## Dépannage

### Erreur : "Account not found"

Vérifier le format du SNOWFLAKE_ACCOUNT :
- Doit être : `account.region`
- Exemple : `xy12345.us-east-1`

### Erreur : "Authentication failed"

1. Vérifier le nom d'utilisateur
2. Vérifier le mot de passe
3. Tester la connexion manuellement :
```bash
snowsql -a xy12345.us-east-1 -u dbt_service_user
```

### Erreur : "Insufficient privileges"

Vérifier les permissions :
```sql
-- Se connecter en tant qu'admin
USE ROLE ACCOUNTADMIN;

-- Vérifier les grants
SHOW GRANTS TO ROLE DBT_ROLE;
SHOW GRANTS TO USER dbt_service_user;
```

### Erreur : "Warehouse not found"

Créer le warehouse :
```sql
CREATE WAREHOUSE DBT_WH
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

GRANT USAGE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;
```

## Sécurité

### Bonnes pratiques

1. **Mot de passe fort** : Minimum 12 caractères, majuscules, minuscules, chiffres, symboles
2. **Rotation régulière** : Changer le mot de passe tous les 90 jours
3. **Principe du moindre privilège** : Donner uniquement les permissions nécessaires
4. **Audit régulier** : Vérifier les accès et permissions
5. **Secrets séparés** : Ne jamais commiter les secrets dans le code

### Rotation des secrets

Pour changer le mot de passe :

1. Dans Snowflake :
```sql
ALTER USER dbt_service_user SET PASSWORD = 'NouveauMotDePasse123!';
```

2. Dans GitHub :
   - Settings → Secrets → SNOWFLAKE_PASSWORD
   - Cliquer sur **Update**
   - Entrer le nouveau mot de passe
   - Sauvegarder

3. Tester immédiatement avec un workflow

## Checklist finale

- [ ] Tous les secrets sont configurés dans GitHub
- [ ] Les environnements dev et production sont créés
- [ ] L'utilisateur de service Snowflake est créé
- [ ] Les permissions sont correctement configurées
- [ ] Le warehouse est créé et accessible
- [ ] Un test manuel du workflow a réussi
- [ ] Les données sont visibles dans Snowflake
- [ ] La documentation est à jour

---

Dernière mise à jour : Janvier 2026
