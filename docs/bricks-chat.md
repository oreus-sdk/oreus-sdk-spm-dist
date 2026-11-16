# Briques Chat

Ce document catalogue les briques publiques du SDK Vox Chat iOS consacrées à la conversation : la façade `ChatScreen` (quatre points d'entrée) et la brique d'historique des conversations `VoxChatHistory`. Toutes sont gatées par scopes et s'intègrent dans une navigation pilotée par votre app (voir [démarrage](getting-started.md)).

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

### ChatScreen

Écran de conversation : fil de messages en streaming, barre de saisie avec mentions d'agents et pièces jointes, phrases de démarrage, aperçus de fichiers et d'images générées, chat éphémère, mode Voxie. Le composant est **autosuffisant sans barre de navigation** : il n'expose aucun contrôle en toolbar — la barre de titre, le menu de conversation et les actions de niveau écran restent de la responsabilité de votre app.

**Import** : `import VoxCore`

Quatre initialisateurs publics, tous avec `onChatChange` optionnel :

```swift
// 1. Conversation vide
ChatScreen()

// 2. Ouvrir une session existante
ChatScreen(sessionId: session.id)

// 3. Démarrer une conversation avec un agent en mention
ChatScreen(agent: agent.toMentionItem)

// 4. Démarrer une conversation en mode Voxie
ChatScreen(voxie: voxie)

// Avec notification de changement de conversation :
ChatScreen(sessionId: nil, onChatChange: { sessionId, voxieId in
    // sessionId : session créée après le premier message
    // voxieId   : voxie porté par la session (nil si conversation classique)
})
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `sessionId` | `String` | Identifiant de la session à ouvrir (init 2). |
| `agent` | `MentionItemEntity` | Agent pré-associé au chat : pastille de mention au-dessus de la barre de saisie + phrases de démarrage de l'agent (init 3). |
| `voxie` | `VoxieEntity` | Voxie pré-associé : conversation en mode Voxie (init 4). |
| `onChatChange` | `((String?, String?) -> Void)?` | Notifié quand la conversation courante change **de l'intérieur** du chat : `(sessionId, voxieId)`. Voir le contrat ci-dessous. |

**Contrat `onChatChange`** : le callback est le miroir du canon cross-plateforme. Il n'est **pas** déclenché par la conversation posée par votre app via les initialisateurs `sessionId:` / `agent:` / `voxie:` — seul un changement interne l'émet, typiquement la **création de session après le premier message** (le `sessionId` passe de `nil` à un identifiant) ou l'ouverture d'une conversation depuis l'historique du chat. `voxieId` est fourni quand un voxie est porté par la session.

**Scope requis** : `write:vox` (fonctionnalité `chat`). Sans ce scope, l'écran rend le filet de verrouillage interne du SDK plutôt que le fil de conversation — c'est le seul cas où un écran verrouillé est affiché ; les autres fonctionnalités non accordées sont simplement invisibles (voir [scopes](scopes.md)).

**États** : chargement de session / écran de démarrage (phrases proposées) / conversation en cours (scroll infini dans l'historique du fil) / sortie du mode Voxie avec confirmation. Les présentations utilitaires (aperçu de pièce jointe, sélecteur de contexte Drive, liste des agents de session) sont gérées par le composant lui-même.

**Toolbar et nav bar** : le chat est présentable avec ou sans nav bar hôte. Chez un hôte tiers, le bouton de chat éphémère est rendu en pastille flottante au-dessus du contenu au lieu de la barre : le composant reste complet sans aucune barre à composer.

---

### VoxChatHistory

Historique des conversations : liste paginée des noms des discussions précédentes (rendu canonique du menu latéral). Tap court = ouverture de la discussion (déléguée à votre app via `onSelect`) ; tap long = aperçu des deux derniers messages + menu **Renommer / Supprimer**, géré par la brique elle-même (alertes internes, appels réseau inclus).

**Import** : `import VoxCore`

```swift
struct MonMenuLateral: View {
    @State private var search = ""
    @State private var activeSessionId: String?

    var body: some View {
        VStack {
            TextField("Rechercher", text: $search)
            VoxChatHistory(
                search: $search,
                activeSessionId: $activeSessionId,
                headerTitleText: Text("Récents"),
                onSelect: { session in
                    activeSessionId = session.id
                    // ouvrir ChatScreen(sessionId: session.id)
                }
            )
        }
    }
}
```

**Paramètres** :

| Param | Type | Description |
|---|---|---|
| `search` | `Binding<String>` (défaut vide) | Miroir du champ de recherche de votre app : non-vide, la brique affiche les résultats de recherche à la place de la liste. |
| `activeSessionId` | `Binding<String?>` | Surbrillance de la conversation active (écrite par vous à la navigation, et par la brique aux événements internes). |
| `isPresented` | `Binding<Bool>?` (défaut `nil`) | Présentation effective de la brique : `nil` = toujours présentée. Un binding diffère le rafraîchissement à l'ouverture (utile si la brique vit dans un menu latéral monté en permanence). |
| `headerTitleText` | `Text?` (défaut `nil`) | Titre de la liste posé par votre app (aucun en-tête par défaut). |
| `sessionsRepository` | `SessionsRepository` | Dépendance injectable (tests, previews). |
| `topContent` | `@ViewBuilder` (init avec slot) | Contenu inséré au-dessus de la liste. Réservé aux extensions de l'app hôte d'origine — ne compte pas dessus en tiers (voir [personnalisation](customization.md)). |
| `onSelect` | `((SessionPreviewEntity) -> Void)?` | Tap sur une conversation : l'ouverture du chat vous revient. |

**Scope requis** : `read:sessions` pour l'affichage de la liste (sinon filet de verrouillage sous le contenu du slot). Les actions par ligne sont gatées individuellement :

- **Renommer** : `write:sessions` — entrée masquée sans ce scope.
- **Supprimer** : disponible uniquement dans l'app hôte d'origine (aucun contrat tiers pour la suppression de session) — l'entrée est invisible dans une intégration tierce.

**États** : chargement initial (loader) / liste paginée (pagination infinie, pull-to-refresh) / résultats de recherche / mise à jour automatique aux événements distants (création, renommage, suppression d'une conversation, changement d'organisation).

---

## Pour aller plus loin

- [Scopes et gating](scopes.md) : `write:vox`, `read:sessions`, `write:sessions`.
- [Briques Agents](bricks-agents.md) : mobiliser un agent dans une conversation via `AgentDetailsModal`.
- [Personnalisation](customization.md) : slots (first-party) et répartition des marges.
