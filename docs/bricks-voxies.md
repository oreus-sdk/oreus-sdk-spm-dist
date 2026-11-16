# Briques Voxies

Ce document catalogue les briques publiques du SDK Vox Chat iOS consacrées aux Voxies (assistants personnalisés à champ structuré) : la liste des voxies existants, la création décrite, le formulaire d'édition et l'écran éditeur. Toutes s'intègrent dans une navigation pilotée par votre app (voir [démarrage](getting-started.md)).

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Vue d'ensemble

| Brique | Rôle | Scope requis |
|---|---|---|
| `VoxVoxieList` | Grille des voxies existants | `read:voxies` + `write:voxies` |
| `VoxDescribeVoxie` | Création d'un voxie par description | `read:voxies` + `write:voxies` |
| `VoxieEditorScreen` | Éditeur complet d'un voxie | `read:voxies` + `write:voxies` |
| `VoxieEditorForm` | Formulaire nu (nom, description, objectif…) | aucun |

Note d'écart : `VoxiePreviewScreen` (aperçu d'un voxie en conversation) est **internalisé** — il est présenté automatiquement par `VoxieEditorScreen` via son bouton d'aperçu, sans câblage de votre part, et n'est pas instanciable directement. La façade `VoxiesScreen` (héros, champ de création, recherche) est également considérée hors contrat de composition tiers : préférez `VoxVoxieList` + `VoxDescribeVoxie` pour composer votre écran.

---

### VoxVoxieList

Grille adaptative de cartes de voxies : charge les voxies de l'utilisateur (pagination de 12), carte à bordure dégradée avec chip nommée, description tronquée et menu ⋮. L'édition délègue à votre app ; la suppression est gérée par la brique (confirmation interne).

**Import** : `import VoxCore`

```swift
VoxVoxieList(
    onSelect: { voxie in
        // voxie mobilisé pour le chat : ChatScreen(voxie: voxie)
    },
    onEditClick: { voxie in
        // présenter VoxieEditorScreen(voxieId: voxie.id)
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `pageSize` | `Int` (défaut `12`) | Taille de page de la pagination. |
| `voxieRepository` | `VoxieRepository` | Dépendance injectable (tests, previews). |
| `onSelect` | `((VoxieEntity) -> Void)?` | Tap sur une carte : la mobilisation du voxie dans le chat vous revient. |
| `onEditClick` | `((VoxieEntity) -> Void)?` | Entrée Edit du menu ⋮ — présentez l'éditeur à votre convenance. |

**Scope requis** : `read:voxies` + `write:voxies` cumulés (fonctionnalité absente sinon — filet de verrouillage). La suppression du menu est gatée `delete:voxies` : sans ce scope, l'entrée est invisible (politique d'invisibilité, voir [scopes](scopes.md)).

**États** : chargement (placeholders) / vide (message dédié) / erreur (retry) / grille paginée. Les blocs d'intégrations des cartes (icônes de connecteurs) ne sont pas exposés aux intégrations tierces : ils restent vides, sans appel réseau.

---

### VoxDescribeVoxie

Création d'un voxie par description : champ compact ouvrant un dialog canon (saisie 8 lignes à bordure dégradée et halos), bouton « Créer » (le texte saisi sert de prompt de génération) et rangée « de zéro / Continuer » (le texte saisi pré-remplit la description de l'éditeur). La création du brouillon (appel réseau `POST /voxies`) est effectuée par la brique ; vous recevez l'identifiant du voxie créé et présentez `VoxieEditorScreen` à votre convenance.

**Import** : `import VoxCore`

```swift
VoxDescribeVoxie(
    onCreate: { voxieId, prompt in
        // « Créer » : brouillon créé, génération via prompt
        VoxieEditorScreen(voxieId: voxieId, generatingPrompt: prompt, isNew: true)
    },
    onContinue: { voxieId, initialDescription in
        // « Continuer » : brouillon créé, description à pré-remplir
        VoxieEditorScreen(voxieId: voxieId, initialDescription: initialDescription, isNew: true)
    }
)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `voxieRepository` | `VoxieRepository` | Dépendance injectable (tests, previews). |
| `onCreate` | `((String, String?) -> Void)?` | Après « Créer » : `(voxieId, prompt saisi)`. Émis après la fermeture du dialog. |
| `onContinue` | `((String, String?) -> Void)?` | Après « Continuer » : `(voxieId, description saisie, nil si vide)`. |

