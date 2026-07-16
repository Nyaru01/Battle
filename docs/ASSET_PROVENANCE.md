# Provenance des actifs visuels

Ce registre documente les actifs distribués dans la v0.40. Toutes les illustrations ont été créées avec la génération d’images OpenAI intégrée à Codex le 16 juillet 2026. Aucun actif, logo, personnage ou fichier propriétaire tiers n’a été utilisé.

## Rigs articulés

Fichiers : `assets/v040/rigs/*-rig-v040.png` pour Gardien, Éclaireuse, Colosse, Lames jumelles, Alchimiste et Rempart.

Résumé des prompts : six combattants fantasy originaux, volumes de jouets 3D peints, silhouette très lisible sur mobile et palette propre à chaque carte. Chaque atlas suit une grille stricte 4×4 : torse, tête, bras, jambes, arme et accessoire vus de face puis de dos, sur fond chromatique uniforme. Les images ont ensuite été détourées localement et assemblées en huit sprites articulés par `unit_view_2d.gd`.

## Arène et tours

Fichiers : `assets/v040/environment/arena-royale-v040.png` et `tower-parts-v040.png`.

Résumé des prompts : arène verticale fantasy royale originale, symétrique, deux voies, rivière turquoise, deux ponts, végétation abondante et six fondations vides ; atlas séparé de tours en pierre, or et cristal cyan, états normal, tir et destruction. Aucun personnage, texte ou logo dans le décor source.

## Sorts et interface

Fichiers : `assets/v040/ui/spell-art-v040.png`, `ui-icons-v040.png` et `app-icon-v040.png`.

Résumé des prompts : Comète et Stase sous forme d’illustrations énergétiques opposées ; huit pictogrammes fantasy sans texte sur grille 4×2 ; emblème d’application original bleu, cyan et or, lisible à petite taille. Les atlas nécessitant de la transparence ont été détourés localement par clé chromatique.

## Typographies

- `Baloo2-Variable.ttf` : titres et boutons ronds à fort impact ;
- `Nunito-Variable.ttf` : texte courant lisible sur mobile ;
- origine : dépôts officiels Google Fonts ;
- licence : SIL Open Font License 1.1, conservée dans `assets/fonts/OFL-Baloo2.txt` et `OFL-Nunito.txt`.

## Rendu et animation

Le rendu final est original et écrit en GDScript : composition d’arène, interpolation, rigs découpés, poses de marche et d’attaque par profil, déploiement, dégâts, mort, eau, tours, projectiles, sorts, ciblage et prévisualisation de pose. La v0.40 ne distribue plus les anciens atlases 0.32.

La capture de référence fournie pendant la conception n’est ni versionnée ni distribuée avec le jeu ; elle a servi uniquement à qualifier le niveau de lisibilité et de finition attendu.
