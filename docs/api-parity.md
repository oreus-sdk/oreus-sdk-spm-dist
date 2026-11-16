# Écarts fonctionnels et alignement cross-platform

Ce document décrit ce que le SDK Vox Chat iOS expose différemment selon le contexte d'intégration : fonctionnalités réservées à l'app Oreus (first-party) et invisibles pour une intégration tierce, et alignement du SDK iOS sur les autres clients Oreus.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## 1. Fonctionnalités réservées à l'app Oreus

Certaines fonctionnalités sont **réservées à l'app Oreus** et invisibles pour une intégration tierce. Ce n'est pas une restriction arbitraire : ces fonctionnalités passent par des routes d'API **sans équivalent dans le contrat tiers**. Un hôte tiers qui les afficherait verrait des interactions cassées (erreurs 403/404 au moment de l'action). Le SDK applique donc la politique d'invisibilité : le point d'entrée est masqué, jamais grisé, jamais en échec.

Côté client, la distinction se fait via un réglage interne du SDK, actif uniquement pour l'app Oreus. Une intégration tierce n'a rien à configurer : elle est automatiquement dans le cas tiers.

### Tableau des écarts

| Fonctionnalité | Comportement tiers | Lect./écrit. | Point d'entrée concerné |
|---|---|---|---|
| **Favoris d'agents (écriture)** | Étoile favorite masquée (cartes d'agents, fiche détaillée) | Écriture masquée, **lecture conservée** | Cartes et fiches d'agents |
| **Reprise de runs en pause** | Carte HITL de reprise masquée | Écriture masquée | Chat (cartes de pause) |
| **Conversion IA des fichiers (Drive)** | Bouton « Convertir » et assistant de conversion masqués | Écriture masquée | Drive (`MyDriveScreen`, table de fichiers) |
| **Suppression de session** | Entrée « Supprimer » masquée (le **renommage** reste disponible, gaté par scope) | Écriture masquée | Historique des conversations |
| **Connecteurs de voxies** | Onglet Connecteurs et badges d'intégrations masqués ; aucun appel réseau correspondant | Écriture masquée | Éditeur de voxies, cartes |
| **Feedback des messages IA** | Pouces masqués ; seul le bouton « Copier » subsiste | Écriture masquée | Messages du chat |
| **Connexions d'applications** | Écran inexistant côté tiers ; l'intention est déléguée à l'hôte via `HostAction.openIntegrations`, jamais émise en contexte tiers | Écriture masquée | Cartes HITL du chat |

### Cas détaillés

**Favoris d'agents.** Aucun scope dédié n'existe pour l'écriture des favoris dans le contrat tiers : le point d'entrée d'écriture est donc masqué aux tiers. En revanche, l'**état** `isFavorite` reste lisible en lecture dans le contrat : vos données d'agent portent l'information, et un écran tiers peut l'afficher. Seul le toggle d'écriture est concerné.

**Reprise de runs en pause.** Une session peut rapporter un run en pause (lecture autorisée au tiers), mais sa **reprise** passe par des routes sans équivalent tiers. Sans masquage, un hôte tiers verrait une carte interactive dont la résolution échouerait en 403/404. La carte est donc masquée en tiers.

**Conversion IA des fichiers.** Les routes de conversion IA des fichiers (simuler et générer un embedding) sont réservées à l'app Oreus. Chez un tiers, le menu de fichier et la toolbar du Drive n'affichent pas le bouton « Convertir », et l'assistant de conversion n'est pas accessible.

**Suppression de session.** La route de suppression de conversation est sans contrat tiers : l'entrée « Supprimer » du tap long d'historique est masquée. Attention à ne pas la confondre avec le **renommage**, qui traverse bien le contrat tiers et reste gouverné par le scope d'écriture des sessions (voir [scopes](scopes.md)).

### Comment vérifier ce qui s'applique à vous

Les scopes que vous demandez dans `VoxConfig` gouvernent tout le reste (voir [scopes](scopes.md)) : si une fonctionnalité n'apparaît pas alors qu'elle figure dans le contrat tiers, comparez d'abord vos scopes demandés à ceux accordés. Les écarts ci-dessus, eux, ne dépendent **pas** des scopes : ils sont invisibles par conception pour toute intégration tierce, même avec le jeu de scopes complet.

## 2. Alignement canonique cross-platform

Le SDK iOS est aligné sur les clients Android et Web d'Oreus : il expose les **mêmes surfaces canoniques** (conversation, historique, agents, boutique, drive, voxies) et suit les mêmes conventions de contrat. Concrètement :

- les composants clés portent des contrats calqués sur le canon cross-platform (par exemple, le callback de changement de conversation de `ChatScreen` reflète le canon `OreusVoxChat(sessionId, voxieId, onChatChange)` d'Android) ;
- les gabarits de présentation (cartes, listes, sheets, barres de recherche) suivent le rendu canonique commun aux clients Oreus, personnalisable uniquement par couleur d'accent et typographie (voir [personnalisation](customization.md)).

Les différences propres à chaque plateforme restent d'ordre iOS (présentations SwiftUI natives : sheets, fullscreen covers, NavigationStack) et n'affectent pas le contrat fonctionnel.

## 3. Roadmap de re-exposition

Une fonctionnalité masquée aujourd'hui peut devenir disponible pour les intégrations tierces **dès que le contrat d'API l'ouvre**. La politique est simple : chaque masquage est causé par l'absence de route dans le contrat tiers ; quand une route équivalente apparaît dans ce contrat, la fonctionnalité correspondante peut être ré-exposée en une ligne — le point d'entrée, son gating et son comportement existent déjà dans le SDK.

En pratique : les écarts du tableau ci-dessus ne sont pas des suppressions définitives. Si une fonctionnalité vous manque, vérifiez la documentation du contrat API de votre version — si la route y figure, la fonctionnalité peut être disponible dans une version du SDK ; sinon, elle reste réservée à l'app Oreus jusqu'à ouverture du contrat.

## Pour aller plus loin

- [Scopes et gating](scopes.md) : filtrage fail-closed et politique d'invisibilité.
- [Délégation hôte](host-delegation.md) : `HostAction.openIntegrations` et le canal de délégation.
- [Façades](facades.md) : écrans data-driven et comportement host-scoped du store.
- [Briques Drive](bricks-drive.md) : les fichiers et collections (conversion IA masquée en tiers).
