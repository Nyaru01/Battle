# Plan de développement — Battle

Version : 0.1

Statut : proposition à valider

Plateforme initiale : Android (APK)

## 1. Vision

Créer un jeu de stratégie en arène mobile où deux joueurs construisent un deck, dépensent une ressource qui se régénère et déploient des combattants ou des pouvoirs pendant des parties de 3 à 4 minutes.

Le projet doit s'inspirer du **genre** popularisé par Clash Royale sans en copier les personnages, noms, visuels, sons, arènes, textes, statistiques, interface ou level design. La différenciation doit être définie avant la production des contenus.

### Pistes de différenciation à prototyper

- Deux routes qui évoluent grâce à des objectifs neutres.
- Une compétence de commandant choisie avant le combat.
- Des factions originales avec une identité mécanique claire.
- Une progression compétitive qui ne dépend pas du paiement.

Une seule mécanique signature sera retenue après les tests du prototype.

## 2. Objectif du MVP

Le MVP permet à un nouveau joueur de terminer un tutoriel, composer un deck de 8 cartes, trouver un adversaire humain, jouer une partie complète sur Android, recevoir un résultat et relancer une partie sans redémarrer l'application.

### Inclus

- duel 1 contre 1, une arène et parties de 3 à 4 minutes ;
- 16 cartes originales : 10 unités, 4 pouvoirs, 2 structures ;
- deck de 8 cartes, main tournante de 4 cartes et énergie régénérative ;
- objectifs défensifs, prolongation et règles de victoire ;
- tutoriel, entraînement contre un bot et matchmaking simple ;
- compte invité et liaison de compte ultérieure ;
- accueil, collection, deck, recherche, combat et résultats ;
- progression légère, récompenses en jeu et classement basique ;
- télémétrie, logs serveur, crash reporting et administration minimale ;
- APK interne, puis paquet Android de publication.

### Hors périmètre

- clans, chat, amis, spectateurs, 2 contre 2 et tournois ;
- boutique complexe, publicités, passe de saison et achats intégrés ;
- nombreuses arènes, dizaines de cartes ou événements temporaires ;
- replay complet, iOS, PC et navigateur ;
- localisation étendue.

Tout ajout exige une décision explicite et le retrait d'un élément de coût comparable.

## 3. Principes de conception

- **Lisibilité** : cible, portée, équipe et état d'une unité sont compris immédiatement.
- **Décisions fréquentes** : chaque carte crée un arbitrage de timing, placement ou contre.
- **Contre-jeu** : aucune carte ne doit être dépourvue de réponse accessible.
- **Sessions courtes** : recherche et chargement compris, viser moins de 6 minutes.
- **Serveur autoritaire** : le client envoie des intentions, jamais un résultat.
- **Mobile d'abord** : tactile, chauffe, batterie, réseau instable et petits écrans sont testés tôt.
- **Gameplay piloté par les données** : les cartes sont équilibrables sans changer le code.

## 4. Architecture proposée

### Client

- Unity, version LTS stable au lancement du projet ;
- C#, URP et Input System pour Android ;
- direction 2D ou 3D légère décidée en phase 0 ;
- ScriptableObjects pour l'édition, avec export vers des données communes versionnées ;
- tests Unity de la logique et des parcours critiques.

### Backend

- Nakama pour identité, sessions, matchmaking, stockage et matchs autoritaires ;
- runtime de match en TypeScript ou Go, tranché après un spike ;
- PostgreSQL pour la persistance ;
- Docker pour les environnements local, test et production ;
- administration restreinte pour parties, comptes et configuration.

### Réseau

- simulation serveur à fréquence fixe, indépendante de la physique Unity ;
- commandes horodatées : jouer une carte, position cible, compétence ;
- validation de la session, main, énergie, délai et zone de pose ;
- snapshots, interpolation visuelle et correction côté client ;
- reconnexion courte avec restauration d'état ;
- résultat calculé uniquement par le serveur ;
- limites de débit, détection des commandes impossibles et traces d'audit.

La cadence de simulation et des snapshots sera choisie après mesure pendant le prototype réseau.

### Structure cible

```text
Battle/
├── client/                 # Projet Unity
├── server/                 # Runtime de match et API
├── shared/                 # Schémas et données de gameplay
├── deploy/                 # Docker et environnements
├── docs/                   # Conception et décisions
├── tools/                  # Validation et utilitaires
└── .github/workflows/      # Tests et builds Android
```

### Intégration continue

Chaque pull request valide les données de cartes, exécute les tests client et serveur, analyse le code et recherche les secrets. La branche d'intégration produit un build Android de développement si les contraintes de licence du moteur le permettent. Les clés de signature et secrets ne sont jamais stockés dans Git.

## 5. Systèmes à construire

### Combat

