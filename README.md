# Battle

Jeu mobile original de stratégie en arène, en temps réel, jouable hors ligne contre une IA. Le vertical slice 0.31 remplace l’ancien rendu 2D fixe par une arène 3D responsive et des combattants articulés.

## Prototype 0.31

- arène 3D complète à deux voies, rivière, ponts et six objectifs ;
- caméra orthographique sans étirement, adaptée aux téléphones longs et tablettes portrait ;
- personnages 3D originaux composés de membres indépendants ;
- cycles visibles de marche, balancement des bras, attaques, impacts et morts ;
- projectiles simulés avec temps de trajet et dégâts uniquement à l’impact ;
- huit cartes, main tournante de quatre cartes, énergie et progression locale ;
- trois difficultés d’IA et tutoriel hors ligne ;
- interface fantasy responsive pour l’accueil, la collection, la bataille, la pause et le résultat ;
- rendu Vulkan Mobile, export Android Arm64 et mode immersif ;
- 197 assertions automatisées et campagne reproductible de 1 000 combats IA.

Tous les personnages, modèles procéduraux, illustrations et éléments d’interface sont originaux. Le projet n’embarque aucun actif de Clash Royale.

## Lancer et tester

```powershell
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

## Export Android

```powershell
godot --headless --path . --export-debug "Android Arm64 Debug" "builds/android/Battle-v0.31-alpha-arm64-debug.apk"
powershell -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -ApkPath "builds/android/Battle-v0.31-alpha-arm64-debug.apk" -Variant arm64
```

Configuration de l’APK : API 24 minimum imposée par le modèle Godot standard, API cible 36, `arm64-v8a`, orientation portrait et rendu Vulkan Mobile. Android 10 ou plus récent est recommandé.

## Documentation

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Rapport d’équilibrage](docs/BALANCE_REPORT.md)
- [Distribution Android](docs/ANDROID_DISTRIBUTION.md)
- [Provenance des actifs](docs/ASSET_PROVENANCE.md)
