# Distribution Android

Le prototype produit deux APK signés avec la clé de développement locale :

- `Battle-0.11.0-universal-debug.apk` : armv7 et arm64, compatibilité maximale ;
- `Battle-0.11.0-arm64-debug.apk` : arm64 uniquement, taille réduite pour les appareils modernes.

Les deux paquets utilisent l'identifiant `com.nyaru01.battle`, `versionCode 11`, `versionName 0.11.0` et un SDK minimal Android 7.0 (API 24).

L'export suit uniquement les ressources requises par la scène principale. Les captures, outils de balance et tests headless restent dans le dépôt mais ne sont pas distribués dans l'application.

Ces APK sont des builds de développement. Une future publication en boutique devra utiliser une clé de production protégée et un Android App Bundle arm64.
