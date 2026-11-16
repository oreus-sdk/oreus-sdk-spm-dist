# Façades complètes (écrans data-driven)

Ce document catalogue les **façades** publiques du SDK Vox Chat iOS : des écrans complets, data-driven, qui combinent chargement, états de liste, recherche et navigation interne. Elles s'ajoutent aux briques granulaires catalogées dans [bricks-chat](bricks-chat.md), [bricks-agents](bricks-agents.md), [bricks-drive](bricks-drive.md), [bricks-reviews](bricks-reviews.md) et [bricks-voxies](bricks-voxies.md).

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Façade ou brique granulaire ?

| Besoin | Utiliser |
|---|---|
| Un écran prêt à l'emploi (chargement, recherche, pagination, états d'erreur gérés) | **Façade** (ce document) |
| Un composant à composer dans votre propre écran, avec vos callbacks | **Brique granulaire** (bricks-*.md) |

Les façades gatent leur contenu par scope (fail-closed, voir [scopes](scopes.md)) et délèguent à votre app les intentions métier via la couche de délégation hôte (`.onHostAction`, voir [délégation hôte](host-delegation.md)).

## Vue d'ensemble

| Façade | Rôle | Scope requis | Documentée où |
|---|---|---|---|
| `ChatScreen` | Conversation complète (4 points d'entrée) | `write:vox` | [bricks-chat](bricks-chat.md) |
| `MyAgentsScreen` | Mes agents déployés (liste, recherche, catégories) | `read:agents` | ci-dessous |
| `AgentDetailScreen` | Fiche détaillée d'un agent | `read:agents` | [bricks-agents](bricks-agents.md) |
| `AgentsFromChatScreen` | Liste des agents accessible depuis le chat | `read:agents` | ci-dessous |
| `PurchasedAgentsScreen` | Agents achetés (liste) | `read:stores` | ci-dessous |
| `VoxStoreScreen` | Boutique (découverte, populaires, recherche) | `read:stores` | ci-dessous |
| `MyDriveScreen` | Mon Drive (collections, fichiers) | `read:folders` + `read:files` | [bricks-drive](bricks-drive.md) |
| `VoxiesScreen` | Liste des voxies (héros, création, recherche) | `read:voxies` + `write:voxies` | ci-dessous (note d'écart) |
| `VoxieEditorScreen` | Éditeur complet d'un voxie | `read:voxies` + `write:voxies` | [bricks-voxies](bricks-voxies.md) |

---

### MyAgentsScreen

Liste paginée des agents déployés de l'utilisateur connecté : recherche dans la toolbar, filtres par catégorie, cartes canoniques (avatar, nom, auteur, description, nombre d'utilisateurs) avec états de chargement (placeholders animés), vide et d'erreur (retry).

**Import** : `import VoxCore`

```swift
// Rendu autonome (défaut) : la façade monte sa propre NavigationStack
MyAgentsScreen()

// Intégration dans la pile de l'hôte
MyAgentsScreen(ownsNavigation: false)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `repository` | `AgentRepository` | Dépendance injectable (tests, previews). |
| `ownsNavigation` | `Bool` (défaut `true`) | `true` : la façade monte sa `NavigationStack`. `false` : la pile de push est pilotée par votre app. |

**Scope requis** : `read:agents` (fonctionnalité `agentsBrowse`). Sans ce scope, la façade rend le filet de verrouillage interne (voir [scopes](scopes.md)).

**États** : chargement (squelettes animés) / liste paginée avec recherche / erreur (retry). La catégorie sélectionnée vit dans la toolbar.

**Différence avec les briques** : `VoxAgents` (voir [bricks-agents](bricks-agents.md)) est la brique de présentation à composer ; `MyAgentsScreen` est l'écran complet clé en main. Préférez la façade si vous voulez l'écran tel quel, la brique si vous composez votre propre habillage.

**Note** : l'étoile favori des cartes n'est visible que dans l'app Oreus (voir [écarts fonctionnels](api-parity.md)) ; la mention favorite reste lisible en lecture dans les données.

---

### AgentsFromChatScreen

Liste des agents mobilisables depuis le chat : c'est l'écran ouvert quand l'utilisateur tape le bouton « agents » de la toolbar du chat. Recherche pleine page, cartes à image de fond, tap = intention d'ouverture de la fiche détaillée (déléguée à votre app via `.onHostAction(.openAgentDetail(...))`).

**Import** : `import VoxCore`

```swift
VoxChatContainer {
    AgentsFromChatScreen()
        .addDismissButton() // bouton de fermeture (présentation en sheet)
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `agentRepository` | `AgentRepository` | Dépendance injectable (tests, previews). |

**Scope requis** : `read:agents` (fonctionnalité `agentsBrowse`).

**États** : chargement (squelettes) / liste + recherche / « aucun résultat » (recherche vide) / erreur.

**Différence avec les briques** : c'est l'écran du flux chat → agents. Il est livré avec son bouton de fermeture et son titre de navigation ; son contenu est plus léger que `MyAgentsScreen` (pas de catégories, pas de pagination).

---

### PurchasedAgentsScreen

Liste paginée des agents **achetés** de l'utilisateur : cartes canoniques avec bouton « Utiliser » (intention déléguée à votre app via `.onHostAction(.useThisAgent(mention:))`). C'est l'écran atteint depuis la toolbar du store (« achetés ») et la réaction canonique à `.agentLimitReached`.

**Import** : `import VoxCore`

```swift
NavigationStack {
    PurchasedAgentsScreen()
}
```

**Paramètres** : aucun (init public sans argument, dépendances résolues par le conteneur SDK).

**Scope requis** : `read:stores` (fonctionnalité `store`). Sans ce scope, la façade rend le filet de verrouillage interne.

**États** : chargement / liste / vide (message dédié) / erreur (retry + fermeture).

---

### VoxStoreScreen

Boutique du SDK : sections « Découvrir » et « Les plus populaires » (carrousels horizontaux de cartes), accès aux agents achetés via la toolbar, recherche pleine page via toggle. Les écrans internes (recherche, listes par catégorie, détail) sont atteints par la navigation intra-façade.

**Import** : `import VoxCore`

```swift
// Rendu autonome (défaut)
VoxStoreScreen()

// Intégration dans la pile de l'hôte : le conteneur de la façade ne monte
// pas de NavigationStack, la vue racine est poussée dans votre pile
VoxStoreScreen(ownsNavigation: false)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `voxStoreRepository` | `VoxStoreRepository` | Dépendance injectable (tests, previews). |
| `ownsNavigation` | `Bool` (défaut `true`) | `true` : la façade monte sa `NavigationStack`. `false` : la pile de push est pilotée par votre app. Les sheets internes du store (listes d'agents, détail) continuent de transiter par le conteneur de la façade. |

**Scope requis** : `read:stores` (fonctionnalité `store`). Les achats sont gatés `write:stores` (fonctionnalité `storePurchase`, voir [scopes](scopes.md)).

**États** : chargement (squelettes animés) / contenu (sections découvreur + populaires) / erreur (retry). La façade rafraîchit ses données quand un achat ou une révocation a lieu (notification interne du store).

**Comportement host-scoped** (à connaître pour une intégration tierce) :

- **Détail d'un item du store** : la consultation d'une fiche passe par un paramètre de route différencié côté serveur. Dans le contrat tiers, ce paramètre est **obligatoire** (valeur `VOX`) ; le SDK l'ajoute automatiquement — aucun réglage de votre part.
- **Starter kit** : la section « starter kit » n'a pas d'équivalent dans le contrat tiers. Chez un hôte tiers, l'appel est court-circuité et la section est simplement masquée — l'écran reste complet et fonctionnel (découvrir + populaires + recherche). Dans l'app Oreus, la section apparaît et se dégrade en tableau vide si le serveur ne renvoie rien, sans faire échouer l'écran.

**Différence avec les briques** : les briques store (voir [bricks-agents](bricks-agents.md) pour les cartes et modales) composent votre propre écran boutique ; `VoxStoreScreen` est l'écran complet prêt à l'emploi.

---

### VoxiesScreen (note d'écart)

La façade `VoxiesScreen` (héros, champ de création par description, liste avec recherche, pagination) est **publique** mais son usage s'adresse à la coquille de l'app Oreus : son contrat repose entièrement sur la couche de délégation hôte (émissions `.useThisVoxie`, `.openVoxieEditor`, écoute de la notification de fermeture d'écran hôte, gestion du brouillon partagé). Pour une intégration tierce, préférez la composition des briques `VoxVoxieList` + `VoxDescribeVoxie` documentées dans [bricks-voxies](bricks-voxies.md) : vous recevez les callbacks directs (`onSelect`, `onEditClick`, `onCreate`, `onContinue`) et pilotez vous-même la présentation de `VoxieEditorScreen` et `ChatScreen(voxie:)`.

Si vous composez malgré tout `VoxiesScreen`, sachez que :

- elle émet des `HostAction` et attend que votre app les interprète (voir [délégation hôte](host-delegation.md)) ;
- sa liste se rafraîchit à la fermeture de l'écran d'éditeur présenté par l'hôte, signalée par la notification `.hostScreenDismissed` (voir [délégation hôte](host-delegation.md)) ;
- son scope requis est `read:voxies` + `write:voxies` cumulés.

---

### Écrans sans façade publique

| Écran | Statut | Alternative |
|---|---|---|
| `VoxiePreviewScreen` (aperçu d'un voxie en conversation) | **internal** | Présenté automatiquement par `VoxieEditorScreen` via son bouton d'aperçu (voir [bricks-voxies](bricks-voxies.md)). Non instanciable directement. |
| Écrans internes du store (recherche détaillée, listes par catégorie, consultés récemment) | **internal** | Atteints par la navigation intra-façade de `VoxStoreScreen`. |
| Écran « Connexions d'applications » | **first-party** | L'intention est déléguée à l'hôte via `.onHostAction(.openIntegrations)` (voir [écarts fonctionnels](api-parity.md) et [délégation hôte](host-delegation.md)). |

---

## Pour aller plus loin

- [Délégation hôte](host-delegation.md) : `HostAction`, `.onHostAction`, ré-injection dans les sheets.
- [Scopes et gating](scopes.md) : les scopes requis par chaque façade.
- [Écarts fonctionnels](api-parity.md) : ce qui est réservé à l'app Oreus et pourquoi.
- [Personnalisation](customization.md) : couleur d'accent, typographie, marges de page.
