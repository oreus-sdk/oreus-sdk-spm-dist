# Release 0.1.0 — 16/11/2026

Première publication du dépôt de distribution SPM du SDK Vox Chat iOS.

## Artefacts

| Artefact                | Empreintes sha256                        |
|-------------------------|------------------------------------------|
| `VoxChatSDK.xcframework`| 30 fichiers — voir `manifest.sha256`     |
| `VoxCore.xcframework`   | 116 fichiers — voir `manifest.sha256`    |

Empreintes complètes : `manifest.sha256` (149 fichiers), revalidé bit-à-bit
le 16/11/2026 avant publication. Vérification par tout consommateur :

```sh
cd <copie locale du dépôt>   # au tag v0.1.0
sha256sum -c manifest.sha256   # vérification fichier par fichier
```

## Contenu

- `Package.swift` : deux `binaryTarget` (`VoxChatSDK` + `VoxCore`), **aucune
  dépendance distante** (NetworkClient incrustée statiquement dans le binaire).
- `VoxChatSDK.xcframework` + `VoxCore.xcframework` : slices `ios-arm64` (device)
  et `ios-arm64_x86_64-simulator` (simulateur universel), min iOS 18.0,
  dSYMs release embarqués.
- `README.md` : guide d'intégration (imports duaux).
- `docs/` : documentation catalogue (démarrage, personnalisation, scopes,
  erreurs).
- `RELEASE-NOTES.md` + `manifest.sha256` : empreintes sha256 fichier par
  fichier des artefacts publiés.

## Changelog

- Fabrication des XCFrameworks : slices device + simulateur universel,
  autosuffisance vérifiée (`otool -L` : aucune dépendance dynamique externe),
  ressources embarquées (bundles polices/prism, localisations fr/en).
- Variabilité host-scoped des composants UI, briques canoniques publiques
  (chat, agents, drive, files, collections, voxies, chat history, SSO, orbes).
- Surface publique arrêtée ; preuve de consommation client pur reproduite
  sur ces artefacts exacts (initialisation, imports duaux, façades, sonde
  négative : les types internes ne sont pas résolubles côté consommateur).

## Breaking changes

Aucun (première publication ; sémver 0.x.y : tout peut casser sans
incrément majeur).

## Environnement minimum

- **iOS** : 18.0 minimum (device + simulateur).
- **Xcode** : construit et validé sous Xcode 27.2 (toolchain Swift 6).

## Consommation

Le dépôt de distribution est hébergé sur GitHub (`oreus-sdk/oreus-sdk-spm-dist`,
dépôt public). Tags de distribution : `vX.Y.Z` (préfixe `v`, requis par la
résolution SPM) ; les artefacts sont immuables une fois publiés.

```swift
// Package.swift de l'hôte, ou File > Add Package Dependencies…
.package(url: "https://github.com/oreus-sdk/oreus-sdk-spm-dist.git", from: "0.1.0")
```

```swift
import VoxChatSDK   // initialisation (VoxChatSDK.initialize/reset/version)
import VoxCore      // écrans SwiftUI et couche de délégation hôte
```

Personnalisation côté client : couleur d'accent + famille de typographie
uniquement.
