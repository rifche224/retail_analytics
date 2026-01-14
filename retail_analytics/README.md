# 🛒 Retail Analytics Project

Plateforme d'analyse e-commerce avec dbt et Snowflake en adoptant une architecture médaillon (Bronze/Silver/Gold).

## 📋 Structure du projet
```
retail_analytics/
├── models/
│   ├── staging/          # Tables sources nettoyées (Bronze)
│   ├── intermediate/     # Transformations intermédiaires (Silver)
│   └── marts/           # Tables finales pour analytics (Gold)
├── tests/               # Tests de qualité
├── macros/              # Fonctions réutilisables
└── snapshots/           # Historisation des données
```

## Démarrage rapide
```bash
# Charger les variables d'environnement
source .env

# Installer les dépendances
dbt deps

# Tester la connexion
dbt debug

# Exécuter les modèles
dbt run

# Lancer les tests
dbt test
```

## Documentation

Générer et voir la documentation :
```bash
dbt docs generate
dbt docs serve
```

## Architecture

- **Staging** : Nettoyage et standardisation
- **Intermediate** : Logique métier complexe
- **Marts** : Tables finales optimisées

## Checklist de développement

- [ ] Configurer Snowflake
- [ ] Créer les sources dans staging
- [ ] Développer les modèles intermediate
- [ ] Créer les marts finaux
- [ ] Ajouter les tests
- [ ] Documenter les modèles