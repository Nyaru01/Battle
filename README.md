# Battle

Jeu mobile original de stratégie en arène, en temps réel et jouable hors ligne contre une IA. La v0.50 refond entièrement les personnages et l’interface : héros KayKit animés pré-rendus, accueil royal, collection plus lisible, HUD compact et pose tactile directe.

## Vertical slice 0.50

- six héros KayKit distincts, chacun avec 100 images : apparition, repos, marche, attaque, impact et défaite, de face et de dos ;
- accueil animé avec profil, monnaie, choix de difficulté, grand bouton Combat et navigation Accueil/Cartes/Entraînement/Réglages ;
- collection de huit cartes avec portraits animés, statistiques et améliorations ;
- arène verticale illustrée, tours modulaires, eau animée, projectiles, sorts, impacts et secousses de caméra ;
- énergie segmentée, prochaine carte, sélection dorée, cartes indisponibles atténuées et véritable fantôme du héros pendant le glisser-déposer ;
- trois difficultés d’IA, tutoriel, pause, résultat, progression et sauvegarde hors ligne ;
- interface vérifiée en 540×960, 720×1280 et 800×1280 ;
- 297 assertions automatisées, 1 000 combats IA reproductibles et profil local à 20 héros animés.

Les modèles et composants d’interface tiers sont distribués sous CC0 par KayKit et Kenney. Les polices Baloo 2 et Nunito sont sous SIL Open Font License. Aucun actif de Clash Royale n’est embarqué ; le détail des sources et empreintes est dans [docs/ASSET_PROVENANCE.md](docs/ASSET_PROVENANCE.md).

## Lancer et tester

```powershell
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
godot --path . --script res://tools/profile_visuals.gd
```

## Export Android

```powershell
godot --headless --path . --export-debug "Android Arm64 Debug" "Android/Battle-latest.apk"
powershell -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -ApkPath "Android/Battle-latest.apk" -Variant arm64
```

L’APK courant se trouve toujours dans [Android/Battle-latest.apk](Android/Battle-latest.apk). Chaque export remplace ce fichier stable afin qu’il reste immédiatement visible depuis la racine du dépôt.

Configuration : `versionCode 50`, `versionName 0.50.0-alpha`, API 24 minimum, API cible 36, `arm64-v8a`, portrait, mode immersif et Vulkan Mobile. Android 10 ou plus récent est recommandé.

## Documentation

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Rapport d’équilibrage](docs/BALANCE_REPORT.md)
- [Distribution Android](docs/ANDROID_DISTRIBUTION.md)
- [Provenance des actifs](docs/ASSET_PROVENANCE.md)
