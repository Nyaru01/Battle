# Provenance des actifs visuels

Ce document suit l'origine des actifs visuels intégrés au projet afin d'éviter l'introduction accidentelle de contenus propriétaires tiers.

## `assets/icon.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex
- Usage : icône Android et écran d'accueil
- Direction : deux forteresses originales cyan et rouge séparées par une énergie lumineuse
- Référence propriétaire utilisée : aucune

## `assets/arena-v2.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex
- Usage : fond de l'arène du prototype 0.2
- Direction : arène verticale 2,5D originale, deux voies, rivière turquoise, deux ponts, chemins et six plateformes vides
- Référence : une capture de jeu fournie par le propriétaire du dépôt, utilisée uniquement pour comprendre la composition générale et la lisibilité attendue
- Contraintes de génération : aucun personnage, tour, texte, logo, interface ou actif reconnaissable du jeu de référence

## `assets/card-art-v2.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex
- Usage : portraits des quatre cartes du prototype 0.2
- Contenu : Gardien, Éclaireuse, Colosse et Comète, tous originaux
- Référence propriétaire utilisée : aucune

## `assets/tower-sprites-v3.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex, puis détourage local par clé chromatique
- Usage : tour de voie et forteresse centrale du prototype 0.3
- Direction : deux bâtiments fantasy 2,5D originaux en pierre bleu-gris et laiton, avec lanceur de cristal et noyau cyan
- Référence propriétaire utilisée : aucune

## `assets/unit-sprites-v3.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex, puis détourage local par clé chromatique
- Usage : combattants Gardien, Éclaireuse et Colosse du prototype 0.3
- Direction : trois personnages fantasy 2,5D originaux et lisibles en vue mobile
- Référence propriétaire utilisée : aucune

## `assets/card-art-v4.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex
- Usage : portraits des cartes Duelliste, Alchimiste, Rempart et Stase du prototype 0.4
- Direction : quatre illustrations fantasy 3D originales, réparties sur une grille 2 × 2
- Référence propriétaire utilisée : aucune

## `assets/unit-sprites-v4.png`

- Date : 2026-07-15
- Origine : génération OpenAI intégrée à Codex, puis détourage local par clé chromatique
- Usage : combattants Duelliste, Alchimiste et Rempart du prototype 0.4
- Direction : trois personnages fantasy 2,5D originaux, cadrés pour l'arène mobile
- Référence propriétaire utilisée : aucune

La capture de référence n'est pas versionnée dans Git et n'est pas distribuée avec le jeu.

## Icônes d'interface 0.32

- Date : 2026-07-16
- Origine : génération OpenAI intégrée à Codex, puis détourage local par clé chromatique
- Usage : couronne, éclats, combat, collection et énergie dans l'interface 0.32
- Direction : cinq pictogrammes fantasy originaux, peints en 3D, palette or, cyan et bleu nuit, sans texte ni logo
- Fichiers : `assets/ui/icon-crown.png`, `icon-shard.png`, `icon-battle.png`, `icon-collection.png` et `icon-energy.png`
- Référence propriétaire utilisée : aucune

## Typographies 0.32

- Date : 2026-07-16
- Origine : Google Fonts, téléchargées depuis les dépôts officiels `google/fonts`
- Fichiers : `LilitaOne-Regular.ttf` et `Nunito-Variable.ttf`
- Licence : SIL Open Font License 1.1, copies conservées dans `assets/fonts/OFL-LilitaOne.txt` et `assets/fonts/OFL-Nunito.txt`
- Usage : titres à fort impact et texte courant lisible sur mobile

## Rendu 2,5D 0.32

- Date : 2026-07-16
- Origine : renderer original écrit en GDScript dans `battle_world_2d.gd`
- Usage : composition de l'arène, tours, unités, projectiles, effets, barres de vie et ciblage
- Contenu : réemploi des illustrations originales listées ci-dessus, avec ombres, interpolation, impacts et surimpressions générés par le moteur
- Référence propriétaire utilisée : aucune ressource, texture, modèle ou animation tiers
