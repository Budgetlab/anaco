---
title: 'Avis non reçu — champ avis_recu et motif d''absence'
slug: 'avis-non-recu'
created: '2026-06-17'
status: 'Implementation Complete'
stepsCompleted: [1, 2, 3, 4, 5]
implementedAt: '2026-06-17'
implementedCommitBase: '87cdff9'
tech_stack: ['Rails', 'ActiveRecord', 'ERB', 'DSFR', 'Stimulus', 'Axlsx', 'Roo', 'Ransack', 'Pagy', 'Minitest']
files_to_modify:
  - 'db/migrate/XXXXXX_add_avis_recu_and_motif_absence_to_avis.rb (nouveau)'
  - 'app/models/avi.rb'
  - 'app/controllers/avis_controller.rb'
  - 'app/helpers/avis_helper.rb'
  - 'app/views/avis/_form_debut.html.erb'
  - 'app/views/avis/_form_crg1.html.erb'
  - 'app/views/avis/_form_crg2.html.erb'
  - 'app/views/avis/_form_services_votes.html.erb'
  - 'app/views/avis/show.html.erb'
  - 'app/views/avis/index.html.erb'
  - 'app/views/avis/consultation.html.erb'
  - 'app/views/avis/index.xlsx.axlsx'
  - 'app/views/avis/consultation.xlsx.axlsx'
  - 'app/views/avis/export_avis.xlsx.axlsx'
  - 'test/fixtures/avis.yml'
  - 'test/controllers/avis_controller_test.rb'
code_patterns:
  - 'Stimulus conditional-field controller (toggle fr-hidden + required, inverse-value)'
  - 'DSFR fr-fieldset + fr-radio-group pour radios Oui/Non'
  - 'DSFR fr-select-group + fr-select pour selects'
  - 'Tag-select Stimulus pour filtres statut (check_box_tag q[statut_in][])'
  - 'Override statut/etat post-save dans le contrôleur (pattern dcb_is_updating?)'
  - 'Boutons fr-btns-group par partial avec data-action click->form#save / click->form#open'
test_patterns:
  - 'Minitest + ActiveSupport::TestCase, fixtures :all dans test_helper.rb'
  - 'Aucune factory ; fixtures YAML à peupler'
  - 'Tests contrôleur via ActionDispatch::IntegrationTest'
---

# Tech-Spec: Avis non reçu — champ avis_recu et motif d'absence

**Created:** 2026-06-17

## Overview

### Problem Statement

Aujourd'hui, un CBR n'a aucun moyen de déclarer formellement qu'il n'est **pas en mesure de rendre un avis** sur un BOP (dossier non transmis, transmis tardivement ou incomplet par le RBOP). Il doit soit ne rien saisir — auquel cas l'avis n'apparaît nulle part dans le suivi de remplissage — soit forcer un statut métier qui ne reflète pas la réalité. Conséquence : les restitutions et le suivi de remplissage sont biaisés et les DCB n'ont pas visibilité sur ces cas particuliers.

### Solution

Ajouter en tête de chaque formulaire de saisie d'avis un champ `avis_recu` (booléen, default `true`). Lorsque le CBR sélectionne **Non**, le formulaire bascule en mode minimal : seul un champ `motif_absence` (liste fermée de 3 valeurs) reste affiché. À la validation, l'avis est enregistré avec `statut = "Non reçu"` (nouveau statut métier, badge DSFR brown-caramel) et `etat = "Lu"` directement, sans transition par "En attente de lecture" ni possibilité de brouillon. Le mode "Oui" préserve intégralement le comportement actuel.

### Scope

**In Scope:**

- Migration BDD : ajout des colonnes `avis_recu:boolean default:true null:false` et `motif_absence:string` sur la table `avis`.
- Modèle `Avi` : ajout de `motif_absence` à `ransackable_attributes` ; constante `MOTIFS_ABSENCE` listant les 3 motifs ; ligne d'import (`Avi.import`) pour `motif_absence`.
- Contrôleur `AvisController` : ajout `:avis_recu, :motif_absence` aux strong params ; dans `create` et `update`, lorsque `avis_recu == false` → override `statut = "Non reçu"`, `etat = "Lu"` et **nullification** des champs financiers / dates / drapeaux non pertinents.
- Modification des 4 partials de formulaire : `_form_debut`, `_form_crg1`, `_form_crg2`, `_form_services_votes`.
- Helper `badge_class_for_statut` : ajout du `when 'Non reçu' → 'fr-badge fr-badge--brown-caramel'`.
- Vue `show.html.erb` : affichage du nouveau statut + du motif quand `avis_recu = false`.
- Filtres Ransack : ajout de `"Non reçu"` dans le tableau hardcodé des statuts tag-select de `index.html.erb` et `consultation.html.erb`.
- Import : `Avi.import` reconnaît la colonne `Motif d'absence`.
- Exports Excel : ajout de la colonne `Motif d'absence` juste avant `commentaire` dans les 3 exports `.xlsx.axlsx`.
- Tests Minitest : peupler `test/fixtures/avis.yml` + tests contrôleur pour create/update avec `avis_recu = false`.

