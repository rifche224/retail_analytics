# ✅ Checklist : Tester votre workflow CI

## 🎯 Objectif

Vérifier que votre workflow CI fonctionne correctement avec vos secrets Snowflake.

---

## 📋 Prérequis (À vérifier AVANT de commencer)

- [ ] **Secrets GitHub configurés** (6 secrets)
  - [ ] SNOWFLAKE_ACCOUNT
  - [ ] SNOWFLAKE_USER
  - [ ] SNOWFLAKE_PASSWORD
  - [ ] SNOWFLAKE_ROLE
  - [ ] SNOWFLAKE_DATABASE
  - [ ] SNOWFLAKE_WAREHOUSE

- [ ] **Branche de test créée**
  - [ ] Branche `test-ci-workflow` existe
  - [ ] Fichier `tests/test_workflow_ci.sql` créé
  - [ ] Changements poussés sur GitHub

- [ ] **Accès Snowflake vérifié**
  - [ ] Vous pouvez vous connecter à Snowflake
  - [ ] L'utilisateur de service existe
  - [ ] Les permissions sont configurées

---

## 🚀 Étape 1 : Activer GitHub Actions

### Actions à faire

1. [ ] Aller sur votre repository GitHub
   - URL : https://github.com/rifche224/retail_analytics

2. [ ] Cliquer sur l'onglet **"Actions"** (en haut de la page)

3. [ ] Vérifier l'état de GitHub Actions :

   **Cas A** : Vous voyez un message "Workflows aren't being run on this repository"
   - [ ] Cliquer sur **"I understand my workflows, go ahead and enable them"**
   
   **Cas B** : Vous voyez un bouton "Enable workflows"
   - [ ] Cliquer sur **"Enable workflows"**
   
   **Cas C** : Vous voyez déjà des workflows listés
   - [ ] Parfait ! GitHub Actions est déjà activé ✅

4. [ ] Vérifier les permissions (si nécessaire)
   - [ ] Aller dans **Settings** → **Actions** → **General**
   - [ ] Sous "Actions permissions" : Sélectionner **"Allow all actions and reusable workflows"**
   - [ ] Sous "Workflow permissions" : Sélectionner **"Read and write permissions"**
   - [ ] Cocher **"Allow GitHub Actions to create and approve pull requests"**
   - [ ] Cliquer sur **"Save"**

### ✅ Validation

- [ ] GitHub Actions est activé
- [ ] Vous voyez la liste des workflows dans l'onglet Actions

---

## 🔀 Étape 2 : Créer une Pull Request

### Actions à faire

1. [ ] Retourner sur la page principale du repository

2. [ ] Chercher le bandeau jaune en haut :
   ```
   test-ci-workflow had recent pushes X minutes ago
   [Compare & pull request]
   ```

3. [ ] Cliquer sur **"Compare & pull request"**

4. [ ] Configurer la Pull Request :
   - [ ] **Base branch** : `dev` (IMPORTANT !)
   - [ ] **Compare branch** : `test-ci-workflow`
   - [ ] **Titre** : "Test: Vérification du workflow CI"
   - [ ] **Description** : 
     ```
     Test pour vérifier que le workflow CI fonctionne correctement.
     
     Ce que ce test vérifie :
     - ✅ Connexion à Snowflake avec les secrets
     - ✅ Installation de dbt
     - ✅ Compilation des modèles
     - ✅ Exécution des modèles
     - ✅ Tests dbt
     - ✅ Nettoyage du schéma temporaire
     ```

5. [ ] Cliquer sur **"Create pull request"**

### ✅ Validation

- [ ] La Pull Request est créée
- [ ] Vous êtes sur la page de la Pull Request

---

## 🔍 Étape 3 : Observer le workflow CI

### Actions à faire

1. [ ] Sur la page de la Pull Request, scroller vers le bas

2. [ ] Chercher la section "Checks" ou "All checks have passed"

3. [ ] Identifier le statut du workflow :

   **🟡 En cours** : "Some checks are still running"
   - [ ] Cliquer sur **"Details"** pour voir les logs en temps réel
   - [ ] Observer chaque étape s'exécuter
   - [ ] Attendre la fin (5-10 minutes)
   
   **✅ Succès** : "All checks have passed"
   - [ ] Cliquer sur **"Details"** pour voir les logs
   - [ ] Vérifier que toutes les étapes sont vertes ✅
   - [ ] **FÉLICITATIONS ! Votre CI fonctionne !** 🎉
   
   **❌ Échec** : "Some checks failed"
   - [ ] Cliquer sur **"Details"** pour voir les logs
   - [ ] Identifier l'étape qui a échoué
   - [ ] Lire le message d'erreur
   - [ ] Passer à l'Étape 4 (Dépannage)

### ✅ Validation

- [ ] Le workflow s'est exécuté
- [ ] Vous avez consulté les logs

---

## 🔧 Étape 4 : Comprendre les logs (si succès ✅)

### Étapes du workflow à vérifier

1. [ ] **Checkout code** ✅
   - Clone le repository

2. [ ] **Setup Python** ✅
   - Installe Python 3.11

3. [ ] **Install dbt** ✅
   - Installe dbt-core et dbt-snowflake

4. [ ] **Install dbt packages** ✅
   - Exécute `dbt deps`

5. [ ] **Configure dbt profile** ✅
   - Crée le fichier profiles.yml avec vos secrets

6. [ ] **Debug dbt** ✅
   - Teste la connexion à Snowflake
   - **IMPORTANT** : Si cette étape passe, vos secrets sont corrects !

7. [ ] **Compile dbt models** ✅
   - Compile tous les modèles SQL

8. [ ] **Run dbt models** ✅
   - Exécute les modèles dans le schéma `dbt_ci_pr_<numéro>`

