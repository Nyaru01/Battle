# Plan de développement — Battle

Version : 0.58

Statut : HUD fantasy sculpté, château plein écran et famille complète de boutons texturés 0.58 intégrés ; validation tactile et thermique sur appareils physiques en cours

Plateforme initiale : Android (APK)

## 1. Vision

Créer un jeu de stratégie en arène mobile où un joueur affronte d'abord une IA avec un deck, une ressource qui se régénère et des combattants ou pouvoirs déployés pendant des parties de 3 à 4 minutes. Le multijoueur humain arrivera dans un second jalon.

Le projet doit s'inspirer du **genre** popularisé par Clash Royale sans en copier les personnages, noms, visuels, sons, arènes, textes, statistiques, interface ou level design. La différenciation doit être définie avant la production des contenus.

### Pistes de différenciation à prototyper

- Deux routes qui évoluent grâce à des objectifs neutres.
- Une compétence de commandant choisie avant le combat.
- Des factions originales avec une identité mécanique claire.
- Une progression compétitive qui ne dépend pas du paiement.

Une seule mécanique signature sera retenue après les tests du prototype.

## 2. Objectifs de livraison

### MVP 1 — APK contre IA

Le premier MVP permet à un nouveau joueur de terminer un tutoriel, composer un deck de 8 cartes, choisir une difficulté, jouer hors ligne contre une IA, recevoir un résultat et relancer une partie sans redémarrer l'application.

### Inclus

- duel 1 contre 1 face à une IA, une arène et parties de 3 à 4 minutes ;
- 16 cartes originales : 10 unités, 4 pouvoirs, 2 structures ;
- deck de 8 cartes, main tournante de 4 cartes et énergie régénérative ;
- objectifs défensifs, prolongation et règles de victoire ;
- tutoriel, entraînement libre et trois niveaux d'IA sans triche ;
- plusieurs decks IA et scénarios de test ;
- sauvegarde locale versionnée, sans compte obligatoire ;
- accueil, collection, deck, choix du combat, combat et résultats ;
- progression locale légère et récompenses gagnées en jeu ;
- télémétrie respectueuse du consentement et crash reporting ;
- APK installable et jouable sans connexion.

### MVP 2 — Multijoueur

- compte invité et liaison de compte ;
- matchmaking, classement et progression synchronisée ;
- matchs autoritaires, reconnexion et validation anti-triche ;
- backend, administration, télémétrie serveur et exploitation en ligne.

### Hors périmètre

- clans, chat, amis, spectateurs, 2 contre 2 et tournois ;
- boutique complexe, publicités, passe de saison et achats intégrés ;
- nombreuses arènes, dizaines de cartes ou événements temporaires ;
- multijoueur dans le MVP 1, replay complet, iOS, PC et navigateur ;
- localisation étendue.

Tout ajout exige une décision explicite et le retrait d'un élément de coût comparable.

## 3. Principes de conception

- **Lisibilité** : cible, portée, équipe et état d'une unité sont compris immédiatement.
- **Décisions fréquentes** : chaque carte crée un arbitrage de timing, placement ou contre.
- **Contre-jeu** : aucune carte ne doit être dépourvue de réponse accessible.
- **Sessions courtes** : recherche et chargement compris, viser moins de 6 minutes.
- **IA équitable** : elle reçoit les mêmes informations, ressources et délais que le joueur.
- **Préparation au réseau** : humain, IA et futur client distant utilisent les mêmes commandes de jeu.
- **Mobile d'abord** : tactile, chauffe, batterie, stockage et petits écrans sont testés tôt ; le réseau dégradé sera ajouté au MVP 2.
- **Gameplay piloté par les données** : les cartes sont équilibrables sans changer le code.

## 4. Architecture proposée

### Socle de simulation

- logique de combat en GDScript pur, découplée des scènes, animations et entrées Godot ;
- simulation à fréquence fixe avec graines aléatoires reproductibles ;
- commandes communes : jouer une carte, position cible et compétence ;
- contrôleurs interchangeables `Humain`, `IA` et, plus tard, `Réseau` ;
- sauvegarde locale versionnée et migrations testées ;
- replays de diagnostic fondés sur la graine et la liste des commandes.

### Client

- Godot 4.7.1 au démarrage du prototype, version figée par jalon ;
- GDScript et rendu Vulkan Mobile pour Android Arm64 ;
- arène 2,5D stylisée et interface responsive, optimisées pour une lecture tactile immédiate ;
- ScriptableObjects pour l'édition, avec export vers des données communes versionnées ;
- tests headless de la logique et des parcours critiques.

