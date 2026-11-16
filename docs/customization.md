# Personnalisation du SDK Vox Chat iOS

Ce document décrit les axes de personnalisation offerts aux apps tierces : ils sont volontairement limités à la **couleur d'accent** et à la **typographie**. Tout le reste (couleurs sémantiques, espacements internes, navigation, comportements) est géré par le SDK pour garantir une cohérence d'interface.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## 1. Les deux axes de personnalisation client

La personnalisation tierce se limite à deux champs de `VoxConfig`, passés à `VoxChatSDK.initialize(configuration:)` (voir [démarrage](getting-started.md)) :

| Axe | Champ | Effet |
|---|---|---|
| Couleur d'accent | `accentColor: Color?` | Remplace la couleur de marque et alimente le dégradé du bouton primaire (variants assombri/éclairci dérivés automatiquement). |
| Typographie | `fontFamily: String?` | Famille de police utilisée par toutes les briques. `nil` = SF Pro. |

```swift
VoxChatSDK.initialize(
    configuration: VoxConfig(
        endpoint: "https://sso.exemple.com",
        clientId: "VOTRE_APP_ID",
        redirectURI: "native-vox-sdk://oidc/callback",
        resource: "https://api.exemple.com",
        apiBaseURL: "https://api.exemple.com",
        accentColor: .purple,            // votre couleur de marque
        fontFamily: "MaPolice-Regular"   // nom PostScript de votre famille
    )
)
```

Aucun autre axe n'est personnalisable côté tiers : ni couleurs sémantiques, ni logos, ni textes, ni espacements.

## 2. Contrat typographique

Si vous fournissez une `fontFamily`, vous devez **embarquer les polices dans votre app** (elles ne sont pas livrées dans le SDK) :

- **4 faces obligatoires** : Regular, Medium, Semibold, Bold. Le SDK résout ces quatre graisses ; une face manquante retombe visuellement sur une autre.
- **Nom PostScript de famille** : `fontFamily` doit être le nom PostScript (celui résolu par `UIFont(name:)` et `Font.custom`), pas le nom « affiché » de la police. Exemple : `"Inter-Regular"` plutôt que `"Inter"`.
- **Italique non requis** : le SDK n'utilise pas de variante italique.

### Tailles fixes, sans Dynamic Type

Les tailles de texte du SDK sont **fixes et indépendantes du Dynamic Type** : la taille et la graisse sont décidées par les briques, seule la famille est personnalisable.

L'extension `Font.vox(size:weight:design:)` est le point d'entrée unique du rendu texte :

```swift
Text("Bonjour")
    .font(.vox(size: 16, weight: .medium))
```

- Le paramètre `design` (optionnel) ne concerne que la variante système (par exemple `.rounded`) ; il est **ignoré** quand une famille cliente est configurée.
- Le rendu passe par `Font.vox` en interne : vous n'avez rien à câbler, toutes les briques du SDK l'utilisent déjà avec la famille configurée.

> **Note** : l'accès programmatique direct au thème (par exemple pour produire un `UIFont` pour des vues UIKit ou des `NSAttributedString`) n'est pas exposé publiquement dans cette version. Si vous avez ce besoin, ouvrez une demande auprès d'Oreus : le pont UIKit existe en interne et peut être exposé selon vos retours.

## 3. Thème : couleurs de marque vs couleurs sémantiques

- **Couleurs de marque** (seule catégorie dynamique) : remplacées par votre `accentColor`. Le dégradé du bouton primaire est dérivé automatiquement de votre accent — vous ne personnalisez qu'une couleur, le SDK calcule les variants.
- **Couleurs sémantiques** (succès, erreur, avertissement, fonds, textes…) : **résolues statiquement par le SDK**. Elles ne dépendent pas de votre marque et ne sont pas personnalisables.

En pratique : votre couleur d'accent colore boutons primaires, éléments actifs et états de sélection ; les feedbacks d'erreur, de succès et les fonds restent ceux du SDK.

## 4. Slots : insertion de vues — first-party uniquement

Le SDK expose des **slots** : des points d'insertion de vues (`ViewBuilder` avec valeur par défaut) permettant de placer du contenu supplémentaire dans certaines briques.

**Important** : les slots sont réservés aux **extensions de l'app hôte first-party** (l'app d'origine d'Oreus). Ils ne font **pas** partie du contrat d'intégration tiers : une app tierce ne doit pas compter sur eux pour sa personnalisation. Pour un tiers, les deux seuls axes restent la couleur d'accent et la typographie décrits ci-dessus.

## 5. Padding : qui est responsable de quoi

Répartition claire des marges pour éviter les doubles espacements :

- **Marges externes** (latérales et verticales, c'est-à-dire l'espace entre la brique et les bords de votre écran ou les vues voisines) : **responsabilité de l'app hôte**. Ajoutez le padding autour de la brique dans votre layout.
- **Espacements internes** (entre les éléments d'une même brique) : **responsabilité de la brique**. N'essayez pas de les compenser avec du padding négatif ou des overlays.

```swift
// Correct : l'hôte gère les marges externes
VoxChatContainer(ownsNavigation: false) {
    ChatScreen()
}
.padding(.horizontal, 16)   // marge latérale : votre responsabilité
.padding(.top, 8)           // marge verticale : votre responsabilité
```

## 6. Bouton SSO : `VoxSsoButton`

La brique publique `VoxSsoButton` (« Se connecter avec Oreus ») lance le flux OAuth du SDK (Authorization Code + PKCE via le navigateur système). Son rendu est **personnalisable par votre couleur d'accent** : fond dans la couleur d'accent effective du thème, contenu dans la couleur de texte adaptée, sans dégradé.

```swift
import VoxChatSDK
import VoxCore

VoxSsoButton { success in
    if success {
        // Utilisateur connecté : présentez vos écrans.
    }
}
```

Le bouton gère son propre état de chargement (désactivé pendant le flux). L'écran de connexion complet reste votre responsabilité : la brique fournit le déclencheur, pas la page.

## Pour aller plus loin

- [Démarrage](getting-started.md) : initialisation et champ `VoxConfig`.
- [Scopes et gating](scopes.md) : quelles fonctionnalités votre app peut afficher.
- [Erreurs](errors.md) : comportement du SDK en cas d'échec réseau ou de configuration.
