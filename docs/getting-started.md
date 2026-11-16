# Démarrage avec le SDK Vox Chat iOS

Ce guide décrit l'intégration du SDK Vox Chat iOS (`VoxChatSDK` + `VoxCore`) dans une app iOS tierce : ajout du package, initialisation, configuration et premier écran. Le SDK est distribué sous forme de XCFrameworks binaires via Swift Package Manager.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez (par exemple `docs/` sur le tag `v0.1.0`), pas la branche principale.

---

## 1. Ajouter le package dans Xcode

1. Dans Xcode : **File > Add Package Dependencies…**
2. Collez l'URL du dépôt de distribution :
   ```
   https://github.com/oreus-sdk/oreus-sdk-spm-dist.git
   ```
3. Choisissez la règle de version **Up to Next Minor** à partir de `0.1.0` (ou épinglez exactement `Exact Version` si vous préférez figer vos mises à jour).
4. Ajoutez les deux produits à votre target d'app :
   - **VoxChatSDK** — point d'entrée (initialisation, reset, version) ;
   - **VoxCore** — écrans SwiftUI, briques et couche de délégation hôte.

## 2. Contrat d'imports : les deux modules sont obligatoires

Le SDK n'expose **aucune réexportation**. L'app hôte doit importer les deux modules explicitement :

```swift
import VoxChatSDK   // initialisation : VoxChatSDK.initialize / reset / version
import VoxCore      // écrans SwiftUI (ChatScreen, …) et couche de délégation hôte
```

Un import seul ne suffit pas : sans `import VoxChatSDK` vous n'avez pas accès au cycle de vie, sans `import VoxCore` vous n'avez pas accès aux écrans et aux types de configuration avancés.

## 3. Initialiser le SDK

L'app hôte s'auto-initialise : le SDK exige une `VoxConfig` complète, il n'y a **aucun repli** ni configuration implicite. Appelez `VoxChatSDK.initialize(configuration:)` une seule fois, typiquement dans le `init()` de votre `App`, avant le premier frame.

```swift
import SwiftUI
import VoxChatSDK
import VoxCore

@main
struct MonApp: App {
    init() {
        VoxChatSDK.initialize(
            configuration: VoxConfig(
                // Racine du tenant OIDC (origine nue, sans slash final ;
                // le SDK normalise de toute façon les slashs de fin).
                endpoint: "https://sso.exemple.com",
                // client_id OIDC de votre application (App ID fourni par la
                // console Oreus). Ce n'est PAS votre Bundle ID.
                clientId: "VOTRE_APP_ID",
                // Redirect URI en schéma personnalisé. Le schéma canonique
                // du SDK est native-vox-sdk://oidc/callback.
                redirectURI: "native-vox-sdk://oidc/callback",
                // Indicateur de ressource RFC 8707 visant l'API Oreus.
                resource: "https://api.exemple.com",
                // Origine nue du backend Oreus : SANS préfixe /api/v1 ni
                // /api/v1/external. Le SDK construit lui-même ces préfixes
                // de routage ; les indiquer ici casserait les appels réseau.
                apiBaseURL: "https://api.exemple.com",
                // Personnalisation (les deux seuls axes client, optionnels) :
                accentColor: .purple,
                fontFamily: "MaPolice-Regular"
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Détail des champs

| Champ | Description |
|---|---|
| `endpoint` | Origine nue du serveur d'autorisation OIDC. Le slash final est géré par le SDK. |
| `clientId` | `client_id` OIDC de votre app (App ID console Oreus), public par nature. |
| `redirectURI` | Redirect URI en schéma personnalisé, déclarée à l'identique côté serveur d'autorisation. Le schéma canonique du SDK est `native-vox-sdk://oidc/callback`. |
| `resource` | Indicateur de ressource RFC 8707. C'est un identifiant, pas une adresse réseau : distinct de `apiBaseURL`. |
| `apiBaseURL` | Origine nue du backend Oreus. Les préfixes `/api/v1` (routes first-party) et `/api/v1/external` (contrat tiers) sont construits par le SDK. Ne les ajoutez pas. |
| `scopes` | Scopes demandés, séparés par une espace. Voir [scopes](scopes.md) ; par défaut, un jeu recommandé est appliqué. |
| `accentColor` | Couleur d'accent de marque. `nil` = couleurs Oreus par défaut. Voir [personnalisation](customization.md). |
| `fontFamily` | Nom PostScript de votre famille de polices. `nil` = SF Pro. Voir [personnalisation](customization.md). |

### Déclarer le schéma de callback

Nous recommandons de déclarer le schéma de callback dans le `CFBundleURLTypes` de votre Info.plist, même si l'interception repose sur `ASWebAuthenticationSession` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>native-vox-sdk</string>
        </array>
    </dict>
</array>
```

### Réinitialisation

`VoxChatSDK.reset()` purge les instances internes, efface la configuration stockée et restaure le thème par défaut. À appeler au logout de votre app ou en fin de session SDK. La session d'authentification elle-même (Keychain) est purgée par la déconnexion du SDK.

```swift
VoxChatSDK.reset()
```

## 4. Navigation pilotée par l'hôte

Les briques et écrans du SDK **n'embarquent pas de `NavigationStack`** : c'est votre app qui compose et possède la navigation. Vous avez deux options, contrôlées par le paramètre `ownsNavigation` (défaut : `true`) :

- **`ownsNavigation: true` (défaut)** — zéro changement : le conteneur du SDK monte sa propre `NavigationStack`. Idéal pour une intégration rapide où le SDK gère ses propres pushes internes.
- **`ownsNavigation: false`** — la brique rend son contenu sans pile de navigation : les pushes sont pilotés par votre propre `NavigationStack`, pour une intégration au sein d'une hiérarchie de navigation existante.

```swift
// Le SDK possède sa pile de navigation (défaut)
VoxChatContainer {
    ChatScreen()
}

// L'hôte possède la pile : la brique rend son contenu sans NavigationStack
NavigationStack {
    VoxChatContainer(ownsNavigation: false) {
        ChatScreen()
    }
}
```

## 5. Exemple minimal : une app hôte qui présente le chat

```swift
import SwiftUI
import VoxChatSDK
import VoxCore

@main
struct MonApp: App {
    init() {
        VoxChatSDK.initialize(
            configuration: VoxConfig(
                endpoint: "https://sso.exemple.com",
                clientId: "VOTRE_APP_ID",
                redirectURI: "native-vox-sdk://oidc/callback",
                resource: "https://api.exemple.com",
                apiBaseURL: "https://api.exemple.com",
                accentColor: .purple,
                fontFamily: "MaPolice-Regular"
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            // Ecran d'accueil de l'hôte : connexion puis chat.
            HomeView()
        }
    }
}

struct HomeView: View {
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            NavigationStack {
                VoxChatContainer {
                    ChatScreen()
                }
            }
        } else {
            // Brique publique du SDK : lance le flux OAuth (Authorization
            // Code + PKCE via le navigateur système).
            VoxSsoButton { success in
                isAuthenticated = success
            }
        }
    }
}
```

## Pour aller plus loin

- [Personnalisation](customization.md) : couleur d'accent, typographie, slots et padding.
- [Scopes et gating](scopes.md) : déclarer vos scopes, comprendre le filtrage fail-closed.
- [Erreurs](errors.md) : classification des 403, gestion des jetons, toasts.