9. [ ] **Test dbt models** ✅
   - Lance tous les tests dbt

10. [ ] **Generate documentation** ✅
    - Génère la documentation dbt

11. [ ] **Cleanup CI schema** ✅
    - Supprime le schéma temporaire

### ✅ Validation

- [ ] Toutes les étapes sont vertes ✅
- [ ] Aucune erreur dans les logs
- [ ] Le schéma temporaire a été nettoyé

---

## 🚨 Étape 5 : Dépannage (si échec ❌)

### Erreur : "Account not found"

**Symptôme** : Échec à l'étape "Debug dbt"
```
Error: Account 'xy12345' not found
```

**Solution** :
- [ ] Vérifier le format de SNOWFLAKE_ACCOUNT
- [ ] Doit être : `account.region` (ex: `xy12345.us-east-1`)
- [ ] Corriger dans Settings → Secrets → SNOWFLAKE_ACCOUNT

---

### Erreur : "Authentication failed"

**Symptôme** : Échec à l'étape "Debug dbt"
```
Error: Incorrect username or password
```

**Solution** :
- [ ] Vérifier SNOWFLAKE_USER
- [ ] Vérifier SNOWFLAKE_PASSWORD
- [ ] Tester la connexion manuellement :
  ```bash
  snowsql -a <account> -u <user>
  ```

---

### Erreur : "Insufficient privileges"

**Symptôme** : Échec à l'étape "Run dbt models"
```
Error: Insufficient privileges to operate on schema 'dbt_ci_pr_123'
```

**Solution** :
- [ ] Vérifier les permissions dans Snowflake
- [ ] L'utilisateur doit pouvoir créer des schémas
- [ ] Exécuter dans Snowflake :
  ```sql
  GRANT CREATE SCHEMA ON DATABASE RETAIL_DB TO ROLE DBT_ROLE;
  ```

---

### Erreur : "Warehouse not found"

**Symptôme** : Échec à l'étape "Debug dbt"
```
Error: Warehouse 'DBT_WH' does not exist
```

**Solution** :
- [ ] Vérifier que le warehouse existe dans Snowflake
- [ ] Créer le warehouse si nécessaire :
  ```sql
  CREATE WAREHOUSE DBT_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
  ```

---

### Erreur : "Compilation failed"

**Symptôme** : Échec à l'étape "Compile dbt models"
```
Error: Compilation Error in model ...
```

**Solution** :
- [ ] Lire le message d'erreur complet
- [ ] Identifier le modèle problématique
- [ ] Corriger le SQL localement
- [ ] Tester avec `dbt compile`
- [ ] Commit et push

---

## 🎉 Étape 6 : Validation finale

### Si tout est vert ✅

1. [ ] **Vérifier dans Snowflake** (optionnel)
   - [ ] Se connecter à Snowflake
   - [ ] Vérifier que le schéma `dbt_ci_pr_<numéro>` a été créé puis supprimé
   - [ ] Consulter l'historique des requêtes

2. [ ] **Merger la Pull Request** (optionnel pour le test)
   - [ ] Cliquer sur **"Merge pull request"**
   - [ ] Confirmer le merge
   - [ ] Observer le workflow `deploy-dev.yml` se déclencher

3. [ ] **Documenter le succès**
   - [ ] Noter la date et l'heure du test réussi
   - [ ] Capturer des screenshots si nécessaire
   - [ ] Partager avec l'équipe

### ✅ Validation finale

- [ ] Le workflow CI fonctionne parfaitement
- [ ] Les secrets Snowflake sont corrects
- [ ] Vous comprenez le processus CI/CD
- [ ] Vous êtes prêt pour les prochaines étapes

---

## 📊 Résumé de votre test

### Informations à noter

- **Date du test** : _______________
- **Durée du workflow** : ___________ minutes
- **Statut final** : ✅ Succès / ❌ Échec
- **Numéro de la PR** : #___________
- **Schéma CI créé** : dbt_ci_pr____________

### Problèmes rencontrés

- [ ] Aucun problème ✅
- [ ] Problème résolu : _______________
- [ ] Problème en cours : _______________

---

## 🎯 Prochaines étapes

Une fois le CI validé ✅, vous pouvez :

1. [ ] **Créer les environnements GitHub**
   - [ ] Environnement "dev"
   - [ ] Environnement "production"

2. [ ] **Tester le déploiement en dev**
   - [ ] Merger la PR vers `dev`
   - [ ] Observer `deploy-dev.yml`
   - [ ] Vérifier dans Snowflake (schéma `dbt_dev`)

3. [ ] **Tester le déploiement en production**
   - [ ] Créer une PR de `dev` vers `main`
   - [ ] Merger vers `main`
   - [ ] Observer `deploy-prod.yml`
   - [ ] Vérifier dans Snowflake (schéma `dbt_prod`)

4. [ ] **Configurer l'exécution planifiée**
   - [ ] Tester manuellement `scheduled-run.yml`
   - [ ] Attendre l'exécution automatique

---

## 📚 Ressources

- **Guide d'apprentissage** : `docs/GUIDE_CI_CD_APPRENTISSAGE.md`
- **Visualisation des workflows** : `docs/WORKFLOW_CI_CD_VISUEL.md`
- **Configuration des secrets** : `docs/SECRETS_SETUP.md`
- **Configuration CI/CD** : `docs/CI_CD_SETUP.md`

---

## 🆘 Besoin d'aide ?

Si vous rencontrez des problèmes :

1. Consultez la section "Dépannage" ci-dessus
2. Lisez les logs complets du workflow
3. Vérifiez la documentation Snowflake et dbt
4. Consultez les issues GitHub du projet

---

*Bon test ! Prenez votre temps et n'hésitez pas à recommencer si nécessaire.* 🚀