- victoire, durée, prolongation et abandon ;
- énergie, pioche, main, cycle et pose ;
- déplacement par routes et choix de cible ;
- attaques, portée, cadence, dégâts, vie et effets d'état ;
- destruction des objectifs, résultat et classement ;
- déconnexion, reconnexion et fin forcée ;
- bot déterministe pour tutoriel, entraînement et tests de charge.

### Métajeu

- catalogue, collection et construction du deck ;
- récompense de fin, niveau de compte et classement ;
- configuration distante de l'économie ;
- aucune économie en argent réel avant validation de la rétention et revue juridique.

### Données minimales d'une carte

```text
id, version, nom_localise, type, cout_energie, points_de_vie,
degats, cadence, portee, vitesse, cibles_autorisees, rayon,
duree, tags, effets
```

Chaque configuration d'équilibrage est versionnée et associée aux matchs qui l'utilisent.

## 6. Feuille de route

Les durées supposent une petite équipe expérimentée de 3 à 5 personnes. Pour une personne seule, prévoir plutôt 6 à 10 mois selon la finition et les actifs externalisés.

### Phase 0 — Cadrage et risques (1 semaine)

Livrables : pitch et public cible, mécanique signature, direction visuelle originale, matrice d'appareils Android, budget, registre des risques et deux spikes techniques : export APK et match serveur minimal.

**Sortie :** un APK vide s'installe sur un appareil cible et deux clients rejoignent une même session de test.

### Phase 1 — Prototype hors ligne (2 à 3 semaines)

Livrables : arène grise, caméra et tactile, énergie, main, pose, déplacement, ciblage, dégâts, six cartes temporaires, bot simple et instrumentation des parties.

**Sortie :** 20 parties internes se terminent sans blocage et la boucle est comprise et jugée intéressante. Sinon, itérer ou arrêter avant de produire les actifs.

### Phase 2 — Vertical slice (3 semaines)

Livrables : une arène représentative, huit cartes avec son et effets, écrans principaux, première passe d'accessibilité et profilage sur appareils bas, moyen et haut de gamme.

**Sortie :** le jeu est présentable, lisible en combat chargé et respecte le budget de performance fixé en phase 0.

### Phase 3 — Multijoueur autoritaire (3 à 4 semaines)

Livrables : compte invité, matchmaking, simulation serveur, commandes validées, snapshots, gestion de latence et reconnexion, résultats persistés, tests de triche et de charge, environnements Docker.

**Sortie :** 100 matchs automatisés consécutifs produisent un résultat cohérent et les profils réseau cibles restent jouables.

### Phase 4 — Contenu et progression (3 semaines)

Livrables : 16 cartes originales, tutoriel, entraînement, collection, deck, récompenses, classement, équilibrage versionné, localisation initiale et événements analytiques documentés.

**Sortie :** un nouveau compte accomplit tout le parcours MVP sans intervention manuelle.

### Phase 5 — Alpha fermée (2 semaines)

Livrables : APK interne, 30 à 100 testeurs, tableau de bord de stabilité et réseau, équilibrage initial, brouillons de politique de confidentialité, conditions d'utilisation et suppression de compte.

**Sortie :** aucun bug bloquant connu, stabilité conforme à la cible et majorité des matchs terminés normalement.

### Phase 6 — Bêta Android (2 semaines minimum)

Livrables : build signé reproductible, fiche de boutique, classification d'âge, test fermé Google Play en complément de l'APK, suivi qualité quotidien et procédures de support, sauvegarde et incident.

**Sortie :** seuils qualité tenus pendant une semaine, puis décision explicite de lancer, itérer ou arrêter.

## 7. Backlog initial

### P0 — Premier match complet

- initialiser client, serveur et environnement Docker ;
- définir le schéma versionné des cartes ;
- implémenter la simulation à fréquence fixe ;
- créer énergie, cycle et validation de pose ;
- créer déplacement, ciblage, combat et victoire ;
- connecter deux clients à un match autoritaire ;
- gérer résultats, erreurs réseau et reconnexion ;
- produire un APK de développement par CI.

### P1 — Alpha utile

- tutoriel, bot, deck et collection ;
- matchmaking et classement ;
- 16 cartes, effets et équilibrage ;
- télémétrie, crash reporting et administration ;
- optimisation Android, accessibilité et localisation ;
- tests de charge et de réseau dégradé.

### P2 — Après validation du MVP

- replay et spectateur ;
- clans, amis et modes d'équipe ;
- événements, quêtes et passe saisonnier ;
- cosmétiques et achats conformes à la plateforme ;
- nouvelles arènes, factions et modes.

## 8. Équipe

Configuration recommandée :

- responsable produit/game designer : vision, règles, économie, tests et priorités ;
- développeur Unity : interface, rendu, contrôles et intégration ;
- développeur backend/gameplay : simulation, réseau, données et infrastructure ;
- artiste technique/généraliste : identité, modèles ou sprites, animation, VFX et optimisation ;
- QA, UX, son, juridique et localisation en renfort.

