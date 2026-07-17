# Provenance des actifs visuels — v0.50

Ce registre documente tous les actifs visuels distribués. Les archives sources 3D ne sont pas versionnées : seuls les sprites 2D pré-rendus et les composants d’interface nécessaires au jeu sont inclus.

## Personnages KayKit — CC0

Sources officielles :

- KayKit Adventurers Free 2.0 — https://kaylousberg.itch.io/kaykit-adventurers — archive `KayKit_Adventurers_2.0_FREE.zip` — SHA-256 `ABE48F4763FBA0896BAB486EE9E6D08CA6B5B3884B9601F235C8847AE94DC479` ;
- KayKit Character Animations 1.1 — https://kaylousberg.itch.io/kaykit-character-animations — archive `KayKit_Character_Animations_1.1.zip` — SHA-256 `65882F31F905AD2E953819648A59287CDEAB8F623908D5EF701971D3758BE20F` ;
- licence déclarée dans les deux archives : Creative Commons Zero 1.0 (CC0).

Correspondance des cartes :

| Carte | Modèle | Équipement | Attaque |
|---|---|---|---|
| Gardien | Knight | épée et bouclier rond | attaque horizontale 1 main |
| Éclaireuse | Ranger | arc et carquois | lâcher de flèche |
| Colosse | Barbarian | hache lourde à 2 mains | frappe verticale 2 mains |
| Lames jumelles | Rogue Hooded | deux dagues | attaque ambidextre |
| Alchimiste | Mage | baguette et fiole/mug | tir magique |
| Rempart | Knight sans cape | masse-hache et grand bouclier carré | contre de bouclier |

Fichiers distribués : `assets/v050/characters/*-kaykit-v050.png`.

`tools/generate_v050_sprites.gd` charge les GLTF officiels, applique les animations sur leur squelette commun, attache l’équipement aux os KayKit et effectue un rendu 3D éclairé dans Godot. Chaque atlas 1920×1920 contient une grille 10×10 de cellules 192×192 : 50 images de face puis 50 de dos. Les séquences sont apparition 8, repos 8, marche 10, attaque 10, impact 4 et défaite 10.

## Interface Kenney — CC0

Sources officielles :

- UI Pack RPG Expansion 1.0 — https://kenney.nl/assets/ui-pack-rpg-expansion — SHA-256 `C69C30C09D74DF542842E4EC811735B6D260CD6C9E2EE261D7B894D259A6ADB4` ;
- Fantasy UI Borders 1.0 — https://kenney.nl/assets/fantasy-ui-borders — SHA-256 `59532DA3BD61195A425585455B40BAA6CBF1EDA8227C42ADCEF31A535A737769` ;
- Board Game Icons 1.1 — https://kenney.nl/assets/board-game-icons — SHA-256 `05F4358381D8B16B303B2F056393B76CE3F6A58228599E88CAA2EAB11D4C2946` ;
- licence déclarée sur chaque page et dans les archives : Creative Commons Zero 1.0 (CC0).

Les boutons de navigation, la bordure ornementale et les pictogrammes utiles ont été copiés dans `assets/v050/ui/`. Leur couleur, composition et comportement responsive sont appliqués en GDScript ; les archives complètes ne sont pas distribuées.

## Actifs originaux conservés

- `assets/v040/environment/arena-royale-v040.png` et `tower-parts-v040.png` : arène et tours originales générées le 16 juillet 2026 avec la génération d’images OpenAI intégrée à Codex ;
- `assets/v040/ui/spell-art-v040.png`, `ui-icons-v040.png` et l’emblème copié vers `assets/v050/ui/app-icon-v050.png` : sorts, pictogrammes et emblème originaux générés dans la même session ;
- les captures de référence et archives sources ne sont ni versionnées ni distribuées.

## Typographies

- `Baloo2-Variable.ttf` : titres et boutons ;
- `Nunito-Variable.ttf` : texte courant ;
- origine : dépôts officiels Google Fonts ;
- licence : SIL Open Font License 1.1, conservée dans `assets/fonts/OFL-Baloo2.txt` et `OFL-Nunito.txt`.

## Propriété intellectuelle

Le jeu s’inspire des conventions générales du genre stratégie en arène. Aucun personnage, nom, logo, son, texte, statistique ou fichier propriétaire de Clash Royale n’est inclus. KayKit, Kenney et les actifs originaux ci-dessus constituent l’intégralité des sources visuelles distribuées.
