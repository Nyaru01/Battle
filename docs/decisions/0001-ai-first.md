# ADR 0001 — Livrer le mode contre IA avant le multijoueur

Date : 2026-07-15

Statut : accepté

## Contexte

Le projet doit obtenir rapidement un APK jouable et permettre de valider les règles de combat sans dépendre d'un backend, d'une population active ou de conditions réseau. Le plan initial plaçait le duel humain et le serveur autoritaire dans le premier MVP.

## Décision

Le MVP 1 sera un jeu hors ligne contre IA. Le multijoueur devient le MVP 2 et ne commence qu'après validation du combat solo sur appareils Android réels.

La logique de combat sera une bibliothèque C# pure, sans dépendance aux scènes ou à la physique Unity. Les contrôleurs humain et IA produiront les mêmes commandes. Le futur service de match .NET réutilisera cette bibliothèque et deviendra autoritaire en ligne.

L'IA du MVP 1 suivra quatre règles :

- aucune information cachée ou ressource supplémentaire ;
- délai de décision explicite selon la difficulté ;
- comportement piloté par les données et reproductible avec une graine ;
- validation par tests unitaires et 1 000 parties bot contre bot.

## Conséquences

### Positives

- premier APK testable plus tôt et entièrement hors ligne ;
- boucle de combat et équilibrage validés avant les coûts réseau ;
- tests automatisés rapides grâce au mode bot contre bot ;
- architecture réutilisable pour le multijoueur.

### Contraintes

- le classement, les comptes et le matchmaking sont reportés ;
- la simulation ne doit pas dépendre de composants Unity ;
- l'interface des commandes doit rester stable et sérialisable ;
- la migration serveur devra vérifier la parité des résultats avec les mêmes graines et commandes.

## Critère de révision

Cette décision sera revue après l'alpha fermée du MVP 1. Le MVP 2 sera autorisé uniquement si l'APK solo est stable, lisible et jugé amusant par les testeurs ciblés.
