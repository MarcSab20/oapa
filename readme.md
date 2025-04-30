# Preuve de Concept Spring Boot + OPA + GraphQL

Cette preuve de concept démontre Open Policy Agent (OPA) pour la gestion des autorisations basées sur les attributs.

## Fonctionnalités

- **Autorisation avec OPA** - Décisions d'autorisation basées sur:
  - Attributs utilisateur (rôles, départements, attributs personnalisés)
  - Attributs de ressource (type, classification, département, tags, attributs personnalisés)
  - Contexte de la requête (action demandée, informations additionnelles)

## Architecture

L'application est structurée selon les principes suivants:

 **OPA** fonctionne comme un service externe qui prend les décisions d'autorisation


## Configuration requise

- Docker et Docker Compose (pour exécuter OPA)

## Démarrage rapide

1. Démarrer le serveur OPA:
   ```bash
   cd opa
   docker-compose up -d
   ```

## Utilisateurs de démonstration

L'application est préchargée avec les utilisateurs suivants:

| Username | Password | Rôles        | Départements     | Attributs                |
|----------|----------|--------------|------------------|--------------------------|
| admin    | admin    | ADMIN, USER  | IT               | clearance = TOP_SECRET   |
| editor   | editor   | EDITOR, USER | MARKETING        | clearance = CONFIDENTIAL |
| user     | user     | USER         | SALES            | clearance = PUBLIC       |
| multi    | multi    | EDITOR, USER | SALES, MARKETING | clearance = CONFIDENTIAL |

## Ressources de démonstration

Des ressources de différents types sont préchargées pour démontrer les règles d'autorisation:

| Nom                      | Type     | Classification | Département | Propriétaire |
|--------------------------|----------|---------------|-------------|--------------|
| Document public          | DOCUMENT | PUBLIC        | COMMON      | admin        |
| Rapport IT confidentiel  | REPORT   | CONFIDENTIAL  | IT          | admin        |
| Plan marketing 2023      | PROJECT  | CONFIDENTIAL  | MARKETING   | editor       |
| Données de ventes Q1 2023| DATA_SET | CONFIDENTIAL  | SALES       | user         |
| Projet X                 | PROJECT  | TOP_SECRET    | IT          | admin        |



## Structure des politiques OPA

Les politiques OPA dans `opa/policies/authorization.rego` démontrent plusieurs concepts:

1. **Règles basées sur les attributs utilisateur** - Autorisations selon le rôle, le département, etc.
2. **Règles basées sur les attributs de ressource** - Autorisations selon la classification, le type, etc. 
3. **Règles contextuelles** - Autorisations selon l'action et d'autres informations contextuelles
4. **Décisions explicatives** - Les décisions incluent la raison et des métadonnées


## Avantages à souligner

- **Séparation des préoccupations** - La logique d'autorisation est externalisée d'application
- **Cohérence** - Mêmes règles appliquées partout
- **Maintenance simplifié** - Mise à jour des règles sans redéployer l'application
- **Performance** - OPA est optimisé pour les décisions rapides
- **Explicabilité** - Les décisions incluent les raisons facilitant le debugging
- **Vérifiabilité** - Les politiques peuvent être testées unitairement

## Prochaines étapes

- Ajout d'une interface utilisateur React
- Implémentation de politiques plus sophistiquées (hiérarchies, rôles hérités, etc.)
- Mise en cache des décisions pour améliorer les performances