**Out of Scope:**

- Partial `_form_execution` et méthode `Avi.import_execution`.
- Callback `set_etat_avis` du modèle (inchangé).
- Refonte des statuts existants (uniquement ajout de `Non reçu`).
- Helpers de restitutions (comptés comme remplis via `etat = Lu`).
- Règles de suppression (inchangées).
- Édition après validation (rebascule Non → Oui autorisée).
- Refactorisation des boutons (dupliqués entre partials) en un sub-partial commun.

## Context for Development

### Codebase Patterns

**Formulaires :**
- Pattern uniforme : `form_with(model: [@bop, @avis], data: ...)` enveloppé dans `<div data-controller="form">`.
- Champs cachés en haut : `user_id`, `phase`, `annee`, `etat`.
- Mise en page DSFR à deux colonnes.
- Pattern radio DSFR :
  ```erb
  <fieldset class="fr-fieldset fr-mb-3w">
    <legend class="fr-fieldset__legend--regular fr-fieldset__legend fr-mb-1w">Libellé*</legend>
    <div class="fr-fieldset__element fr-fieldset__element--inline fr-mb-0">
      <div class="fr-radio-group">
        <%= f.radio_button :champ, true, id: "champ-oui" %>
        <label class="fr-label" for="champ-oui">Oui</label>
      </div>
    </div>
  </fieldset>
  ```
- Pattern select DSFR : `<div class="fr-select-group"><label class="fr-label">...</label><%= f.select ... %></div>`.

**Affichage conditionnel — contrôleur Stimulus existant `conditional-field`** :
- Targets : `checkbox` (radio source) et `field` (blocs à toggle).
- Values : `inverse: Boolean` pour inverser la logique.
- Comportement : ajoute/retire `fr-hidden` ; vide les selects masqués ; gère `required`.
- Markup :
  ```erb
  <%= f.radio_button :avis_recu, true, id: "avis-recu-oui",
        data: { action: "change->conditional-field#toggle",
                conditional_field_target: "checkbox" } %>
  <div data-conditional-field-target="field"><!-- visible si Oui --></div>
  <div data-conditional-field-target="field"
       data-conditional-field-inverse-value="true"
       class="fr-hidden"><!-- visible si Non --></div>
  ```

**Boutons** (dans chaque partial individuellement) :
```erb
<ul class="fr-btns-group fr-btns-group--icon-left fr-btns-group--inline fr-btns-group--right">
  <li>
    <button class="fr-btn fr-icon-save-3-fill fr-btn--icon-left fr-btn--secondary"
            data-action="click->form#save">Enregistrer</button>
  </li>
  <li>
    <button class="fr-btn bouton_inactive" data-form-target="Btnvalidate"
            data-action="click->form#open" disabled>Valider</button>
  </li>
</ul>
```

**Filtres statut (tag-select Stimulus)** : `index.html.erb` l.256-275, `consultation.html.erb` l.345-364. Liste hardcodée dans un `each` — ajouter `"Non reçu"`.

**Affichage show** : `<p class="fr-my-1w"><span class="fr-text--bold">Label:</span> value</p>` ; statut rendu avec `badge_class_for_statut`.

**Pattern de forçage post-save** (déjà en usage via `dcb_is_updating?`) : après `@avi.save`, condition → `@avi.update(...)`.

**Imports/exports** : `Avi.import` (Roo) → mapping `avis.attr = row_data['En-tête']`. Axlsx → header array + row array (insérer avant `commentaire`).

**Tests** : Minitest, `ActionDispatch::IntegrationTest`, fixtures YAML.

### Files to Reference

