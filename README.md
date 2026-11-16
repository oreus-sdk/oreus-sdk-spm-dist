# VoxChatSDK — Dépôt de distribution SPM

Distribution du SDK Vox Chat iOS sous forme de XCFrameworks précompilés,
consommable par les applications hôtes tierces via Swift Package Manager.

## Contenu

| Produit       | Artefact                  | Rôle                                                    |
|---------------|---------------------------|---------------------------------------------------------|
| `VoxChatSDK`  | `VoxChatSDK.xcframework`  | Point d'entrée : `initialize` / `reset` / `version`     |
| `VoxCore`     | `VoxCore.xcframework`     | Écrans SwiftUI et couche de délégation hôte             |

Caractéristiques des artefacts :

- Slices `ios-arm64` (device) et `ios-arm64_x86_64-simulator` (simulateur universel) ;
- Minimum iOS 18.0 ;
- dSYMs de release embarqués dans chaque `.xcframework` ;
- `NetworkClient` incrustée statiquement dans `VoxCore` : aucun dylib
  séparé dans la distribution, aucun framework de dépendance à embarquer
  (fiabilisation des previews et de la consommation SPM).

## Intégration (app hôte tierce)

Dans Xcode : **File > Add Package Dependencies…**, puis pointer sur
`https://github.com/oreus-sdk/oreus-sdk-spm-dist.git` (dépôt public, tag
`sdk-v0.1.0`).
Les deux produits sont proposés ; importer les deux (contrat d'imports duaux) :

```swift
import VoxChatSDK   // initialisation
import VoxCore      // écrans et couche de délégation hôte
```

Initialisation minimale dans le `App` hôte :

```swift
VoxChatSDK.initialize(
    configuration: VoxConfig(
        endpoint: "https://oreus-sso.example.com",
        clientId: "APP_ID_SSO",
        redirectURI: "monapp://oidc/callback",
        resource: "https://oreus.example.com/api/v1",
        apiBaseURL: "https://oreus.example.com",
        accentColor: .purple,
        fontFamily: "MaPolice-Regular"
    )
)
```

Personnalisation côté client limitée à la couleur d'accent et à la famille de
police (faces Regular/Medium/Semibold/Bold embarquées par le client).

## Maintenance

Ce dépôt est régénéré à chaque release : les deux `.xcframework` sont copiés
depuis la sortie de fabrication du SDK et le manifeste `Package.swift` ne
change que si la structure des produits évolue. Ne jamais éditer un
`.xcframework` à la main.
