package authorization

# Règle par défaut : refuser l'accès
default allow = false

# Règle principale qui décide l'autorisation
allow if {
    # Vérifie les conditions basées sur l'action
    action_rules[input.action]

    # Vérifie les conditions basées sur l'utilisateur et ses attributs
    user_rules[input.action]

    # Vérifie les conditions basées sur la ressource et ses attributs (si applicable)
    resource_rules[input.action]

    # Vérifie les conditions basées sur le contexte
    context_rules[input.action]
}

# Règles basées sur l'action
action_rules["read"] if {
    # Tout utilisateur authentifié peut lire
    true
}

action_rules["list"] if {
    # Tout utilisateur authentifié peut lister
    true
}

action_rules["create"] if {
    # Tout utilisateur authentifié peut créer
    true
}

action_rules["update"] if {
    # Conditions d'update vérifiées dans resource_rules
    true
}

action_rules["delete"] if {
    # Conditions de delete vérifiées dans resource_rules
    true
}

action_rules["admin"] if {
    # Seuls les administrateurs peuvent exécuter des actions d'administration
    some i
    input.user.roles[i] == "ADMIN"
}

# Règles basées sur l'utilisateur
user_rules["active"] if {
    # Vérifie que l'utilisateur est actif
    input.user.enabled == true
}

# Propager la règle d'utilisateur actif à toutes les actions spécifiques
user_rules["read"] if {
    user_rules["active"]
}

user_rules["list"] if {
    user_rules["active"]
}

user_rules["create"] if {
    user_rules["active"]
    # Tout utilisateur actif peut créer une ressource
    true
}

user_rules["update"] if {
    user_rules["active"]
    # Seuls les utilisateurs avec le rôle EDITOR ou ADMIN peuvent mettre à jour
    some i
    input.user.roles[i] == "EDITOR"
}

user_rules["update"] if {
    user_rules["active"]
    # Les ADMIN peuvent toujours mettre à jour
    some i
    input.user.roles[i] == "ADMIN"
}

user_rules["delete"] if {
    user_rules["active"]
    # Seuls les ADMIN peuvent supprimer
    some i
    input.user.roles[i] == "ADMIN"
}

user_rules["admin"] if {
    user_rules["active"]
    # Seuls les ADMIN ont accès aux fonctions d'administration
    some i
    input.user.roles[i] == "ADMIN"
}

# Règles basées sur la ressource
resource_rules["read"] if {
    # Pour les ressources existantes, vérifier la classification de sécurité
    input.resource.securityClassification == "PUBLIC"
}

resource_rules["read"] if {
    # Les utilisateurs peuvent lire les ressources CONFIDENTIELLES de leur département
    input.resource.securityClassification == "CONFIDENTIAL"
    some i
    input.resource.department == input.user.departments[i]
}

resource_rules["read"] if {
    # Les utilisateurs ADMIN peuvent lire toutes les ressources
    some i
    input.user.roles[i] == "ADMIN"
}

resource_rules["list"] if {
    # Règle simple pour la démonstration - la vraie logique dépendrait de votre cas d'utilisation
    true
}

resource_rules["create"] if {
    # Pour la création, nous n'avons pas encore de ressource à vérifier
    true
}

resource_rules["update"] if {
    # L'utilisateur peut mettre à jour sa propre ressource
    input.resource.ownerId == input.user.id
}

resource_rules["update"] if {
    # L'utilisateur peut mettre à jour des ressources dans son département avec le rôle EDITOR
    some i
    input.resource.department == input.user.departments[i]
    some j
    input.user.roles[j] == "EDITOR"
}

resource_rules["delete"] if {
    # L'utilisateur peut supprimer sa propre ressource s'il est ADMIN
    input.resource.ownerId == input.user.id
    some i
    input.user.roles[i] == "ADMIN"
}

resource_rules["delete"] if {
    # Seuls les ADMIN du même département peuvent supprimer
    some i
    input.resource.department == input.user.departments[i]
    some j
    input.user.roles[j] == "ADMIN"
}

# Règles basées sur les attributs de ressource
resource_rules["read"] if {
    # Accès spécial basé sur un attribut de ressource (exemple)
    resource_has_attribute("access_level", "public")
}

# Règles basées sur le contexte
context_rules["read"] if {
    # Règle générique pour la lecture
    true
}

context_rules["list"] if {
    # Règle générique pour le listage
    true
}

context_rules["create"] if {
    # Règle générique pour la création
    true
}

context_rules["update"] if {
    # Règle générique pour la mise à jour
    true
}

context_rules["delete"] if {
    # Règle générique pour la suppression
    true
}

context_rules["admin"] if {
    # Règle générique pour l'administration
    true
}

# Vérifications des attributs
# Vérifie si un attribut avec une clé et une valeur spécifiques existe
resource_has_attribute(key, value) if {
    some i
    input.resource.attributes[i].key == key
    input.resource.attributes[i].value == value
}

user_has_attribute(key, value) if {
    some i
    input.user.attributes[i].key == key
    input.user.attributes[i].value == value
}

# Prédicats d'aide pour déterminer la raison
admin_user if {
    some i
    input.user.roles[i] == "ADMIN"
}

owner_resource if {
    input.resource.ownerId == input.user.id
}

public_resource if {
    input.resource.securityClassification == "PUBLIC"
}

department_access if {
    some i
    input.resource.department == input.user.departments[i]
}

# Détermination de la raison
reason = "Accès autorisé en tant qu'administrateur" if {
    allow
    admin_user
}

reason = "Accès autorisé car l'utilisateur est le propriétaire" if {
    allow
    owner_resource
    not admin_user
}

reason = "Accès autorisé car la ressource est publique" if {
    allow
    public_resource
    not admin_user
    not owner_resource
}

reason = "Accès autorisé car l'utilisateur appartient au département" if {
    allow
    department_access
    not admin_user
    not owner_resource
    not public_resource
}

reason = "Accès autorisé par défaut" if {
    allow
    not admin_user
    not owner_resource
    not public_resource
    not department_access
}

# Information de ressource
resource_info = {
    "id": input.resource.id,
    "type": input.resource.type,
    "securityClassification": input.resource.securityClassification,
    "department": input.resource.department
} if {
    input.resource
}

default resource_info = null

# Règle pour renvoyer plus d'informations avec la décision
decision = {
    "allow": allow,
    "reason": reason,
    "metadata": {
        "user": {
            "id": input.user.id,
            "roles": input.user.roles
        },
        "resource": resource_info,
        "action": input.action
    }
}