| File | Purpose |
| ---- | ------- |
| [app/models/avi.rb](../../app/models/avi.rb) | Constante MOTIFS_ABSENCE, ransackable_attributes, ligne d'import |
| [app/controllers/avis_controller.rb](../../app/controllers/avis_controller.rb) | Strong params (l.219-221), create (l.69-78), update (l.87-101), pattern dcb_is_updating? (l.264-266) |
| [app/helpers/avis_helper.rb](../../app/helpers/avis_helper.rb) | badge_class_for_statut (l.16-27) |
| [app/javascript/controllers/conditional_field_controller.js](../../app/javascript/controllers/conditional_field_controller.js) | Réutilisé tel quel |
| [app/javascript/controllers/form_controller.js](../../app/javascript/controllers/form_controller.js) | Comprendre `save`/`open`/`validateForm` |
| [app/views/avis/_form_debut.html.erb](../../app/views/avis/_form_debut.html.erb) | Radio + motif + wrappers + bouton conditionnel |
| [app/views/avis/_form_crg1.html.erb](../../app/views/avis/_form_crg1.html.erb) | Idem |
| [app/views/avis/_form_crg2.html.erb](../../app/views/avis/_form_crg2.html.erb) | Idem |
| [app/views/avis/_form_services_votes.html.erb](../../app/views/avis/_form_services_votes.html.erb) | Idem |
| [app/views/avis/show.html.erb](../../app/views/avis/show.html.erb) | Affichage `avis_recu` + `motif_absence` |
| [app/views/avis/index.html.erb](../../app/views/avis/index.html.erb) | Tableau tag-select l.256-275 |
| [app/views/avis/consultation.html.erb](../../app/views/avis/consultation.html.erb) | Tableau tag-select l.345-364 |
| [app/views/avis/index.xlsx.axlsx](../../app/views/avis/index.xlsx.axlsx) | Header + cellule avant `commentaire` |
| [app/views/avis/consultation.xlsx.axlsx](../../app/views/avis/consultation.xlsx.axlsx) | Idem |
| [app/views/avis/export_avis.xlsx.axlsx](../../app/views/avis/export_avis.xlsx.axlsx) | Idem |
| [test/fixtures/avis.yml](../../test/fixtures/avis.yml) | À peupler |
| [test/controllers/avis_controller_test.rb](../../test/controllers/avis_controller_test.rb) | Nouveaux tests |
| [db/schema.rb](../../db/schema.rb) | Cible : table `avis` enrichie |
| [app/assets/stylesheets/dsfr.scss](../../app/assets/stylesheets/dsfr.scss) | `fr-badge--brown-caramel` déjà disponible |

### Technical Decisions