### Backend — MVP 2

- Nakama pour identité, sessions, matchmaking, stockage et matchs autoritaires ;
- processus Godot headless autoritaire réutilisant les scripts de simulation ;
- PostgreSQL pour la persistance ;
- Docker pour les environnements local, test et production ;
- administration restreinte pour parties, comptes et configuration.

### Réseau — MVP 2

- simulation serveur à fréquence fixe, conforme aux règles du socle local ;
- commandes horodatées : jouer une carte, position cible, compétence ;
- validation de la session, main, énergie, délai et zone de pose ;
- snapshots, interpolation visuelle et correction côté client ;
- reconnexion courte avec restauration d'état ;
- résultat calculé uniquement par le serveur ;
- limites de débit, détection des commandes impossibles et traces d'audit.

La cadence de simulation locale est mesurée dès le MVP 1. La cadence réseau et celle des snapshots seront choisies pendant le prototype multijoueur.

### Structure cible

```text
Battle/
├── assets/                 # Icônes et futurs actifs visuels/sonores
├── scenes/                 # Scènes Godot
├── scripts/sim/            # Simulation et IA sans dépendance visuelle
├── tests/                  # Tests headless et matchs automatisés
├── docs/                   # Conception et décisions
├── deploy/                 # Backend du MVP 2
└── .github/workflows/      # Tests et builds Android
```

### Intégration continue

Chaque pull request valide les données de cartes, exécute les tests de simulation et du client, analyse le code et recherche les secrets. Les tests serveur sont activés avec le MVP 2. La branche d'intégration produit un build Android de développement si les contraintes de licence du moteur le permettent. Les clés de signature et secrets ne sont jamais stockés dans Git.

## 5. Systèmes à construire

### Combat

- victoire, durée, prolongation et abandon ;
- énergie, pioche, main, cycle et pose ;
- déplacement par routes et choix de cible ;
- attaques, portée, cadence, dégâts, vie et effets d'état ;
- destruction des objectifs, résultat et progression locale ;
- pause, reprise, abandon et sauvegarde des réglages ;
- déconnexion, reconnexion et fin forcée ajoutées au MVP 2.

### Intelligence artificielle

- l'IA observe l'état public du combat et agit avec les mêmes règles que le joueur ;
- un système d'utilité note les actions possibles selon défense, attaque, synergies, coût et risque ;
- une carte n'est jouée qu'après un délai de décision configurable ;
- les placements utilisent des zones candidates évaluées, pas des coordonnées parfaites cachées ;
- les personnalités modifient les poids : agressive, contrôle, économie ou contre-attaque ;
- les difficultés changent délai, profondeur d'évaluation et qualité des choix, jamais les dégâts ou l'énergie ;
- une graine rend chaque partie reproductible pour le débogage ;
- les decks et scénarios IA sont pilotés par les données ;
- un mode bot contre bot accélère les tests de stabilité et d'équilibrage.

Critères d'acceptation de l'IA du MVP 1 :

- elle sait défendre chaque route, construire une attaque et terminer une partie ;
- elle ne joue jamais une carte invalide et ne reste pas inactive plus longtemps que sa configuration ;
- les trois difficultés sont distinguables lors de tests à l'aveugle ;
- le niveau débutant laisse volontairement des fenêtres d'apprentissage ;
- le niveau avancé est compétitif sans accès à une information cachée ni bonus de statistiques ;
- 1 000 parties bot contre bot se terminent sans blocage ni état invalide.

### Métajeu

- catalogue, collection et construction du deck ;
- récompense de fin, profil local et défis solo ;
- compte synchronisé et classement ajoutés au MVP 2 ;
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

Les durées supposent une petite équipe expérimentée de 3 à 5 personnes. Pour le MVP 1 réalisé en solo, prévoir plutôt 4 à 7 mois selon la finition et les actifs externalisés.

### Phase 0 — Cadrage et socle APK (1 semaine)

Livrables : pitch et public cible, mécanique signature, direction visuelle originale, matrice d'appareils Android, budget, registre des risques, export APK et preuve de simulation GDScript indépendante d'une scène Godot.

**Sortie :** un APK s'installe sur un appareil cible et une simulation reproductible accepte des commandes humaines ou IA.

### Phase 1 — Prototype de combat et IA simple (2 à 3 semaines)

