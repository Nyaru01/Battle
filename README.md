# Battle

Jeu mobile original de stratégie en arène, en temps réel et jouable hors ligne contre une IA. La v0.57 donne enfin à l’action Combat un véritable bouton fantasy texturé : panneau bleu profond, relief de métal forgé, liseré doré et proportions responsives inspirées des grands menus RTS classiques.

## Vertical slice 0.57

- six héros KayKit distincts, chacun avec 100 images : apparition, repos, marche, attaque, impact et défaite, de face et de dos ;
- accueil château plein écran avec profondeur illustrée, trio animé posé sur son estrade, HUD fantasy sculpté, bouton Combat original en métal et émail bleu, navigation en dock et fiche de difficulté dédiée ;
- collection de huit cartes avec portraits animés, statistiques et améliorations ;
- arène verticale illustrée en cadrage `cover` 2:3 sans déformation ni bandes noires, tours modulaires, eau animée, projectiles, sorts, impacts et secousses de caméra ;
- placement libre des unités dans la base alliée, position x/y conservée, trajectoires convergentes, projectiles issus de la position réelle et orientation dynamique vers la cible ;
- héros recalés sur leurs ombres, vues face/dos opposées par camp et miroir horizontal selon leur direction ;
- énergie segmentée avec état x2 doré, prochaine carte, sélection animée, flash de disponibilité, repères d’équipe cyan/rouge et véritable fantôme du héros pendant le glisser-déposer ;
- annonces d’arène pour l’énergie x2, la mort subite et les objectifs détruits, score de couronnes séparé de la santé des forteresses et nouveaux effets de mêlée/défaite ;
- trois difficultés d’IA, tutoriel, pause, résultat, progression et sauvegarde hors ligne ;
- interface vérifiée en 540×960, 591×1280, 720×1280 et 800×1280 ;
- 344 assertions automatisées, 1 000 combats IA reproductibles et profil local à 20 héros animés.

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

Configuration : `versionCode 57`, `versionName 0.57.0-alpha`, API 24 minimum, API cible 36, `arm64-v8a`, portrait, mode immersif et Vulkan Mobile. Android 10 ou plus récent est recommandé.

## Documentation

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Rapport d’équilibrage](docs/BALANCE_REPORT.md)
- [Distribution Android](docs/ANDROID_DISTRIBUTION.md)
- [Provenance des actifs](docs/ASSET_PROVENANCE.md)
