# Rapport de simulation IA

Dernière campagne : 2026-07-17 — règles inchangées dans le vertical slice 0.51.0-alpha

```powershell
godot --headless --path . --script res://tools/run_balance.gd -- --matches=1000
```

| Mesure | Valeur |
|---|---:|
| Matchs terminés | 1 000 / 1 000 |
| Victoires côté joueur | 503 |
| Victoires côté adversaire | 448 |
| Égalités | 49 |
| Prolongations | 825 |
| Durée moyenne | 213,3 s |
| Commandes IA invalides | 0 |
| États finaux invalides | 0 |

La v0.51 ne modifie aucune règle, statistique, progression ni décision d’IA. Les 1 000 combats se terminent sans blocage, état invalide ou commande refusée. L’ordre d’exécution des contrôleurs alterne à chaque match et les difficultés tournent entre initiation, tactique et expert.
