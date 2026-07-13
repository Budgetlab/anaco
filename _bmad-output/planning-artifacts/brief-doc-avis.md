# Brief de cadrage — Documentation « Avis »

> À transmettre à **Paige (Tech Writer)** via `/tech-writer` → `WD`.
> Projet : **avisbop** (Rails 8.1 + DSFR).
> **Langue de sortie : français** (override du défaut BMM `document_output_language: English`).
> **Périmètre : strictement l'existant** — aucune mention des TODO ou évolutions à venir.
> **Livrable : document unique** `docs/feature-avis.md`.

---

## 1. Objectif du document

Produire un **guide de référence et d'utilisation** de la fonctionnalité **Avis** d'avisbop, couvrant :

- la création d'un avis (toutes les phases du cycle de vie),
- la visualisation (historique, consultation, détail),
- la consultation par les DCB et le passage à l'état « Lu »,
- les tableaux de bord et restitutions associés,
- les imports/exports administrateur.

Le document doit servir à la fois de **référence technique** (pour les développeurs entrants) et de **guide fonctionnel** (pour comprendre le métier).

---

## 2. Audience

Trois lectures possibles, à distinguer si pertinent :

1. **Développeur entrant** sur le projet → cherche modèles, routes, contrôleur, vues, helpers.
2. **Product owner / métier (CBR, DCB)** → cherche le parcours utilisateur et les règles métier.
3. **Administrateur** → cherche les opérations d'import/export et de back-up.

---

## 3. Périmètre fonctionnel (à couvrir)

### 3.1 Modèle de données — `Avi`

- Fichier : `app/models/avi.rb`
- Attributs principaux :
  - **Cycle** : `phase`, `statut`, `etat`, `annee`
  - **Financier** : `ae_i`/`ae_f`, `cp_i`/`cp_f`, `t2_i`/`t2_f`, `etpt_i`/`etpt_f`
  - **Dates** : `date_envoi`, `date_reception`, `duree_prevision` (défaut 12 mois)
  - **Flags** : `is_delai`, `is_crg1`
  - **Liens** : `bop_id`, `user_id`, `commentaire`
- Associations : `belongs_to :bop`, `belongs_to :user`
- Callback : `before_save :set_etat_avis` — passe automatiquement à « Brouillon » si champs requis manquants.

### 3.2 Cycle de vie (états & phases)

**États (`etat`)** :
1. **Brouillon** (incomplet, auto-déterminé)
2. **En attente de lecture** (soumis par CBR)
3. **Lu** (validé par DCB)

**Phases (`phase`)** — workflow métier :
1. **Début de gestion** — phase initiale (requiert `date_reception`, `date_envoi`, `statut`)
2. **CRG1** — conditionnel à `is_crg1 = true`
3. **CRG2** — suit CRG1
4. **Services votés** — piste secondaire, multi-versions numérotées
5. **Exécution** — N-1, auto-alimenté depuis « début de gestion »

→ **Diagramme attendu** : un Mermaid `stateDiagram` pour les états et un autre pour l'enchaînement des phases (voir `MG` en complément).

### 3.3 Statuts métier (`statut`)

À documenter en tableau, avec couleur de badge (cf. `app/helpers/avis_helper.rb` → `badge_class_for_statut`) :
Favorable, Favorable avec réserve, Défavorable, Aucun risque, Risques éventuels ou modérés, Risques modérés, Risques certains ou significatifs, Risques significatifs.

### 3.4 Parcours utilisateur

#### Création (CBR)
- Route : `GET /bops/:bop_id/avis/new` → `avis#new`
- Vue : `app/views/avis/new.html.erb` + form partial sélectionné par `set_form_phase`
- Formulaires phase-spécifiques :
  - `_form_debut.html.erb`
  - `_form_crg1.html.erb`
  - `_form_crg2.html.erb`
  - `_form_services_votes.html.erb`
  - `_form_execution.html.erb`
  - `_form_chiffres.html.erb` (sous-formulaire chiffres partagé)
- Soumission : `POST /bops/:bop_id/avis/:id` → `avis#create`

