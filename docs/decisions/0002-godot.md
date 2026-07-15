# ADR 0002 — Utiliser Godot pour le prototype Android

Date : 2026-07-15

Statut : accepté

## Contexte

La machine de développement ne disposait d'aucun moteur. Unity aurait ajouté une installation lourde et une étape d'activation avant le premier prototype. Le MVP 1 est un jeu 2D hors ligne contre IA et doit produire rapidement un APK testable.

## Décision

Le prototype utilise Godot 4.7.1 avec GDScript et le renderer Compatibility. La simulation reste indépendante des scènes et n'utilise pas la physique du moteur. Un futur serveur autoritaire pourra exécuter les mêmes scripts avec Godot en mode headless.

## Conséquences

- moteur open source, léger et automatisable sans activation ;
- export Android reproductible en ligne de commande ;
- tests de simulation rapides en mode headless ;
- interface tactile et desktop testables dans le même projet ;
- le plan et l'ADR 0001 doivent être lus avec cette décision pour tout choix de langage ou de serveur.
