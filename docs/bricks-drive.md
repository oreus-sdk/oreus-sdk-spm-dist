# Briques Drive

Ce document catalogue les briques publiques du SDK Vox Chat iOS consacrées au Drive et aux fichiers : la grille de collections (dossiers), la table de fichiers et le sélecteur de destination de déplacement, plus la façade complète « Mon Drive ». Contrat commun : **les marges externes et le chrome de page (titre, barre de navigation) relèvent de votre app** — la recherche et les actions sont intégrées aux composants, qui n'embarquent aucune barre de navigation.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Vue d'ensemble

| Brique | Rôle | Scope requis |
|---|---|---|
| `VoxCollections` | Grille des collections (dossiers personnels) | `read:folders` + `read:files` |
| `VoxFilesTable` | Liste des fichiers d'un dossier, actions incluses | `read:folders` + `read:files` |
| `FolderPickerSheet` | Sélecteur de dossier de destination (déplacement) | `read:folders` + `read:files` |
| `MyDriveScreen` | Façade complète « Mon Drive » | `read:folders` + `read:files` |

---

### VoxCollections

Grille adaptative de cartes de collection : charge les dossiers racine personnels de l'utilisateur (pagination de 20), recherche intégrée au-dessus de la grille, renommage et suppression gérés par la brique. L'image de dossier est paramétrable : vous fournissez votre visuel, ou vous laissez la vignette canonique teintée.

**Import** : `import VoxCore`

```swift
VoxCollections(
    folderImage: Image("MonVisuelDossier"),  // nil = vignette canonique
    onSelect: { folder in
        // navigation vers le contenu du dossier
        VoxFilesTable(folderId: folder.id)
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `folderImage` | `Image?` (défaut `nil`) | Image de dossier fournie par votre app, rendue à la place de la vignette canonique (dégradés de lisibilité conservés). |
| `isScrollEnabled` | `Bool` (défaut `true`) | `false` : contenu rendu à taille intrinsèque, sans ScrollView interne — pour empiler plusieurs briques dans votre propre ScrollView. |
| `driveRepository` | `DriveRepository` | Dépendance injectable (tests, previews). |
| `onSelect` | `((DriveItemEntity) -> Void)?` | Tap sur une carte : la navigation vous revient. |
| `onRenameClick` | `((DriveItemEntity) -> Void)?` | Hook d'override du renommage (voir ci-dessous). |

**Scope requis** : `read:folders` + `read:files` cumulés (fonctionnalité absente sinon — filet de verrouillage). Voir [scopes](scopes.md).

**Actions** :

- **Renommer** (tap long, gated `write:folders`) : par défaut intra-brique (alerte de renommage interne, appel réseau inclus). Fournissez `onRenameClick` pour composer votre propre présentation — l'effet métier vous revient alors.
- **Supprimer** (tap long, gated `delete:folders`) : toujours intra-brique — confirmation interne, appel réseau inclus. Sans `delete:folders`, l'entrée est invisible.

**États** : chargement (squelettes) / vide / erreur (retry) / grille paginée avec pull-to-refresh et recherche debouncée. Les compteurs de fichiers des cartes se rafraîchissent automatiquement après une mutation des fichiers.

---

### VoxFilesTable

Liste des fichiers d'un dossier : vignettes typées mime, nom, taille, badge de statut IA, menu d'actions par ligne. La brique porte sa propre barre d'outils — champ de recherche, bouton upload (+) et bouton actions (ellipsis → sélection multiple) — et gère le flux d'upload complet (pickers, garde de taille, dédoublonnage, capsule de progression). **Aucune dépendance à une NavigationStack hôte.**

**Import** : `import VoxCore`

```swift
// Composant autonome (défaut) : tout fonctionne sans câblage.
VoxFilesTable(folderId: folder.id)

