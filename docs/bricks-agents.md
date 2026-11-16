# Briques Agents

Ce document catalogue les briques publiques du SDK Vox Chat iOS consacrées aux agents : la liste « mes agents », la bibliothèque (store) d'agents, la fiche détaillée et ses modales, plus les briques atomiques de composition. Toutes s'intègrent dans une `NavigationStack` pilotée par votre app (voir [démarrage](getting-started.md)).

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Vue d'ensemble

| Brique | Rôle | Scope requis |
|---|---|---|
| `VoxAgents` | Liste paginée des agents de l'utilisateur | `read:agents` |
| `VoxAgentLibrary` | Bibliothèque (store) des agents disponibles | `read:stores` |
| `AgentDetailScreen` | Fiche détaillée d'un agent | `read:agents` |
| `AgentDetailsModal` | Modale présentant la fiche détaillée | `read:agents` |
| `AgentLimitModal` | Alerte « limite d'agents atteinte » | aucun |
| `AgentStatCard`, `AgentToolPill`, `AgentToolsList` | Briques atomiques statiques | aucun |

---

### VoxAgents

Liste paginée (20 par page) des agents déployés de l'utilisateur connecté : cartes canoniques (avatar, nom, auteur, description sur 2 lignes, nombre d'utilisateurs, pastille de catégorie) avec bouton « Utiliser ». Le bouton « Utiliser » émet par défaut une `HostAction.useThisAgent` (agent mobilisé dans le chat) en plus de son callback.

**Import** : `import VoxCore`

