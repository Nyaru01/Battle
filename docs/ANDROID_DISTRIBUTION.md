# Distribution Android 0.40

Le vertical slice produit un APK de développement Arm64 :

- `Android/Battle-latest.apk`, chemin stable remplacé à chaque export ;
- identifiant `com.nyaru01.battle` ;
- `versionCode 40`, `versionName 0.40.0-alpha` ;
- API 24 minimum, API cible 36 ; Android 10 ou plus récent recommandé ;
- architecture `arm64-v8a` uniquement ;
- portrait, mode immersif et rendu Vulkan Mobile ;
- budget maximal automatisé : 95 Mo.

L’affichage utilise des conteneurs responsives et `stretch/aspect="expand"`. L’arène conserve son ratio 2:3 et se centre sans étirement non uniforme sur téléphones longs et tablettes portrait.

Après export, `tools/verify_apk.ps1` contrôle la scène principale, les douze scripts d’exécution, les onze textures v0.40, les deux polices, l’architecture Arm64 et le budget de taille.

L’APK est signé avec la clé de développement locale. Une publication en boutique nécessitera une clé de production protégée et un Android App Bundle signé.