**Scope requis** : `read:voxies` + `write:voxies` cumulés (filet de verrouillage sinon).

**États** : champ compact (défaut) / dialog de description en modale native (titre, bouton de fermeture) / création en cours (indicateur sur le bouton) / erreur (alerte, le dialog reste ouvert). Le bouton « Créer » se débloque à partir de 3 caractères saisis.

---

### VoxieEditorScreen

Éditeur complet d'un voxie : formulaire structuré (nom, description, objectif, format, contraintes), sauvegarde (bouton checkmark), bouton d'aperçu qui présente l'aperçu en conversation en sheet locale. À la création, la fermeture sans sauvegarde annule le brouillon.

**Import** : `import VoxCore`

```swift
// Édition
VoxieEditorScreen(voxieId: voxie.id)

// Création (brouillon sorti de VoxDescribeVoxie)
VoxieEditorScreen(voxieId: voxieId, generatingPrompt: prompt, isNew: true)
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `voxieId` | `String` | Identifiant du voxie (existant ou brouillon créé). |
| `generatingPrompt` | `String?` (défaut `nil`) | Texte à générer (chemin « Créer »). Mutuellement exclusif avec `initialDescription`. |
| `initialDescription` | `String?` (défaut `nil`) | Description à pré-remplir (chemin « Continuer »). Ignorée si le voxie existe déjà. |
| `isNew` | `Bool` (défaut `false`) | `true` : la fermeture sans sauvegarde annule le brouillon ; un toast de succès confirme la création. |

**Scope requis** : `read:voxies` + `write:voxies` cumulés (filet de verrouillage sinon).

**États** : chargement (contenu réduit) / édition / sauvegarde en cours (bouton désactivé) / erreur de sauvegarde (alerte). L'aperçu est une présentation modale locale gérée par le composant ; les connecteurs de voxie ne sont pas exposés aux intégrations tierces (l'onglet correspondant est masqué).

---

### VoxieEditorForm

Formulaire nu de création/édition : cinq champs — nom, description, objectif, format, contraintes — avec labels, tooltips d'aide et placeholders. Le client tiers le compose dans son propre écran ; c'est la brique utilisée par `VoxieEditorScreen` elle-même.

**Import** : `import VoxCore`

```swift
struct MonEditeurVoxie: View {
    @State private var name = ""
    @State private var description = ""
    @State private var objective = ""
    @State private var format = ""
    @State private var constraint = ""

    var body: some View {
        Form {
            VoxieEditorForm(
                name: $name,
                description: $description,
                objective: $objective,
                format: $format,
                constraint: $constraint
            )
            // vos boutons de sauvegarde, votre routage…
        }
    }
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `name` | `Binding<String>` | Nom du voxie. |
| `description` | `Binding<String>` | Description (2 lignes). |
| `objective` | `Binding<String>` | Objectif (5 lignes, tooltip d'aide). |
| `format` | `Binding<String>` | Format de sortie (5 lignes, tooltip d'aide). |
| `constraint` | `Binding<String>` | Contraintes (5 lignes, tooltip d'aide). |

**Scope requis** : aucun — le formulaire est une brique de présentation pure ; le gating des opérations réseau vous revient.

**États** : rendu statique piloté par vos bindings (placeholders sur champs vides).

---

## Pour aller plus loin

- [Briques Chat](bricks-chat.md) : démarrer une conversation en mode Voxie avec `ChatScreen(voxie:)`.
- [Scopes et gating](scopes.md) : `read:voxies`, `write:voxies`, `delete:voxies`.
- [Personnalisation](customization.md) : marges et intégration visuelle.
