# Distribution Android 0.53

Le vertical slice produit un APK de développement Arm64 :

- `Android/Battle-latest.apk`, chemin stable remplacé à chaque export ;
- identifiant `com.nyaru01.battle` ;
- `versionCode 53`, `versionName 0.53.0-alpha` ;
- API 24 minimum, API cible 36 ; Android 10 ou plus récent recommandé ;
- architecture `arm64-v8a` uniquement ;
- portrait, mode immersif et rendu Vulkan Mobile ;
- budget maximal automatisé : 95 Mo.

L’affichage utilise des conteneurs responsives et `stretch/aspect="expand"`. L’arène emploie un cadrage `cover` : elle conserve strictement son ratio 2:3, remplit la surface disponible et rogne seulement les bords nécessaires, sans étirement. Les parcours Accueil, Réglages, Collection, Combat, Placement libre, Énergie x2, Tour détruite, Ciblage, Pause et Résultat sont capturés automatiquement en 540×960, 591×1280, 720×1280 et 800×1280.

Après export, `tools/verify_apk.ps1` contrôle la scène principale, les quinze scripts d’exécution, les textures d’arène, les six atlas KayKit, les composants Kenney, les deux polices, l’architecture Arm64 et le budget de taille.

L’APK est signé avec la clé de développement locale. Une publication en boutique nécessitera une clé de production protégée et un Android App Bundle signé.
