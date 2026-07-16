# Rapport de simulation IA

Dernière campagne : 2026-07-16 — vertical slice 0.32.0-alpha

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

Cette campagne introduit des projectiles autoritaires : les tirs de l’Éclaireuse, de l’Alchimiste et des forteresses appliquent désormais leurs dégâts à l’impact. Un tir dont la cible meurt pendant le trajet se dissipe sans dégâts et sans nouvelle cible.

La durée moyenne reste pratiquement identique à la référence 0.28 (213,4 s). Les 1 000 combats se terminent sans blocage, état invalide ou commande refusée. L’ordre d’exécution des contrôleurs alterne à chaque match et les difficultés tournent entre initiation, tactique et expert.
