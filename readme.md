# Preuve de Concept Spring Boot + OPA + GraphQL

Cette preuve de concept démontre l'intégration de Spring Boot avec Open Policy Agent (OPA) pour la gestion des autorisations basées sur les attributs, exposées via une API GraphQL.

## Fonctionnalités

- **API GraphQL** - Interface pour accéder et gérer les ressources
- **Authentification JWT** - Authentification basée sur des tokens
- **Autorisation avec OPA** - Décisions d'autorisation basées sur:
  - Attributs utilisateur (rôles, départements, attributs personnalisés)
  - Attributs de ressource (type, classification, département, tags, attributs personnalisés)
  - Contexte de la requête (action demandée, informations additionnelles)
- **Base de données intégrée** - Base de données H2 en mémoire pour les tests

## Architecture

L'application est structurée selon les principes suivants:

1. **Spring Boot** héberge l'application principale et expose une API GraphQL
2. **OPA** fonctionne comme un service externe qui prend les décisions d'autorisation
3. **Service d'autorisation** dans Spring Boot communique avec OPA
4. **Directive GraphQL** `@authorize` pour protéger les points d'entrée GraphQL

## Configuration requise

- Java 17+
- Maven
- Docker et Docker Compose (pour exécuter OPA)

## Démarrage rapide

1. Démarrer le serveur OPA:
   ```bash
   cd opa
   docker-compose up -d
   ```

2. Démarrer l'application Spring Boot:
   ```bash
   mvn spring-boot:run
   ```

3. Accéder à l'application:
   - GraphQL Playground: http://localhost:8080/api/graphiql
   - Console H2: http://localhost:8080/api/h2-console (JDBC URL: `jdbc:h2:mem:opa`, User: `sa`, Password: `password`)

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

## Comment tester les autorisations

1. Se connecter avec un utilisateur (obtenir un token JWT):
   ```graphql
   mutation {
     login(username: "admin", password: "admin") {
       token
     }
   }
   ```

2. Utiliser le token dans l'en-tête HTTP `Authorization: Bearer <token>` pour les requêtes suivantes.

3. Tester l'accès aux ressources:
   ```graphql
   query {
     resources {
       id
       name
       securityClassification
       department
     }
   }
   ```

4. Tester explicitement une autorisation:
   ```graphql
   query {
     checkAuthorization(resourceId: 1, action: "update") {
       allowed
       reason
       metadata
     }
   }
   ```

## Structure des politiques OPA

Les politiques OPA dans `opa/policies/authorization.rego` démontrent plusieurs concepts:

1. **Règles basées sur les attributs utilisateur** - Autorisations selon le rôle, le département, etc.
2. **Règles basées sur les attributs de ressource** - Autorisations selon la classification, le type, etc. 
3. **Règles contextuelles** - Autorisations selon l'action et d'autres informations contextuelles
4. **Décisions explicatives** - Les décisions incluent la raison et des métadonnées

## Exemples de requêtes GraphQL

### Authentification
```graphql
mutation {
  login(username: "admin", password: "admin") {
    token
    id
    username
    roles
  }
}
```

### Obtenir les ressources
```graphql
query {
  resources {
    id
    name
    type
    securityClassification
    department
    owner {
      username
    }
    tags
  }
}
```

### Créer une ressource
```graphql
mutation {
  createResource(input: {
    name: "Nouveau document",
    description: "Description du document",
    type: DOCUMENT,
    securityClassification: "CONFIDENTIAL",
    department: "IT",
    tags: ["document", "nouveau"]
  }) {
    id
    name
  }
}
```

### Vérifier l'autorisation
```graphql
query {
  checkAuthorization(resourceId: 2, action: "update") {
    allowed
    reason
    metadata
  }
}
```

## Comment démontrer OPA à votre équipe

1. **Présenter l'architecture** - Utilisez le diagramme d'architecture pour expliquer comment OPA s'intègre
2. **Montrer les politiques** - Expliquez comment les règles Rego traduisent les exigences métier
3. **Démonstration dynamique** - Connectez-vous avec différents utilisateurs et montrez comment les décisions d'autorisation changent
4. **Modifier une politique** - Montrez comment la modification d'une politique affecte immédiatement les autorisations sans redémarrer l'application
5. **Examiners les logs** - Montrez comment les décisions sont journalisées pour l'audit

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
- Déploiement en production avec plusieurs instances OPA