# Guide de Contribution

Bienvenue ! Ce guide vous aidera à contribuer efficacement au projet Retail Analytics.

## Table des matières

- [Code de conduite](#code-de-conduite)
- [Premiers pas](#premiers-pas)
- [Standards de développement](#standards-de-développement)
- [Processus de Pull Request](#processus-de-pull-request)
- [Reporting de bugs](#reporting-de-bugs)
- [Propositions de fonctionnalités](#propositions-de-fonctionnalités)

---

## Code de conduite

Nous attendons de tous les participants qu'ils :

- Respectent les autres contributeurs
- Fournissent des retours constructifs
- Collaborent de manière professionnelle
- Maintiennent un environnement inclusif

---

## Premiers pas

### Configuration initiale

1. **Fork et clone le repository**
```bash
git clone https://github.com/votre-username/retail_analytics.git
cd retail_analytics
```

2. **Installer les dépendances**
```bash
python -m venv venv
source venv/bin/activate
pip install dbt-snowflake
dbt deps
```

3. **Configurer Snowflake**
   
   Consultez le README.md pour les détails de configuration.

### Workflow de contribution

1. Créer une branche depuis `develop`
2. Développer votre fonctionnalité
3. Tester localement
4. Soumettre une Pull Request
5. Répondre aux commentaires de review

---

## Standards de développement

### Nommage des branches

Utilisez ces préfixes :
- `feature/` - Nouvelles fonctionnalités
- `fix/` - Corrections de bugs
- `refactor/` - Refactoring
- `docs/` - Documentation
- `test/` - Tests

Exemples :
```
feature/add-churn-model
fix/revenue-calculation
refactor/optimize-sales-daily
```

### Messages de commit

Format : `type(scope): description`

Types disponibles :
- `feat` - Nouvelle fonctionnalité
- `fix` - Correction de bug
- `refactor` - Refactoring
- `docs` - Documentation
- `test` - Tests
- `chore` - Maintenance

Scopes :
- `customer`, `product`, `marketing`, `core`
- `staging`, `intermediate`, `marts`

Exemples :
```
feat(customer): add lifetime value calculation
fix(core): correct revenue aggregation
docs(readme): update setup instructions
```

### Standards SQL

Respectez ces conventions :

1. Mots-clés SQL en MAJUSCULES
2. Noms de colonnes en snake_case
3. Indentation de 4 espaces
4. Utiliser des CTEs pour la clarté
5. Commenter le code complexe

Exemple :
```sql
SELECT
    customer_id,
    order_date,
    SUM(net_amount) AS total_revenue
FROM {{ ref('stg_orders') }}
WHERE order_status = 'completed'
GROUP BY 1, 2
ORDER BY order_date DESC
```

### Standards Jinja

Évitez la duplication avec des boucles :

```sql
{%- set channels = ['web', 'mobile', 'store'] -%}

SELECT
    date_day,
    {% for channel in channels %}
    SUM(CASE WHEN order_channel = '{{ channel }}' THEN revenue ELSE 0 END) AS {{ channel }}_revenue
    {%- if not loop.last %},{% endif %}
    {% endfor %}
FROM {{ ref('stg_orders') }}
```

### Tests requis

Chaque modèle nécessite :

1. Tests de schéma (unique, not_null)
2. Tests de qualité des données
3. Tests de logique métier si applicable

Exemple :
```yaml
columns:
  - name: customer_id
    tests:
      - unique
      - not_null
  - name: total_revenue
    tests:
      - positive_values
```

### Documentation

Documentez tous les modèles dans les fichiers YAML :

```yaml
models:
  - name: mart_customer_churn
    description: Prédiction du churn client basée sur RFM
    
    columns:
      - name: customer_id
        description: Identifiant unique du client
      - name: churn_probability
        description: Probabilité de churn (0-1)
```

---

## Processus de Pull Request

### Avant de soumettre

Vérifiez que :
- Le code respecte les standards
- Les tests passent (`dbt test`)
- La documentation est à jour
- CHANGELOG.md est mis à jour
- `dbt compile` fonctionne
- La branche est à jour avec develop

### Description de la PR

```markdown
## Description
[Description claire et concise des changements]

## Type de changement
- [ ] Nouvelle fonctionnalité (non-breaking change)
- [ ] Correction de bug (non-breaking change)
- [ ] Breaking change (fonctionnalité ou correction qui casse la compatibilité)
- [ ] Documentation
- [ ] Refactoring

## Motivation et contexte
[Pourquoi ce changement est-il nécessaire ? Quel problème résout-il ?]

## Comment a-t-il été testé ?
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Tests manuels

Décrivez les tests effectués :
[Description des tests]

## Modèles affectés
- Nouveaux : `mart_customer_churn`
- Modifiés : `int_customer_lifetime_value`
- Supprimés : Aucun

## Captures d'écran (si applicable)
[Ajouter des captures d'écran]

## Checklist
- [ ] Mon code suit les standards du projet
- [ ] J'ai effectué une auto-review de mon code
- [ ] J'ai commenté mon code, particulièrement les parties complexes
- [ ] J'ai mis à jour la documentation
- [ ] Mes changements ne génèrent pas de nouveaux warnings
- [ ] J'ai ajouté des tests qui prouvent que ma correction est efficace
- [ ] Les tests unitaires et d'intégration passent localement
- [ ] J'ai mis à jour le CHANGELOG.md

## Dépendances
Cette PR dépend de :
- [ ] Aucune
- [ ] PR #XXX

## Notes supplémentaires
[Informations supplémentaires pour les reviewers]
```

Incluez dans votre PR :
- Description claire des changements
- Type de changement (feature, fix, etc.)
- Tests effectués
- Modèles affectés
- Captures d'écran si pertinent

### Review

Le processus de review inclut :
1. Validation automatique (CI/CD)
2. Review manuelle (1 approbation minimum)
3. Corrections si nécessaire
4. Merge par un mainteneur

Critères d'acceptation :
- Tests passants
- Code review approuvé
- Documentation complète
- Pas de conflits

---

## Reporting de bugs

Avant de créer un rapport :
1. Vérifiez si le bug existe déjà
2. Testez avec la dernière version
3. Collectez les informations nécessaires

Format du rapport :

```markdown
## Description du bug
[Description claire et concise du bug]

## Étapes pour reproduire
1. Aller à '...'
2. Cliquer sur '...'
3. Exécuter '...'
4. Voir l'erreur

## Comportement attendu
[Ce qui devrait se passer]

## Comportement actuel
[Ce qui se passe réellement]

## Captures d'écran
[Si applicable]

## Environnement
- OS: [e.g. macOS 12.0]
- dbt version: [e.g. 1.11.2]
- Snowflake version: [e.g. 7.0]
- Python version: [e.g. 3.9]

## Logs
```
[Coller les logs pertinents]
```

## Contexte additionnel
[Toute autre information pertinente]
```

---

## Propositions de fonctionnalités

Format de proposition :

```markdown
## Problème à résoudre
[Description du problème que cette fonctionnalité résoudrait]

## Solution proposée
[Description de la solution souhaitée]

## Alternatives considérées
[Autres solutions envisagées]

## Bénéfices
- Bénéfice 1
- Bénéfice 2

## Complexité estimée
- [ ] Faible (< 1 jour)
- [ ] Moyenne (1-3 jours)
- [ ] Élevée (> 3 jours)

## Contexte additionnel
[Toute autre information pertinente]
```

---

## Ressources

Documentation du projet :
- [README.md](README.md)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)
- [DATA_DICTIONARY.md](docs/DATA_DICTIONARY.md)

Ressources externes :
- [Documentation dbt](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Snowflake Documentation](https://docs.snowflake.com/)

Support :
- Questions : Ouvrir une issue
- Discussions : GitHub Discussions

---

Merci de contribuer au projet Retail Analytics !
