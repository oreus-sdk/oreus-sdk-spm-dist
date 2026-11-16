# Release sdk-v0.1.0 — 16/11/2026

Première publication du dépôt de distribution SPM du SDK Vox Chat iOS (ST#69, Phase 4).

## Artefacts

| Artefact                | Empreinte sha256 (agrégat trié des fichiers du manifest) |
|-------------------------|----------------------------------------------------------|
| `VoxChatSDK.xcframework`| `eb068823…` (agrégat consigné dans `spm-dist-manifest.sha256`) |
| `VoxCore.xcframework`   | `59891da8…` (agrégat consigné dans `spm-dist-manifest.sha256`) |

Empreintes complètes : `build/ct71-e3/spm-dist-manifest.sha256` (149 fichiers,
revalidés bit-à-bit le 16/11/2026 avant commit — 148 fichiers hors état local
`.swiftpm/`, zéro différence).

## Contenu

- `Package.swift` : deux `binaryTarget` (`VoxChatSDK` + `VoxCore`), **aucune
  dépendance distante** (ADR#47 : NetworkClient incrustée statiquement, ADR#65).
- `VoxChatSDK.xcframework` + `VoxCore.xcframework` : slices `ios-arm64` (device)
  et `ios-arm64_x86_64-simulator` (simulateur universel), min iOS 18.0,
  dSYMs release embarqués.
- `README.md` : guide d'intégration (imports duaux, contrat ADR#48).

## Changelog

- Phase 4 complète : fabrication des XCFrameworks (ST#75/ST#136, ADR#50/56),
  autosuffisance vérifiée `otool -L` (CT#69), transport des ressources
  embarquées — bundles math/prism, lproj (CT#70, ST#133).
- Phase 5 : variabilité host-scoped (ADR#60–92), 14 backports ST#242–256
  (SSO durci 6aec2f69, SessionManager 2dbac82e, paywall fe7f3f77, etc.),
  briques canoniques oreus-* (ST#257–282), sample app à jour.
- Surface publique arrêtée ST#112 ; preuve de consommation client pur E3
  reproduite 16/11/2026 (CT#71 étape 3) sur ces artefacts exacts.

## Breaking changes

Aucun (première publication ; sémver 0.x.y pendant la phase, ADR#47 :
tout peut casser sans incrément majeur).

## Environnement minimum

- **iOS** : 18.0 minimum (device + simulateur).
- **Xcode** : construit et validé sous Xcode 27.2 (toolchain Swift 6).

## Consommation

```swift
// Package.swift de l'hôte, ou File > Add Package Dependencies… (tag sdk-v0.1.0)
.package(url: "https://github.com/<org>/vox-chat-sdk-spm.git", from: "0.1.0")
```

```swift
import VoxChatSDK   // initialisation (VoxChatSDK.initialize/reset/version)
import VoxCore      // écrans SwiftUI et couche de délégation hôte
```

Personnalisation côté client : couleur d'accent + famille de typographie
uniquement (ADR#66). Tags de distribution : `sdk-vX.Y.Z` (préfixe `sdk-`,
Q#57) ; artefacts immuables une fois publiés (ADR#47).
