# Gestion des erreurs

Ce document décrit comment le SDK Vox Chat iOS classifie et traite les erreurs : réponses 403, erreurs de jetons, validation de configuration et affichage des toasts.

> **Versionnage** : cette documentation est versionnée avec le SDK. Consultez toujours la doc correspondant au tag de la version que vous intégrez.

---

## 1. Classification des réponses 403

Un 403 du backend est systématiquement classifié comme une **erreur de configuration applicative**, pas comme un échec d'authentification utilisateur. Le SDK décode le corps de la réponse en un DTO d'acquittement strict (`AckResponseDto`) dont la règle de rejet garantit que toute enveloppe d'erreur atterrit bien dans la classification.

Points clés :

- L'utilisateur est authentifié ; c'est la **déclaration de l'application** côté console Oreus qui est en cause (application non enregistrée, jeton tiers sans client rattaché, etc.).
- L'erreur porte un **message actionnable** évoquant la vérification de la déclaration de l'application dans la console Oreus.
- **Aucune déconnexion n'est déclenchée** par un 403 : déconnecter l'utilisateur ne résoudrait rien puisqu'il est bien authentifié.

En pratique : si vos appels échouent en 403, vérifiez l'enregistrement de votre application (type d'application, rattachement organisation, App ID) dans la console Oreus.

### Exemple de diagnostic

```text
Réponse : 403
Corps   : enveloppe d'erreur décodée via AckResponseDto
Erreur  : configuration applicative — message actionnable évoquant
          la console Oreus
Déconnexion : NON (l'utilisateur reste authentifié)
```

À distinguer d'un **401**, qui signifie un jeton invalide ou expiré et déclenche le mécanisme décrit dans la section suivante.

## 2. `handleTokenError` : quand le SDK déconnecte-t-il

En cas d'erreur de jeton, le SDK applique une politique stricte de déconnexion :

- **Seuls les codes HTTP 400 et 401** sur le rafraîchissement du jeton signifient des credentials invalides ou expirés → **déconnexion automatique**. Tout autre code (en particulier les erreurs réseau de type `URLError`) n'entraîne pas de déconnexion : c'est une panne transitoire, pas une mort de session.
- **Rotation du refresh token** : le SDK s'appuie sur la rotation du refresh token côté serveur ; un refresh token révoqué ou expiré produit un 400/401 et donc une déconnexion propre.
- **Garde pendant le SSO en cours** : aucune déconnexion n'est déclenchée tant qu'un flux de connexion SSO est en cours. Pendant l'installation de la session, l'absence **temporaire** de refresh token (l'id_token peut être publié avant les autres jetons) n'est pas interprétée comme une session morte.

### Détail de la politique de déconnexion

| Situation | Comportement du SDK |
|---|---|
| Refresh en échec 400 ou 401 | Déconnexion automatique (credentials invalides ou expirés). |
| Refresh en échec avec `URLError` (réseau indisponible, timeout…) | Aucune déconnexion : erreur transitoire, nouvelle tentative au retour du réseau. |
| Refresh en échec avec un autre code (5xx…) | Aucune déconnexion : panne serveur, pas une mort de session. |
| Absence de refresh token hors flux SSO | Déconnexion automatique. |
| Absence temporaire de refresh token pendant un SSO en cours | Aucune déconnexion (garde active tant que le flux est en vol). |

Le SDK gère seul la rotation du refresh token : vous n'avez rien à implémenter pour la renouveler. En revanche, votre app doit être capable de réagir à la déconnexion (retour à l'écran de connexion).

## 3. Validation du claim `client_id` sur les access tokens

Le SDK valide le claim `client_id` des **access tokens** (conformément à la RFC 8707 sur les ressources visées), **pas** celui de l'id_token. Cette validation se fait à l'obtention du jeton.

Si le claim `client_id` est divergent ou absent, le SDK classifie la réponse comme une erreur de configuration applicative (même famille que les 403 décrits ci-dessus) : message actionnable, **pas de déconnexion** — le problème est côté déclaration de l'application dans la console Oreus, pas côté utilisateur.

## 4. Erreurs de configuration : validation au démarrage

La `VoxConfig` passée à `VoxChatSDK.initialize(configuration:)` est **validée au démarrage**. Une configuration invalide produit une erreur explicite plutôt qu'un échec silencieux plus tard :

- `clientId` ou `redirectURI` vides : la configuration est incomplète et le flow OIDC échouera avec une erreur typée `notConfigured`.
- URLs malformées ou préfixes de routage inclus par erreur dans `apiBaseURL` (par exemple ajouter manuellement `/api/v1`) : les appels réseau échoueront ; `apiBaseURL` doit être une **origine nue** (voir [démarrage](getting-started.md)).

Le SDK normalise automatiquement ce qui peut l'être (slashs de fin des URLs, dédoublonnage des scopes) ; le reste relève de votre responsabilité à l'intégration.

### Checklist de configuration

- [ ] `endpoint` : origine nue du serveur OIDC, sans chemin ni slash final.
- [ ] `clientId` : App ID de la console Oreus, pas votre Bundle ID.
- [ ] `redirectURI` : schéma canonique `native-vox-sdk://oidc/callback`, déclaré côté console Oreus et dans le `CFBundleURLTypes` de votre app.
- [ ] `resource` : identifiant de ressource RFC 8707, distinct de `apiBaseURL`.
- [ ] `apiBaseURL` : origine nue du backend, sans `/api/v1` ni `/api/v1/external`.
- [ ] `scopes` : jeu complet listé dans la doc du contrat API, séparés par des espaces, `offline_access` inclus.
- [ ] Polices : les 4 faces Regular/Medium/Semibold/Bold embarquées dans l'app si `fontFamily` est renseigné (voir [personnalisation](customization.md)).

## 5. Toasts : au-dessus de toutes les présentations modales

Les erreurs transitoires signalées à l'utilisateur (échec réseau, erreur de synchronisation…) sont affichées via les **toasts du SDK** :

- Les toasts sont **visibles au-dessus des présentations modales** (sheets, fullscreen covers) : ils sont attachés au layer de la fenêtre **host par layer présenté**, pas à une vue particulière de la hiérarchie.
- Conséquence : un toast déclenché depuis une modale reste visible, et un toast déclenché en arrière-plan reste visible même si une modale est présentée entre-temps.
- Vous n'avez rien à configurer pour les toasts ; si vous préférez un rendu d'erreur propre à votre app pour un flux donné, certaines briques (comme `VoxSsoButton`) acceptent une closure `onFailure` pour remplacer le toast par défaut.

## Pour aller plus loin

- [Démarrage](getting-started.md) : configuration initiale et validation de la `VoxConfig`.
- [Scopes et gating](scopes.md) : filtrage fail-closed des fonctionnalités.
- [Personnalisation](customization.md) : bouton SSO et rendu des erreurs par l'app hôte.