Livrables : arène grise, caméra et tactile, énergie, main, pose, déplacement, ciblage, dégâts, six cartes temporaires, IA à règles simples, bot contre bot et instrumentation des parties.

**Sortie :** 20 parties internes se terminent sans blocage et la boucle est comprise et jugée intéressante. Sinon, itérer ou arrêter avant de produire les actifs.

### Phase 2 — IA du MVP et boucle solo (2 à 3 semaines)

Livrables : système d'utilité, trois difficultés, personnalités, decks IA, tutoriel, choix du combat, résultat, sauvegarde locale et tests de 1 000 parties automatisées.

**Sortie :** l'APK est jouable hors ligne de bout en bout, les difficultés sont perceptibles et aucune partie automatisée ne se bloque.

### Phase 3 — Vertical slice solo (terminée en 0.50)

Livrables : une arène représentative, huit cartes avec son et effets, écrans principaux, progression locale, première passe d'accessibilité et profilage sur appareils bas, moyen et haut de gamme.

**Sortie :** arène 2D fantasy, six héros KayKit animés pré-rendus de face et de dos, tirs à temps de trajet réel, accueil/collection/HUD/overlays refondus, glisser-déposer tactile, APK Arm64 et campagne de 1 000 matchs livrés. La validation tactile et thermique sur appareil physique reste requise.

### Phase 4 — Contenu et alpha APK solo (3 semaines)

Livrables : 16 cartes originales, collection, deck, récompenses locales, équilibrage versionné, localisation initiale, événements analytiques documentés et distribution fermée de l'APK.

**Sortie :** un nouveau joueur accomplit tout le parcours solo sans compte, connexion ni intervention manuelle.

### Phase 5 — Stabilisation du MVP 1 (2 semaines)

Livrables : 30 à 100 testeurs, tableau de bord de stabilité, équilibrage joueur/IA, optimisation Android, accessibilité et politique de confidentialité adaptée aux données réellement collectées.

**Sortie :** APK solo publiable, aucun bug bloquant connu, stabilité conforme et majorité des testeurs capables de terminer le tutoriel puis trois combats.

### Phase 6 — MVP 2 multijoueur (4 à 6 semaines, après validation)

Livrables : compte invité, matchmaking, serveur autoritaire, snapshots, latence, reconnexion, classement, progression synchronisée, tests de triche et de charge, environnements Docker et bêta fermée Android.

**Sortie :** 100 matchs réseau automatisés consécutifs sont cohérents, les profils réseau cibles restent jouables et les seuils qualité sont tenus pendant une semaine.

## 7. Backlog initial

### P0 — Premier APK contre IA

- initialiser le projet Godot et le build Android ;
- définir le schéma versionné des cartes ;
- implémenter la simulation GDScript à fréquence fixe, isolée des nœuds Godot ;
- créer énergie, cycle et validation de pose ;
- créer déplacement, ciblage, combat et victoire ;
- définir les commandes communes aux contrôleurs humain et IA ;
- créer l'IA d'utilité, trois difficultés et plusieurs decks ;
- gérer tutoriel, résultats, sauvegarde locale et progression ;
- automatiser 1 000 parties bot contre bot ;
- produire un APK de développement par CI.

### P1 — Alpha utile

- deck, collection et boucle de progression locale ;
- 16 cartes, effets et équilibrage ;
- télémétrie consentie et crash reporting ;
- optimisation Android, accessibilité et localisation ;
- tests sur la matrice d'appareils et alpha fermée.

### P2 — Après validation du MVP

- comptes, matchmaking, serveur autoritaire et classement ;
- tests de charge, reconnexion et réseau dégradé ;
- replay et spectateur ;
- clans, amis et modes d'équipe ;
- événements, quêtes et passe saisonnier ;
- cosmétiques et achats conformes à la plateforme ;
- nouvelles arènes, factions et modes.

## 8. Équipe

Configuration recommandée :

- responsable produit/game designer : vision, règles, économie, tests et priorités ;
- développeur Godot : interface, rendu, contrôles et intégration ;
- développeur gameplay/IA : simulation, comportements, données et tests ;
- développeur backend en renfort pour le MVP 2 ;
- artiste technique/généraliste : identité, modèles ou sprites, animation, VFX et optimisation ;
- QA, UX, son, juridique et localisation en renfort.

En solo, commencer par huit cartes, une arène et deux difficultés. N'ajouter ni backend ni matchs privés avant que l'APK solo soit stable et plaisant.

