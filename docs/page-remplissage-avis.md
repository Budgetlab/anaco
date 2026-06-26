---
title: Page Liste de travail avis/notes (remplissage_avis)
description: Documentation fonctionnelle et technique de l'écran de remplissage des avis (tableau de suivi par BOP et par phase)
audience: Développeurs entrants, product owners (CBR), administrateurs
project: avisbop
language: fr
---

# Page Liste de travail avis/notes

L'écran **Liste de travail avis/notes** est le tableau de bord principal du CBR/DCB. Il liste tous ses BOP et, pour chacun, l'état d'avancement de la saisie sur chaque **phase** définie au calendrier budgétaire de **l'année en cours**. C'est l'écran d'entrée pour démarrer ou reprendre la rédaction d'un avis. La page est verrouillée sur l'année courante — il n'y a pas de navigation entre années (la consultation des avis historiques se fait depuis la page d'historique ou la fiche BOP).

- **URL** : `/anaco/remplissage_avis`
- **Action contrôleur** : `AvisController#remplissage_avis` ([app/controllers/avis_controller.rb](../app/controllers/avis_controller.rb#L204))
- **Vue principale** : [app/views/avis/remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb)
- **Partial ligne** : [app/views/avis/_bop_actif_row.html.erb](../app/views/avis/_bop_actif_row.html.erb)
- **Audience** : CBR et DCB connectés. Chaque utilisateur voit les BOP qui le concernent (pas de distinction de traitement entre les deux profils sur cette page). Le rôle admin n'a pas vocation à passer par cet écran pour saisir.

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Structure de l'écran](#2-structure-de-lécran)
3. [Colonnes dynamiques et phases](#3-colonnes-dynamiques-et-phases)
4. [Logique des badges de statut](#4-logique-des-badges-de-statut)
5. [Boutons d'action](#5-boutons-daction)
6. [Compteur « il reste X avis/notes à rédiger »](#6-compteur--il-reste-x-avis-notes-à-rédiger-)
7. [Bandeau Resana et phase courante](#7-bandeau-resana-et-phase-courante)
8. [Onglet BOP inactifs](#8-onglet-bop-inactifs)
9. [Référence technique](#9-référence-technique)

---

## 1. Vue d'ensemble

Le CBR/DCB voit, pour chaque BOP **actif** de l'année en cours, une ligne du tableau avec **une colonne par phase** présente au calendrier de cette année (table `phases`). Chaque cellule porte un ou plusieurs badges indiquant l'état d'avancement (rien à faire, brouillon en cours, avis transmis, non reçu, etc.).

Deux boutons à droite de chaque ligne permettent d'agir :

- **Rédiger** — ouvre le formulaire de la **prochaine phase à saisir** pour ce BOP (résultat de `next_phase_to_fill`). Désactivé si toutes les phases ouvertes sont déjà transmises.
- **Consulter les avis** — ouvre la page du BOP ([show](../app/views/bops/show.html.erb)).

Un **bandeau d'alerte** en haut totalise le nombre d'avis encore à rédiger ou en brouillon, toutes phases et tous BOP confondus.

## 2. Structure de l'écran

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│ Liste de travail avis/notes 2026                                                      │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ Nous sommes en phase de CRG1 2026                                                     │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ 🔗 Lien Resana — où déposer les avis/notes complets finalisés                         │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ Onglets : [ BOP actifs (51) ] [ BOP inactifs (0) ]                                    │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ ⚠ Il reste 98 avis/notes à rédiger   ← compteur global, onglet actifs                 │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ ┌────────┬─────────┬───────────┬──────┬──────┬────────┬────────┐                      │
│ │ BOP    │ SV1 …   │ Début …   │ CRG1 │ CRG2 │ Rédig. │ Consul.│   ← cols dynamiques  │
│ │        │ SV2 …   │           │      │      │        │        │     selon Phase      │
│ ├────────┼─────────┼───────────┼──────┼──────┼────────┼────────┤                      │
│ │ BOP X  │ ✓Trans. │ Brouillon │ À r. │ 🔒NO │ Rédig. │ Cons.  │                      │
│ │        │ À réd.  │           │      │      │        │        │                      │
│ └────────┴─────────┴───────────┴──────┴──────┴────────┴────────┘                      │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

Le tableau utilise les composants DSFR `fr-table` + `fr-tabs`. Chaque ligne d'un BOP actif est rendue par le partial [_bop_actif_row.html.erb](../app/views/avis/_bop_actif_row.html.erb).

## 3. Colonnes dynamiques et phases

Les colonnes de phase ne sont **plus codées en dur** : elles sont générées à partir de la table `phases`.

- **Sélection des colonnes** : `noms_phases_pour_annee(annee)` retourne les noms de phase présents au calendrier de l'année, dans l'ordre canonique défini par `Phase::NOMS_CONNUS` (`['services votés', 'programmation initiale', 'CRG1', 'CRG2']`). Une année sans `services votés` n'aura pas de colonne SV.
- **Libellé de colonne** : `Phase.libelle_colonne(nom)` — libellé court présenté en en-tête (`SV`, `Avis à la programmation`, etc.).
- **Cellule multi-instances** : si plusieurs instances d'une même phase coexistent (cas typique : `SV1` et `SV2` la même année), la cellule empile **un badge par instance**, préfixé par le libellé court (`SV1`, `SV2`).

Le calendrier (ouverture / fermeture des phases) est désormais piloté par la table `phases` — chaque instance porte sa propre `date_debut`. Plus de pivots hardcodés (20 février, 1er juin, 1er septembre). L'administration de ces phases se fait sur `/anaco/phases` (voir [Page Phases](#)).

## 4. Logique des badges de statut

Pour chaque couple (BOP, instance de phase), le badge affiché est déterminé par le helper `phase_status_badge` ([app/helpers/avis_helper.rb#L51](../app/helpers/avis_helper.rb#L51)).

Règles, appliquées dans cet ordre :

| Condition | Badge | Classe DSFR | Sens métier |
|---|---|---|---|
| Phase **CRG1** + avis début existe avec `is_crg1 == false` | **N/A** | `fr-badge` | Le CBR a déclaré qu'il n'y aurait pas de CRG1 pour ce BOP. Pas de saisie attendue. |
| Phase **non ouverte** (`phase.date_debut > today`) | **Non ouvert** | `fr-badge` + icône cadenas | La phase ne peut pas encore être saisie. |
| Phase ouverte, **aucun avis** pour cette instance | **À rédiger** | `fr-badge--warning` + icône edit | Aucune saisie démarrée. |
| Avis en `etat = 'Brouillon'` | **Brouillon** | `fr-badge--new` | Une saisie est en cours mais pas finalisée. |
| Avis avec `statut = 'Non reçu'` | **Non reçu** | `fr-badge--brown-caramel` | Le CBR a finalisé en déclarant qu'il ne peut pas rendre d'analyse (dossier non transmis, tardif ou incomplet). |
| Sinon (`etat` ∈ `['Lu', 'En attente de lecture']` et statut métier classique) | **Transmis** | `fr-badge--info` + icône check | L'avis est finalisé et transmis. |

Le préfixe `prefix` ajouté au label (ex: « SV1 À rédiger ») n'apparaît que lorsque plusieurs instances coexistent.

**Mapping avis ↔ instance de phase** : `avis_pour_phase(avis_bop, phase)` retrouve l'avis via `a.phase_id == phase.id` (et non plus via le nom de phase seul). Les avis legacy sans `phase_id` ne sont pas matchés ici — cas marginal après backfill.

## 5. Boutons d'action

### 5.1 Bouton Rédiger

- **Cible** : `new_bop_avi_path(bop_id:, date: annee_affichee, phase_id: next_phase.id)` — la **phase ciblée est un objet `Phase`** (pas un nom), ce qui permet de cibler une instance précise quand plusieurs coexistent (SV1 vs SV2).
- **Logique de priorité** (helper `next_phase_to_fill` — [app/helpers/avis_helper.rb#L89](../app/helpers/avis_helper.rb#L89)) : itération sur les instances de phase de l'année triées par `date_debut` croissant. Une instance est candidate ssi :
  1. elle est **ouverte** (`phase.ouverte?(reference_date)`)
  2. ce n'est pas CRG1 alors que `avis_debut.is_crg1 == false` (cas N/A)
  3. l'avis associé est manquant **ou** en brouillon
  La première instance candidate gagne. Si aucune ne correspond, retourne `nil`.
- **État désactivé** : `next_phase = nil` → `<button … disabled>` (gris).

Le contrôleur [`AvisController#new`](../app/controllers/avis_controller.rb#L46) reçoit `phase_id`, résout l'instance via `Phase.find_by`, et redirige vers `edit_bop_avi_path` si un brouillon existe déjà sur ce couple (BOP, phase) — l'utilisateur reprend là où il s'était arrêté.

### 5.2 Bouton Consulter les avis

- **Cible** : `bop_path(bop)` — page de consultation du BOP, qui liste tous les avis déjà saisis (transmis, en attente, lu) et leurs détails.
- Toujours actif, indépendamment de l'état de saisie.

## 6. Compteur « il reste X avis/notes à rédiger »

Le bandeau d'alerte en haut de l'onglet actifs affiche le nombre total d'avis/notes dans un état « à produire » sur l'année affichée.

- **Méthode** : [`User#avis_a_remplir(annee, reference_date = Date.today)`](../app/models/user.rb#L76)
- **Définition** : somme, pour chaque BOP actif de l'année, du nombre de cases du tableau qui afficheraient un badge **À rédiger** ou **Brouillon**. Strictement aligné sur les badges visibles.
- **Lecture des phases** : `Phase.pour_annee(annee).where('date_debut <= ?', reference_date)` — seules les phases dont au moins une instance est ouverte à la date de référence sont comptées.
- **Exclusions explicites** :
  - **Transmis** — l'avis est finalisé normalement.
  - **Non reçu** — l'avis est finalisé avec déclaration d'absence d'analyse. Bien que distinct de transmis, c'est une finalisation, donc pas une action à rédiger.
  - **N/A** — CRG1 explicitement non programmé (`début.is_crg1 == false`).
  - **Non ouvert** — la phase n'a pas encore commencé à la date de référence.
- **CRG1 sans avis début** : compté comme « à rédiger ».
- **SV** : la cellule représente le **dernier** avis SV de l'année (le plus récent par `created_at`) ; le compteur ne compte qu'une unité par BOP pour cette phase même si plusieurs instances coexistent.
- **Performance** : 1 seule requête `self.avis.where(annee:, bop_id: ids).group_by(&:bop_id)` pour récupérer tous les avis, puis comptage en mémoire. Pas de N+1.

## 7. Bandeau Resana et phase courante

- **« Nous sommes en phase de … »** : titre `h3` affiché en permanence. Indique la phase en cours via `@phase_courante` — alimenté par [`Phase.courante_pour(@annee, Date.today)`](../app/models/phase.rb#L42) dans `ApplicationController#set_global_variable`.
- **Bandeau Resana** : pictogramme + texte explicatif + lien vers le dossier Resana où déposer les avis/notes finalisés.

## 8. Onglet BOP inactifs

Un second onglet liste les BOP marqués `inactif` pour l'année en cours (`current_user.bops_inactifs(@annee)`). Aucun avis n'est attendu sur ces BOP.

Colonnes : **BOP**, **Programme**, **Statut** (`Inactif`), **Modifier la dotation** → `edit_bop_path(bop)` permettant de remettre une dotation et donc de réactiver le BOP (cf. `BopsController#update`), et **Consulter** → `bop_path(bop)`.

Le rendu est inline dans [remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb) (pas de partial dédié, structure courte).

## 9. Référence technique

### 9.1 Action contrôleur

```ruby
# app/controllers/avis_controller.rb
def remplissage_avis
  @annee_a_afficher = @annee
  @bops_inactifs    = current_user.bops_inactifs(@annee_a_afficher).order(code: :asc)
  @bops_actifs      = current_user.bops_actifs(@annee_a_afficher).order(code: :asc)
  @avis             = current_user.avis.where(annee: @annee_a_afficher).to_a
  @avis_par_bop     = @avis.group_by(&:bop_id)
end
```

L'action force `@annee_a_afficher = @annee` (année courante) — `params[:date]` n'est plus lu. `@avis_par_bop` est précalculé pour éviter une requête par ligne (N+1). `@phase_courante`, `@annee`, etc. sont posés par `ApplicationController#set_global_variable` (callback global).

### 9.2 Helpers

Cinq helpers de [app/helpers/avis_helper.rb](../app/helpers/avis_helper.rb) portent toute la logique métier de la page :

| Helper | Signature | Rôle |
|---|---|---|
| `phases_for_annee` | `(annee)` | Charge et mémoïze `Phase.pour_annee(annee)`. |
| `phases_groupees_par_nom` | `(annee)` | Hash `{ nom => [Phase, …] }`, triées par `date_debut`. Permet d'empiler N badges par cellule. |
| `noms_phases_pour_annee` | `(annee)` | Noms de phase présents dans l'année, ordonnés selon `Phase::NOMS_CONNUS`. Génère les colonnes du tableau. |
| `avis_pour_phase` | `(avis_bop, phase)` | Trouve l'avis lié à une **instance** précise via `phase_id`. |
| `phase_status_badge` | `(avis, phase_nom, ouverte, avis_debut: nil, prefix: nil)` | Retourne le HTML du badge selon les règles de la section 4. |
| `next_phase_to_fill` | `(avis_bop, annee, reference_date = Date.today)` | Retourne la **prochaine instance `Phase`** à rédiger, ou `nil`. |

Côté modèle, `Phase` expose `Phase.pour_annee(annee)`, `Phase.courante_pour(annee, date)`, `Phase.libelle_colonne(nom)`, et l'instance `#ouverte?(reference_date)`.

### 9.3 Fichiers impliqués

| Fichier | Rôle |
|---|---|
| [app/views/avis/remplissage_avis.html.erb](../app/views/avis/remplissage_avis.html.erb) | Vue principale : bandeaux, onglets, en-tête de tableau dynamique. |
| [app/views/avis/_bop_actif_row.html.erb](../app/views/avis/_bop_actif_row.html.erb) | Une ligne `<tr>` pour un BOP actif. Itère sur les colonnes dynamiques et empile N badges si plusieurs instances. |
| [app/helpers/avis_helper.rb](../app/helpers/avis_helper.rb) | `phases_for_annee`, `phases_groupees_par_nom`, `noms_phases_pour_annee`, `avis_pour_phase`, `phase_status_badge`, `next_phase_to_fill`. |
| [app/models/user.rb](../app/models/user.rb) | `avis_a_remplir(annee, reference_date)` (compteur), `bops_actifs(annee)`, `bops_inactifs(annee)`. |
| [app/models/phase.rb](../app/models/phase.rb) | Table `phases` : scopes (`pour_annee`), méthodes de classe (`courante_pour`, `libelle_colonne`), instance (`ouverte?`, `libelle_court_avec_numero`). |
| [app/controllers/application_controller.rb](../app/controllers/application_controller.rb#L44) | `set_global_variable` — définit `@annee`, `@phase_courante` et lit la table `phases` pour rétro-compatibilité (`@date_debut`, `@date_crg1`, `@date_crg2` dérivés des instances). |
| [app/controllers/avis_controller.rb](../app/controllers/avis_controller.rb) | `remplissage_avis` (action), `new` (cible du bouton Rédiger, accepte `phase_id`). |
| [app/controllers/bops_controller.rb](../app/controllers/bops_controller.rb#L28) | `update` (Modifier la dotation) : `dotation = aucune` ⇒ `statut: inactif` + `date_fin_activite: 1er janvier annee`. Sinon réactive. |

### 9.4 Modèle de données mobilisé

- **`bops`** — filtrée par `bops_actifs(annee)` / `bops_inactifs(annee)`. La période d'activité est portée par `date_debut_activite` (inclusive) et `date_fin_activite` (**exclusive** : `date_fin_activite = 1er janvier N` ⇒ inactif sur N).
- **`phases`** — calendrier de l'année. Colonnes : `nom`, `annee`, `date_debut`. Chaque ligne = une instance ouvrable indépendamment. Une même `nom` peut avoir plusieurs instances dans une année (SV1, SV2…).
- **`avis`** — agrégés par BOP, lus pour calculer les badges. Colonnes lues : `phase`, `phase_id`, `etat`, `statut`, `is_crg1`, `created_at`.
- **Pas d'écriture en base** depuis cet écran (toutes les actions de saisie passent par les formulaires de `AvisController`).

### 9.5 Points d'attention pour les évolutions

- **Ajouter une nouvelle phase canonique** (nouvelle famille de phase) : étendre `Phase::NOMS_CONNUS`, `Phase::LIBELLES_COLONNE`, `Avi::STATUTS_PAR_PHASE`, et adapter `User#avis_a_remplir` pour la prendre en compte. L'en-tête du tableau et les colonnes se mettront à jour automatiquement via `noms_phases_pour_annee`.
- **Ajouter une nouvelle instance d'une phase existante** (ex. SV3 sur une année) : passe uniquement par la page `/anaco/phases` (admin) — aucun code à modifier, le partial empile automatiquement les badges et `next_phase_to_fill` itère sur toutes les instances.
- **Modifier une date pivot** : se fait via la page `/anaco/phases` — plus aucune date n'est codée dans le contrôleur. La modification rétroactive sur les années passées est verrouillée (admin de Phase).
- **Nouveau badge / statut** : étendre `phase_status_badge`. Si la nouvelle catégorie doit compter dans le bandeau, mettre aussi à jour `User#avis_a_remplir`.

---

## Voir aussi

- [Fonctionnalité Avis](./feature-avis.md) — Cycle de vie complet de l'avis, formulaires, exports.
- [Tech-spec Avis non reçu](../_bmad-output/implementation-artifacts/tech-spec-avis-non-recu.md) — Spécification du statut `Non reçu` introduit en 2026-06.
- [data-models.md](./data-models.md) — Schéma des tables `avis`, `bops`, `phases` et associations.
