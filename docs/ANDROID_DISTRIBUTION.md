# Distribution Android

Le prototype produit deux APK signés avec la clé de développement locale :

- `Battle-0.11.0-universal-debug.apk` : armv7 et arm64, compatibilité maximale ;
- `Battle-0.11.0-arm64-debug.apk` : arm64 uniquement, taille réduite pour les appareils modernes.

Les deux paquets utilisent l'identifiant `com.nyaru01.battle`, `versionCode 11`, `versionName 0.11.0` et un SDK minimal Android 7.0 (API 24).

L'export inclut toutes les ressources reconnues par Godot afin d'embarquer les scripts globaux chargés via `class_name` ainsi que leurs textures. Les captures, outils de balance et tests headless sont explicitement exclus de l'application.

Après chaque export, `tools/verify_apk.ps1` contrôle que la scène principale, les six scripts d'exécution et les bibliothèques natives attendues sont réellement présents dans l'archive APK. Ce contrôle évite qu'un export sélectif produise une application installable mais incapable d'initialiser sa première scène.

Ces APK sont des builds de développement. Une future publication en boutique devra utiliser une clé de production protégée et un Android App Bundle arm64.