#### Édition / Suppression
- `GET /bops/:bop_id/avis/:id/edit` → `avis#edit`
- `PATCH /bops/:bop_id/avis/:id` → `avis#update` (préserve l'état si finalisé)
- `DELETE /bops/:bop_id/avis/:id` → `avis#destroy` (uniquement si « Brouillon » + propriétaire ou admin)

#### Visualisation
- **Détail** : `GET /avis/:id` → `avis#show`
- **Historique (CBR)** : `GET /historique` → `avis#index` (Ransack + Pagy 15/page + export Excel)
- **Consultation (DCB)** : `GET /consultation` → `avis#consultation` (onglets : en attente / lus)
- **Vue programme** : `GET /programmes/:id/avis` → `programmes#show_avis`

#### Marquage comme lu (DCB)
- `POST /update_etat` → `avis#update_etat` (unitaire ou en masse)

#### Tableaux de bord
- `GET /remplissage_avis` — formulaire principal, regroupe BOPs actifs/inactifs
- `GET /suivi_remplissage_avis` — supervision par contrôleur / DCB
- `GET /restitutions` — niveau national, programmes déconcentrés
- `GET /restitutions_perimetre` — restitutions à périmètre utilisateur

#### Administration
- `POST /import_avis` → `avis#import` (admin)
- `GET /export_avis` → `avis#export_avis` (admin, par année)
- `GET /admin_back_up_avis` → `avis#admin_back_up_avis`

### 3.5 Permissions

| Action | Rôle | Garde |
|---|---|---|
| CRUD propre | CBR | `redirect_unless_bop_controller` + ownership |
| Suppression | CBR/admin | uniquement si « Brouillon » et propriétaire |
| Consultation / Marquage lu | DCB | `redirect_unless_dcb` |
| Import / Export / Backup | admin | `authenticate_admin!` |
| Restitutions / Dashboards | CBR, DCB | filtrage phase-aware |

### 3.6 Imports / Exports

- **Import** : `Avi.import(file)` (services votés) et `Avi.import_execution(file)` — logique embarquée dans le modèle, format tableur attendu (à documenter : **colonnes exactes attendues**, format dates via `Avi.parse_date`, gestion des erreurs de parsing).
- **Exports Excel** (Axlsx) : `index.xlsx.axlsx`, `consultation.xlsx.axlsx`, `export_avis.xlsx.axlsx`.
  - **À documenter pour chaque export** : liste exhaustive des colonnes générées, dans l'ordre, avec libellé et source (attribut modèle ou calcul). Paige doit ouvrir les trois fichiers `.axlsx` dans `app/views/avis/` et énumérer les colonnes telles que définies dans le DSL Axlsx.

---

## 4. Plan suggéré du document

```
1. Introduction
   1.1 Qu'est-ce qu'un avis ?
   1.2 Rôles concernés (CBR, DCB, admin)
   1.3 Vocabulaire métier (BOP, programme, phase, CRG, services votés)

2. Modèle de données
   2.1 Attributs
   2.2 Associations
   2.3 Callbacks et validations implicites

3. Cycle de vie d'un avis
   3.1 États (diagramme)
   3.2 Phases (diagramme)
   3.3 Statuts métier (tableau + badges)

4. Création d'un avis
   4.1 Pré-requis (BOP actif, droits)
   4.2 Sélection automatique du formulaire (set_form_phase)
   4.3 Formulaires par phase (capture d'écran ou description)
   4.4 Sauvegarde, états Brouillon vs Transmis

5. Visualisation
   5.1 Historique CBR (filtres Ransack)
   5.2 Détail
   5.3 Consultation DCB (onglets en attente / lus)
   5.4 Marquage comme lu (unitaire & bulk)

6. Tableaux de bord & restitutions
   6.1 Remplissage
   6.2 Suivi
   6.3 Restitutions nationale et périmètre

7. Administration
   7.1 Import (formats attendus)
   7.2 Export Excel (3 variantes)
   7.3 Back-up

8. Référence technique
   8.1 Routes (table complète)
   8.2 Contrôleur (actions & before_actions)
   8.3 Vues & partials (arborescence)
   8.4 Helper (avis_helper.rb)

9. Annexes
   9.1 Glossaire métier
   9.2 Liens vers data-models.md, component-inventory.md
```

---

## 5. Diagrammes recommandés (à demander via `MG`)

1. **stateDiagram** — états de l'avis (`Brouillon → En attente de lecture → Lu`).
2. **flowchart** — enchaînement des phases (`Début de gestion → CRG1? → CRG2 → Services votés / Exécution`).
3. **sequenceDiagram** — création par CBR → consultation par DCB → marquage lu.

---

## 6. Sources à utiliser (ancrage projet)

- `docs/data-models.md` (section Avi)
- `docs/component-inventory.md` (templates avis)
- `docs/architecture.md` (contexte global)
- `docs/api-contracts.md` (routes sous `/anaco`)
- Code : `app/models/avi.rb`, `app/controllers/avis_controller.rb`, `app/helpers/avis_helper.rb`, `app/views/avis/*`, `config/routes.rb` (lignes 33-73).

---

## 7. Contraintes & règles éditoriales

- **Langue : français** sur tout le document (titres, corps, légendes de diagrammes).
- **Strictement l'existant** : ne pas décrire de TODO, FIXME, refactors envisagés ou évolutions à venir. Si un comportement est limité ou bancal, le décrire factuellement sans proposer de fix.
- **Ne pas inventer** : tout fait métier ou technique doit être ancré dans le code ou les docs existantes (`docs/data-models.md`, `docs/architecture.md`, etc.). Si une information manque, l'indiquer explicitement (« non documenté à ce jour ») plutôt que de combler.
- **DSFR / contexte étatique** : ton sobre, vocabulaire métier conservé tel quel (avis, BOP, CRG, CBR, DCB, services votés, début de gestion).
- **Pas de tests dans le scope** : les tests sont des placeholders (mentionner dans une note brève « état actuel des tests »).
- **Captures d'écran** : pas obligatoires en première passe ; signaler les emplacements où elles ajouteraient de la valeur.

---

## 8. Livrable attendu

- **Format** : Markdown.
- **Fichier unique** : `docs/feature-avis.md` (à l'intérieur du `project_knowledge` BMM). Pas de split.
- **Langue** : français.
- **Mise à jour** : ajouter une entrée dans `docs/index.md` sous « Generated Documentation », libellé suggéré : `- [Fonctionnalité Avis](./feature-avis.md) — Cycle de vie, création, visualisation, administration des avis`.
- **Validation** : enchaîner avec `VD` (Validate Document) après rédaction.
