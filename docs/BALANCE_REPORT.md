# Rapport de simulation IA

Dernière campagne : 2026-07-17 — placement spatial et trajectoires libres du vertical slice 0.53.0-alpha

```powershell
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

| Mesure | Valeur |
|---|---:|
| Matchs terminés | 1 000 / 1 000 |
| Victoires côté joueur | 489 |
| Victoires côté adversaire | 460 |
| Égalités | 51 |
| Prolongations | 825 |
| Durée moyenne | 213,4 s |
| Commandes IA invalides | 0 |
| États finaux invalides | 0 |

La v0.53 ajoute des coordonnées x/y réelles, une convergence horizontale vers les cibles et un calcul spatial des portées. Les 1 000 combats se terminent sans blocage, état invalide ou commande refusée. L’écart entre les deux côtés reste contenu malgré l’alternance de l’ordre d’exécution, et les difficultés tournent entre initiation, tactique et expert.