En solo, réduire d'abord le périmètre à huit cartes, une arène, un bot et des matchs privés avant le matchmaking public.

## 9. Qualité et acceptation

### Objectifs de départ

- 60 images/s sur appareil médian et mode 30 images/s stable en bas de gamme ;
- pas d'allocation mémoire récurrente importante dans la boucle de combat ;
- chargement compatible avec la fenêtre de matchmaking ;
- consommation réseau mesurée par match ;
- installation et reprise testées sur chaque version Android supportée.

Les valeurs finales sont fixées après mesure sur la matrice d'appareils.

### Tests obligatoires

- tests unitaires des coûts, ciblage, dégâts, victoire et classement ;
- propriétés : valeurs non négatives, résultat unique, deck toujours valide ;
- parties bot contre bot en CI avec graines reproductibles ;
- intégration client-serveur ;
- latence, perte, duplication et réordonnancement de messages ;
- installation, mise en arrière-plan et reprise Android ;
- tests manuels de lisibilité, tutoriel et accessibilité.

### Definition of Done

- critères d'acceptation approuvés ;
- code relu et tests passants ;
- erreurs et télémétrie prévues ;
- comportement dégradé défini ;
- performance vérifiée sur appareil réel ;
- documentation et données à jour ;
- aucun secret ni actif sans licence.

## 10. Mesures produit

- fin du tutoriel et délai jusqu'au premier match ;
- durée de recherche et qualité de connexion ;
- parties terminées, abandonnées ou déconnectées ;
- durée et distribution des résultats ;
- usage et victoire par carte, deck et niveau ;
- utilisateurs sans crash et erreurs serveur par match ;
- rétention J1 et J7 pendant la bêta ;
- retours sur lisibilité, contrôles, équité et plaisir.

Avant toute collecte, définir consentement, conservation, accès, suppression et anonymisation pour les pays visés.

## 11. Sécurité, conformité et propriété intellectuelle

- ne jamais faire confiance au client pour l'inventaire, l'énergie, les dégâts ou le résultat ;
- limiter les requêtes, révoquer les sessions et conserver des traces proportionnées ;
- chiffrer les communications et protéger les secrets au repos ;
- prévoir suppression de compte, export et politique de confidentialité ;
- évaluer RGPD, protection des mineurs, classification d'âge et règles Google Play avec un conseil compétent ;
- tenir un registre des licences des polices, sons, textures, modèles, outils et dépendances ;
- revoir l'originalité des noms, silhouettes, interface, arène et textes avant la bêta ;
- ne pas utiliser « Clash Royale » dans le nom, l'icône, les métadonnées ou les visuels du produit.

## 12. Risques principaux

| Risque | Impact | Réduction du risque |
|---|---|---|
| Simulation réseau trop complexe | Retards et triche | Prototype autoritaire dès la phase 0, pas de physique non déterministe |
| Périmètre trop large | MVP jamais terminé | Hors-périmètre explicite, une mécanique signature, décisions de fin de phase |
| Coût du contenu | Peu de cartes ou faible qualité | Style léger, kit modulaire, 16 cartes maximum |
| Déséquilibre | Frustration | Données versionnées, simulations bot et petits ajustements mesurés |
| Performance Android | Appareils exclus | Budgets précoces, profilage réel et effets adaptatifs |
| Faible population | Matchmaking lent | Bot transparent, fenêtres de test et critères assouplis |
| Coûts serveur | Exploitation non viable | Tests de charge, coût par match, limites et extinction des environnements inutiles |
| Ressemblance juridique | Retrait ou litige | Univers original, registre des sources et revue PI avant publication |

## 13. Gouvernance

- branche `main` toujours déployable ;
- branches courtes et pull requests relues ;
- décisions structurantes enregistrées dans `docs/decisions/` ;
- données d'équilibrage relues comme du code ;
- builds client, serveur et configuration identifiables séparément ;
- décision à chaque fin de phase : continuer, ajuster, réduire ou arrêter ;
- aucune date publique avant la réussite du vertical slice et du prototype réseau.

## 14. Prochaines actions

1. Valider la vision, le public cible et la mécanique signature.
2. Confirmer la taille d'équipe, le budget et le calendrier réel.
3. Choisir cinq à huit appareils Android représentatifs.
4. Produire le mini-GDD des règles et les wireframes des six écrans.
5. Réaliser les spikes APK et match autoritaire.
6. Transformer le backlog P0 en tickets estimés.
7. Lancer le prototype gris sans actifs définitifs.

Le plan doit être revu après les deux spikes techniques. Les estimations et le périmètre seront alors ajustés à partir de mesures réelles.
