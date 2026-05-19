# Story 3.2: Filtres de recherche incluant T2 — refonte Titre / Périmètre + natures T2 dans le filtre Nature

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an instructor or admin,
I want to filter the **Liste de travail** ([app/views/actes/index.html.erb](app/views/actes/index.html.erb)), the **Historique des actes** ([app/views/actes/historique.html.erb](app/views/actes/historique.html.erb)) and the **dashboard pages** (`tableau_de_bord`, `synthese_temporelle`, `synthese_anomalies`, `synthese_suspensions`) by **Titre** (T2 / HT2) and **Périmètre** (État / Organisme) using two adjacent multi-select checkbox groups, **and** filter by **Nature** including the 7 new T2 natures from the advanced-filters modal dropdown,
so that I can scope my queries to one or both titles, one or both perimeters (or any combination) on every search-capable page, and find T2 acts by nature exactly like HT2 acts.

> ℹ️ **Recadrage par rapport à l'épic** : l'épic [story 3.2](_bmad-output/planning-artifacts/epics-t2-integration.md:556) prévoyait un filtre "Titre" (HT2 / T2 / les deux) **et** un filtre "Nature" conditionnel à T2. La demande utilisateur recadrée couvre **trois changements** :
>
> 1. **Sélecteur Titre / Périmètre** côte à côte (2 groupes de cases à cocher) en remplacement du bloc radio "Vue consolidée / Vue État / Vue Organisme" — sur **Historique**, **Tableau de bord**, **Synthèse temporelle**, **Synthèse anomalies**, **Synthèse suspensions** (5 pages).
>    - **Titre** : `T2 (actes de personnel)` / `HT2 (hors actes de personnel)` — checkboxes (multi-sélection)
>    - **Périmètre** : `État` / `Organisme` — checkboxes (multi-sélection)
> 2. Sur la **Liste de travail** (`index.html.erb`), le sélecteur Périmètre existe déjà en `check_box_tag` `q_current[perimetre_in][]` — ajouter à côté un groupe identique pour le **Titre**.
> 3. **Filtre Nature** : ajouter les 7 natures T2 (`Annexe financière`, `Enveloppe limitative`, `Fongibilité asymétrique`, `ISP`, `Marché`, `Mesure transversale`, `Référentiel`) à la liste déroulante du modal "Filtres avancés" sur Liste de travail et Historique, pour que `q[nature_eq]` puisse cibler un acte T2.

## Acceptance Criteria

### AC1 — Page Historique : remplacement du bloc radio "Vue consolidée / Vue État / Vue Organisme"

**Given** je suis sur la page `actes_historique_path`
**And** le bloc actuel [historique.html.erb:17-48](app/views/actes/historique.html.erb:17) affiche trois `radio_button_tag` (`q[perimetre_eq]` valeurs `''`, `etat`, `organisme`)
**When** la story est livrée
**Then** ce bloc radio est **entièrement remplacé** par deux groupes de cases à cocher (`check_box_tag`) côte à côte au-dessus du bouton "Filtrer les résultats" :

- Label `Titre` + deux checkboxes : `T2 (actes de personnel)` (valeur `T2`) et `HT2 (hors actes de personnel)` (valeur `HT2`), nom de paramètre `q[titre_in][]`
- Label `Périmètre` + deux checkboxes : `Etat` (valeur `etat`) et `Organisme` (valeur `organisme`), nom de paramètre `q[perimetre_in][]`

**And** la disposition visuelle reproduit la maquette fournie (libellé du groupe à gauche, cases à cocher alignées horizontalement à droite, séparation visuelle entre `Titre` et `Périmètre`)
**And** les classes DSFR utilisées sont cohérentes avec le style des checkboxes Etat/Organisme existant sur `index.html.erb` ([index.html.erb:67-87](app/views/actes/index.html.erb:67)) : `fr-fieldset--inline`, `fr-checkbox-group fr-checkbox-group--md`, `fr-checkbox`, `fr-label`
**And** le formulaire continue à soumettre automatiquement à chaque changement (`onchange: 'this.form.requestSubmit()'`)

### AC2 — Page Historique : sémantique "tout coché == tout désélectionné == vue consolidée"

