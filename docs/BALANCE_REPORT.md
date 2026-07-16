# Rapport de simulation IA

Dernière campagne : 2026-07-16 — prototype 0.20.0

Commande :

```powershell
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

## Résultats

| Mesure | Valeur |
|---|---:|
| Matchs terminés | 1 000 / 1 000 |
| Victoires côté joueur | 476 |
| Victoires côté adversaire | 479 |
| Égalités | 45 |
| Prolongations | 809 |
| Durée moyenne | 211,8 s |
| Commandes IA invalides | 0 |
| États finaux invalides | 0 |

L'ordre d'exécution des deux contrôleurs alterne à chaque match. Les difficultés tournent entre initiation, tactique et expert. Les graines de simulation et d'IA sont déterministes.

La phase d'énergie doublée pendant la dernière minute produit davantage d'égalités de couronnes entre contrôleurs symétriques. La mort subite est limitée à 45 secondes, avec énergie triplée et départage aux points de vie à son terme. Cette limite ramène la durée moyenne de 223,3 à 213,2 secondes par rapport à la première passe 0.19, sans match inachevé ni état invalide.

La campagne 0.20 intègre la carte d'escouade Lames jumelles. L'écart entre les deux côtés n'est que de trois victoires et la durée moyenne descend à 211,8 secondes ; son coût de 3 est donc conservé pour les essais sur appareil.

La première passe a détecté 104 fins de partie laissant une unité vaincue dans l'état terminal lorsqu'un sort achevait simultanément un objectif. La simulation nettoie désormais les unités vaincues avant de figer le résultat ; la seconde campagne ne reproduit plus le défaut.
