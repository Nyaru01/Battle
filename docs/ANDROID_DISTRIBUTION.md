# Distribution Android 0.32

Le vertical slice produit un APK de développement Arm64 :

- `Android/Battle-latest.apk`, fichier stable remplacé à chaque nouvel export ;
- identifiant `com.nyaru01.battle` ;
- `versionCode 32`, `versionName 0.32.0-alpha` ;
- API 24 minimum, API cible 36 ; Android 10 ou plus récent recommandé ;
- architecture `arm64-v8a` uniquement ;
- orientation portrait, mode immersif et rendu Vulkan Mobile.

L’affichage utilise des conteneurs responsives et `stretch/aspect="expand"`. Le renderer 2,5D conserve le ratio de l’arène et centre la surface de jeu : les écrans plus longs ou plus larges révèlent des marges décoratives, sans étirement non uniforme.

Après export, `tools/verify_apk.ps1` vérifie la scène principale, les huit scripts d’exécution, les textures et icônes compilées ainsi que la présence exclusive de la bibliothèque Arm64.

L’APK est signé avec la clé de développement locale. Une publication en boutique nécessitera une clé de production protégée et un Android App Bundle signé.