```swift
VoxAgents(
    orientation: .vertical,
    title: "Mon équipe",
    onSeeAllClick: { /* présenter la liste complète */ },
    onAgentClick: { agent in /* navigation vers la fiche détaillée */ },
    onUseClick: { agent in
        // L'agent est mobilisé : démarrez un chat avec agent.toMentionItem
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `pageSize` | `Int` (défaut `20`) | Taille de page de la pagination. |
| `orientation` | `VoxAgentsOrientation` (défaut `.vertical`) | `.vertical` : colonne unique sur iPhone, grille adaptative sur iPad. `.horizontal` : rangée défilante à hauteur fixe. |
| `showFavorite` | `Bool` (défaut `false`) | Affiche l'étoile favori de la carte, en lecture seule (l'écriture du favori n'est pas exposée aux tiers). |
| `addToChatOnUse` | `Bool` (défaut `true`) | « Utiliser » émet aussi la `HostAction.useThisAgent` (retour au chat avec l'agent en mention). |
| `title` | `LocalizedStringKey?` (défaut « Mes agents ») | Titre de la section ; `nil` supprime l'écharpe de titre. |
| `onSeeAllClick` | `(() -> Void)?` | Action du lien « Voir tout » de l'écharpe. |
| `agentRepository` | `AgentRepository` | Dépendance injectable (tests, previews). |
| `onAgentClick` | `((AgentLightEntity) -> Void)?` | Tap sur une carte. |
| `onUseClick` | `((AgentLightEntity) -> Void)?` | Bouton « Utiliser ». |

**Scope requis** : `read:agents` (fonctionnalité absente sinon — écran de verrouillage `FeatureLockedScreen` en filet). Voir [scopes](scopes.md).

**États** : chargement (squelettes de cartes) / vide (message dédié) / erreur avec bouton « Réessayer » / liste paginée infinie. La brique ne pose ni fond ni marge externe : ils sont à votre charge (voir [personnalisation](customization.md)).

---

### VoxAgentLibrary

Bibliothèque d'agents : charge les items du store selon un filtre (Tous, Découvrir, Les plus populaires, Oreus), liste verticale paresseuse (grille adaptative sur iPad) et présente la modale de détail d'un agent lorsqu'une carte est touchée — la brique gère cette présentation elle-même.

**Import** : `import VoxCore`

```swift
VoxAgentLibrary(
    filter: .mostPopular,
    onSelect: { item in /* tap sur une carte (la modale est présentée par la brique) */ },
    onUseClick: { mention in
        // « Utiliser » depuis la modale : agent prêt pour le chat
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `filter` | `VoxStoreScope` (défaut `.all`) | Filtre initial du catalogue (`.all`, `.discover`, `.mostPopular`, `.oreus`). Modifiable : la liste se recharge au changement. |
| `voxStoreRepository` | `VoxStoreRepository` | Dépendance injectable (tests, previews). |
| `onSelect` | `((AgentStoreItemEntity) -> Void)?` | Tap sur une carte. |
| `onUseClick` | `((MentionItemEntity) -> Void)?` | « Utiliser » de la modale, avec l'agent sous forme de mention prête pour le chat. |

**Scope requis** : `read:stores` (fonctionnalité absente sinon — `FeatureLockedScreen` en filet). L'ajout d'un agent à la liste de l'utilisateur, proposé depuis la modale de détail, exige en outre `write:stores` : sans ce scope l'action est masquée.

**États** : chargement (squelettes) / vide / erreur (retry) / liste paginée avec chips de filtre.

---

### AgentDetailScreen

Fiche détaillée d'un agent : statistiques (note, utilisateurs, mise à jour, auteur), phrases d'accroche, description, outils activés, section avis et actions (« Utiliser », « Ajouter à mes agents » pour un item de store, « Noter cet agent », retrait).

**Import** : `import VoxCore`

```swift
NavigationStack {
    AgentDetailScreen(
        agentId: agent.id,
        storeItemId: agent.storeItemId
    )
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `agentId` | `String` | Identifiant de l'agent à afficher. |
| `storeItemId` | `String?` | Identifiant de l'item de store associé : active l'ajout/retrait de « mes agents » (gated `write:stores`). |
| `showsNavigationBar` | `Bool` (défaut `true`) | `false` quand votre app compose sa propre barre : le SDK retire son titre et son bouton favori de la barre. |
| `showsWriteReviewCta` | `Bool` (défaut `true`) | Affiche le CTA « Noter cet agent » de la section avis. |
| `agentRepository` | `AgentRepository` | Dépendance injectable. |

**Scope requis** : `read:agents`. Les actions fines sont gatées individuellement : `write:stores` pour l'ajout à « mes agents », `write:reviews` pour le CTA de notation (masqué sinon — invisibilité, voir [scopes](scopes.md)).

**États** : chargement (squelette) / contenu / erreur (retry). Le bouton « Utiliser » émet la `HostAction.useThisAgent` : c'est votre app qui décide de la suite (retour au chat, etc.).

---

### AgentDetailsModal

Modale (sheet) autonome qui présente `AgentDetailScreen` avec son propre routage interne, et capte les intentions « Utiliser » et « limite d'agents atteinte » pour vous les déléguer.

**Import** : `import VoxCore`

```swift
Button("Détails") { showDetail = true }
    .agentDetailsModal(
        isPresented: $showDetail,
        agentId: agent.id,
        storeItemId: agent.storeItemId
    ) { mention in
        // « Utiliser cet agent » : démarrez un chat avec cette mention
    }
```

**Paramètres** (via le modifier `View.agentDetailsModal(isPresented:agentId:storeItemId:showsWriteReviewCta:onUse:)`) :

| Param | Type | Description |
|---|---|---|
| `isPresented` | `Binding<Bool>` | Pilote la présentation de la modale. |
| `agentId` | `String` | Identifiant de l'agent à afficher. |
| `storeItemId` | `String?` | Item de store associé (entrée « Ajouter à mes agents »). |
| `showsWriteReviewCta` | `Bool` (défaut `true`) | CTA « Noter cet agent » de la section avis. |
| `onUse` | `((MentionItemEntity) -> Void)?` | « Utiliser cet agent » ; la modale se ferme ensuite. |

**Scope requis** : `read:agents` (la fiche). Voir [scopes](scopes.md).

**États** : la fiche gère ses propres états ; à la limite d'agents atteinte, la modale se ferme et l'intention vous revient (`HostAction.agentLimitReached`).

---

### AgentLimitModal

Alerte système « limite d'agents atteinte » : titre, message et actions Annuler / Gérer mes agents. Neutre en routage : c'est votre app qui décide de ce que fait « Gérer ».

**Import** : `import VoxCore`

```swift
MonEcran()
    .agentLimitModal(isPresented: $limitReached) {
        // ouvrir votre écran de gestion des agents
    }
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `isPresented` | `Binding<Bool>` | Pilote la présentation de l'alerte ; repassé à `false` à chaque action. |
| `onManage` | `(() -> Void)?` | Action du bouton « Gérer mes agents » ; `nil` masque le bouton. |

**Scope requis** : aucun.

**États** : alerte système, sans état de données.

---

### AgentStatCard et AgentToolsList

Briques atomiques statiques pour composer vos propres fiches d'agents : `AgentStatCard` affiche une statistique (icône, valeur en gras, libellé en capitales) ; `AgentToolsList` affiche le titre « Outils » suivi de pills ; `AgentToolPill` est la pill individuelle, réutilisable seule.

**Import** : `import VoxCore`

```swift
HStack(spacing: 12) {
    AgentStatCard(icon: "AgentsRate", value: "4.8", label: "AgentDetail.rating")
    AgentStatCard(icon: "AgentsUser", value: "1 240", label: "AgentDetail.users",
                  showsBackground: false) // carte nue pour une barre groupée
}

AgentToolsList(tools: [
    AgentToolEntity(name: "gmail"),
    AgentToolEntity(name: "mcp")   // connecteur MCP personnalisé
])
```

**Paramètres `AgentStatCard`** :

| Param | Type | Description |
|---|---|---|
| `icon` | `String` | Nom de l'asset image (icône 16 pt). |
| `value` | `String?` | Valeur affichée en gras ; `nil` affiche un tiret. |
| `label` | `LocalizedStringKey` | Clé de localisation du libellé, rendu en capitales. |
| `showsBackground` | `Bool` (défaut `true`) | Fond individuel ou carte nue pour composer une barre groupée. |

**Paramètres `AgentToolsList`** : `tools: [AgentToolEntity]` — une liste vide ne rend rien. `AgentToolPill(tool:)` prend un outil unique (intégration connue ou connecteur MCP personnalisé).

**Scope requis** : aucun.

**États** : rendu statique ; pas d'état de données.

---

## Pour aller plus loin

- [Briques Reviews](bricks-reviews.md) : la section avis intégrée à la fiche détaillée.
- [Briques Chat](bricks-chat.md) : mobiliser un agent dans une conversation.
- [Scopes et gating](scopes.md) : `read:agents`, `read:stores`, `write:stores`, `write:reviews`.
