# Rapport de simulation IA

Dernière campagne : 2026-07-16 — prototype 0.19.0

Commande :

```powershell
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

## Résultats

| Mesure | Valeur |
|---|---:|
| Matchs terminés | 1 000 / 1 000 |
| Victoires côté joueur | 500 |
| Victoires côté adversaire | 472 |
| Égalités | 28 |
| Prolongations | 834 |
| Durée moyenne | 213,2 s |
| Commandes IA invalides | 0 |
| États finaux invalides | 0 |

L'ordre d'exécution des deux contrôleurs alterne à chaque match. Les difficultés tournent entre initiation, tactique et expert. Les graines de simulation et d'IA sont déterministes.

La phase d'énergie doublée pendant la dernière minute produit davantage d'égalités de couronnes entre contrôleurs symétriques. La mort subite est limitée à 45 secondes, avec énergie triplée et départage aux points de vie à son terme. Cette limite ramène la durée moyenne de 223,3 à 213,2 secondes par rapport à la première passe 0.19, sans match inachevé ni état invalide.

La première passe a détecté 104 fins de partie laissant une unité vaincue dans l'état terminal lorsqu'un sort achevait simultanément un objectif. La simulation nettoie désormais les unités vaincues avant de figer le résultat ; la seconde campagne ne reproduit plus le défaut.
