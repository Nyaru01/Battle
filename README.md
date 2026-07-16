# Battle

Jeu mobile original de stratégie en arène, en temps réel et jouable hors ligne contre une IA. La v0.40 est une refonte visuelle complète pensée pour le portrait Android : arène fantasy lumineuse, accueil vivant, cartes premium et combattants réellement articulés.

## Vertical slice 0.40

- six combattants construits avec huit parties indépendantes, animés au repos, en marche, en attaque, à l’impact, au déploiement et à la défaite ;
- arène verticale illustrée, tours modulaires, eau animée, projectiles, sorts, impacts et secousses de caméra ;
- pose tactile au choix : sélectionner puis toucher l’arène, ou glisser directement une carte avec prévisualisation valide/interdite ;
- huit cartes, main tournante de quatre cartes, énergie, progression locale et collection améliorable ;
- trois difficultés d’IA, tutoriel, pause, résultat et sauvegarde hors ligne ;
- interface responsive testée en 540×960, 720×1280 et 800×1280 ;
- rendu Vulkan Mobile, export Android Arm64 immersif ;
- 248 assertions automatisées et campagne reproductible de 1 000 combats IA.

Tous les personnages, bâtiments, illustrations et éléments d’interface sont originaux. Baloo 2 et Nunito sont distribuées sous SIL Open Font License. Aucun actif de Clash Royale n’est embarqué.

## Lancer et tester

```powershell
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

## Export Android

```powershell
godot --headless --path . --export-debug "Android Arm64 Debug" "Android/Battle-latest.apk"
powershell -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -ApkPath "Android/Battle-latest.apk" -Variant arm64
```

L’APK courant se trouve toujours dans [Android/Battle-latest.apk](Android/Battle-latest.apk). Chaque export remplace ce fichier stable afin qu’il reste immédiatement visible depuis la racine du dépôt.

Configuration : API 24 minimum, API cible 36, `arm64-v8a`, portrait, mode immersif et Vulkan Mobile. Android 10 ou plus récent est recommandé.

## Documentation

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Rapport d’équilibrage](docs/BALANCE_REPORT.md)
- [Distribution Android](docs/ANDROID_DISTRIBUTION.md)
- [Provenance des actifs](docs/ASSET_PROVENANCE.md)
