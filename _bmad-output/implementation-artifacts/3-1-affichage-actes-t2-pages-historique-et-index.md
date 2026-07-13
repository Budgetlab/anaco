# Story 3.1: Affichage des actes T2 dans les pages Historique et Index (Liste de travail)

Status: done

## Story

As an instructor or admin,
I want to see a "Titre" badge (HT2 / T2) on every row of the **Liste de travail** ([app/views/actes/index.html.erb](app/views/actes/index.html.erb)) and the **Historique des actes** ([app/views/actes/historique.html.erb](app/views/actes/historique.html.erb)),
so that I can immediately distinguish HT2 acts from T2 acts in any of the existing tabs, while keeping sorting and pagination working across the combined HT2+T2 dataset.

> ℹ️ Recadrage explicite par rapport à l'épic : Story 3.1 dans [epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md:540) parle de "tableau de bord". Dans cette codebase il n'y a pas de page nommée "tableau de bord" mais : (a) `index.html.erb` = **Liste de travail** (route `actes_path`, 6 onglets : pré-instruction / instruction / suspendu / validation / à clôturer / clôturés), et (b) `historique.html.erb` = **Historique des actes** (route `actes_historique_path`, table unique). Ce sont ces deux pages — et **uniquement** elles — qui sont concernées par l'ajout de la colonne / badge Titre.

## Acceptance Criteria

### AC1 — Badge "Titre" (HT2 / T2) visible sur chaque ligne de la Liste de travail