- **Nom du champ booléen** : `avis_recu` (default `true`, non nullable).
- **Statut `Non reçu`** : nouvelle valeur du champ `statut` existant.
- **Forçage statut/etat côté contrôleur** : juste avant `@avi.save`, si `params[:avi][:avis_recu] == 'false'` → assign `statut = 'Non reçu'`, `etat = 'Lu'`, et **nullification** de `date_envoi`, `date_reception`, `is_delai`, `is_crg1`, `ae_i`, `ae_f`, `cp_i`, `cp_f`, `t2_i`, `t2_f`, `etpt_i`, `etpt_f`, `commentaire`, `duree_prevision`. Cette règle prime sur `dcb_is_updating?`.
- **Affichage conditionnel** : un seul radio + deux wrappers `conditional-field` avec `inverse-value` opposés.
- **Bouton Enregistrer** : enveloppé dans un wrapper conditional-field (visible si Oui).
- **Pas de validations modèle dures** sur `motif_absence` (cohérent avec l'existant).
- **Filtres** : `avis_recu` non exposé à Ransack ; on filtre via statut `"Non reçu"`.
- **`motif_absence` dans ransackable_attributes** : ajouté par cohérence.
- **Migration BDD** : `avis_recu = true` par défaut → tous les avis existants restent cohérents.

## Implementation Plan

### Tasks

> Ordre par dépendance : BDD → modèle → contrôleur → helper → vues → import/export → tests.

- [x] **Task 1 — Migration BDD : ajout des deux colonnes**
  - Fichier : `db/migrate/<timestamp>_add_avis_recu_and_motif_absence_to_avis.rb` (nouveau)
  - Action :
    ```ruby
    class AddAvisRecuAndMotifAbsenceToAvis < ActiveRecord::Migration[<version>]
      def change
        add_column :avis, :avis_recu, :boolean, default: true, null: false
        add_column :avis, :motif_absence, :string
      end
    end
    ```
  - Notes : `default: true` garantit la rétro-compatibilité des avis existants. Exécuter `bin/rails db:migrate` puis vérifier `db/schema.rb`.

- [x] **Task 2 — Modèle : constante des motifs + ransackable**
  - Fichier : `app/models/avi.rb`
  - Action :
    1. Ajouter en tête de classe :
       ```ruby
       MOTIFS_ABSENCE = [
         'Absence de dossier transmis par le RBOP',
         'Dossier transmis tardivement par le RBOP',
         'Dossier incomplet, ne permettant pas de rendre un avis'
       ].freeze
       ```
    2. Dans `self.ransackable_attributes`, ajouter `"motif_absence"` à la liste (laisser `avis_recu` exclu pour ne pas l'exposer en filtre).
  - Notes : ne pas ajouter de validation Rails (cohérent avec l'existant). Le callback `set_etat_avis` reste inchangé.

- [x] **Task 3 — Contrôleur : strong params + forçage statut/etat/nullification**
  - Fichier : `app/controllers/avis_controller.rb`
  - Action :
    1. Étendre `avi_params` (l.219-221) :
       ```ruby
       params.require(:avi).permit(
         :user_id, :phase, :bop_id, :date_reception, :date_envoi,
         :is_delai, :is_crg1, :statut,
         :ae_i, :cp_i, :t2_i, :etpt_i,
         :ae_f, :cp_f, :t2_f, :etpt_f,
         :commentaire, :etat, :annee, :duree_prevision,
         :avis_recu, :motif_absence
       )
       ```
    2. Ajouter une méthode privée :
       ```ruby
       def force_non_recu_attributes!(attrs)
         return attrs unless attrs[:avis_recu] == 'false' || attrs[:avis_recu] == false
         attrs.merge(
           statut: 'Non reçu',
           etat: 'Lu',
           date_envoi: nil, date_reception: nil,
           is_delai: nil, is_crg1: nil,
           ae_i: nil, ae_f: nil, cp_i: nil, cp_f: nil,
           t2_i: nil, t2_f: nil, etpt_i: nil, etpt_f: nil,
           commentaire: nil, duree_prevision: nil
         )
       end
       ```
    3. Dans `create` (l.69-78) : appliquer `force_non_recu_attributes!(avi_params)` à la place de `avi_params` lors de la construction de `@avi`. Conserver la logique existante `dcb_is_updating?` (elle est neutralisée si `avis_recu = false` car `etat = 'Lu'` est déjà imposé).
    4. Dans `update` (l.87-101) : appliquer la même transformation avant `@avi.update(...)`. Conserver la garde existante sur la préservation de l'état précédent (mais elle est dominée par `avis_recu = false`).
  - Notes : ne pas modifier le callback modèle. La nullification protège contre la persistance de données saisies puis masquées par bascule Oui → Non.

- [x] **Task 4 — Helper : badge pour le statut "Non reçu"**
  - Fichier : `app/helpers/avis_helper.rb`
  - Action : dans `badge_class_for_statut` (l.16-27), ajouter avant le `else` :
    ```ruby
    when 'Non reçu'
      'fr-badge fr-badge--brown-caramel'
    ```
  - Notes : classe DSFR confirmée disponible dans `dsfr.scss`.

- [x] **Task 5 — Partial `_form_debut` : radio avis_recu + motif + wrappers + bouton conditionnel**
  - Fichier : `app/views/avis/_form_debut.html.erb`
  - Action :
    1. Tout en haut du `form_with`, après les hidden fields, ajouter le fieldset radio `avis_recu` (Oui/Non, Oui coché par défaut, obligatoire, label *« Je suis en capacité de rendre mon analyse* »*). Markup :
       ```erb
       <fieldset class="fr-fieldset fr-mb-3w">
         <legend class="fr-fieldset__legend--regular fr-fieldset__legend fr-mb-1w">
           Je suis en capacité de rendre mon analyse*
         </legend>
         <div class="fr-fieldset__element fr-fieldset__element--inline fr-mb-0">
           <div class="fr-radio-group">
             <%= f.radio_button :avis_recu, true, id: "avis-recu-debut-oui",
                   checked: (@avi.avis_recu.nil? || @avi.avis_recu),
                   data: { action: "change->conditional-field#toggle",
                           conditional_field_target: "checkbox" } %>
             <label class="fr-label" for="avis-recu-debut-oui">Oui</label>
           </div>
         </div>
         <div class="fr-fieldset__element fr-fieldset__element--inline fr-mb-0">
           <div class="fr-radio-group">
             <%= f.radio_button :avis_recu, false, id: "avis-recu-debut-non",
                   data: { action: "change->conditional-field#toggle",
                           conditional_field_target: "checkbox" } %>
             <label class="fr-label" for="avis-recu-debut-non">Non</label>
           </div>
         </div>
       </fieldset>
       ```
    2. Envelopper **tous les champs existants** (colonnes gauche + droite, accordéons, `_form_chiffres`, textarea) dans un wrapper :
       ```erb
       <div data-conditional-field-target="field" class="<%= 'fr-hidden' unless (@avi.avis_recu.nil? || @avi.avis_recu) %>">
         <!-- contenu existant inchangé -->
       </div>
       ```
    3. Ajouter, avant le bloc bouton, le wrapper "Non" contenant le select `motif_absence` :
       ```erb
       <div data-conditional-field-target="field"
            data-conditional-field-inverse-value="true"
            class="<%= 'fr-hidden' if (@avi.avis_recu.nil? || @avi.avis_recu) %>">
         <div class="fr-select-group">
           <label for="avi-motif-absence-debut" class="fr-label">Motif d'absence*</label>
           <%= f.select :motif_absence,
                 options_for_select(Avi::MOTIFS_ABSENCE, @avi.motif_absence),
                 { include_blank: 'Sélectionner' },
                 { id: 'avi-motif-absence-debut', class: 'fr-select',
                   data: { 'form-target': 'fieldRequire' } } %>
         </div>
       </div>
       ```
    4. Wrapper le `<li>` du bouton **Enregistrer** dans un wrapper conditional-field (visible si Oui) :
       ```erb
       <li data-conditional-field-target="field" class="<%= 'fr-hidden' unless (@avi.avis_recu.nil? || @avi.avis_recu) %>">
         <button ...>Enregistrer</button>
       </li>
       ```
       Conserver le bouton **Valider** tel quel.
    5. Mettre `data-controller="form conditional-field"` sur le `<div>` racine du form (en lieu et place du `data-controller="form"`).
  - Notes : le `data-form-target="fieldRequire"` posé sur le select garantit que `form#validateForm` débloque le bouton **Valider**. Vérifier après implémentation que `conditional-field` ne casse pas la validation Stimulus quand un wrapper est masqué (le contrôleur nettoie déjà les selects masqués).

- [x] **Task 6 — Partial `_form_crg1` : appliquer les mêmes modifications qu'à la Task 5**
  - Fichier : `app/views/avis/_form_crg1.html.erb`
  - Action : reproduire la Task 5 à l'identique, en suffixant les `id` par `-crg1` pour éviter les collisions.

- [x] **Task 7 — Partial `_form_crg2` : idem**
  - Fichier : `app/views/avis/_form_crg2.html.erb`
  - Action : idem avec suffixes `-crg2`.

- [x] **Task 8 — Partial `_form_services_votes` : idem**
  - Fichier : `app/views/avis/_form_services_votes.html.erb`
  - Action : idem avec suffixes `-sv`.

- [x] **Task 9 — Vue `show.html.erb` : affichage du nouveau statut + du motif**
  - Fichier : `app/views/avis/show.html.erb`
  - Action :
    1. Quand `@avi.avis_recu == false`, afficher **avant** le bloc statut :
       ```erb
       <p class="fr-my-1w">
         <span class="fr-text--bold">Capacité à rendre l'avis :</span> Non
       </p>
       <p class="fr-my-1w">
         <span class="fr-text--bold">Motif d'absence :</span> <%= @avi.motif_absence %>
       </p>
       ```
    2. Le rendu du statut (`badge_class_for_statut`) restitue automatiquement le badge brown-caramel pour `"Non reçu"` — aucune modif supplémentaire.
    3. Quand `@avi.avis_recu == false`, masquer les blocs financiers / dates qui n'ont plus de sens (date reception, date envoi, suspension délai, chiffres, commentaire) via un simple `unless @avi.avis_recu == false` autour de ces blocs (ou `if @avi.avis_recu`).
  - Notes : insérer après "Avis donné après suspension du délai" (l.31-33) pour la phase début de gestion, ou après "Date de la note d'analyse" (l.74-76) pour CRG1/CRG2 — selon le bloc conditionnel par phase déjà présent.

- [x] **Task 10 — Filtres `index.html.erb` : ajout "Non reçu"**
  - Fichier : `app/views/avis/index.html.erb` (l.256-275)
  - Action : ajouter `"Non reçu"` au tableau des statuts itéré :
    ```erb
    <% ["Favorable", "Favorable avec réserve", "Défavorable",
        "Aucun risque", "Risques éventuels ou modérés",
        "Risques certains ou significatifs", "Non reçu"].each do |t| %>
    ```
  - Notes : aucune autre modification ; le filtre `q[statut_in][]` fonctionne déjà sur tout statut existant en base.

- [x] **Task 11 — Filtres `consultation.html.erb` : ajout "Non reçu"**
  - Fichier : `app/views/avis/consultation.html.erb` (l.345-364)
  - Action : idem Task 10, en respectant la liste de variantes spécifiques à la consultation (« Risques modérés », etc.).

- [x] **Task 12 — Import : `Avi.import` reconnaît la colonne `Motif d'absence`**
  - Fichier : `app/models/avi.rb` (méthode `self.import`, l.8-49)
  - Action : juste après la ligne `avis.commentaire = row_data['commentaire']`, ajouter :
    ```ruby
    avis.motif_absence = row_data["Motif d'absence"]
    avis.avis_recu = (row_data['Statut/Risque'] != 'Non reçu')
    ```
  - Notes : la deuxième ligne reconstruit `avis_recu` à partir du statut importé, garantissant la cohérence sans nouvelle colonne d'import. Le statut `"Non reçu"` passé en entrée est accepté tel quel.

- [x] **Task 13 — Export `index.xlsx.axlsx` : ajout colonne `Motif d'absence`**
  - Fichier : `app/views/avis/index.xlsx.axlsx`
  - Action :
    1. Dans le `add_row` des headers : insérer `'Motif d\'absence'` juste avant `'commentaire'`.
    2. Dans le `add_row` des cellules data : insérer `avis.motif_absence` juste avant `avis.commentaire`.
  - Notes : préserver l'ordre des autres colonnes.

- [x] **Task 14 — Export `consultation.xlsx.axlsx` : idem Task 13**
  - Fichier : `app/views/avis/consultation.xlsx.axlsx`

- [x] **Task 15 — Export `export_avis.xlsx.axlsx` : idem Task 13**
  - Fichier : `app/views/avis/export_avis.xlsx.axlsx`

- [x] **Task 16 — Fixtures : peupler `test/fixtures/avis.yml`**
  - Fichier : `test/fixtures/avis.yml`
  - Action : créer au minimum 3 fixtures :
    - `avis_debut_lu` (avis_recu: true, etat: Lu, statut: Favorable, phase: 'début de gestion')
    - `avis_brouillon` (avis_recu: true, etat: Brouillon, statut: nil)
    - `avis_non_recu` (avis_recu: false, statut: 'Non reçu', etat: 'Lu', motif_absence: 'Dossier incomplet, ne permettant pas de rendre un avis')
  - Référencer `bops(:bop_1)` et `users(:cbr_1)` (vérifier les fixtures existantes ; en créer si nécessaire).
  - Notes : nécessaire pour tous les tests qui suivent.

- [x] **Task 17 — Tests contrôleur : create avec `avis_recu = false`**
  - Fichier : `test/controllers/avis_controller_test.rb`
  - Action : ajouter un test (en se basant sur les fixtures de Task 16) :
    ```ruby
    test "create avec avis_recu=false force statut=Non reçu et etat=Lu" do
      sign_in users(:cbr_1)
      assert_difference -> { Avi.count } do
        post bop_avis_path(bops(:bop_1)), params: { avi: {
          phase: 'début de gestion', annee: Date.today.year,
          user_id: users(:cbr_1).id, bop_id: bops(:bop_1).id,
          avis_recu: 'false',
          motif_absence: 'Absence de dossier transmis par le RBOP'
        }}
      end
      avi = Avi.last
      assert_equal 'Non reçu', avi.statut
      assert_equal 'Lu',       avi.etat
      assert_equal false,      avi.avis_recu
      assert_nil avi.date_envoi
      assert_nil avi.ae_i
    end
    ```
  - Notes : vérifier le helper `sign_in` (Devise) ou adapter au pattern existant si différent.

- [x] **Task 18 — Tests contrôleur : update avec `avis_recu = false` rebascule un Lu existant**
  - Fichier : `test/controllers/avis_controller_test.rb`
  - Action : test complémentaire qui part de `avis(:avis_debut_lu)` (avis_recu: true, statut: Favorable) et soumet un `PATCH` avec `avis_recu: 'false'` + motif. Asserter : `statut == 'Non reçu'`, `etat == 'Lu'`, données financières nullifiées.

### Acceptance Criteria

> Convention : G = Given, W = When, T = Then.

- [x] **AC 1 — Affichage par défaut**
  - G : un CBR ouvre le formulaire de création d'avis pour un BOP éligible.
  - W : la page se charge.
  - T : le radio "Je suis en capacité de rendre mon analyse" est affiché tout en haut, **Oui coché** ; tous les champs habituels (dates, chiffres, statut, commentaire, accordéons) sont visibles ; les boutons **Enregistrer** et **Valider** sont présents ; le bouton **Valider** est désactivé tant que la validation Stimulus n'a pas passé.

- [x] **AC 2 — Bascule sur "Non" masque le formulaire et affiche le motif**
  - G : le formulaire est affiché en mode Oui.
  - W : le CBR clique sur la radio "Non".
  - T : tous les champs précédents disparaissent (classe `fr-hidden`) ; un select **Motif d'absence** apparaît avec les 3 options (Absence de dossier transmis par le RBOP / Dossier transmis tardivement par le RBOP / Dossier incomplet, ne permettant pas de rendre un avis) ; le bouton **Enregistrer** est masqué ; seul **Valider** reste visible, désactivé tant que `motif_absence` n'est pas sélectionné.

- [x] **AC 3 — Validation en mode Non force statut + etat + nullifie le reste**
  - G : le CBR a sélectionné Non et choisi un motif.
  - W : il clique sur **Valider** (et confirme la modale).
  - T : l'avis est persisté avec `avis_recu = false`, `motif_absence` renseigné, `statut = "Non reçu"`, `etat = "Lu"` ; `date_envoi`, `date_reception`, `is_delai`, `is_crg1`, `ae_*`, `cp_*`, `t2_*`, `etpt_*`, `commentaire`, `duree_prevision` valent `nil` ; le CBR est redirigé vers `historique_path` ; aucune transition par `"En attente de lecture"`.

- [x] **AC 4 — Mode Oui : comportement actuel inchangé**
  - G : le CBR remplit tous les champs en mode Oui.
  - W : il clique sur **Enregistrer** (brouillon) ou **Valider**.
  - T : le comportement est strictement identique à aujourd'hui (Brouillon si champs requis manquants, En attente de lecture sinon, ou Lu si CBR == DCB).

- [x] **AC 5 — Badge brown-caramel pour "Non reçu"**
  - G : un avis avec `statut = "Non reçu"` existe.
  - W : il est affiché dans `show.html.erb`, `index.html.erb` ou `consultation.html.erb` via `badge_class_for_statut`.
  - T : le badge porte les classes `fr-badge fr-badge--brown-caramel`.

- [x] **AC 6 — Filtre statut "Non reçu"**
  - G : la page historique CBR (`/anaco/historique`) ou consultation DCB (`/anaco/consultation`).
  - W : le CBR/DCB coche le tag `"Non reçu"` dans le bloc Statut/Risque.
  - T : la liste filtrée n'affiche que les avis dont `statut = "Non reçu"` (combiné avec les autres filtres actifs).

- [x] **AC 7 — Affichage show pour un avis "Non reçu"**
  - G : un avis avec `avis_recu = false`.
  - W : on consulte `/anaco/avis/:id`.
  - T : la page affiche `"Capacité à rendre l'avis : Non"`, `"Motif d'absence : <valeur>"`, le badge statut brown-caramel ; les blocs financiers et de dates ne sont **pas** affichés.

- [x] **AC 8 — Exports Excel contiennent la colonne Motif d'absence**
  - G : un export Excel est déclenché (`/historique?format=xlsx`, `/consultation?format=xlsx`, `/export_avis?annee=YYYY`).
  - W : le fichier est généré.
  - T : la colonne `Motif d'absence` est présente juste avant `commentaire` ; pour les lignes `avis_recu = false`, la cellule contient le motif ; pour les autres, elle est vide.

- [x] **AC 9 — Import accepte la colonne Motif d'absence et le statut "Non reçu"**
  - G : un fichier d'import au format attendu, incluant une colonne `Motif d'absence` et des lignes avec `Statut/Risque = "Non reçu"`.
  - W : un admin déclenche `POST /import_avis`.
  - T : les avis correspondants sont créés/mis à jour avec `statut = "Non reçu"`, `motif_absence` correctement renseigné, et `avis_recu = false` (reconstruit à partir du statut).

- [x] **AC 10 — Migration rétro-compatible**
  - G : une base de données contenant des avis existants.
  - W : la migration `AddAvisRecuAndMotifAbsenceToAvis` est exécutée.
  - T : aucun avis existant n'est altéré ; chacun reçoit `avis_recu = true` ; `motif_absence` reste `NULL` ; aucune contrainte ne fait échouer la migration.

- [x] **AC 11 — Édition d'un avis "Non reçu" : rebascule Non → Oui autorisée**
  - G : un avis existant avec `avis_recu = false`, `statut = "Non reçu"`, `etat = "Lu"`.
  - W : le CBR édite l'avis, repasse la radio à Oui, remplit les champs habituels et valide.
  - T : l'avis est mis à jour avec `avis_recu = true`, `motif_absence = nil` (à confirmer en implémentation : reset explicite), et le comportement de transmission standard s'applique.

- [x] **AC 12 — Suppression : un "Non reçu" est non supprimable côté CBR**
  - G : un avis "Non reçu" en état `Lu`.
  - W : le CBR tente `DELETE /bops/:bop_id/avis/:id`.
  - T : la suppression est refusée (règle existante : suppression uniquement si `etat == "Brouillon"`).

## Additional Context

### Dependencies

- Aucune nouvelle gem.
- Le contrôleur Stimulus `conditional-field` doit être présent et chargé (déjà le cas dans le pipeline JS du projet).
- La classe CSS `fr-badge--brown-caramel` doit exister dans le bundle DSFR (confirmé dans `dsfr.scss`).
- Migration BDD à appliquer en pré-déploiement.

### Testing Strategy

**Tests automatisés (Minitest)** :
- **Tasks 16-18** couvrent les chemins critiques : création + mise à jour avec `avis_recu = false`, vérification du forçage statut/etat et de la nullification.
- Optionnel : test modèle pour valider que `Avi::MOTIFS_ABSENCE` contient bien les 3 valeurs attendues.

**Tests manuels obligatoires** :
- **TM 1** — Création début de gestion en mode Non → valider → vérifier la redirection et l'apparition dans l'historique avec badge brown-caramel.
- **TM 2** — Création CRG1 / CRG2 / services votés en mode Non → idem.
- **TM 3** — Mode Oui complet (cas brouillon, cas transmis) → comportement inchangé.
- **TM 4** — Bascule Oui ↔ Non sur le même formulaire avant submit (vérifier que le contrôleur Stimulus toggle correctement et qu'aucun champ masqué ne déclenche d'erreur de validation).
- **TM 5** — Édition d'un avis "Non reçu" existant → bascule en Oui, remplissage, validation.
- **TM 6** — Filtres historique CBR + consultation DCB : cocher `"Non reçu"` seul, combiné, décoché.
- **TM 7** — Export `historique`, `consultation`, `export_avis` → ouvrir les `.xlsx` et vérifier la colonne `Motif d'absence`.
- **TM 8** — Import d'un fichier contenant des lignes `Non reçu` + colonne `Motif d'absence` → vérifier la BDD.
- **TM 9** — Cas DCB = CBR (BOP où `user_id == dcb_id`) en mode Non → vérifier que le forçage `etat = Lu` est cohérent avec l'override existant `dcb_is_updating?` (pas de double traitement, pas d'erreur).

**Couverture restitutions** : non couverte par cette spec ; vérifier post-déploiement que les compteurs `avis_annee_remplis` / `suivi_remplissage` incluent bien les "Non reçu" (ils devraient, puisque ces avis sont en `etat = Lu`).

### Notes

**Points d'attention / risques identifiés** :

1. **Validation Stimulus du bouton Valider en mode Non** : le contrôleur `form` débloque **Valider** sur la base des éléments `data-form-target="fieldRequire"`. En mode Non, le seul élément requis est `motif_absence`. Vérifier que `validateForm` ignore correctement les fieldRequire masqués (le contrôleur `conditional-field` les nettoie déjà).

2. **Double override `dcb_is_updating?` + `avis_recu=false`** : les deux peuvent imposer `etat = Lu`. En cas de conflit (CBR == DCB sur un avis non reçu), `force_non_recu_attributes!` s'exécute d'abord, le code aval ne change pas l'état (déjà `Lu`). Pas de régression attendue, mais à vérifier manuellement (TM 9).

3. **Rebascule Non → Oui** : à l'édition d'un avis "Non reçu" passé à Oui, l'utilisateur doit re-remplir manuellement tous les champs (ils ont été nullifiés). C'est volontaire. À documenter dans la doc fonctionnelle Avis si nécessaire (hors scope).

4. **Filtre `statut_in` combiné avec `avis_recu`** : on n'expose pas `avis_recu` à Ransack pour éviter la double-source-de-vérité. Si un besoin de filtre direct `avis_recu` apparaît plus tard, l'ajouter à `ransackable_attributes`.

5. **Suivi des restitutions** : si le PO souhaite plus tard une catégorie spécifique "Non reçu" dans `avis_repartition` (badge dédié dans les graphes), prévoir une spec ultérieure (hors scope ici).

6. **Tests Devise / sign_in** : si le projet n'utilise pas le helper `sign_in` standard de Devise dans les tests d'intégration, adapter la Task 17 au mécanisme d'authentification existant (vérifier `test/test_helper.rb` lors de l'implémentation).

7. **Cohérence libellé bouton "Enregistrer" / "Enregistrer en Brouillon"** : actuellement le libellé varie entre partials. La spec n'harmonise pas (out of scope), mais l'occasion peut être saisie côté dev s'il est trivial de le faire au passage.

**Limitations connues** :

- Aucune validation Rails dure n'est ajoutée (cohérent avec l'existant). Un avis pourrait théoriquement être créé en API/console avec `avis_recu = false` sans motif. Pas de risque utilisateur car l'UI force la sélection.
- L'import ne valide pas que `motif_absence` est dans `MOTIFS_ABSENCE`. À envisager si l'on observe des dérives.

**Évolutions futures possibles (out of scope)** :

- Filtre dédié `avis_recu` dans l'UI.
- Catégorie distincte dans les helpers de restitutions.
- Refactorisation des boutons en partial commun (`_form_buttons.html.erb`).
- Refactorisation des 4 partials en un partial paramétré par phase.
- Validations modèle Rails pour durcir l'API.
