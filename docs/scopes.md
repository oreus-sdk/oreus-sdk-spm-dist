# Scopes et gating fonctionnel

Ce document décrit comment le SDK Vox Chat iOS gère les scopes d'autorisation : état en mémoire, filtrage fail-closed des composants, et politique d'affichage des fonctionnalités indisponibles.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## 1. Source de vérité des scopes

La **liste canonique des scopes est celle du backend Oreus** : elle est définie dans la documentation transverse du contrat API fournie par Oreus, qui reste la source de vérité. Ce document ne la duplique pas — référez-vous à la documentation API de votre version.

Côté client, vous déclarez les scopes **demandés** via la configuration OIDC, dans le champ `scopes` de `VoxConfig` (séparés par une espace) :

```swift
VoxChatSDK.initialize(
    configuration: VoxConfig(
        endpoint: "https://sso.exemple.com",
        clientId: "VOTRE_APP_ID",
        redirectURI: "native-vox-sdk://oidc/callback",
        resource: "https://api.exemple.com",
        apiBaseURL: "https://api.exemple.com",
        scopes: "openid profile email offline_access read:vox write:vox"
        // + les scopes applicatifs listés dans la doc du contrat API
    )
)
```

À défaut, un jeu de scopes recommandé est appliqué. En pratique, demandez le **jeu complet** des scopes utilisés par votre intégration : le filtrage fail-closed (voir ci-dessous) masque toute fonctionnalité dont un scope manque, même si le reste de la session est valide.

## 2. État des scopes : comment le SDK les gère

- **Volatil en mémoire** : l'état des scopes accordés vit en mémoire, reconstruit à chaque session. Rien n'est persisté côté SDK.
- **Filtrage fail-closed** : en cas d'incertitude (scope absent, information manquante, erreur), l'accès est **refusé**. Un composant gaté ne s'affiche que si le scope requis est explicitement accordé.
- **Exigence conjonctive** : quand une fonctionnalité nécessite plusieurs scopes, **tous** doivent être accordés (et logique).
- **Appariement minimal par route** : chaque route d'API du SDK déclare le scope minimal qui la couvre ; c'est ce scope minimal qui sert au gating, pas un sur-ensemble.

L'écart entre scopes demandés et scopes réellement accordés est observable par le SDK : si le serveur d'autorisation accorde moins que ce que votre config demande, les fonctionnalités correspondantes sont simplement absentes de l'interface.

### Exemple de comportement

```text
Config demandée :  "read:vox write:vox read:folders read:files"
Accordé (serveur) : "read:vox write:vox"
```

Résultat à l'exécution :
- Le chat est disponible : `write:vox` (le scope requis par la conversation) est accordé.
- Le drive n'apparaît **pas** dans l'interface : la lecture du drive exige `read:folders` **et** `read:files` cumulés ; `read:folders` manque, et le filtrage fail-closed refuse l'accès plutôt que de tenter des appels destinés à échouer.

Aucune erreur n'est levée côté utilisateur : la fonctionnalité est simplement invisible. Si vous vous attendez à voir une brique et qu'elle n'apparaît pas, comparez d'abord vos scopes demandés aux scopes listés dans la doc du contrat API.

## 3. Gating UI : ce que voit l'utilisateur

Les composants data-driven du SDK sont **gatés par scope** : leur affichage dépend des scopes de la session courante.

La politique appliquée est **« invisibilité plutôt que verrouillage »** : quand une fonctionnalité est indisponible pour la session (scope non accordé), elle **n'est pas affichée du tout** — l'utilisateur ne voit ni bouton grisé, ni écran de blocage. L'interface présente uniquement ce que la session peut réellement faire.

Un écran interne de verrouillage (`FeatureLockedScreen`) existe pour les rares cas où un écran data-driven doit être rendu alors que son scope fait défaut — il est géré par le SDK, vous n'avez pas à l'instancier.

## 4. Accès first-party : pas de bypass

L'app hôte d'origine (first-party) obtient ses accès **par les mêmes scopes demandés** que n'importe quelle app tierce, via sa configuration OIDC. Il n'existe **aucun mécanisme de bypass du filtrage** : le gating s'applique uniformément à toutes les apps intégrées, y compris celle d'Oreus.

Conséquence pratique : si une fonctionnalité du SDK n'apparaît pas dans votre intégration, vérifiez d'abord que le scope correspondant figure bien dans les scopes demandés **et** accordés (voir la doc du contrat API pour la liste des scopes par fonctionnalité).

## 5. Gating différencié : trois niveaux d'outillage

Le SDK distingue trois niveaux selon la nature du composant :

1. **Écran data-driven gaté** : les écrans complets (chat, agents, drive…) évaluent eux-mêmes leurs scopes et masquent ou réduisent leur contenu en conséquence. Aucun travail de votre part.
2. **Utilitaire de composition documenté** : pour composer votre propre interface à partir des briques du SDK, un utilitaire d'évaluation des scopes est documenté et utilisable depuis votre app, afin d'aligner vos choix d'affichage sur ceux du SDK.
3. **Helper interne internalisé** : certains helpers de gating restent internes au SDK (non publics). Ils ne font pas partie du contrat d'intégration et ne doivent pas être contournés.

En résumé : pour les écrans fournis, le gating est automatique ; pour vos compositions personnalisées, appuyez-vous sur l'utilitaire documenté ; n'attendez rien des helpers internes.

### Pièges fréquents

- **Scopes séparés par une espace, pas une virgule** : `"read:vox write:vox"` est correct ; `"read:vox,write:vox"` ne l'est pas. (Le SDK dédoublonne et tolère les séparateurs multiples à l'initialisation, mais restez sur l'espace pour la lisibilité.)
- **Ne demandez pas seulement ce que vous affichez** : les écrans du SDK gatent aussi leurs appels réseau. Un scope manquant sur une route utilisée en arrière-plan rend la fonctionnalité indisponible même si votre UI l'affiche.
- **`offline_access` est indispensable** : sans lui, pas de refresh token, donc pas de session durable — l'utilisateur devrait se reconnecter à chaque lancement.

## Pour aller plus loin

- [Démarrage](getting-started.md) : champ `scopes` de la `VoxConfig`.
- [Personnalisation](customization.md) : adapter le rendu des briques gatées.
- [Erreurs](errors.md) : ce qui se passe quand une requête atteint malgré tout une route interdite.
