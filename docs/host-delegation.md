# Délégation hôte : `HostAction`, `.onHostAction` et présentation

Le SDK ne possède ni compte, ni paiement, ni onboarding, ni écran de réglages : quand un composant atteint un concept qui appartient à la coquille de votre app, il **émet une action de délégation** au lieu de naviguer lui-même. Votre app reçoit l'intention et choisit **sa** présentation (sheet, fullscreen cover, push sur sa propre pile…).

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## Principe

- Le défaut de l'environnement est un **no-op** : un composant posé sans coquille coordinatrice ignore silencieusement l'action, sans crash. Conséquence : si une action « ne se passe pas », vérifiez d'abord que votre handler est bien injecté (et ré-injecté dans les couches présentées, voir section dédiée ci-dessous).
- Chaque action transporte **l'intention métier**, jamais la destination : à vous de décider comment la présenter.
- Les payloads d'événements (ex. `[AgentSummary]`) ne sont pas `Sendable` ; consommez-les sur le MainActor. Un import `@preconcurrency import VoxCore` est recommandé si votre cible a une concurrence stricte.

## L'enum `HostAction`

Toutes les actions publiques du canal de délégation :

| Action | Rôle |
|---|---|
| `.manageMyAccount` | Gestion du compte utilisateur. |
| `.manageOrganizations` | Gestion des organisations. |
| `.contactUs` | Contact avec l'équipe. |
| `.editPassword(hasPassword:)` | Édition (ou définition) du mot de passe. |
| `.noAssociatedAccount` | Compte sans organisation associée, après connexion. |
| `.registrationInformation` | Complétion d'inscription : le nom de l'utilisateur manque. |
| `.newOnboarding(accessLevel:organizationName:)` | Onboarding post-connexion. |
| `.openSettings` | Ouverture des réglages : l'écran Settings tout entier vous revient (écran, données de section, liens externes). |
| `.showPaywall` | Montée en gamme : le paiement est exclu du SDK, vous décidez de sa présentation (voir [`VoxPlusPaywallSheet`](#voxpluspaywallsheet) ci-dessous). |
| `.openIntegrations` | Connexions d'applications : fonctionnalité réservée à l'app Oreus, jamais émise chez un hôte tiers. |
| `.openAgentsFromChat` | Liste des agents accessible depuis le chat (bouton toolbar). |
| `.showAgentRecap(summaries:)` | Récapitulatif des agents mobilisés dans une réponse du chat. Vue prête à présenter fournie par le SDK : [`AgentRecapSheet(summaries:)`](#composition-avec-voxchatcontainer). |
| `.openAgentDetail(agentId:storeItemId:)` | Fiche détaillée d'un agent. |
| `.agentLimitReached` | Limite d'agents atteinte : le SDK signale le fait, vous gouvernez la réaction (ex. présenter les agents achetés). |
| `.useThisAgent(mention:)` | « Utiliser cet agent » confirmé depuis la fiche détaillée : retour au chat avec l'agent en mention (`MentionItemEntity`). |
| `.useThisVoxie(voxie)` | « Utiliser ce voxie » (miroir des agents) : démarrer un chat avec ce voxie (`VoxieEntity`). |
| `.openVoxieEditor(voxieId:prompt:initialDescription:isNew:)` | Éditeur de voxie (création ou édition). `prompt` porte le texte à générer (« Créer ») ; `initialDescription` pré-remplit la description de l'éditeur (« Continuer ») — mutuellement exclusifs. |
| `.openExternal(URL)` | Ouverture d'un lien externe (CGU, confidentialité, mentions légales) : le SDK ne présente ni WebView ni NavigationLink, vous ouvrez l'URL selon votre politique (SFSafariViewController, navigateur système…). |

## Injecter le handler : `.onHostAction`

`.onHostAction` est une valeur d'environnement SwiftUI : posez-la **au-dessus** de tout contenu SDK.

**Import** : `import VoxCore`

```swift
struct MonShell: View {
    var body: some View {
        NavigationStack {
            VoxChatContainer {
                ChatScreen()
            }
        }
        .environment(\.onHostAction) { action in
            handle(action)
        }
    }

    private func handle(_ action: HostAction) {
        switch action {
        case .showPaywall:
            // Votre présentation (ici : fullscreen cover)
            paywallPresented = true
        case .openAgentDetail(let agentId, let storeItemId):
            agentDetail = AgentDetailSelection(agentId: agentId, storeItemId: storeItemId)
        case .useThisAgent(let mention):
            // Retour au chat avec l'agent en mention
            chatMention = mention
        case .openExternal(let url):
            openURL = url
        // ... et les autres intentions selon les écrans que vous composez
        default:
            break
        }
    }
}
```

La liste complète des actions que vous devez gérer dépend des écrans du SDK que vous composez : un chat seul émet un sous-ensemble (paywall, récapitulatif d'agents, intégrations, liens externes…) ; les écrans d'agents et de voxies en émettent d'autres. C'est à vous de câbler celles qui correspondent à votre intégration.

## Le contrat de fermeture : `.hostScreenDismissed`

Quand un écran que vous avez présenté en réponse à une `HostAction` est refermé, **postez la notification** `.hostScreenDismissed` (typiquement dans le `onDisappear` de la couche présentée) :

```swift
.sheet(item: $destination) { dest in
    dest.screen
        .onDisappear {
            NotificationCenter.default.post(name: .hostScreenDismissed, object: nil)
        }
}
```

Cette notification est l'acquittement attendu par la chaîne de gates du SDK : par exemple, la liste des voxies rafraîchit l'élément édité quand la sheet d'éditeur que **vous** avez présentée se referme, et les écrans racine du SDK enchaînent leurs gates (inscription → paywall → onboarding) à chaque fermeture d'écran hôte. Sans ce post, un écran SDK peut rester dans un état périmé après une action menée dans votre présentation.

## `VoxPlusPaywallSheet`

Le paywall Vox Plus est exclu du SDK (le paiement est de la responsabilité de la coquille), mais le SDK fournit la vue prête à présenter en réponse à `.showPaywall` :

**Import** : `import VoxCore`

```swift
// Réaction à .showPaywall : vous décidez de la présentation.
// Ici, une fullscreen cover posée par votre shell :
.fullScreenCover(isPresented: $paywallPresented) {
    VoxPlusPaywallSheet(isFullscreen: true)
}
```

| Param | Type | Description |
|---|---|---|
| `isFullscreen` | `Bool` (défaut `false`) | `true` : rendu plein écran ; `false` : rendu calibré pour une sheet. |

C'est une vue, pas une présentation : c'est vous qui la posez (sheet ou fullscreen cover) et qui en gérez la fermeture. Son contenu décrit les offres Vox Plus ; l'acte de paiement lui-même vous revient.

## `AgentRecapSheet`

Vue prête à présenter en réponse à `.showAgentRecap(summaries:)` : le récapitulatif des agents mobilisés dans une réponse du chat.

**Import** : `import VoxCore`

```swift
case .showAgentRecap(let summaries):
    recap = summaries   // présentée ensuite en sheet par votre app
```

```swift
.sheet(isPresented: $recapPresented) {
    AgentRecapSheet(summaries: recap)
        .environment(\.onHostAction, handle)   // ré-injection (voir ci-dessous)
}
```

| Param | Type | Description |
|---|---|---|
| `summaries` | `[AgentSummary]` | Agents mobilisés dans la réponse (payload de `.showAgentRecap`). |

Comme pour le paywall : c'est une vue, la présentation et la fermeture vous appartiennent.

---

## ⚠️ RÈGLE CRITIQUE : ré-injection de `.onHostAction` dans les couches présentées

**Toute couche présentatrice de L'HÔTE contenant du contenu SDK doit ré-injecter `.onHostAction` dans son contenu.**

Les valeurs d'environnement **custom** posées sur votre coquille **ne sont pas lues** dans le contenu d'une sheet ou d'une fullscreen cover attachée à la même vue que l'injection : SwiftUI lit l'environnement du point d'attach de la présentation, pas celui de la hiérarchie de départ. Sans ré-injection, les `HostAction` émises depuis le contenu de la sheet retombent sur le **défaut no-op** : les taps « Utiliser », « payer », « voir la fiche »… sont silencieusement perdus, sans erreur.

Ce défaut est une source classique de bug : l'écran s'affiche parfaitement, mais ses intentions métier ne parviennent jamais à votre routeur.

```swift
// ❌ PERDU : le contenu de la sheet ne lit pas l'environnement posé
// sur la coquille. Les HostAction émises par ChatScreen sont no-op.
.environment(\.onHostAction, handle)
.sheet(item: $selection) { session in
    NavigationStack {
        ChatScreen(sessionId: session.id)
    }
}

// ✅ CORRECT : ré-injection explicite dans le contenu de la présentation
.environment(\.onHostAction, handle)
.sheet(item: $selection) { session in
    NavigationStack {
        ChatScreen(sessionId: session.id)
            .addDismissButton()
            .environment(\.onHostAction, handle)   // ← ré-injection
    }
}
```

**Ce que cette règle couvre** : les `.sheet(item:)` et `.fullScreenCover(item:)` de **votre** app qui présentent du contenu SDK (chat pré-rempli, fiche d'agent, éditeur de voxie, historique → chat…).

**Ce qu'elle ne couvre pas** : les sheets présentées **par le SDK lui-même** (aperçus de pièces jointes, sélecteur de contexte Drive, alertes internes…) — elles héritent normalement de l'injection racine et ne demandent rien de votre part.

**Pattern de référence** : la sample app du SDK montre la ré-injection à deux niveaux — sur la coquille (handler unique) et dans chaque couche `.sheet` / `.fullScreenCover` présentée, y compris pour un chat ouvert depuis la brique d'historique. Reprenez ce double câblage tel quel.

## Composition avec `VoxChatContainer`

Rappel (voir [démarrage](getting-started.md)) : `VoxChatContainer(ownsNavigation:)` contrôle qui possède la pile de navigation.

- **`ownsNavigation: true` (défaut)** : le conteneur du SDK monte sa propre `NavigationStack` — zéro câblage pour les pushes internes.
- **`ownsNavigation: false`** : la brique rend son contenu sans pile ; les pushes sont pilotés par **votre** `NavigationStack`. C'est le mode recommandé quand vous présentez du contenu SDK dans une sheet que vous enrogez vous-même d'une `NavigationStack` (chat pré-rempli, fiche d'agent).

### Le pattern « push hôte »

Vous pouvez pousser une brique du SDK dans **votre propre** `NavigationStack` et réagir aux `HostAction` qu'elle émet :

```swift
NavigationStack {
    VoxChatContainer(ownsNavigation: false) {
        MyAgentsScreen(ownsNavigation: false)
    }
    .navigationDestination(for: AgentRoute.self) { route in
        switch route {
        case .detail(let agentId, let storeItemId):
            AgentDetailScreen(agentId: agentId, storeItemId: storeItemId)
        }
    }
}
.environment(\.onHostAction) { action in
    switch action {
    case .openAgentDetail(let agentId, let storeItemId):
        path.append(AgentRoute.detail(agentId: agentId, storeItemId: storeItemId))
    case .useThisAgent(let mention):
        // présenter le chat pré-rempli à votre convenance
        chatMention = mention
    default:
        break
    }
}
```

Avec ce pattern, le SDK n'impose aucune coquille : les intentions remontent, la géométrie de navigation vous appartient.

## Pour aller plus loin

- [Démarrage](getting-started.md) : initialisation, `VoxChatContainer`, `ownsNavigation`.
- [Façades](facades.md) : les écrans data-driven qui émettent ces actions.
- [Scopes et gating](scopes.md) : ce qui conditionne l'affichage des points d'entrée.
- [Écarts fonctionnels](api-parity.md) : actions réservées à l'app Oreus (`.openIntegrations`, etc.).