## 9. Qualité et acceptation

### Objectifs de départ

- 60 images/s sur appareil médian et mode 30 images/s stable en bas de gamme ;
- pas d'allocation mémoire récurrente importante dans la boucle de combat ;
- chargement d'un combat inférieur à la cible fixée en phase 0 ;
- autonomie, chauffe et taille de l'APK mesurées sur appareil réel ;
- installation et reprise testées sur chaque version Android supportée.

Les valeurs finales sont fixées après mesure sur la matrice d'appareils.

### Tests obligatoires

- tests unitaires des coûts, ciblage, dégâts, victoire et progression ;
- propriétés : valeurs non négatives, résultat unique, deck toujours valide ;
- parties bot contre bot en CI avec graines reproductibles ;
- tests des décisions IA et de l'absence de commandes invalides ;
- intégration client-serveur et tests réseau ajoutés au MVP 2 ;
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
- difficulté choisie et taux de victoire face à chaque profil IA ;
- parties terminées ou abandonnées ;
- durée et distribution des résultats ;
- usage et victoire par carte, deck et niveau ;
- utilisateurs sans crash et erreurs de simulation par match ;
- rétention J1 et J7 pendant la bêta ;
- retours sur lisibilité, contrôles, équité et plaisir.

Avant toute collecte, définir consentement, conservation, accès, suppression et anonymisation pour les pays visés.

## 11. Sécurité, conformité et propriété intellectuelle

- ne jamais faire confiance au client pour l'inventaire, l'énergie, les dégâts ou le résultat ;
- limiter les requêtes, révoquer les sessions et conserver des traces proportionnées ;
- chiffrer les communications et protéger les secrets au repos ;
- prévoir une politique de confidentialité dès le MVP 1, puis suppression et export de compte avec le MVP 2 ;
- évaluer RGPD, protection des mineurs, classification d'âge et règles Google Play avec un conseil compétent ;
- tenir un registre des licences des polices, sons, textures, modèles, outils et dépendances ;
- revoir l'originalité des noms, silhouettes, interface, arène et textes avant la bêta ;
- ne pas utiliser « Clash Royale » dans le nom, l'icône, les métadonnées ou les visuels du produit.

## 12. Risques principaux

| Risque | Impact | Réduction du risque |
|---|---|---|
| Simulation de combat trop complexe | Retards et bugs | Socle GDScript testé dès la phase 0, pas de physique non déterministe |
| Périmètre trop large | MVP jamais terminé | Hors-périmètre explicite, une mécanique signature, décisions de fin de phase |
| Coût du contenu | Peu de cartes ou faible qualité | Style léger, kit modulaire, 16 cartes maximum |
| Déséquilibre | Frustration | Données versionnées, simulations bot et petits ajustements mesurés |
| IA prévisible ou injuste | Ennui ou frustration | Personnalités, tests à l'aveugle, mêmes règles et aucune information cachée |
| Performance Android | Appareils exclus | Budgets précoces, profilage réel et effets adaptatifs |
| Migration vers le réseau | Réécriture du combat | Simulation isolée et mêmes commandes pour humain, IA et réseau |
| Coûts serveur du MVP 2 | Exploitation non viable | Tests de charge, coût par match et limites d'usage |
| Ressemblance juridique | Retrait ou litige | Univers original, registre des sources et revue PI avant publication |

## 13. Gouvernance

- branche `main` toujours déployable ;
- branches courtes et pull requests relues ;
- décisions structurantes enregistrées dans `docs/decisions/` ;
- données d'équilibrage relues comme du code ;
- builds client et configuration identifiables séparément, puis serveur au MVP 2 ;
- décision à chaque fin de phase : continuer, ajuster, réduire ou arrêter ;
- aucune date publique avant la réussite du vertical slice solo et des tests IA automatisés.

## 14. Prochaines actions

1. Valider la vision, le public cible et la mécanique signature.
2. Confirmer la taille d'équipe, le budget et le calendrier réel.
3. Choisir cinq à huit appareils Android représentatifs.
4. Produire le mini-GDD des règles, de l'IA et les wireframes des six écrans.
5. Réaliser les spikes APK, simulation GDScript indépendante et contrôleur IA.
6. Transformer le backlog P0 en tickets estimés.
7. Lancer le prototype gris sans actifs définitifs.

Le plan doit être revu après les spikes techniques puis après 1 000 parties bot contre bot. Le multijoueur ne démarre qu'après validation du MVP solo sur appareils réels.
