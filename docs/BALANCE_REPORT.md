# Rapport de simulation IA

Dernière campagne : 2026-07-15 — prototype 0.9.0

Commande :

```powershell
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

## Résultats

| Mesure | Valeur |
|---|---:|
| Matchs terminés | 1 000 / 1 000 |
| Victoires côté joueur | 511 |
| Victoires côté adversaire | 485 |
| Égalités | 4 |
| Prolongations | 354 |
| Durée moyenne | 190,5 s |
| Commandes IA invalides | 0 |
| États finaux invalides | 0 |

L'ordre d'exécution des deux contrôleurs alterne à chaque match. Les difficultés tournent entre initiation, tactique et expert. Les graines de simulation et d'IA sont déterministes.

La première passe a détecté 104 fins de partie laissant une unité vaincue dans l'état terminal lorsqu'un sort achevait simultanément un objectif. La simulation nettoie désormais les unités vaincues avant de figer le résultat ; la seconde campagne ne reproduit plus le défaut.
