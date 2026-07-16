# Distribution Android 0.31

Le vertical slice produit un APK de développement Arm64 :

- `builds/android/Battle-v0.31-alpha-arm64-debug.apk` ;
- identifiant `com.nyaru01.battle` ;
- `versionCode 31`, `versionName 0.31.0-alpha` ;
- API 24 minimum, API cible 36 ; Android 10 ou plus récent recommandé ;
- architecture `arm64-v8a` uniquement ;
- orientation portrait, mode immersif et rendu Vulkan Mobile.

L’affichage utilise des conteneurs responsives et `stretch/aspect="expand"`. La zone 3D conserve toujours ses proportions : les écrans plus longs ou plus larges révèlent davantage de fond autour de l’arène, sans étirement non uniforme.

Après export, `tools/verify_apk.ps1` vérifie la scène principale, les huit scripts d’exécution, les textures compilées et la présence exclusive de la bibliothèque Arm64.

L’APK est signé avec la clé de développement locale. Une publication en boutique nécessitera une clé de production protégée et un Android App Bundle signé.
