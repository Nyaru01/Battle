# Battle

`Battle` est le nom de travail d'un jeu mobile de stratégie en arène, en temps réel, destiné à Android. Le projet reprend les codes du genre — deck, énergie, déploiement d'unités et parties courtes — avec un univers, des règles, une interface et des contenus originaux.

## État du projet

Le développement du premier prototype jouable est en cours.

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Décision : mode contre IA en premier](docs/decisions/0001-ai-first.md)
- Cible initiale : APK Android
- Mode prioritaire : duel 1 contre 1 contre une IA, jouable hors ligne
- Première livraison : APK solo sans compte ni backend obligatoire
- Étape suivante : multijoueur avec serveur autoritaire
- Moteur : Godot 4.7.1, rendu Compatibility

## Prototype actuel

- menu et trois difficultés d'IA ;
- tutoriel interactif guidant les quatre premières actions tactiles ;
- écran Collection présentant les huit cartes, leurs coûts et statistiques ;
- arène à deux voies avec tours et noyaux ;
- deck de huit cartes avec main tournante de quatre cartes et prochaine pioche visible ;
- huit cartes originales, dont trois nouveaux combattants et le sort de ralentissement Stase ;
- énergie, déplacement, ciblage, combat, victoire et limite de temps ;
- score par forteresses détruites, prolongation en mort subite et énergie doublée ;
- pause manuelle, pause automatique en arrière-plan, reprise et abandon ;
- IA équitable utilisant les mêmes commandes que le joueur ;
- banc reproductible de 1 000 matchs IA avec contrôle des états et commandes ;
- sauvegarde locale des victoires et défaites ;
- progression locale versionnée avec niveau, expérience, éclats et récompenses de match ;
- contrôles souris et tactiles ;
- arène 2,5D originale avec chemins, rivière et ponts ;
- cartes, combattants et forteresses illustrés avec des actifs originaux ;
- export APK Android debug.
- distributions universelle (armv7 + arm64) et arm64 allégée.

## Lancer le projet

Avec Godot 4.7.1 ou une version compatible :

```powershell
godot --path .
```

Lancer les tests headless :

```powershell
godot --headless --path . --script res://tests/run_tests.gd
```

Exporter l'APK après configuration du SDK Android et des modèles d'export :

```powershell
godot --headless --path . --export-debug "Android Debug" builds/Battle-debug.apk
```

Exporter uniquement pour les appareils arm64 modernes :

```powershell
godot --headless --path . --export-debug "Android Arm64 Debug" builds/Battle-arm64-debug.apk
```

## Prochaine décision

Tester la boucle de combat sur un appareil Android, puis itérer sur l'IA, l'équilibrage et la lisibilité.