**Given** je suis sur la page Historique
**When** je coche les deux options d'un groupe (par exemple Titre = HT2 + T2)
**Then** la liste affiche **tous les actes** (équivalent fonctionnel à l'ancienne "Vue consolidée")
**And** quand **aucune** case du groupe `Titre` n'est cochée, le filtre `titre_in` est absent du paramètre et la liste affiche également tous les titres
**And** quand **une seule** case du groupe Titre est cochée (ex. T2), la liste n'affiche que les actes du titre coché
**And** la même logique s'applique au groupe `Périmètre`
**And** les deux filtres se cumulent (ET logique) — ex. Titre=T2 + Périmètre=État → uniquement les actes T2 avec `perimetre='etat'`
**And** par défaut au chargement initial (aucun filtre dans l'URL), **les 4 cases sont cochées** (équivalent vue consolidée) — cohérent avec le pattern actuel de la Liste de travail ([index.html.erb:70-86](app/views/actes/index.html.erb:70) où `selected_perimetres.empty?` coche tout par défaut)

### AC3 — Page Historique : conservation des autres filtres lors du clic sur Titre / Périmètre

**Given** j'ai appliqué plusieurs filtres avancés (ex. Type d'acte = visa, Exercice = 2026, Nature = ISP)
**When** je modifie une checkbox Titre ou Périmètre
**Then** le formulaire est resoumis et **tous les autres filtres restent appliqués**
**And** les hidden fields préservant les autres `q[...]` ([historique.html.erb:49-57](app/views/actes/historique.html.erb:49)) sont mis à jour pour ne pas réécrire les clés `perimetre_eq`, `perimetre_in`, ni `titre_in` (qui sont maintenant gérées par le formulaire principal)
**And** le badge "Filtres appliqués (N)" ([historique.html.erb:111](app/views/actes/historique.html.erb:111)) reflète correctement les filtres avancés actifs (Titre/Périmètre **ne comptent pas** dans ce compteur, identique à la règle existante pour `perimetre_in` dans la Liste de travail — cf. [actes_controller.rb:1507-1508](app/controllers/actes_controller.rb:1507))

### AC4 — Page Historique : ancien paramètre `q[perimetre_eq]` retiré / migré

**Given** la migration du formulaire est effectuée
**When** je recherche dans le code (`grep -rn "perimetre_eq"` sur `app/views/actes/historique.html.erb`)
**Then** **toutes** les occurrences de `q[perimetre_eq]` dans `historique.html.erb` sont supprimées ou remplacées :

- Le hidden field `q[perimetre_eq]` en ligne 345 (dans le modal des filtres avancés) est supprimé — il devient un hidden field qui rejoue `q[perimetre_in][]` (multi-valeur)
- Les branches conditionnelles `unless (@q_params || {})[:perimetre_eq] == 'etat'` (lignes 373, 750, 770) et `unless (@q_params || {})[:perimetre_eq] == 'organisme'` (ligne 756) sont **réécrites** en fonction de `Array((@q_params || {})[:perimetre_in])`. Règle de migration :
  - `:perimetre_eq == 'etat'` → équivalent : `Array(:perimetre_in) == ['etat']` (uniquement Etat sélectionné)
  - `:perimetre_eq == 'organisme'` → équivalent : `Array(:perimetre_in) == ['organisme']`
  - `:perimetre_eq.blank?` (vue consolidée) → équivalent : `Array(:perimetre_in).empty? || Array(:perimetre_in).sort == %w[etat organisme]`

**And** la sémantique d'affichage reste : un bloc/champ conditionné par "périmètre Organisme uniquement" s'affiche uniquement si **exclusivement** Organisme est coché (pas si Etat+Organisme sont tous deux cochés). Idem côté État.

> ⚠️ Le controller (`actes_controller.rb#historique`) doit aussi être mis à jour : actuellement Ransack reçoit `perimetre_eq` ; il devra recevoir `perimetre_in` à la place. Comme `perimetre` est déjà ransackable ([acte.rb:67](app/models/acte.rb:67) liste `perimetre`), `perimetre_in` est supporté par Ransack out-of-the-box. **Aucune modification** du modèle n'est requise.

### AC5 — Page Historique : filtre Titre fonctionnel côté Ransack

**Given** je coche uniquement `T2 (actes de personnel)` dans le groupe Titre
**When** la requête est soumise
**Then** l'URL contient `q[titre_in][]=T2`
**And** Ransack filtre les actes sur `titre IN ('T2')` — l'attribut `titre` est déjà déclaré ransackable ([acte.rb:67](app/models/acte.rb:67))
**And** la liste n'affiche que les actes T2
**And** le tri Ransack par `numero_utilisateur` ([historique.html.erb:267](app/views/actes/historique.html.erb:267)) continue de fonctionner sur le sous-ensemble filtré

### AC6 — Liste de travail (`index.html.erb`) : ajout du filtre Titre à côté du filtre Périmètre existant

**Given** je suis sur `actes_path` (Liste de travail)
**And** le filtre Périmètre existe déjà en `check_box_tag 'q_current[perimetre_in][]'` ([index.html.erb:67-87](app/views/actes/index.html.erb:67))
**When** la story est livrée
**Then** un groupe `Titre` de deux checkboxes (`T2 (actes de personnel)` / `HT2 (hors actes de personnel)`) est **ajouté à gauche du groupe Périmètre existant**, sur la même rangée, dans le même bloc `<div class="fr-col-12 fr-col-md-3">` ou son équivalent agrandi (`fr-col-md-6` recommandé pour accueillir les deux groupes côte à côte sans débordement)
**And** le nom de paramètre est `q_current[titre_in][]`
**And** la sémantique "tout coché ou aucun coché = pas de filtre" est strictement identique à celle déjà appliquée pour Périmètre ([index.html.erb:71](app/views/actes/index.html.erb:71)) : `selected_titres.include?('T2') || selected_titres.empty?` → coché par défaut
**And** la barre de recherche (`f.search_field :numero_formate_or...`) conserve sa largeur (`fr-col-md-9` peut être ajusté à `fr-col-md-6` selon le rendu — confirmation visuelle requise)
**And** la barre "Filtres avancés" reste accessible à droite du champ de recherche

### AC7 — Liste de travail : hidden fields préservent le nouveau filtre Titre lors d'un changement avancé

**Given** je suis sur la Liste de travail
**And** j'ai coché uniquement Titre = T2 et Périmètre = Organisme
**When** je modifie un filtre dans le modal "Filtres avancés" puis je clique "Appliquer"
**Then** la nouvelle URL conserve `q_current[titre_in][]=T2` et `q_current[perimetre_in][]=organisme`
**And** **inversement**, quand je modifie le filtre Titre/Périmètre via les checkboxes principales, les filtres avancés actifs sont préservés (le `<% if params[:q_current].present? %>` / `<% params[:q_current].each do |key, value| %>` en [index.html.erb:43-54](app/views/actes/index.html.erb:43) exclut `perimetre_in` ET doit également exclure `titre_in` pour éviter la duplication des hidden fields)

### AC8 — Liste de travail : `titre_in` n'est pas compté dans `@filtres_count`

**Given** je suis sur la Liste de travail avec uniquement Titre=T2 coché
**When** la vue calcule `@filtres_count = count_active_filters(params[:q_current])` ([actes_controller.rb:131](app/controllers/actes_controller.rb:131))
**Then** la méthode `count_active_filters` ([actes_controller.rb:1481](app/controllers/actes_controller.rb:1481)) supprime `titre_in` du compte, **comme elle supprime déjà `perimetre_in`** ([actes_controller.rb:1507-1508](app/controllers/actes_controller.rb:1507))
**And** le badge "N filtre avancé actif" ne s'incrémente pas sur un simple changement Titre

### AC9 — Default coché = équivalent vue consolidée (cohérence visuelle avec la maquette)

**Given** je charge la page Historique ou Liste de travail sans paramètres
**When** l'écran s'affiche
**Then** les 4 cases à cocher (T2, HT2, Etat, Organisme) sont **toutes cochées par défaut**
**And** aucun paramètre `titre_in`/`perimetre_in` n'est forcé dans l'URL initiale (le check vient du fait que `selected_*.empty?` rend la case cochée — pattern existant index.html.erb:72)
**And** la maquette fournie par l'utilisateur (toutes les cases bleues cochées) correspond à cet état initial

### AC10 — Pas de régression sur le filtre Périmètre existant de la Liste de travail

**Given** un user qui n'utilisait que le filtre Périmètre avant la story
**When** il décoche Etat (laisse Organisme coché)
**Then** seuls les actes `perimetre='organisme'` sont affichés (comportement inchangé)
**And** les onglets et la pagination Pagy fonctionnent comme avant
**And** la suite de tests `bundle exec rails test test/controllers/actes_controller_test.rb` reste verte sur les tests pré-existants liés à `perimetre_in`

### AC11 — Pas de régression sur la page Historique pour les utilisateurs HT2-only

**Given** un instructeur n'ayant que des actes HT2 dans son historique
**When** il ouvre `actes_historique_path` sans paramètres
**Then** toutes les cases (T2, HT2, Etat, Organisme) sont cochées par défaut → tous ses actes HT2 s'affichent
**And** s'il décoche HT2 (laisse seulement T2 coché), la liste est vide (cohérent : il n'a pas d'actes T2)
**And** s'il recoche HT2, ses actes réapparaissent
**And** le tri, la pagination, et le bouton "Télécharger les actes" ([historique.html.erb:240](app/views/actes/historique.html.erb:240)) continuent de fonctionner avec le sous-ensemble filtré

### AC12 — Tags "filtres appliqués" pour Titre (Historique uniquement)

**Given** je suis sur la page Historique et j'ai coché uniquement Titre=T2
**When** la section "Filtres appliqués (N)" se rend ([historique.html.erb:111-227](app/views/actes/historique.html.erb:111))
**Then** **aucun** tag n'est affiché pour le filtre Titre (cohérent avec AC3 et AC8 : Titre/Périmètre sont des filtres "primaires" de la barre principale, pas du modal avancé)
**And** le compteur "Filtres appliqués (N)" reste indépendant de Titre/Périmètre
**And** la logique `filter_count = [...]` ([historique.html.erb:98-106](app/views/actes/historique.html.erb:98)) n'inclut **pas** `selected_titres.any?` ni `selected_perimetres.any?`

### AC13 — Pages dashboard (`tableau_de_bord`, `synthese_temporelle`, `synthese_anomalies`, `synthese_suspensions`, `synthese_utilisateurs`) : remplacement du sélecteur radio

**Given** ces **5** pages utilisent actuellement le bloc radio "Vue consolidée / Vue État / Vue Organisme" lié à `q[perimetre_eq]` :
- [tableau_de_bord.html.erb:26-52](app/views/actes/tableau_de_bord.html.erb:26)
- [synthese_temporelle.html.erb:24-50](app/views/actes/synthese_temporelle.html.erb:24)
- [synthese_anomalies.html.erb:24-50](app/views/actes/synthese_anomalies.html.erb:24)
- [synthese_suspensions.html.erb:24-50](app/views/actes/synthese_suspensions.html.erb:24)
- [synthese_utilisateurs.html.erb:15-46](app/views/actes/synthese_utilisateurs.html.erb:15)

**When** la story est livrée
**Then** chacune de ces **5** pages voit son bloc radio remplacé par les **deux groupes de cases à cocher côte à côte** (Titre + Périmètre), avec la même structure DSFR que sur Historique (AC1)
**And** les noms de paramètres sont `q[titre_in][]` et `q[perimetre_in][]`
**And** la sémantique "tout coché par défaut == aucun filtre == vue consolidée" est appliquée (AC2 + AC9)
**And** le bouton "Filtrer les résultats" / boutons d'export / sélecteurs d'année existants restent inchangés en dessous
**And** la boucle hidden fields `<% @q_params.except(:perimetre_eq).each do |key, value| %>` (présente dans les 5 vues, lignes ~47-55 selon la vue) est mise à jour pour exclure également `:titre_in` et `:perimetre_in`

### AC14 — Pages dashboard : migration de la logique d'agrégation `perimetre_eq` → `perimetre_in`

**Given** les **5** pages dashboard contiennent des branches conditionnelles basées sur `@q_params[:perimetre_eq]` (controller ET vues) :
- Controller `synthese_temporelle` ([actes_controller.rb:556, 591, 604](app/controllers/actes_controller.rb:556)) : 3 branches `blank?` / `== 'etat'` / `== 'organisme'` pour construire les séries du graphique délais.
- Controller `synthese_utilisateurs` ([actes_controller.rb:965](app/controllers/actes_controller.rb:965)) : `@selected_perimetre = @q_params[:perimetre_eq].presence` (scalaire) passé en argument à `user_ht2_stats(... @selected_perimetre ...)` ([lignes 969-970](app/controllers/actes_controller.rb:969)). Le helper `user_ht2_stats` ([actes_controller.rb:1399-1432](app/controllers/actes_controller.rb:1399)) consomme ce scalaire ligne 1402 : `actes_user.where(perimetre: perimetre)`. Rails ActiveRecord `where(col: array)` génère `IN (...)`, donc on peut **passer un array directement** sans rien changer au helper — seul l'appelant change.
- Vue `tableau_de_bord.html.erb` lignes [613, 723, 793](app/views/actes/tableau_de_bord.html.erb:613) : 2 branches `== 'etat'` et `== 'organisme'`, plus 1 hidden_field `:perimetre_eq` ligne 793.
- Vue `synthese_temporelle.html.erb` lignes [225, 241, 270](app/views/actes/synthese_temporelle.html.erb:225) : idem.
- Vue `synthese_anomalies.html.erb` lignes [278, 308, 351](app/views/actes/synthese_anomalies.html.erb:278) : idem.
- Vue `synthese_suspensions.html.erb` lignes [328, 344, 373](app/views/actes/synthese_suspensions.html.erb:328) : idem.
- Vue `synthese_utilisateurs.html.erb` ligne [257](app/views/actes/synthese_utilisateurs.html.erb:257) : 1 hidden_field `:perimetre_eq`. **Pas** de branche conditionnelle dans la vue (toute la logique est dans le helper `user_ht2_stats`).

**When** la migration est effectuée
**Then** la sémantique cible est :
- "Tout coché" (Etat ET Organisme) ou "rien coché" → équivalent ancien `perimetre_eq.blank?` (vue consolidée, 3 courbes/agrégats)
- "Etat uniquement coché" → équivalent ancien `perimetre_eq == 'etat'` (1 courbe État)
- "Organisme uniquement coché" → équivalent ancien `perimetre_eq == 'organisme'` (1 courbe Organisme)

**And** la logique de branchement dans le **controller `synthese_temporelle`** est réécrite en s'appuyant sur l'array `Array(@q_params[:perimetre_in])`. Pseudo-code :
```ruby
selected = Array(@q_params[:perimetre_in]).reject(&:blank?)
mode = if selected.empty? || selected.sort == %w[etat organisme]
         :consolide
       elsif selected == ['etat']
         :etat
       elsif selected == ['organisme']
         :organisme
       end
case mode
when :consolide then series = [delais_etat, delais_organisme, delais_global]
when :etat      then series = [delais_etat]
when :organisme then series = [delais_organisme]
end
```

**And** chaque vue dashboard substitue ses `<% if @q_params[:perimetre_eq] == 'etat' %>` / `'organisme'` par le helper `perimetre_exclusively?` (cf. AC4 et Task 6) — toujours avec la sémantique "EXCLUSIVEMENT" (un seul périmètre coché) pour conserver l'affichage actuel
**And** les hidden fields `<%= f.hidden_field :perimetre_eq, value: @q_params[:perimetre_eq] %>` (présents dans chaque vue dashboard à l'intérieur du modal "Filtres avancés" pour rejouer le périmètre) sont **remplacés** par autant de `hidden_field_tag 'q[perimetre_in][]', val` (un par valeur sélectionnée) **et** `hidden_field_tag 'q[titre_in][]', val` pour le nouveau filtre Titre
**And** le filtre **Titre** étant nouveau pour ces pages, il s'applique aussi aux agrégats : ex. cocher uniquement T2 → les graphiques n'agrègent que les actes T2. Cette logique ne demande aucun code custom dans les vues : Ransack filtre déjà sur `q[titre_in]` via `@actes_filtered = @q.result(distinct: true)` qui alimente toutes les agrégations en aval

**And** le `@selected_perimetre = @q_params[:perimetre_eq].presence` ([actes_controller.rb:965](app/controllers/actes_controller.rb:965)) dans `synthese_utilisateurs` est **remplacé** par :
```ruby
selected = Array(@q_params[:perimetre_in]).reject(&:blank?)
@selected_perimetres = (selected.empty? || selected.sort == %w[etat organisme]) ? nil : selected
```
Et l'appel à `user_ht2_stats` passe `@selected_perimetres` (nil ou array) au lieu de `@selected_perimetre` (nil ou scalaire). Le helper `user_ht2_stats` ([ligne 1402](app/controllers/actes_controller.rb:1402)) `actes_user.where(perimetre: perimetre)` fonctionne identiquement avec un array (génère `IN (...)`) — **aucun changement requis** dans le helper.

### AC15 — Filtre Nature : extension de la liste déroulante avec les 7 natures T2

**Given** le modal "Filtres avancés" sur **Liste de travail** ([index.html.erb:1190](app/views/actes/index.html.erb:1190)) et **Historique** ([historique.html.erb:685](app/views/actes/historique.html.erb:685)) contient un `f.select :nature_eq` alimenté par `@liste_natures`
**And** `@liste_natures` est défini dans `set_variables_filtres` ([actes_controller.rb:1342-1379](app/controllers/actes_controller.rb:1342)) et contient actuellement **uniquement** les natures HT2 (Marchés, Subventions, Conventions, etc.)
**When** la story est livrée
**Then** `@liste_natures` est étendu pour inclure les **7 natures T2** :
- `Annexe financière`
- `Enveloppe limitative`
- `Fongibilité asymétrique`
- `ISP`
- `Marché` ⚠️ collision avec d'éventuelles natures HT2 — voir Dev Notes
- `Mesure transversale`
- `Référentiel`

**And** la liste est triée par ordre alphabétique pour la lisibilité (ou groupée HT2/T2 via `optgroup` si jugé plus clair en revue — décision : alphabétique simple par défaut, KISS)
**And** le filtre fonctionne pour les utilisateurs qui sélectionnent une nature T2 : `q[nature_eq]=ISP` → seuls les actes T2 de nature ISP apparaissent (Ransack filtre via `WHERE nature = 'ISP'`)
**And** **aucune** modification du formulaire de saisie (`_form_informations.html.erb`, `_form_informations_organisme.html.erb`, `_form_informations_t2.html.erb`) n'est introduite : ces vues utilisent le `@liste_natures` défini dans `set_variables_form` (lignes 1228-1312), qui est **distinct** et filtre déjà la nature par titre HT2/T2. **NE PAS MÉLANGER** les deux

> ⚠️ **Collision potentielle** : la valeur `'Marché'` (nature T2) doit être distincte des natures HT2 `'Marché unique'`, `'Marché à tranches'`, etc. déjà présentes. Vérifier en BDD qu'aucun acte HT2 n'a `nature = 'Marché'` (sinon le filtre va remonter des HT2 quand l'utilisateur sélectionne "Marché" en pensant cibler du T2). Si collision détectée, deux options :
> - (A) Renommer la nature T2 affichée en `Marché (PSC)` dans la liste déroulante mais conserver `Marché` en valeur stockée (cohérent avec [epics-t2-integration.md:373](_bmad-output/planning-artifacts/epics-t2-integration.md:373) qui parle de "Marché (PSC)").
> - (B) Filtrer par `titre+nature` combiné si l'utilisateur sélectionne une nature T2 (plus complexe, surcharge le filtre Nature).
>
> **Décision proposée** : (A) — afficher `Marché (PSC)` dans la liste avec valeur `Marché`, en suivant le pattern epic. Confirmer en revue.

### AC16 — Pas de régression sur le formulaire de saisie

**Given** un instructeur crée un nouvel acte HT2 ou T2
**When** il sélectionne la nature dans le formulaire de saisie ([_form_informations_t2.html.erb:27](app/views/actes/_form_informations_t2.html.erb:27))
**Then** la liste déroulante reste **filtrée par titre + périmètre + profil** comme avant (cf. `set_variables_form` lignes 1228-1340)
**And** **aucun** mélange avec la liste étendue du filtre n'est introduit dans le formulaire de saisie
**And** les tests existants sur le formulaire de création passent toujours

## Tasks / Subtasks

- [x] **Task 1 : Page Historique — refonte du sélecteur principal** (AC: 1, 2, 3, 4, 5, 11, 12)
  - [x] `<fieldset>` lignes 17-48 remplacé par 2 groupes côte à côte Titre+Périmètre, format `fr-fieldset--inline` + `fr-checkbox-group` (pattern Liste de travail). Hidden fields lignes 49-57 mis à jour pour `except(:titre_in, :perimetre_in, :perimetre_eq)`. Hidden field `q[perimetre_eq]` ligne 345 du modal remplacé par des boucles `Array(@q_params[:titre_in/perimetre_in]).each` rejouant les checkboxes principales.

- [x] **Task 2 : Page Historique — migration `perimetre_eq` → `perimetre_in` dans les branches conditionnelles** (AC: 4)
  - [x] 5 occurrences `unless (@q_params || {})[:perimetre_eq] == ...` substituées par `unless perimetre_exclusively?(@q_params, ...)` (lignes 396, 773, 779, 793, 799 après refactor). `grep -n perimetre_eq historique.html.erb` ne retourne plus que la clause `except(...)` (cleanup intentionnel).

- [x] **Task 3 : Page Historique — ajustement controller** (AC: 5, 11)
  - [x] `actes_controller.rb#historique` ne référence pas `perimetre_eq` dans sa logique métier — Ransack reçoit `titre_in` et `perimetre_in` (attributs déjà ransackable sur `Acte`). Aucune modification controller nécessaire.

- [x] **Task 4 : Liste de travail — ajout du filtre Titre** (AC: 6, 7, 8, 9, 10)
  - [x] Bloc `Titre` ajouté à gauche du bloc Périmètre dans `index.html.erb`. Layout colonnes `fr-col-md-6` (search) + `fr-col-md-6` (filtres Titre + Périmètre) pour accueillir les 4 cases. Boucle hidden fields ligne 45 mise à jour pour exclure également `titre_in`.

- [x] **Task 5 : Liste de travail — `count_active_filters` ignore `titre_in`** (AC: 8)
  - [x] `q.delete("titre_in")` et `q.delete(:titre_in)` ajoutés dans `count_active_filters` ([actes_controller.rb:1508-1509](app/controllers/actes_controller.rb:1508)) à côté des lignes `perimetre_in`. La méthode est appelée pour `params[:q_current]` (index) et `params[:q]` (historique) — couvre les 2 pages.

- [x] **Task 6 : Helper `perimetre_exclusively?`** (AC: 4)
  - [x] Ajouté dans [app/helpers/actes_helper.rb:207-213](app/helpers/actes_helper.rb:207) la méthode `perimetre_exclusively?(q_params, target)` qui lit `Array((q_params || {})[:perimetre_in]).reject(&:blank?) == [target]`.
  - [x] (Skip optionnel) `titre_exclusively?` non implémenté — aucune branche conditionnelle existante n'en a besoin.

- [x] **Task 7 : Tests controller** (AC: 5, 6, 10, 11)
  - [x] Section `# Story 3.2` ajoutée dans `actes_controller_test.rb` avec helper `create_mixte_set` + 7 tests : AC9 (4 cases cochées par défaut sur index), AC5/AC6 (titre_in=T2 filtre), AC2 (les 2 cochés == pas de filtre), AC10 (regression perimetre_in=etat), AC8 (titre_in non compté dans filtres_count), AC5 historique titre_in=T2, AC9 historique 4 cases.

- [x] **Task 8 : Tests helper** (AC: 4)
  - [x] 5 tests `perimetre_exclusively?` ajoutés dans [test/helpers/actes_helper_test.rb:46-72](test/helpers/actes_helper_test.rb:46) — couvre target unique, both selected, empty, nil, target absent. `bundle exec rails test test/helpers/actes_helper_test.rb` → 8 runs / 32 assertions / 0 failures.

- [x] **Task 9 : Pages dashboard — refonte du sélecteur (5 vues)** (AC: 13)
  - [x] 5 vues (`tableau_de_bord`, `synthese_temporelle`, `synthese_anomalies`, `synthese_suspensions`, `synthese_utilisateurs`) : bloc `<fieldset>` radio remplacé par les 2 groupes Titre+Périmètre. Boucle hidden fields mise à jour pour exclure `:titre_in, :perimetre_in, :perimetre_eq`.

- [x] **Task 10 : Pages dashboard — migration de la logique d'agrégation `perimetre_eq` → `perimetre_in`** (AC: 14)
  - [x] Controller `synthese_temporelle` ([actes_controller.rb:554-562](app/controllers/actes_controller.rb:554)) : calcul d'un `perimetre_mode` ∈ `{:consolide, :etat, :organisme}` à partir de `Array(@q_params[:perimetre_in]).reject(&:blank?)`. Les 3 branches `if perimetre_mode == ...` produisent 3 séries / 1 série Etat / 1 série Organisme selon le mode.
  - [x] Controller `synthese_utilisateurs` ([actes_controller.rb:977-984](app/controllers/actes_controller.rb:977)) : `@selected_perimetres` calculé en array (`nil` si consolidée, sinon `['etat']` ou `['organisme']`). Les 2 appels à `user_ht2_stats` reçoivent l'array — le helper `where(perimetre: array)` génère `IN (...)` natif. Helper non modifié.
  - [x] Vues `tableau_de_bord.html.erb`, `synthese_temporelle.html.erb`, `synthese_anomalies.html.erb`, `synthese_suspensions.html.erb` : 8 branches `if @q_params[:perimetre_eq] == ...` substituées par `if perimetre_exclusively?(@q_params, ...)`. `synthese_utilisateurs.html.erb` n'a pas de branche vue (toute la logique est dans le helper).
  - [x] 5 hidden fields modaux substitués par des boucles `Array(@q_params[:titre_in/perimetre_in]).each` rejouant les paramètres array.

- [x] **Task 11 : Étendre `@liste_natures` avec les natures T2 dans `set_variables_filtres`** (AC: 15, 16)
  - [x] `set_variables_filtres` ([actes_controller.rb:1342-1395](app/controllers/actes_controller.rb:1342)) refactor : passage au format `[[label, value], ...]` pour permettre `["Marché (PSC)", "Marché"]`. 35 natures HT2 + 7 natures T2 (Annexe financière, Enveloppe limitative, Fongibilité asymétrique, ISP, Marché (PSC), Mesure transversale, Référentiel). Tri alphabétique final via `.sort_by { |label, _| label }`.
  - [x] Vérif collision : `bundle exec rails runner "puts Acte.where(titre:'HT2', nature:'Marché').count"` → **0** acte HT2 avec nature exacte `Marché`. La valeur `Marché` peut être stockée sans risque pour les T2.
  - [x] `set_variables_form` ([actes_controller.rb:1217-1340](app/controllers/actes_controller.rb:1217)) non touché — sépare strictement saisie vs. filtre. Les partials `_form_informations.html.erb`, `_form_informations_organisme.html.erb`, `_form_informations_t2.html.erb` continuent de recevoir des strings via `set_variables_form` (qui est dans `before_action only: [:edit, :validate_acte]` + appelé directement dans `create`).
  - [x] Vues consommatrices ([index.html.erb:1211](app/views/actes/index.html.erb:1211) et [historique.html.erb:708](app/views/actes/historique.html.erb:708)) **inchangées** : `options_for_select` gère nativement les tuples `[label, value]`.

- [x] **Task 12 : Tests étendus** (AC: 13, 14, 15)
  - [x] 9 tests Story 3.2 supplémentaires : AC13 tableau_de_bord (4 checkboxes rendues), AC14 synthese_temporelle 4 scénarios (vue consolidée / etat+organisme / etat seul / organisme seul → 3/3/1/1 séries vérifiées via extraction `data-highcharts-actes-dataset-value`), AC14 synthese_utilisateurs (rendu OK sur 4 combinaisons), AC13 synthese_utilisateurs admin checkboxes, AC15 liste déroulante Nature contient 7 natures T2 (assertions sur `<option value=...>`), AC15 historique?q[nature_eq]=ISP filtre uniquement T2 ISP, AC16 régression saisie new_acte_path.

- [ ] **Task 13 : Vérification manuelle** (AC: 1, 6, 9, 13, 14, 15)
  - [ ] **Non exécutée** (test automatisé exhaustif couvre tous les ACs critiques). Smoke check navigateur recommandé avant merge :
    - `/actes` : 4 checkboxes côte à côte au-dessus de la barre de recherche
    - `/actes/historique` : bloc radio remplacé par les 2 groupes côte à côte
    - `/actes/tableau_de_bord`, `synthese_*` : idem (5 vues)
    - Liste Nature contient `Marché (PSC)`, `ISP`, etc.
    - `/actes/new` formulaire saisie inchangé (T2 hors contrat : 7 natures filtrées correctement)

### Review Follow-ups (AI)

Revue adversariale du 2026-05-19 — 3 HIGH + 4 MEDIUM + 3 LOW trouvées. HIGH + MEDIUM fixés ci-dessous, LOW laissés en suivi.

- [x] [AI-Review][HIGH] AC7 cassé sur Liste de travail : le modal "Filtres avancés" ne préservait pas `titre_in` → fix dans [index.html.erb:891-901](app/views/actes/index.html.erb:891)
- [x] [AI-Review][HIGH] `synthese_utilisateurs` rendait les checkboxes Titre mais ignorait le filtre → propagation du paramètre `titre` dans `user_ht2_stats` ([actes_controller.rb:1428](app/controllers/actes_controller.rb:1428)) + calcul de `@selected_titres` dans l'action ([actes_controller.rb:980-983](app/controllers/actes_controller.rb:980))
- [x] [AI-Review][HIGH] Tests "checked by default" ne distinguaient pas le scénario "une case décochée" → 2 nouveaux tests AC9bis (`titre_in=[T2]` → `titre-ht2:not([checked])`, `perimetre_in=[organisme]` → `perimetre-etat:not([checked])`)
- [x] [AI-Review][MEDIUM] Inconsistance `.reject(&:blank?)` entre vues → ajouté sur [index.html.erb:67-68](app/views/actes/index.html.erb:67)
- [x] [AI-Review][MEDIUM] Aucun test ne vérifiait les hidden_field du modal des dashboards → test AC7bis qui boucle sur 4 vues dashboard + assert sur les hidden `q[titre_in][]` et `q[perimetre_in][]`
- [x] [AI-Review][MEDIUM] Test AC16 ne touchait pas le partial T2 → nouveau test qui rend `_form_informations_t2` via `new_acte_path(titre: 'T2', perimetre: 'etat')` et asserte les 7 `option[value=X]:text=X` (verrouille `set_variables_form` en strings)
- [ ] [AI-Review][LOW] Task 13 (smoke check navigateur) non exécutée — recommandée avant merge
- [ ] [AI-Review][LOW] Commentaires `# Story 3.2 — ...` verbeux à nettoyer post-merge
- [ ] [AI-Review][LOW] Accessibilité : les `<fieldset>` n'ont pas de `<legend>` sémantique (les `<span class="fr-label">` servent de label visuel uniquement) — vérifier spec DSFR et envisager `<legend class="fr-sr-only">` pour lecteurs d'écran

> ℹ️ MEDIUM **M2** (docstring `perimetre_exclusively?` ne couvre pas les clés string) laissé tel quel : l'usage actuel passe systématiquement `@q_params` post-`to_unsafe_h.deep_dup` (clés symboles). Risque théorique uniquement.

## Dev Notes

### Architecture du filtre — modèle existant à étendre

- L'attribut `titre` est déjà déclaré ransackable sur `Acte` ([acte.rb:67](app/models/acte.rb:67)) — `q[titre_in]` (multi-select Ransack) fonctionne **out-of-the-box** sans modification du modèle.
- L'attribut `perimetre` est également déjà ransackable et déjà utilisé en `perimetre_in` sur la Liste de travail ([index.html.erb:70](app/views/actes/index.html.erb:70)).
- La sémantique cible "tout coché == aucun filtre == vue consolidée" est **déjà implémentée** sur la Liste de travail (cf. `selected_perimetres.include?('etat') || selected_perimetres.empty?` qui force le check par défaut). Reproduire exactement ce pattern.

### Pourquoi `titre_in` (array) et pas `titre_eq` (scalaire) ?

Trois raisons :

1. La maquette utilisateur impose 2 checkboxes (donc multi-sélection : T2 OR HT2 OR les deux).
2. Cohérence avec le pattern existant `perimetre_in` sur la Liste de travail.
3. Avec un scalaire `titre_eq`, on devrait gérer 3 états (T2 / HT2 / les deux) — ce qui force soit un radio (régression vs. checkbox), soit une logique applicative custom. `titre_in` est natif Ransack et plus simple.

### Migration `perimetre_eq` (scalaire) → `perimetre_in` (array) — pièges identifiés

1. **Branches conditionnelles existantes** : 4 occurrences dans `historique.html.erb` (lignes 373, 750, 756, 770) testent `:perimetre_eq == 'etat'` ou `:perimetre_eq == 'organisme'`. **Toutes** ces branches doivent être réécrites en `perimetre_exclusively?(...)` — sinon les blocs "Catégorie (Organisme uniquement)" s'affichent à tort quand les deux périmètres sont cochés.
2. **Synthese / tableau de bord** : NE PAS toucher — leur logique aggrégation est plus complexe (cf. AC13). Si on migre tout, on casse les graphiques. Une story `3.2-bis` peut être créée plus tard.
3. **Anciens bookmarks** : si un utilisateur a un bookmark avec `?q[perimetre_eq]=etat`, après cette story le paramètre sera ignoré par Ransack (clé inconnue → no-op silencieux). Pas critique mais à signaler en release notes si nécessaire.
4. **`historique.html.erb:345`** : le modal "Filtres avancés" rejoue actuellement `q[perimetre_eq]` en hidden field pour préserver le filtre principal lors d'une re-soumission via le modal. Il faudra rejouer `q[titre_in][]` et `q[perimetre_in][]` (potentiellement plusieurs hidden fields, un par valeur sélectionnée).

### Pattern de référence à suivre (Liste de travail)

Le code [index.html.erb:67-87](app/views/actes/index.html.erb:67) est le **gold standard** pour cette story. Reproduire la même structure pour Titre, en pré-pendant au bloc Périmètre :

```erb
<div class="fr-fieldset--inline">
  <% selected_titres = Array(params.dig(:q_current, :titre_in)) %>
  <span class="fr-label fr-text--bold fr-mr-1w">Titre</span>
  <div class="fr-checkbox-group fr-checkbox-group--md">
    <%= check_box_tag 'q_current[titre_in][]', 'T2',
                      selected_titres.include?('T2') || selected_titres.empty?,
                      class: "fr-checkbox", id: "titre-t2",
                      onchange: 'this.form.requestSubmit()' %>
    <label class="fr-label" for="titre-t2">T2 (actes de personnel)</label>
  </div>
  <div class="fr-checkbox-group fr-checkbox-group--md">
    <%= check_box_tag 'q_current[titre_in][]', 'HT2',
                      selected_titres.include?('HT2') || selected_titres.empty?,
                      class: "fr-checkbox", id: "titre-ht2",
                      onchange: 'this.form.requestSubmit()' %>
    <label class="fr-label" for="titre-ht2">HT2 (hors actes de personnel)</label>
  </div>
  <!-- ... puis le bloc Périmètre existant inchangé ... -->
</div>
```

Pour la page Historique, utiliser `q[titre_in][]` et `q[perimetre_in][]` (pas `q_current`), et envelopper dans un `<fieldset class="fr-fieldset">` cohérent avec la structure existante.

### Sémantique "0 ou 2 cases cochées = pas de filtre"

Quand l'utilisateur coche les 2 cases du groupe Titre (T2+HT2), Ransack reçoit `titre_in=['T2','HT2']`. SQL : `WHERE titre IN ('T2','HT2')`. Comme `titre` ne peut être que `'T2'` ou `'HT2'` ([acte.rb:87](app/models/acte.rb:87) `inclusion: { in: %w[HT2 T2] }`), c'est équivalent à pas de filtre. **Pas besoin de logique applicative supplémentaire** : Ransack et la BDD font le job.

Quand 0 case est cochée (l'utilisateur décoche les 2), `params[:q_current][:titre_in]` n'est pas envoyé (HTML form n'envoie pas un array vide pour des checkboxes non cochées). Ransack reçoit `nil` → pas de filtre. Comportement attendu.

### Project Structure Notes

- Pas de migration BDD (les colonnes `titre` et `perimetre` existent déjà).
- Pas de modification du modèle `Acte` (ransackable déjà OK).
- Modifications limitées à : 2 vues (`index.html.erb`, `historique.html.erb`), 1 helper (`actes_helper.rb`), 1 ligne controller (`count_active_filters`).
- Pas de Stimulus controller à toucher (la logique se passe via `form.requestSubmit()` natif).

### Testing standards

- Tests d'intégration controller via Minitest ([test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)).
- Pour créer un T2 valide minimal dans un test : `titre: 'T2'`, `categorie_t2: 'hors contrat'`, `nature: 'ISP'` (ou autre nature valide), `type_acte: 'avis'`, `etat: "en pré-instruction"`, `annee: Date.today.year`, `instructeur: 'AB'`. Pour `nature == 'Marché' && perimetre == 'etat'` ajouter `montant_ae: 1000` ([acte.rb:90](app/models/acte.rb:90)).
- Le helper test peut vivre dans [test/helpers/actes_helper_test.rb](test/helpers/actes_helper_test.rb) (créé en Story 3.1) — utiliser `class ActesHelperTest < ActionView::TestCase`.

### Pages dashboard — sémantique des graphiques sous filtres array

La logique d'agrégation actuelle (controller `synthese_temporelle`) construit **3 séries** en mode consolidé : `delais_etat`, `delais_organisme`, `delais_global`. Le passage à `perimetre_in` array doit préserver cette UX. Mapping recommandé :

| `Array(perimetre_in)` (après reject blank) | Mode | Séries affichées |
|---|---|---|
| `[]` (rien coché) | `:consolide` | 3 (Etat / Organisme / Consolidé) |
| `['etat', 'organisme']` (tout coché) | `:consolide` | 3 (Etat / Organisme / Consolidé) |
| `['etat']` | `:etat` | 1 (Délai moyen État) |
| `['organisme']` | `:organisme` | 1 (Délai moyen Organisme) |

Côté **vues**, les 8 occurrences de `if @q_params[:perimetre_eq] == 'etat'` / `'organisme'` (tableau_de_bord:613,723 ; synthese_temporelle:225,241 ; synthese_anomalies:278,308 ; synthese_suspensions:328,344) se traduisent toutes par `if perimetre_exclusively?(@q_params, 'etat')` / `'organisme'` — ces blocs cachent des sous-tableaux ou des chiffres "uniquement quand on est en vue État seule", la sémantique exclusive doit être préservée à l'identique.

**Particularité `synthese_utilisateurs`** : pas de branche conditionnelle dans la vue — toute la logique d'agrégation est encapsulée dans le helper `user_ht2_stats` ([actes_controller.rb:1399-1432](app/controllers/actes_controller.rb:1399)). Comme `actes_user.where(perimetre: array)` génère un `IN (...)` SQL valide, on **peut passer un array directement** au helper sans le modifier. Seul l'appelant change ([actes_controller.rb:965-970](app/controllers/actes_controller.rb:965)) : le scalaire `@selected_perimetre` devient un array `@selected_perimetres` (ou `nil` en vue consolidée pour skipper la clause `where`).

### Filtre Nature étendu — `set_variables_filtres` vs. `set_variables_form` (NE PAS confondre)

La codebase distingue deux contextes :

| Méthode | Ligne | Utilisé par | Contenu actuel |
|---|---|---|---|
| `set_variables_form` | [1217-1340](app/controllers/actes_controller.rb:1217) | `new`, `edit`, `validate_acte` (formulaire de saisie) | Filtré par titre/périmètre/profil — adapté à ce que l'utilisateur peut SAISIR |
| `set_variables_filtres` | [1342-1379](app/controllers/actes_controller.rb:1342) | `index`, `historique`, `tableau_de_bord`, `synthese_*` (pages de recherche/dashboard) | Liste **complète** HT2 — ne contient PAS encore les natures T2 → à corriger |

**La modification doit uniquement toucher `set_variables_filtres`**. Le formulaire de saisie continue d'utiliser sa propre liste filtrée par contexte (cf. AC16).

### Filtre Nature — alphabétique vs. groupé (optgroup)

Décision par défaut : **alphabétique simple**. Justification : la liste actuelle HT2 est déjà alphabétique, intercaler 7 natures T2 (Annexe financière, Enveloppe limitative, Fongibilité asymétrique, ISP, Marché (PSC), Mesure transversale, Référentiel) garde la cohérence visuelle. Un groupement via `optgroup` HT2/T2 serait plus didactique mais ajoute du markup pour un gain limité — à reconsidérer en revue si l'utilisateur le demande.

### Collision `Marché` (T2) vs. natures HT2 `Marché unique` / `Marché à tranches`

Vérification BDD à exécuter avant la story :
```sh
bundle exec rails runner "puts Acte.where(titre: 'HT2', nature: 'Marché').count"
```
- Si `0` → aucun risque, on peut utiliser la valeur stockée `Marché` pour la nature T2.
- Si `> 0` → renommer la nature T2 stockée (`Marché PSC` par exemple) — implique une migration des actes T2 déjà créés (Story 2.6).

Décision provisoire : afficher `Marché (PSC)` en libellé, conserver `Marché` en valeur stockée (compatible avec [acte.rb:90](app/models/acte.rb:90) qui valide `nature == 'Marché'` pour les T2). La distinction visuelle dans la liste déroulante évite la confusion utilisateur.

### Hors scope — à confirmer en review

- `avis_controller.rb` / pages avis (si présentes) — non concernées (cette story = scope `actes` uniquement). Vérifier en revue qu'aucune page avis n'utilise un sélecteur `q[perimetre_eq]` similaire ; si oui, créer une story dédiée (`3.2-bis avis`).
- Filtres "Catégorie T2" (Contrat / Hors contrat) — non demandé dans le scope user.
- Affichage de tags `fr-tag--filtres` pour Titre / Périmètre dans la section "Filtres appliqués" — décision : NON (cohérent avec AC12 et la règle existante qui exclut `perimetre_in` du compteur).
- Optgroup HT2/T2 dans la liste Nature — à reconsidérer si demandé en revue.

### References

- Epic spec — Story 3.2 (recadrée par demande utilisateur) : [_bmad-output/planning-artifacts/epics-t2-integration.md:556](_bmad-output/planning-artifacts/epics-t2-integration.md:556)
- Vue Historique (cible principale) : [app/views/actes/historique.html.erb](app/views/actes/historique.html.erb), bloc filtre principal lignes [17-48](app/views/actes/historique.html.erb:17)
- Vue Liste de travail (filtre Périmètre de référence) : [app/views/actes/index.html.erb:67-87](app/views/actes/index.html.erb:67)
- Controller `historique` : [app/controllers/actes_controller.rb:150](app/controllers/actes_controller.rb:150)
- Controller `index` : [app/controllers/actes_controller.rb:17](app/controllers/actes_controller.rb:17)
- Modèle Acte (`titre` ransackable, validations `titre IN HT2/T2`) : [app/models/acte.rb:67-87](app/models/acte.rb:67)
- Méthode `count_active_filters` : [app/controllers/actes_controller.rb:1481](app/controllers/actes_controller.rb:1481)
- Helper de référence (Story 3.1) : [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb)
- Pages dashboard à migrer (cf. AC13-14) :
  - [tableau_de_bord.html.erb:26-52](app/views/actes/tableau_de_bord.html.erb:26) + branches 613, 723, 793
  - [synthese_temporelle.html.erb:24-50](app/views/actes/synthese_temporelle.html.erb:24) + branches 225, 241, 270
  - [synthese_anomalies.html.erb:24-50](app/views/actes/synthese_anomalies.html.erb:24) + branches 278, 308, 351
  - [synthese_suspensions.html.erb:24-50](app/views/actes/synthese_suspensions.html.erb:24) + branches 328, 344, 373
  - [synthese_utilisateurs.html.erb:15-46](app/views/actes/synthese_utilisateurs.html.erb:15) + hidden field 257 (pas de branche conditionnelle vue ; logique métier déplacée en controller)
- Controller `synthese_temporelle` (logique d'agrégation 3 branches) : [actes_controller.rb:556-616](app/controllers/actes_controller.rb:556)
- Controller `synthese_utilisateurs` (scalar → array) : [actes_controller.rb:954-971](app/controllers/actes_controller.rb:954)
- Helper `user_ht2_stats` (consomme l'array sans modif) : [actes_controller.rb:1399-1432](app/controllers/actes_controller.rb:1399)
- `set_variables_filtres` (où étendre `@liste_natures`) : [actes_controller.rb:1342-1379](app/controllers/actes_controller.rb:1342)
- `set_variables_form` (NE PAS toucher) : [actes_controller.rb:1217-1340](app/controllers/actes_controller.rb:1217)

### Previous Story Intelligence (Story 3.1)

- Story 3.1 a ajouté la **colonne** Titre sur les listings (badge HT2 / T2) — donc l'utilisateur voit déjà le titre par ligne. Cette story 3.2 ajoute la **capacité de filtrer** par titre. Cohérence UX : la valeur affichée dans la colonne (HT2/T2) doit matcher la valeur du filtre (T2/HT2) — bien utiliser exactement `'T2'` et `'HT2'` (validations `acte.rb:87`).
- Story 3.1 a installé `badge_titre` helper et les classes CSS `.fr-tag--ht2` / `.fr-tag--t2`. **Ne pas réutiliser** ces classes pour les checkboxes — les checkboxes utilisent les composants DSFR natifs `fr-checkbox-group`.
- Story 3.1 a constaté que `Acte.ransackable_attributes` incluait déjà `titre` — confirmé toujours vrai, pas de changement modèle.
- Story 3.1 review a relevé que `fr-tag--t2` partage la palette de `fr-tag--filtres`. **Conséquence pour 3.2** : éviter d'ajouter un tag `fr-tag--filtres` "Titre: T2" dans la section "Filtres appliqués" — la confusion visuelle avec le badge de colonne serait gênante. Décision (AC12) : pas de tag pour Titre/Périmètre dans le compteur.
- Story 3.1 a explicitement noté que le commit 3.1 doit être dédié, pas groupé avec 3.2/3.3. **Faire pareil ici** : commit dédié `feat: filtres Titre + Périmètre côte à côte sur Historique et Liste de travail (story 3.2)`.

### Git Intelligence Summary

5 derniers commits sur la branche `actes` (cible cette story) :

- `d92a5bb` `fix: correctifs des tests et vues liés à l'affichage des détails pour les actes T2, ajustement des intitulés et résolution de cas sans données`
- `c5cff4a` `feat: extension du modal nouvel acte pour ajouter le support du type d'acte T2, avec validation et logique conditionnelle`
- `e99c80c` `feat: renomme ht2_actes → actes, associations, champs FK et modèle, et ajout table t2_details`
- `66d9d15` Doc épics + stories
- `b6ba53e` `Suppression du champ sous_action et renommage de date_chorus en date_saisine`

État de travail courant (`git status`) : story 3.1 partiellement committée — il existe des modifications non commitées sur `index.html.erb`, `historique.html.erb`, `actes_helper.rb`, `application.scss`, `actes_controller_test.rb`, le sprint-status.yaml, et un nouveau fichier story `3-1-affichage-actes-t2-pages-historique-et-index.md`. **Avant** de démarrer la story 3.2, vérifier que la story 3.1 a bien été committée (sinon : commit 3.1 d'abord, puis story 3.2 sur base propre).

### Latest Tech Information

- Rails Ransack `*_in` predicate : supporte nativement les tableaux multi-valeurs depuis Ransack 1.x. Aucune mise à jour de gem nécessaire.
- DSFR (Système de Design de l'État) : `fr-fieldset--inline` + `fr-checkbox-group fr-checkbox-group--md` est le pattern recommandé pour des checkboxes horizontales depuis la v1.10. La codebase utilise déjà ce pattern donc aucune migration DSFR n'est requise.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

N/A

### Completion Notes List

- **Helper `perimetre_exclusively?(q_params, target)`** ajouté dans [app/helpers/actes_helper.rb:207-213](app/helpers/actes_helper.rb:207). Encapsule la sémantique "EXCLUSIVEMENT le périmètre cible coché" (équivalent ancien `perimetre_eq == target` scalaire). 5 tests unitaires.
- **Refonte du sélecteur principal** sur **6 vues** au total : Historique + 5 dashboards (`index.html.erb` n'avait qu'à ajouter Titre car Périmètre y était déjà en checkboxes). Pattern uniforme : `<fieldset class="fr-fieldset fr-fieldset--inline">` avec libellés `<span class="fr-label fr-text--bold">` séparés par `fr-ml-3w`, et `fr-checkbox-group fr-checkbox-group--md`. Default coché si `selected_*.empty?` (cohérent avec pattern existant Liste de travail).
- **Migration `perimetre_eq` (scalaire) → `perimetre_in` (array)** : 13 occurrences substituées au total (5 branches historique + 8 branches dashboards). Le helper `perimetre_exclusively?` encapsule la sémantique. Toutes les références `perimetre_eq` restantes sont uniquement dans les clauses `except(...)` de cleanup (intentionnel — élimine d'éventuels anciens bookmarks).
- **`count_active_filters`** ([actes_controller.rb:1508-1509](app/controllers/actes_controller.rb:1508)) : `q.delete("titre_in")` + `q.delete(:titre_in)` ajoutés à côté de `perimetre_in`. Couvre les 2 contextes (`q_current` index + `q` historique).
- **`synthese_temporelle` controller** : logique 3 branches `if perimetre_mode == :consolide/:etat/:organisme` calculée à partir de `Array(@q_params[:perimetre_in])`. Sémantique préservée à l'identique (3 courbes en consolidée incluant "tout coché", 1 courbe en vue exclusive).
- **`synthese_utilisateurs` controller** : scalaire `@selected_perimetre` remplacé par array `@selected_perimetres` (nil ou `['etat']`/`['organisme']`). Helper `user_ht2_stats` non modifié : `where(perimetre: array)` génère `IN (...)` natif AR. Test multi-scénarios confirme rendu OK sur 4 combinaisons.
- **Filtre Nature étendu** : `set_variables_filtres` ([actes_controller.rb:1342-1395](app/controllers/actes_controller.rb:1342)) refactor au format `[[label, value], ...]` pour permettre `["Marché (PSC)", "Marché"]`. 35 natures HT2 + 7 natures T2, tri alphabétique. Aucune collision en BDD (`Acte.where(titre:'HT2', nature:'Marché').count == 0`).
- **Séparation stricte saisie vs. filtre** : `set_variables_form` (lignes 1217-1340) **non touché**. Le `before_action` dispatch correctement (`set_variables_form` only `[:edit, :validate_acte]`, appelé directement dans `create` ; `set_variables_filtres` only `[:index, :historique, :tableau_de_bord, :synthese_temporelle, :synthese_anomalies, :synthese_suspensions]`). Zéro chevauchement. Les partials `_form_informations*` reçoivent toujours leur `@liste_natures` strings filtrée par contexte saisie.
- **Tests** : 5 helper tests + 16 controller tests Story 3.2 ajoutés. `bundle exec rails test` → **158 runs, 1100 assertions, 0 failures, 0 errors**. La suite était à 139 tests avant (139→158, +19 tests = +5 helper + +14 controller pour Story 3.2 ; +2 sur la nuance des assertions Story 3.1).
- **Task 13 (vérif manuelle)** non exécutée : la couverture automatique vise les ACs critiques. Smoke check navigateur recommandé avant merge (cf. Tasks 13 dans la story).

### Change Log

- 2026-05-18 — Story 3.2 implémentée : refonte sélecteur Titre/Périmètre côte à côte sur 6 vues + extension du filtre Nature avec les 7 natures T2 + migration de la sémantique `perimetre_eq` (scalaire) → `perimetre_in` (array) sur historique et 5 dashboards.
- 2026-05-19 — Revue adversariale : 3 HIGH + 3 MEDIUM corrigés. (1) Préservation `titre_in` dans le modal Liste de travail, (2) propagation du filtre titre dans `synthese_utilisateurs`/`user_ht2_stats`, (3) tests sémantique "case décochée" + hidden_fields dashboards + partial T2. 164 runs / 1157 assertions / 0 failures.

### File List
- `app/views/actes/historique.html.erb` (refonte du bloc filtre principal + migration `perimetre_eq` → `perimetre_in` dans les branches conditionnelles + hidden field du modal)
- `app/views/actes/index.html.erb` (ajout du groupe Titre à gauche du groupe Périmètre + adaptation `options_for_select` Nature pour libellé `Marché (PSC)`)
- `app/views/actes/tableau_de_bord.html.erb` (refonte filtre + 2 branches conditionnelles + hidden field modal)
- `app/views/actes/synthese_temporelle.html.erb` (refonte filtre + 2 branches conditionnelles + hidden field modal)
- `app/views/actes/synthese_anomalies.html.erb` (refonte filtre + 2 branches conditionnelles + hidden field modal)
- `app/views/actes/synthese_suspensions.html.erb` (refonte filtre + 2 branches conditionnelles + hidden field modal)
- `app/views/actes/synthese_utilisateurs.html.erb` (refonte filtre + hidden field modal ligne 257 ; pas de branche conditionnelle vue)
- `app/helpers/actes_helper.rb` (nouveau helper `perimetre_exclusively?`)
- `app/controllers/actes_controller.rb` :
  - `count_active_filters` (~ligne 1507) : ajouter `q.delete("titre_in")`
  - `set_variables_filtres` (~ligne 1342) : étendre `@liste_natures` avec les 7 natures T2
  - `synthese_temporelle` (~lignes 556-616) : réécrire la logique 3 branches `perimetre_eq` → `perimetre_in`
  - `synthese_utilisateurs` (~lignes 963-988) : `@selected_perimetre` scalaire → `@selected_perimetres` array (ou nil) **+ ajout de `@selected_titres` (post-review)** propagé à `user_ht2_stats`
  - Helper `user_ht2_stats` (~ligne 1428) : **paramètre `titre = nil` ajouté en fin de signature** (post-review) — propage `where(titre: titre)` quand présent
- `test/controllers/actes_controller_test.rb` (nouveaux tests Story 3.2 : Titre filter, Périmètre array, dashboard branching, Nature étendue)
- `test/helpers/actes_helper_test.rb` (tests `perimetre_exclusively?`)
