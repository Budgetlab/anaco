---
title: Page Remplissage des avis
description: Documentation fonctionnelle et technique de l'écran de remplissage des avis (tableau de suivi par BOP et par phase)
audience: Développeurs entrants, product owners (CBR), administrateurs
project: avisbop
language: fr
---

# Page Remplissage des avis

L'écran **Remplissage des avis** est le tableau de bord principal du CBR. Il liste tous les BOP dont il a la charge et, pour chacun, l'état d'avancement de la saisie des avis sur chaque **phase** du calendrier budgétaire. C'est l'écran d'entrée pour démarrer ou reprendre la rédaction d'un avis.

- **URL** : `/anaco/remplissage_avis`
- **Action contrôleur** : `AvisController#remplissage_avis` ([app/controllers/avis_controller.rb](../app/controllers/avis_controller.rb))
- **Vue principale** : [app/views/avis/remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb)
- **Audience** : CBR connecté (les rôles DCB et admin n'ont pas vocation à passer par cet écran pour saisir).

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Structure de l'écran](#2-structure-de-lécran)
3. [Logique des badges de statut](#3-logique-des-badges-de-statut)
4. [Boutons d'action](#4-boutons-daction)
5. [Compteur "il reste X avis à rédiger"](#5-compteur-il-reste-x-avis-à-rédiger)
6. [Calendrier des phases](#6-calendrier-des-phases)
7. [Sélecteur d'année](#7-sélecteur-dannée)
8. [Onglet BOP inactifs](#8-onglet-bop-inactifs)
9. [Référence technique](#9-référence-technique)

---

## 1. Vue d'ensemble

Le CBR voit, pour chaque BOP actif de l'année affichée, une ligne du tableau avec 4 cases représentant les 4 phases de saisie : **Services votés**, **Avis à la programmation** (phase `début de gestion` côté code), **CRG1**, **CRG2**. Chaque case porte un badge qui indique en un coup d'œil l'état d'avancement (rien à faire, brouillon en cours, avis transmis, etc.).

Deux boutons à droite de chaque ligne permettent d'agir :

- **Rédiger** — ouvre le formulaire de la prochaine phase à saisir pour ce BOP. Désactivé si toutes les phases ouvertes sont déjà transmises.
- **Consulter les avis** — ouvre la page de consultation du BOP ([show](../app/views/bops/show.html.erb)).

Un **bandeau d'alerte** en haut totalise le nombre d'avis encore à rédiger ou en brouillon, toutes phases et tous BOP confondus. Un **sélecteur d'année** permet de basculer entre l'année en cours et l'année précédente.

## 2. Structure de l'écran

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Remplissage des avis/notes                                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│ [2025] [2026]   ← sélecteur d'année                                          │
├──────────────────────────────────────────────────────────────────────────────┤
│ ⚠ Il reste 98 avis/notes à rédiger     ← compteur global                     │
├──────────────────────────────────────────────────────────────────────────────┤
│ Onglets : [ BOP actifs (51) ] [ BOP inactifs (0) ]                           │
├──────────────────────────────────────────────────────────────────────────────┤
│ ┌─────────┬─────────────┬─────────────┬───────────┬───────────┬─────┬─────┐  │
│ │ BOP     │ Services    │ Avis à la   │ CRG1      │ CRG2      │     │     │  │
│ │         │ votés       │ programm.   │           │           │     │     │  │
│ ├─────────┼─────────────┼─────────────┼───────────┼───────────┼─────┼─────┤  │
│ │ BOP X   │ ⚠ À rédiger │ ✓ Transmis  │ ⚠ À réd.  │ 🔒 Non    │ Réd │ Cons│  │
│ │         │             │             │           │   ouvert  │     │     │  │
│ └─────────┴─────────────┴─────────────┴───────────┴───────────┴─────┴─────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

Le tableau utilise le composant DSFR `fr-table fr-table--bordered`. Chaque ligne est rendue par le partial [_bop_actif_row.html.erb](../app/views/avis/_bop_actif_row.html.erb), qui appelle les helpers documentés en section 9.

## 3. Logique des badges de statut

Pour chaque couple (BOP, phase), le badge affiché est déterminé par le helper `phase_status_badge` ([app/helpers/avis_helper.rb](../app/helpers/avis_helper.rb)).

Règles, appliquées dans cet ordre :

| Condition | Badge | Classe DSFR | Sens métier |
|---|---|---|---|
| Phase **CRG1** + avis début existe avec `is_crg1 == false` | **N/A** | `fr-badge` | Le CBR a déclaré qu'il n'y aurait pas de CRG1 pour ce BOP. Pas de saisie attendue. |
| Phase **non ouverte** dans le calendrier (date pivot pas encore passée) | **Non ouvert** | `fr-badge` + icône cadenas | La phase ne peut pas encore être saisie. |
| Phase ouverte, **aucun avis** pour cette phase | **À rédiger** | `fr-badge--warning` + icône edit | Aucune saisie démarrée. |
| Avis en `etat = 'Brouillon'` | **Brouillon** | `fr-badge--new` | Une saisie est en cours mais pas finalisée. |
| Avis avec `statut = 'Non reçu'` | **Non reçu** | `fr-badge--brown-caramel` | Le CBR a finalisé en déclarant qu'il ne peut pas rendre d'analyse (dossier non transmis, tardif ou incomplet). |
| Sinon (`etat` ∈ `['Lu', 'En attente de lecture']` et statut métier classique) | **Transmis** | `fr-badge--info` + icône check | L'avis est finalisé et transmis. |

Pour la phase **Services votés**, la cellule représente le **dernier** avis SV de l'année (le plus récent par `created_at`), pas l'ensemble. Cette phase admet plusieurs versions dans l'année — la dernière fait foi pour l'affichage.

## 4. Boutons d'action

### 4.1 Bouton Rédiger

- **Cible** : `new_bop_avi_path(bop_id:, date:, phase:)` — la phase ciblée est calculée par le helper `next_phase_to_fill`.
- **Logique de priorité** (helper [next_phase_to_fill](../app/helpers/avis_helper.rb)) : on prend la **première** phase qui correspond à toutes ces conditions :
  1. **Services votés** (toujours ouverte) si aucun avis SV transmis ou si le dernier SV est en brouillon
  2. sinon **Début de gestion** si la phase est ouverte ET (pas d'avis OU brouillon)
  3. sinon **CRG1** si la phase est ouverte ET début existe avec `is_crg1 == true` ET (pas d'avis OU brouillon)
  4. sinon **CRG2** si la phase est ouverte ET (pas d'avis OU brouillon)
- **État désactivé** : si aucune phase ne correspond, le bouton est rendu en `<button … disabled>` (gris).
- **Param `phase`** : transmis en query string. Le contrôleur ([avis_controller.rb](../app/controllers/avis_controller.rb#L51)) le récupère avec `params[:phase].presence || set_form_phase(@annee_a_afficher)` — la phase explicite a la priorité sur la déduction automatique.

Le contrôleur `new` redirige automatiquement vers `edit_bop_avi_path` si un brouillon existe déjà pour la phase ciblée (l'utilisateur reprend là où il s'était arrêté).

### 4.2 Bouton Consulter les avis

- **Cible** : `bop_path(bop)` — page de consultation du BOP, qui liste tous les avis déjà saisis (transmis, en attente, lu) et leurs détails.
- Toujours actif, indépendamment de l'état de saisie.

## 5. Compteur "il reste X avis à rédiger"

Le bandeau d'alerte en haut affiche le nombre total d'avis dans un état "à produire" sur l'année affichée.

- **Méthode** : `User#avis_a_remplir(annee, date_debut, date_crg1, date_crg2)` ([app/models/user.rb](../app/models/user.rb))
- **Définition** : somme, pour chaque BOP actif de l'année, du nombre de **cases du tableau** qui afficheraient un badge "À rédiger" ou "Brouillon". Strictement aligné sur les badges visibles.
- **Exclusions explicites** :
  - **Transmis** — l'avis est finalisé normalement.
  - **Non reçu** — l'avis est finalisé avec déclaration d'absence d'analyse. Bien que distinct de "transmis", c'est une finalisation, donc pas une action à rédiger.
  - **N/A** — CRG1 explicitement non programmé (`début.is_crg1 == false`).
  - **Non ouvert** — la phase n'a pas encore commencé.
- **CRG1 sans avis début** : compté comme "à rédiger" (l'avis début, une fois saisi, déterminera si CRG1 est N/A ou non — pour l'instant on traite comme à faire).
- **Performance** : 1 seule requête `self.avis.where(annee:, bop_id: ids).group_by(&:bop_id)` pour récupérer tous les avis de l'année, puis comptage en mémoire. Pas de N+1.

## 6. Calendrier des phases

Les dates pivots qui déterminent si une phase est ouverte sont fixées dans [ApplicationController#set_global_variable](../app/controllers/application_controller.rb) :

| Date | Variable | Pivot |
|---|---|---|
| 20 février | `@date_debut` | Ouverture de "Avis à la programmation" (`début de gestion`) |
| 1<sup>er</sup> juin | `@date_crg1` | Ouverture de CRG1 |
| 1<sup>er</sup> septembre | `@date_crg2` | Ouverture de CRG2 |

Règles d'ouverture (helper `phase_ouverte?`) :

- **Services votés** : toujours ouverte (pas de date pivot, le BOP est en cours de vote).
- **Début de gestion** : ouverte si `Date.today >= @date_debut`.
- **CRG1** : ouverte si `Date.today >= @date_crg1`.
- **CRG2** : ouverte si `Date.today >= @date_crg2`.

**Cas particulier : année passée.** Si l'utilisateur sélectionne une année antérieure à l'année courante, **toutes les phases sont considérées ouvertes** — l'objectif est de rattraper d'éventuels brouillons ou cellules à rédiger sur une année qui aurait été interrompue.

## 7. Sélecteur d'année

Au-dessus du compteur, un ensemble de tags `fr-tag` permet de basculer entre l'année en cours et l'année précédente (`Date.today.year - 1` et `Date.today.year`).

- Paramètre URL : `?date=<année>`
- Helper qui lit le paramètre : [`annee_a_afficher`](../app/helpers/application_helper.rb#L164) — accepte uniquement les années dans `2023..Date.today.year`, sinon retombe sur l'année courante.
- Variable de vue : `@annee_a_afficher`.

L'ensemble du tableau (badges, compteur, redirections "Rédiger") prend en compte cette année. La logique d'année passée (toutes phases ouvertes) s'applique automatiquement.

## 8. Onglet BOP inactifs

Un second onglet liste les BOP marqués `inactif` pour l'année. Aucun avis n'est attendu sur ces BOP. Si l'année affichée est l'année en cours, un bouton **Modifier la dotation** redirige vers `edit_bop_path(bop)` pour réactiver le BOP (changer son statut ou redéfinir sa dotation).

Le partial qui rend cette section est inline dans [remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb) (pas de partial dédié, structure courte).

## 9. Référence technique

### 9.1 Action contrôleur

```ruby
# app/controllers/avis_controller.rb
def remplissage_avis
  @annee_a_afficher = annee_a_afficher
  @bops_inactifs    = current_user.bops_inactifs(@annee_a_afficher).order(code: :asc)
  @bops_actifs      = current_user.bops_actifs(@annee_a_afficher).order(code: :asc)
  @avis             = current_user.avis.where(annee: @annee_a_afficher).to_a
  @avis_par_bop     = @avis.group_by(&:bop_id)
end
```

`@avis_par_bop` est précalculé pour éviter une requête par ligne du tableau (N+1).

### 9.2 Helpers

Trois helpers de [app/helpers/avis_helper.rb](../app/helpers/avis_helper.rb) portent toute la logique métier de la page :

| Helper | Signature | Rôle |
|---|---|---|
| `phase_ouverte?` | `(phase, annee_affichee, annee, date_debut, date_crg1, date_crg2)` | Booléen : la phase est-elle ouverte à la saisie pour l'année affichée ? |
| `phase_status_badge` | `(avis, phase, ouverte, avis_debut: nil)` | Retourne le HTML du badge (`<p class="fr-badge…">…</p>`) selon les règles de la section 3. |
| `next_phase_to_fill` | `(avis_bop, annee_affichee, annee, date_debut, date_crg1, date_crg2)` | Retourne la chaîne de la prochaine phase à rédiger (SV → début → CRG1 → CRG2), ou `nil` si tout est transmis. |

### 9.3 Fichiers impliqués

| Fichier | Rôle |
|---|---|
| [app/views/avis/remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb) | Vue principale : sélecteur d'année, compteur, onglets, en-tête de tableau. |
| [app/views/avis/_bop_actif_row.html.erb](../app/views/avis/_bop_actif_row.html.erb) | Une ligne `<tr>` du tableau pour un BOP actif. Appelle `phase_status_badge` 4 fois. |
| [app/helpers/avis_helper.rb](../app/helpers/avis_helper.rb) | `phase_ouverte?`, `phase_status_badge`, `next_phase_to_fill`. |
| [app/models/user.rb](../app/models/user.rb) | `avis_a_remplir(annee, date_debut, date_crg1, date_crg2)` — compteur global. `bops_actifs(annee)`, `bops_inactifs(annee)` — scopes BOP. |
| [app/controllers/application_controller.rb](../app/controllers/application_controller.rb) | `set_global_variable` — définit `@annee`, `@date_debut`, `@date_crg1`, `@date_crg2`, `@phase`. |
| [app/controllers/avis_controller.rb](../app/controllers/avis_controller.rb) | `remplissage_avis` (action), `new` (cible du bouton Rédiger). |

### 9.4 Modèle de données mobilisé

- `bops` — table source, filtrée par `bops_actifs(annee)` : `created_at <= 31/12/annee` ET `statut = 'actif'`.
- `avis` — agrégés par BOP, lus pour calculer les badges. Colonnes lues : `phase`, `etat`, `statut`, `is_crg1`, `created_at`.
- Pas d'écriture en base depuis cet écran.

### 9.5 Points d'attention pour les évolutions

- **Ajout d'une nouvelle phase** : il faut mettre à jour 4 endroits : la constante `Avi::STATUTS_PAR_PHASE`, les helpers `phase_ouverte?` et `next_phase_to_fill`, et l'en-tête du tableau dans `remplissage_avis.html.erb`. Un test couvrant ces 4 points est recommandé.
- **Modification d'une date pivot** : à faire dans `ApplicationController#set_global_variable`. Les helpers les recevront automatiquement.
- **Nouveau badge** : étendre `phase_status_badge`. Si la nouvelle catégorie doit compter dans le compteur, mettre aussi à jour `User#avis_a_remplir`.
- **Multi-versions SV** : actuellement seule la dernière SV est représentée dans la case "Services votés". Si on veut afficher chaque version (SV1, SV2…), il faudrait éclater la case ou empiler plusieurs badges.

---

## Voir aussi

- [Fonctionnalité Avis](./feature-avis.md) — Cycle de vie complet de l'avis, formulaires, exports.
- [Tech-spec Avis non reçu](../_bmad-output/implementation-artifacts/tech-spec-avis-non-recu.md) — Spécification du statut "Non reçu" introduit en 2026-06.
- [data-models.md](./data-models.md) — Schéma de la table `avis` et associations.