// Override de l'aperçu par votre app :
VoxFilesTable(
    folderId: folder.id,
    onTap: { file in hostPresentPreview(for: file) }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `folderId` | `String` | Identifiant du dossier dont on liste les fichiers. |
| `pageSize` | `Int` (défaut `20`) | Taille de page de la pagination. |
| `isScrollEnabled` | `Bool` (défaut `true`) | `false` : contenu à taille intrinsèque, sans ScrollView interne (empilement de briques). |
| `driveRepository` | `DriveRepository` | Dépendance injectable (tests, previews). |
| `onTap` | `((DriveFileEntity) -> Void)?` | Hook d'override de l'aperçu. |
| `onRenameClick` | `((DriveFileEntity) -> Void)?` | Hook d'override du renommage. |
| `onMoveClick` | `((DriveFileEntity) -> Void)?` | Hook d'override du déplacement. |

**Scope requis** : `read:folders` + `read:files` cumulés (filet de verrouillage sinon).

**Actions par défaut (aucun câblage requis)** :

- **Aperçu** : QuickLook intra-brique (téléchargement + présentation plein écran locale). Fournissez `onTap` pour présenter votre propre viewer.
- **Renommer** (gated `write:files`) : alerte TextField interne. Fournissez `onRenameClick` pour prendre la main.
- **Déplacer** (gated `write:files`) : sélecteur canonique `FolderPickerSheet` présenté par la brique. Fournissez `onMoveClick` pour composer le vôtre (avec `FolderPickerSheet` si vous le souhaitez).
- **Supprimer** (gated `delete:files`) : toujours intra-composant, confirmation interne. Sans `delete:files`, l'entrée est invisible.
- **Upload** : pickers fichiers/photos/caméra, capsule de progression, rafraîchissement automatique de la liste. La conversion IA des fichiers n'est pas exposée aux intégrations tierces (note d'écart : fonctionnalité absente du contrat).

**États** : chargement (placeholders) / vide / erreur (retry) / liste paginée (grille adaptative, recherche debouncée, pull-to-refresh).

---

### FolderPickerSheet

Sélecteur de destination de déplacement : liste paginée des dossiers du Drive avec sélection d'un dossier cible. Brique publique pour composer le déplacement émis par les callbacks des briques Drive au lieu de dupliquer une implémentation.

**Import** : `import VoxCore`

```swift
.sheet(item: $moveTarget) { file in
    FolderPickerSheet(currentFolderId: currentFolderId) { destinationId in
        // exécuter le déplacement du fichier vers destinationId
    }
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `currentFolderId` | `String?` (défaut `nil`) | Dossier courant, exclu de la navigation. |
| `onFolderSelected` | `(String) -> Void` | Appelé avec l'identifiant du dossier choisi. |

**Scope requis** : s'utilise dans un contexte Drive déjà gaté (`read:folders` + `read:files`).

**États** : liste paginée avec indicateur de chargement ; la feuille embarque sa propre NavigationStack et se referme après sélection.

---

### MyDriveScreen

Façade complète « Mon Drive » : grille de collections + listing des fichiers d'un dossier, recherche au niveau de la barre système, création de dossiers, capsule d'upload, menu de stockage. Le point d'entrée tout-en-un si vous ne composez pas vous-même les briques ci-dessus.

**Import** : `import VoxCore`

```swift
// Le SDK possède sa pile de navigation (défaut)
VoxChatContainer {
    MyDriveScreen()
}

// L'hôte possède la pile, sans barre de titre du SDK :
NavigationStack {
    VoxChatContainer(ownsNavigation: false) {
        MyDriveScreen(showsNavigationBar: false, ownsNavigation: false)
    }
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `showsNavigationBar` | `Bool` (défaut `true`) | Affiche le titre « My Drive » dans la barre de navigation ; `false` quand votre app compose sa propre barre. |
| `ownsNavigation` | `Bool` (défaut `true`) | `false` : la pile de push est pilotée par votre `NavigationStack` (voir [démarrage](getting-started.md)). |

**Scope requis** : `read:folders` + `read:files` cumulés (filet de verrouillage sinon).

**États** : chargement / grille vide ou remplie / navigation intra-composant vers le contenu d'un dossier. Les alertes (création, renommage, suppression de dossier) et les présentations locales sont gérées par le composant.

---

## Pour aller plus loin

- [Briques Chat](bricks-chat.md) : ajouter un fichier du Drive comme contexte de conversation.
- [Scopes et gating](scopes.md) : `read:folders`, `read:files`, `write:files`, `delete:files`, `write:folders`, `delete:folders`.
- [Personnalisation](customization.md) : répartition des marges entre votre app et les briques.
