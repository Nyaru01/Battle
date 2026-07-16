# Battle

Jeu mobile original de stratégie en arène, en temps réel, jouable hors ligne contre une IA. Le vertical slice 0.32 propose une direction 2,5D premium, responsive et immédiatement lisible sur mobile.

## Prototype 0.32

- arène 2,5D illustrée à deux voies, rivière, ponts et six objectifs ;
- mise à l’échelle sans étirement, adaptée aux téléphones longs et tablettes portrait ;
- combattants, tours, cartes et icônes originaux au rendu fantasy cohérent ;
- déplacements interpolés, attaques, impacts, sorts, projectiles et morts animés ;
- projectiles simulés avec temps de trajet et dégâts uniquement à l’impact ;
- huit cartes, main tournante de quatre cartes, énergie et progression locale ;
- trois difficultés d’IA et tutoriel hors ligne ;
- interface fantasy premium pour l’accueil, la collection, la bataille, le ciblage, la pause et le résultat ;
- rendu Vulkan Mobile, export Android Arm64 et mode immersif ;
- 208 assertions automatisées et campagne reproductible de 1 000 combats IA.

Tous les personnages, illustrations et éléments d’interface sont originaux. Les polices Lilita One et Nunito sont distribuées sous SIL Open Font License. Le projet n’embarque aucun actif de Clash Royale.

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

L’APK courant est toujours disponible sous [Android/Battle-latest.apk](Android/Battle-latest.apk). Chaque nouvel export remplace ce fichier afin qu’il reste facile à trouver depuis la racine du dépôt.

Configuration de l’APK : API 24 minimum imposée par le modèle Godot standard, API cible 36, `arm64-v8a`, orientation portrait et rendu Vulkan Mobile. Android 10 ou plus récent est recommandé.

## Documentation

- [Plan de développement](docs/PLAN_DEVELOPPEMENT.md)
- [Rapport d’équilibrage](docs/BALANCE_REPORT.md)
- [Distribution Android](docs/ANDROID_DISTRIBUTION.md)
- [Provenance des actifs](docs/ASSET_PROVENANCE.md)
