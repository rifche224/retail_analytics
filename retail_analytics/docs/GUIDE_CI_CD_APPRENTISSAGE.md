# 🎓 Guide d'apprentissage CI/CD - Retail Analytics

## 📖 Table des matières

1. [Comprendre votre projet actuel](#1-comprendre-votre-projet-actuel)
2. [Qu'est-ce que le CI/CD ?](#2-quest-ce-que-le-cicd)
3. [Vos 4 workflows expliqués](#3-vos-4-workflows-expliqués)
4. [Plan d'apprentissage étape par étape](#4-plan-dapprentissage-étape-par-étape)
5. [Tester votre CI (étape actuelle)](#5-tester-votre-ci-étape-actuelle)
6. [Prochaines étapes](#6-prochaines-étapes)

---

## 1. Comprendre votre projet actuel

### 🏗️ Architecture de votre projet dbt

Vous avez construit un projet d'analyse retail avec **3 couches** :

```
📊 DONNÉES BRUTES (Snowflake)
    ↓
🥉 STAGING (Bronze) - Nettoyage
    ↓ stg_customers, stg_orders, stg_products...
🥈 INTERMEDIATE (Silver) - Logique métier
    ↓ int_customer_lifetime_value, int_product_performance...
🥇 MARTS (Gold) - Tables finales
    → mart_sales_daily, mart_customer_segments...
```

**Ce que vous avez déjà :**
- ✅ 7 modèles staging (views)
- ✅ 5 modèles intermediate (views)
- ✅ 7 modèles marts (tables)
- ✅ 3 macros personnalisées
- ✅ Tests dbt (unique, not_null, relationships)
- ✅ Documentation complète

---

## 2. Qu'est-ce que le CI/CD ?

### 🔄 CI = Continuous Integration (Intégration Continue)

**Objectif** : Vérifier automatiquement que votre code fonctionne **avant** de le merger.

**Dans votre cas :**
- Quand vous créez une Pull Request → GitHub Actions lance automatiquement :
  - ✅ Compilation des modèles dbt
  - ✅ Exécution des modèles dans un schéma temporaire
  - ✅ Tests dbt
  - ✅ Génération de la documentation

**Avantage** : Vous détectez les erreurs AVANT qu'elles arrivent en production !

### 🚀 CD = Continuous Deployment (Déploiement Continu)

**Objectif** : Déployer automatiquement votre code quand il est validé.

**Dans votre cas :**
- Quand vous mergez vers `dev` → Déploiement automatique en environnement dev
- Quand vous mergez vers `main` → Déploiement automatique en production

**Avantage** : Plus besoin de déployer manuellement, tout est automatisé !

---

## 3. Vos 4 workflows expliqués

### 📋 Workflow 1 : `ci.yml` - Tests automatiques (CI)

**Quand il se déclenche :**
```yaml
on:
  pull_request:
    branches: [dev, main]
    paths: ['models/**', 'macros/**', 'tests/**', ...]
```
→ À chaque Pull Request vers `dev` ou `main` qui modifie des fichiers dbt

**Ce qu'il fait :**
1. 🔧 Installe Python et dbt
2. 📦 Installe les packages dbt (`dbt deps`)
3. 🔐 Configure la connexion Snowflake avec vos secrets
4. 🗄️ Crée un schéma temporaire : `dbt_ci_pr_123` (123 = numéro de la PR)
5. ✅ Compile les modèles (`dbt compile`)
6. 🏃 Exécute les modèles (`dbt run`)
7. 🧪 Lance les tests (`dbt test`)
8. 📚 Génère la documentation (`dbt docs generate`)
9. 🧹 Nettoie le schéma temporaire

**Durée** : 5-10 minutes

**Schéma utilisé** : `dbt_ci_pr_<numéro_PR>` (temporaire, supprimé après)

---

### 🟢 Workflow 2 : `deploy-dev.yml` - Déploiement Dev (CD)

**Quand il se déclenche :**
```yaml
on:
  push:
    branches: [dev]
```
→ À chaque push sur la branche `dev`

**Ce qu'il fait :**
1. 🔧 Installe Python et dbt
2. 📦 Installe les packages dbt
3. 🔐 Configure la connexion Snowflake (environnement `dev`)
4. 🏃 Exécute TOUS les modèles dans le schéma `dbt_dev`
5. 🧪 Lance TOUS les tests
6. 📚 Génère la documentation
7. 💾 Sauvegarde les artefacts (manifest.json, catalog.json)

**Durée** : 10-15 minutes

**Schéma utilisé** : `dbt_dev` (permanent)

**Utilisation** : Environnement de développement pour tester vos changements

---

### 🔴 Workflow 3 : `deploy-prod.yml` - Déploiement Production (CD)

**Quand il se déclenche :**
```yaml
on:
  push:
    branches: [main]
```
→ À chaque push sur la branche `main`

**Ce qu'il fait :**
1. 🔧 Installe Python et dbt
2. 📦 Installe les packages dbt
3. 🔐 Configure la connexion Snowflake (environnement `production`)
4. 💾 Crée un backup de l'état actuel
5. 🏃 Exécute TOUS les modèles dans le schéma `dbt_prod`
6. 🧪 Lance TOUS les tests
7. 🔥 Lance les smoke tests (tests critiques)
8. 📚 Génère la documentation
9. 🏷️ Crée un tag Git : `prod-20240202-143000`
10. 💾 Sauvegarde les artefacts

**Durée** : 15-20 minutes

**Schéma utilisé** : `dbt_prod` (permanent)

**Protection** : Nécessite l'environnement GitHub "production" (peut avoir des approbations)

---

### ⏰ Workflow 4 : `scheduled-run.yml` - Exécution planifiée

**Quand il se déclenche :**
```yaml
on:
  schedule:
    - cron: '0 6 * * *'  # Tous les jours à 6h00 UTC
  workflow_dispatch:      # Ou manuellement
```

**Ce qu'il fait :**
1. 🏃 Exécute les modèles incrémentaux (quotidien)
2. 🔄 Full refresh des modèles hebdomadaires (dimanche uniquement)
3. 🧪 Lance les tests
4. 💾 Sauvegarde les résultats

**Durée** : 10-15 minutes

**Utilisation** : Rafraîchir automatiquement vos données tous les jours

---

## 4. Plan d'apprentissage étape par étape

### 📚 Phase 1 : Comprendre (VOUS ÊTES ICI ✅)

- [x] Comprendre l'architecture de votre projet dbt
- [x] Comprendre ce qu'est le CI/CD
- [x] Comprendre vos 4 workflows
- [x] Configurer les secrets GitHub

### 🧪 Phase 2 : Tester le CI (ÉTAPE ACTUELLE)

- [ ] Activer GitHub Actions
- [ ] Créer une Pull Request de test
- [ ] Observer le workflow CI s'exécuter
- [ ] Comprendre les logs
- [ ] Corriger les erreurs éventuelles

### 🟢 Phase 3 : Tester le déploiement Dev

- [ ] Créer les environnements GitHub (dev, production)
- [ ] Merger vers `dev`
- [ ] Observer le déploiement automatique
- [ ] Vérifier les tables dans Snowflake (schéma `dbt_dev`)

### 🔴 Phase 4 : Tester le déploiement Production

- [ ] Créer une Pull Request de `dev` vers `main`
- [ ] Merger vers `main`
- [ ] Observer le déploiement en production
- [ ] Vérifier les tables dans Snowflake (schéma `dbt_prod`)
- [ ] Vérifier le tag Git créé

### ⏰ Phase 5 : Tester l'exécution planifiée

- [ ] Déclencher manuellement le workflow scheduled
- [ ] Vérifier que les données sont rafraîchies
- [ ] Attendre l'exécution automatique du lendemain

---

## 5. Tester votre CI (étape actuelle)

### 🎯 Objectif

Vérifier que le workflow CI fonctionne correctement avec vos secrets Snowflake.

### ✅ Ce que vous avez déjà fait

1. ✅ Créé une branche `test-ci-workflow` depuis `dev`
2. ✅ Configuré les 6 secrets GitHub :
   - `SNOWFLAKE_ACCOUNT`
   - `SNOWFLAKE_USER`
   - `SNOWFLAKE_PASSWORD`
   - `SNOWFLAKE_ROLE`
   - `SNOWFLAKE_DATABASE`
   - `SNOWFLAKE_WAREHOUSE`
3. ✅ Créé un fichier de test : `tests/test_workflow_ci.sql`
4. ✅ Poussé les changements sur GitHub

### 🚀 Prochaines actions (dans l'ordre)

#### Étape 1 : Activer GitHub Actions

1. Allez sur votre repository GitHub : https://github.com/rifche224/retail_analytics
2. Cliquez sur l'onglet **"Actions"** (en haut)
3. Si vous voyez un message pour activer les workflows :
   - Cliquez sur **"I understand my workflows, go ahead and enable them"**
   - OU cliquez sur **"Enable workflows"**

#### Étape 2 : Créer une Pull Request

1. Sur GitHub, vous devriez voir un bandeau jaune :
   - "test-ci-workflow had recent pushes"
   - Cliquez sur **"Compare & pull request"**

2. Configurez la Pull Request :
   - **Base** : `dev`
   - **Compare** : `test-ci-workflow`
   - **Titre** : "Test: Vérification du workflow CI"
   - **Description** : "Test pour vérifier que le CI fonctionne avec les secrets configurés"

3. Cliquez sur **"Create pull request"**

#### Étape 3 : Observer le workflow CI

Une fois la PR créée, vous devriez voir :

```
✅ All checks have passed
   ✓ Tests dbt — Passed in 8m 32s
```

OU

```
🟡 Some checks are still running
   ⏳ Tests dbt — In progress...
```

OU

```
❌ Some checks failed
   ✗ Tests dbt — Failed
```

**Cliquez sur "Details"** pour voir les logs en temps réel.

#### Étape 4 : Comprendre les logs

Le workflow va afficher chaque étape :

```
✅ Checkout code
✅ Setup Python
✅ Install dbt
✅ Install dbt packages
✅ Configure dbt profile
✅ Debug dbt
✅ Compile dbt models
✅ Run dbt models
✅ Test dbt models
✅ Generate documentation
✅ Cleanup CI schema
```

**Si tout est vert ✅** : Félicitations ! Votre CI fonctionne !

**Si c'est rouge ❌** : Regardez quelle étape a échoué et lisez le message d'erreur.

---

## 6. Prochaines étapes

### Une fois le CI validé ✅

1. **Merger la Pull Request** vers `dev`
   - Le workflow `deploy-dev.yml` se déclenchera automatiquement
   - Vos modèles seront déployés dans le schéma `dbt_dev`

2. **Créer les environnements GitHub**
   - Settings → Environments → New environment
   - Créer "dev" et "production"

3. **Tester le déploiement en production**
   - Créer une PR de `dev` vers `main`
   - Merger → Déploiement automatique en prod

4. **Configurer les notifications** (optionnel)
   - Slack, email, etc.

---

## 🆘 Problèmes courants

### Le workflow ne se déclenche pas

**Cause** : GitHub Actions n'est pas activé
**Solution** : Onglet Actions → Enable workflows

### Erreur "Account not found"

**Cause** : Format du SNOWFLAKE_ACCOUNT incorrect
**Solution** : Doit être `account.region` (ex: `xy12345.us-east-1`)

### Erreur "Authentication failed"

**Cause** : Mauvais username/password
**Solution** : Vérifier les secrets dans Settings → Secrets

### Erreur "Insufficient privileges"

**Cause** : L'utilisateur n'a pas les bonnes permissions
**Solution** : Vérifier les GRANTS dans Snowflake (voir SECRETS_SETUP.md)

---

## 📚 Ressources pour aller plus loin

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation dbt](https://docs.getdbt.com/)
- [Best practices CI/CD pour dbt](https://docs.getdbt.com/docs/deploy/deployments)
- Vos docs internes :
  - `docs/SECRETS_SETUP.md` - Configuration des secrets
  - `docs/CI_CD_SETUP.md` - Configuration CI/CD détaillée
  - `docs/DEPLOYMENT.md` - Guide de déploiement

---

## 🎯 Résumé de votre situation actuelle

**Où vous en êtes :**
- ✅ Projet dbt complet et fonctionnel
- ✅ 4 workflows GitHub Actions configurés
- ✅ Secrets Snowflake ajoutés
- ✅ Branche de test créée
- ⏳ **EN ATTENTE** : Activer GitHub Actions et créer la Pull Request

**Prochaine action immédiate :**
1. Aller sur GitHub → Onglet Actions
2. Activer les workflows
3. Créer la Pull Request
4. Observer le CI s'exécuter

**Objectif final :**
Avoir un pipeline CI/CD complet qui :
- ✅ Teste automatiquement chaque changement
- ✅ Déploie automatiquement en dev et prod
- ✅ Rafraîchit les données quotidiennement

---

*Bon apprentissage ! N'hésitez pas à prendre votre temps pour comprendre chaque étape.* 🚀
