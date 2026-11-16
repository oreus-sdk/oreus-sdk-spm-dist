# Briques Reviews

Ce document catalogue les briques publiques du SDK Vox Chat iOS consacrées aux avis sur les agents : la section d'affichage des avis, la carte d'avis individuelle et l'entité qui les alimente. Les briques Reviews sont volontairement **neutres en données** : votre app fournit la page d'avis et décide des actions.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Vue d'ensemble

| Brique | Rôle | Scope requis |
|---|---|---|
| `AgentReviewsSection` | Section « Notes et avis » complète | aucun (données fournies) |
| `ReviewEntity` | Entité d'avis, constructeur public | aucun |
| `WriteReviewModal` | Modale d'écriture d'avis | — (interne, voir note d'écart) |

Note d'écart : les composants de rendu individuels `ReviewCard`, `ReviewRatingBadge` et `ReviewTruncatableText` sont **internes** au SDK dans la version documentée — ils composent `AgentReviewsSection` mais ne font pas partie du contrat public. La modale d'écriture d'avis (`WriteReviewModal`) est également internalisée : elle est présentée par le SDK depuis la fiche détaillée d'agent ([bricks-agents](bricks-agents.md), CTA « Noter cet agent »), mais n'est pas instanciable directement. Ne comptez pas sur ces types dans votre intégration.

---

### AgentReviewsSection

Section « Notes et avis (total) » : titre avec compteur, note moyenne affichée en grand, défilement horizontal des cartes d'avis et CTA « Noter cet agent ». La brique est neutre en données et en routage : elle affiche ce que vous fournissez et délègue les deux intentions (lecture intégrale d'un avis tronqué, écriture d'un avis).

**Import** : `import VoxCore`

```swift
AgentReviewsSection(
    reviews: reviews.data,            // [ReviewEntity]
    totalResults: reviews.totalResults,
    averageRating: "4.6",
    hasAlreadyPostedReview: userHasReviewed,
    showsWriteReviewCta: true,
    onTruncatedReviewTapped: { fullText in
        // présenter la lecture intégrale de l'avis
    },
    onWriteReviewTapped: {
        // ouvrir votre flux d'écriture d'avis
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `reviews` | `[ReviewEntity]` | Avis paginés à afficher ; une liste vide masque le défilement. |
| `totalResults` | `Int?` (défaut `nil`) | Nombre total d'avis (compteur du titre) ; `nil` retombe sur le nombre d'avis fournis. |
| `averageRating` | `String?` (défaut `nil`) | Note moyenne pré-formatée affichée en grand ; `nil` masque la ligne. |
| `hasAlreadyPostedReview` | `Bool` (défaut `false`) | Masque le CTA d'écriture (un utilisateur ne poste qu'un avis par agent). |
| `showsWriteReviewCta` | `Bool` (défaut `true`) | Affiche le CTA « Noter cet agent ». |
| `onTruncatedReviewTapped` | `(String) -> Void` | Appelé avec le texte intégral d'un avis tronqué. |
| `onWriteReviewTapped` | `(() -> Void)?` | Action du CTA d'écriture ; `nil` masque le CTA. |

**Scope requis** : aucun — la brique ne charge rien, elle affiche vos données. Le gating s'applique à l'écriture : c'est à vous d'aligner l'affichage du CTA sur `write:reviews` (dans le SDK, le CTA de la fiche détaillée est masqué sans ce scope — politique d'invisibilité, voir [scopes](scopes.md)).

**États** : rendu statique sans état de données ; avis tronqués automatiquement avec appel du callback de lecture intégrale.

---

### ReviewEntity

Entité d'avis publique : alimente `AgentReviewsSection` et les affichages d'avis du SDK. Instanciable par votre app.

**Import** : `import VoxCore`

```swift
let review = ReviewEntity(
    id: "review-1",
    rating: 5,
    title: "Excellent assistant",
    description: "A transformé notre flux de revue de code…",
    userId: "user-42",
    username: "Camille",
    createdAt: Date()
)
```

**Propriétés** :

| Propriété | Type | Description |
|---|---|---|
| `id` | `String` | Identifiant de l'avis. |
| `rating` | `Int` | Note de 1 à 5. |
| `title` | `String` | Titre de l'avis. |
| `description` | `String` | Texte intégral de l'avis. |
| `userId` | `String` | Identifiant de l'auteur. |
| `username` | `String` | Nom affiché de l'auteur. |
| `createdAt` | `Date?` | Date de publication. |

**Scope requis** : aucun.

---

## Pour aller plus loin

- [Briques Agents](bricks-agents.md) : `AgentDetailScreen` et `AgentDetailsModal`, qui intègrent la section avis et le CTA de notation gaté `write:reviews`.
- [Scopes et gating](scopes.md) : `read:reviews`, `write:reviews`.