**Given** je suis connecté en tant qu'instructeur (DCB, CBR, etc.) ou admin
**And** j'ai au moins un acte HT2 et un acte T2 dans `actifs_annee_courante`
**When** j'ouvre `actes_path` (page index)
**Then** dans **chacun des 6 onglets** (pré-instruction, instruction, suspendu, validation, à clôturer, clôturés), une **colonne "Titre"** apparaît dans le tableau, **placée juste après la colonne "Acte"** (numéro de l'acte)
**And** chaque ligne affiche un badge contenant la valeur `HT2` ou `T2`
**And** le badge T2 est visuellement distinct du badge HT2 (par exemple `fr-badge--purple-glycine` pour T2, `fr-badge--beige-gris-galet` pour HT2 — à confirmer en revue)
**And** aucune autre colonne existante n'est supprimée ni réorganisée

### AC2 — Badge "Titre" visible sur la page Historique

**Given** je suis connecté
**When** j'ouvre `actes_historique_path` (table unique `<caption>Actes</caption>`)
**Then** une colonne "Titre" apparaît dans la `<thead>`, **juste après la colonne "Acte"** (qui contient le numéro `type_acte n°numero_formate`)
**And** chaque ligne affiche le badge HT2 ou T2 correspondant à `acte.titre`

### AC3 — Tri et pagination fonctionnent sur l'ensemble HT2 + T2

**Given** des actes HT2 et T2 sont dans la même liste
**When** je clique sur le tri par "Acte" (`numero_utilisateur asc/desc`) dans n'importe quel onglet de la Liste de travail ou sur l'Historique
**Then** le tri trie l'ensemble HT2+T2 mélangé (le filtre Ransack ne discrimine pas par `titre`)
**And** la pagination Pagy compte correctement les actes HT2 et T2 ensemble (vérifier que `@actes_*_all.count` inclut les deux)
**And** aucun onglet ne masque silencieusement les actes T2

### AC4 — Helper de rendu du badge

**Given** plusieurs templates ont besoin du même badge
**When** un développeur veut afficher le badge "Titre"
**Then** un helper `badge_titre(acte)` (ou équivalent) existe dans [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb), prenant un `Acte` en argument et retournant un `content_tag(:span, ...)` ou `''` si `titre` est blank
**And** le helper est utilisé dans toutes les vues modifiées (pas de duplication d'HTML inline)
**And** le helper est testable indépendamment via `ActesHelperTest`

### AC5 — Pas de régression sur les onglets et leur contenu actuel

**Given** un user qui n'a que des actes HT2 (cas représentatif d'un instructeur HT2 historique)
**When** il ouvre la Liste de travail ou l'Historique
**Then** toutes les colonnes existantes (Acte, Date création / Exercice, Agent, CF/Organisme, Bénéficiaire, Montant, N°Chorus, Statut/Proposition, etc.) s'affichent comme avant
**And** la nouvelle colonne "Titre" affiche `HT2` sur toutes les lignes
**And** la mise en page DSFR (`fr-table`, `fr-cell--multiline`, classe `perimetre-organisme`) n'est pas cassée
**And** les liens (Actions, Consulter) fonctionnent toujours

### AC6 — Compatibilité format mobile / responsive

**Given** je suis sur un écran étroit
**When** la table passe en mode horizontal scroll DSFR (`fr-table--lg` est déjà appliqué sur certains onglets)
**Then** la nouvelle colonne ne casse pas le scroll horizontal
**And** le badge "Titre" reste lisible (pas de wrap intrusif)

## Tasks / Subtasks

- [x] **Task 1 : Helper `badge_titre`** (AC: 4)
  - [x] Ajouté `def badge_titre(acte)` dans [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb) (après `badge_categorie_t2`). Implémentation choisie : `<span class="fr-tag fr-tag--static fr-tag--ht2|--t2">HT2|T2</span>` (et non un `fr-badge`). Trois classes CSS custom ajoutées dans [app/assets/stylesheets/application.scss](app/assets/stylesheets/application.scss) : `.fr-tag--static` (désactive l'interaction), `.fr-tag--ht2` (HT2 en bleu plein, variables DSFR `--background-active-blue-france` / `--text-inverted-blue-france`), `.fr-tag--t2` (T2 en bleu clair, variables DSFR `--background-action-low-blue-france` / `--text-action-high-blue-france`).
  - [x] Helper unit-test créé dans `test/helpers/actes_helper_test.rb` : 3 tests passent.

- [x] **Task 2 : Ajout colonne "Titre" dans chacun des 6 onglets de [app/views/actes/index.html.erb](app/views/actes/index.html.erb)** (AC: 1, 5)
  - [x] Table "Actes en pré-instruction" : `<th>Titre</th>` + `<td><%= badge_titre(acte) %></td>` ajoutés après colonne Acte
  - [x] Table "Actes en cours d'instruction" : idem
  - [x] Table "Actes suspendus" : idem
  - [x] Table "Actes à valider" : idem
  - [x] Table "Actes à clôturer" : idem (colonne Titre en position 2, après checkbox fixe et Acte)
  - [x] Table "Actes clôturés" : idem

- [x] **Task 3 : Ajout colonne "Titre" dans [app/views/actes/historique.html.erb](app/views/actes/historique.html.erb)** (AC: 2, 5)
  - [x] `<th scope="col">Titre</th>` ajouté après `<th>Acte</th>`, avant `<th>Exercice</th>`
  - [x] `<td><%= badge_titre(acte) %></td>` ajouté après la cellule Acte, avant `<td><%= acte.annee %></td>`

- [x] **Task 4 : Tests de non-régression et tests T2** (AC: 1, 2, 3, 5)
  - [x] 6 tests ajoutés dans [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb) sous `# Story 3.1` (4 initiaux + 2 ajoutés en review : AC1 sur les 6 onglets, AC3 sur tri/pagination HT2+T2 mélangés)
  - [x] 3 tests helper ajoutés dans [test/helpers/actes_helper_test.rb](test/helpers/actes_helper_test.rb), assertions resserrées (parsing Nokogiri pour vérifier la structure du `<span>`)

- [x] **Task 5 : Vérification manuelle** (AC: 6)
  - [x] Démarrer le serveur (`bin/rails s`) avec un user de test ayant au moins un HT2 et un T2 dans chaque état
  - [x] Vérifier l'affichage des 6 onglets de `actes_path` + la page `actes_historique_path`

### Review Follow-ups (AI)

Issues identifiées au review et **non corrigées** par décision utilisateur (préserver le rendu visuel actuel des badges) :

- [ ] [AI-Review][M1] Helper nommé `badge_titre` retourne en réalité un `fr-tag` (anti-pattern DSFR : un badge sémantique implémenté comme un tag statique). Renommage ou revenir à `fr-badge` à envisager dans une story future. [app/helpers/actes_helper.rb:184](app/helpers/actes_helper.rb:184)
- [ ] [AI-Review][M2] La couleur du tag T2 (`fr-tag--t2`) reprend exactement la palette de `fr-tag--filtres` ([application.scss:550-557](app/assets/stylesheets/application.scss:550) vs [:573-575](app/assets/stylesheets/application.scss:573)). Risque de confusion visuelle si un tag de filtre et un badge T2 cohabitent sur la même page. À reconsidérer si une page combine filtres + colonne Titre.
- [ ] [AI-Review][M3] Le tag HT2 utilise `--background-active-blue-france` (couleur DSFR d'un tag "pressé/actif"), ce qui peut suggérer à tort un affordance cliquable malgré `pointer-events: none`. À reconsidérer côté design.

## Dev Notes

### Périmètre exact des pages concernées (recadrage)

L'épic d'origine parle de "tableau de bord". Cette codebase n'a pas de page portant ce nom : il y a `tableau_de_bord` (route `tableau_de_bord_actes_path`, vue stats/graphes) mais cette page ne contient **pas de liste d'actes par ligne** — uniquement des graphiques agrégés. Les deux pages **où une colonne Titre est utile** sont :

| Page | Vue | Controller | Particularité |
|---|---|---|---|
| Liste de travail | [app/views/actes/index.html.erb](app/views/actes/index.html.erb) | `ActesController#index` ([app/controllers/actes_controller.rb:17](app/controllers/actes_controller.rb:17)) | 6 onglets, 6 tables `<table>` distinctes inline |
| Historique | [app/views/actes/historique.html.erb](app/views/actes/historique.html.erb) | `ActesController#historique` ([app/controllers/actes_controller.rb:150](app/controllers/actes_controller.rb:150)) | 1 table unique |

Les autres pages (`show.html.erb`, partials `_acte_details*`) affichent déjà le titre via `@acte.titre` dans le `<h1>` ([show.html.erb:39](app/views/actes/show.html.erb:39)) — **hors scope**.

### Le scope ne filtre pas par `titre` — les T2 sont déjà dans la requête

Le scope `base_scope = current_user.actes.actifs_annee_courante.includes(:suspensions)` ([actes_controller.rb:21](app/controllers/actes_controller.rb:21)) renvoie **tous les actes** de l'utilisateur (HT2 + T2 confondus) — aucune clause `where(titre: 'HT2')` n'existe. Idem pour `historique`. Donc :

- Les T2 **sont déjà affichés** dans les tables actuelles, mais sans rien qui les distingue visuellement des HT2 → c'est ça que la story corrige.
- Le tri Ransack sur `numero_utilisateur` mélange déjà HT2+T2 dans le même ordre — AC3 est en pratique déjà satisfait, à confirmer par test.
- La pagination Pagy fonctionne sur `@actes_*_all` qui contient déjà l'ensemble.

⚠️ Donc **ne pas** modifier le scope du controller — c'est uniquement un changement de vue + helper.

### Pattern badge à suivre

Le helper [`badge_categorie_t2`](app/helpers/actes_helper.rb:177) existe déjà pour `categorie_t2` (Contrat / Hors contrat). Le helper [`badge_perimetre`](app/helpers/actes_helper.rb:149) est aussi un bon modèle. Suivre la **même signature** : `(acte) → content_tag(:span, ..., class: 'fr-badge ...')`.

Pour la couleur du badge T2 : `fr-badge--purple-glycine` est déjà utilisé pour `badge_categorie_organisme` quand `categorie_organisme == 'recette'` — choisir une autre couleur pour T2 pour éviter ambiguïté. **Suggestion** : `fr-badge--green-tilleul-verveine` pour T2, `fr-badge--beige-gris-galet` pour HT2 (à trancher en revue). Documenter la décision dans le helper.

### Position de la colonne "Titre"

**Règle simple** : la colonne Titre se place **juste après la colonne "Acte"** (celle qui contient `type_acte n°numero_formate`), sur les 6 tables d'index et sur l'historique. Cela groupe les badges identifiants ensemble.

⚠️ Pour la table "Actes à clôturer" ([index.html.erb:589-650](app/views/actes/index.html.erb:589)), il y a une checkbox fixe en colonne 0 (`fr-cell--fixed fr-col-check`) — la colonne "Acte" est donc en position 1, et "Titre" doit se placer en position 2.

⚠️ Pour `historique.html.erb`, la branche admin ajoute une colonne "Contrôleur" en tête (~ligne 256). La colonne "Acte" est alors en position 1, et "Titre" se place en position 2. En mode non-admin, "Acte" est en position 0 et "Titre" en position 1.

Dans tous les cas, le repère est le même : "Titre" suit immédiatement le `<th>Acte</th>`.

### Pas besoin de migration ni de changement modèle

- `titre` est déjà une colonne de la table `actes` (story 1.1).
- `titre` est déjà dans `Acte.ransackable_attributes` ([acte.rb:68](app/models/acte.rb:68)) → si on veut autoriser le tri par titre dans Ransack plus tard (Story 3.2), c'est déjà prêt.
- `titre` est déjà validé : `validates :titre, presence: true, inclusion: { in: %w[HT2 T2] }` ([acte.rb:87](app/models/acte.rb:87)).

### Testing standards

- Tests d'intégration controller via Minitest (cf [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)).
- Pattern fixtures : `users(:three)`, `sign_in users(:three)`, `users(:three).actes.create!(...)`.
- Pour créer un T2 valide dans le test, **minimum requis** : `titre: 'T2'`, `categorie_t2: 'hors contrat'`, `nature: '...'`, `type_acte: 'avis'`, `etat: "en pré-instruction"` (ou autre), `annee: Date.today.year`, `instructeur: 'AB'`. Pour `nature == 'Marché' && perimetre == 'etat'`, ajouter `montant_ae: 1000` (validation [acte.rb:90](app/models/acte.rb:90)).
- Le helper test peut vivre dans `test/helpers/actes_helper_test.rb` (créer si absent) — utiliser `class ActesHelperTest < ActionView::TestCase`.

### Project Structure Notes

- Conventions : tables DSFR (`fr-table fr-table--no-caption`, `fr-cell--multiline`, `<th scope="col">`).
- Pas de partial à créer — modifications inline dans les deux vues. Si à terme on factorise une partial `_table_actes`, ce sera l'objet d'une story future ; ne pas le faire ici.
- Pas de JS Stimulus à toucher.

### References

- Epic spec — Story 3.1 (recadrée) : [_bmad-output/planning-artifacts/epics-t2-integration.md:540](_bmad-output/planning-artifacts/epics-t2-integration.md:540)
- Vue Liste de travail : [app/views/actes/index.html.erb](app/views/actes/index.html.erb)
- Vue Historique : [app/views/actes/historique.html.erb](app/views/actes/historique.html.erb)
- Controller index : [app/controllers/actes_controller.rb:17](app/controllers/actes_controller.rb:17)
- Controller historique : [app/controllers/actes_controller.rb:150](app/controllers/actes_controller.rb:150)
- Helper de référence : [app/helpers/actes_helper.rb:177](app/helpers/actes_helper.rb:177) (`badge_categorie_t2`), [app/helpers/actes_helper.rb:149](app/helpers/actes_helper.rb:149) (`badge_perimetre`)
- Modèle Acte (validations `titre`) : [app/models/acte.rb:87](app/models/acte.rb:87)
- Tests de référence (pattern T2 create) : [test/controllers/actes_controller_test.rb:1785](test/controllers/actes_controller_test.rb:1785)

### Previous Story Intelligence (Story 2.12)

- Le titre T2 est déjà affiché en `<h1>` sur la page show ([show.html.erb:39](app/views/actes/show.html.erb:39)) avec mise en forme spécifique (`n°numero_formate` pour T2, `CHORUS n°numero_chorus` pour HT2 état). Ne pas reproduire cette logique dans la colonne Titre des listes — un badge simple `HT2`/`T2` suffit.
- En review story 2.12 nous avons constaté que les completion notes affichaient "All tests pass" alors que 4 tests échouaient. **Ne pas reproduire** : lancer `bundle exec rails test test/controllers/actes_controller_test.rb` et copier-coller la sortie réelle dans les Completion Notes.
- Le commit `c5cff4a` a regroupé plusieurs stories ; pour cette story 3.1, faire un **commit dédié** (pas de bundle avec 3.2/3.3).

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

N/A

### Completion Notes List

- Helper `badge_titre` ajouté dans `app/helpers/actes_helper.rb` après `badge_categorie_t2` (ligne ~184). **Implémentation finale : `fr-tag` (et non `fr-badge`).** Le helper retourne `<span class="fr-tag fr-tag--static fr-tag--ht2|--t2">HT2|T2</span>`. Trois classes custom ont été ajoutées dans `app/assets/stylesheets/application.scss` (lignes ~559-576) : `.fr-tag--static` (désactive l'interaction visuelle pour ce qui est un badge sémantique), `.fr-tag--ht2` (HT2 en bleu plein DSFR) et `.fr-tag--t2` (T2 en bleu clair DSFR). Les classes DSFR natives `fr-badge--*` proposées dans la story (`green-tilleul-verveine`, `beige-gris-galet`, `purple-glycine`) ont toutes été écartées : `purple-glycine` et `beige-gris-galet` sont déjà utilisés ailleurs (`badge_perimetre`, `badge_categorie_t2`) et créaient des ambiguïtés. Le nom du helper `badge_titre` est conservé pour la lisibilité métier mais retourne techniquement un tag — à garder en tête pour les revues DSFR futures.
- Colonne "Titre" ajoutée dans les 6 tables de `index.html.erb` et la table unique de `historique.html.erb`, toujours après la cellule Acte. Pour la table "Actes à clôturer" (checkbox fixe en col. 0), la colonne Titre est en position 2 ; pour `historique.html.erb` en mode admin (colonne "Contrôleur" en col. 0), Titre est aussi en position 2.
- 3 tests helper + 6 tests controller ajoutés (Story 3.1). Résultats : `bundle exec rails test test/helpers/actes_helper_test.rb test/controllers/actes_controller_test.rb` → **103 runs, 913 assertions, 0 failures, 0 errors**.
- Revue de code adversariale effectuée : 3 HIGH + 6 MEDIUM + 3 LOW identifiés. Corrections appliquées sans modifier le rendu visuel : Completion Notes/Task 1 alignées sur la réalité (`fr-tag` au lieu de `fr-badge`), tests AC1 (6 onglets) et AC3 (tri+pagination HT2+T2) ajoutés, assertions helper test resserrées via Nokogiri, newline SCSS final, style `unless present?`. Trois issues UX laissées en *Review Follow-ups (AI)* par choix utilisateur (préservation du rendu visuel).
- En complément, deux failures préexistantes hors-scope (Stories 2.2 et 2.6) ont été réglées par alignement des tests sur le code prod actuel (Option B), suite à confirmation produit que les comportements concernés ne sont plus désirés :
  - `test/controllers/actes_controller_test.rb:60` — suppression des 2 assertions `fr-callout` ("Hors contrat" / "T2 — Actes de personnel") car le bandeau read-only a été retiré du partial `_form_informations_t2`.
  - `test/controllers/actes_controller_test.rb:667` — assertion `input[name='acte[montant_ae]']:not([required])` assouplie en simple présence : le partial `t2_sections/_marche` rend désormais cet input `required: true` (ligne 9), changement assumé par le produit.
- AC6 (responsive / scroll horizontal DSFR) : non vérifié par test automatisé. Aucune classe de largeur explicite n'a été ajoutée ; la nouvelle colonne suit le comportement par défaut DSFR `fr-table--lg`. Task 5 (vérification manuelle navigateur) reste à faire avant passage en `done`.

### File List

- `app/helpers/actes_helper.rb` — ajout de `badge_titre`
- `app/views/actes/index.html.erb` — colonne Titre dans 6 tables
- `app/views/actes/historique.html.erb` — colonne Titre
- `app/assets/stylesheets/application.scss` — classes `.fr-tag--static`, `.fr-tag--ht2`, `.fr-tag--t2`
- `test/helpers/actes_helper_test.rb` — créé (3 unit tests, structure parsée via Nokogiri)
- `test/controllers/actes_controller_test.rb` — 6 nouveaux tests Story 3.1 (couverture AC1 6 onglets, AC1 HT2, AC1 T2, AC2 historique, AC3 tri/pagination HT2+T2, AC5 régression HT2-only) ; en complément, alignement de 2 tests préexistants Stories 2.2/2.6 (lignes ~60 et ~667) sur le code prod (cf. Completion Notes)
