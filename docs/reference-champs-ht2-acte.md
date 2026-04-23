# Référence des champs — Ht2Acte (périmètre État et Organisme)

> **Légende**
> - **Obligatoire** : `✅ Oui` = requis en base (NOT NULL) ou bloquant à la sauvegarde / `⚠️ Conditionnel` = requis selon contexte / `❌ Non` = optionnel
> - **Conditionne d'autres champs** : indique si la valeur de ce champ fait apparaître ou devient obligatoire d'autres champs

---

## 1. Champs structurants (périmètre et type)

Ces deux champs déterminent la configuration complète du formulaire.

| Champ | Type BDD | Obligatoire | Valeurs autorisées | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `perimetre` | string NOT NULL | ✅ Oui | `'etat'`, `'organisme'` | `'etat'` | **Oui** — détermine les listes de natures, types d'engagement, motifs de suspension, types d'observations. Si `'organisme'` : active `categorie_organisme` et `nom_organisme` |
| `type_acte` | string NOT NULL | ✅ Oui | `'avis'`, `'visa'`, `'TF'` | — | **Oui** — détermine la liste de natures, la liste d'engagements (`@liste_engagements`), la liste de décisions (`@liste_decisions`), le calcul de `date_limite` et de `delai_traitement` |
| `categorie_organisme` | string | ⚠️ Conditionnel | `'depense'`, `'recette'` | NULL | **Oui** — actif uniquement si `perimetre='organisme'`. Détermine les listes de natures, motifs et types d'observations spécifiques organismes |

---

## 2. Identification et numérotation

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `annee` | integer | ✅ Oui | Année entière (ex. 2024) | NULL | **Oui** — déclenche `set_numero_utilisateur` à la sauvegarde, qui génère `numero_utilisateur` et `numero_formate` |
| `numero_utilisateur` | integer | ❌ Non | Calculé automatiquement | NULL | Non |
| `numero_formate` | string | ❌ Non | Format `YY-XXXX` (ex. `24-0042`). Calculé automatiquement à partir de `annee` + `numero_utilisateur` | NULL | Non |
| `numero_chorus` | string | ❌ Non | Texte libre | NULL | Non — utilisé pour regrouper les actes d'un même dossier Chorus |
| `numero_tf` | string | ❌ Non | Texte libre | NULL | Non |
| `numero_marche` | string | ❌ Non | Texte libre | NULL | Non |
| `numero_deliberation_ca` | string | ⚠️ Conditionnel | Texte libre | NULL | Non — requis si `deliberation_ca = true` |

---

## 3. Champs d'état et cycle de vie

| Champ | Type BDD | Obligatoire | Valeurs autorisées | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `etat` | string | ✅ Oui (auto) | Voir tableau ci-dessous | NULL → forcé à `'en cours d'instruction'` par callback | **Oui** — conditionne le calcul de `date_limite`, de `delai_traitement`, la présence de `decision_finale`, `date_cloture`, `valideur` |
| `pre_instruction` | boolean | ❌ Non | true / false | NULL | Non — mis à `true` automatiquement si `etat = 'en pré-instruction'` |
| `pdf_generation_status` | string NOT NULL | ❌ Non | `'none'`, `'generating'`, `'generated'`, `'failed'` | `'none'` | Non |

### États valides (`VALID_ETATS`)

| Valeur | Description | Transitions automatiques |
|---|---|---|
| `'en pré-instruction'` | Avant la réception officielle | → `pre_instruction = true` (callback) |
| `'en cours d'instruction'` | Instruction en cours | → calculé si état vide/invalide, ou si toutes les suspensions ont une reprise |
| `'suspendu'` | Instruction suspendue | → calculé automatiquement si une suspension sans `date_reprise` existe |
| `'à suspendre'` | Mise en attente de suspension | — |
| `'à valider'` | En attente de validation | — |
| `'à clôturer'` | En attente de clôture | — |
| `'clôturé après pré-instruction'` | Clôturé en pré-instruction | → `date_cloture = today`, `delai_traitement = today - created_at` |
| `'clôturé'` | Clôturé | → copie `proposition_decision` dans `decision_finale` si vide, calcule `delai_traitement` |

> **Édition bloquée** si `etat` n'est pas dans : `'en cours d'instruction'`, `'suspendu'`, `'en pré-instruction'`, `'à suspendre'`.

---

## 4. Dates

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `date_chorus` | date | ⚠️ Conditionnel | Date (JJ/MM/AAAA). Requis pour le calcul de `date_limite` et `delai_traitement` | NULL | **Oui** — déclenche le calcul de `date_limite` (date_chorus + 15 jours + ajustements suspensions) |
| `date_limite` | date | ❌ Non | Calculée automatiquement. `NULL` si `etat='suspendu'` | NULL | Non |
| `date_cloture` | date | ⚠️ Conditionnel | Requis pour calculer `delai_traitement` si `etat='clôturé'`. Mis à `today` automatiquement si `etat='clôturé après pré-instruction'` | NULL | Non |
| `date_deliberation_ca` | date | ⚠️ Conditionnel | Requis si `deliberation_ca = true` | NULL | Non |

### Calcul de `date_limite`

Actif uniquement si `etat` ∈ `['en cours d'instruction', 'suspendu', 'à valider']` et `date_chorus` présente.

| `type_acte` | Formule |
|---|---|
| `avis` | `date_chorus + 15 jours + somme des durées de suspension` |
| `visa` / `TF` | Si dernière suspension a une reprise : `date_reprise + 15 jours`. Sinon : `date_chorus + 15 jours` |
| Si `etat='suspendu'` | `NULL` |

### Calcul de `delai_traitement` (en jours, pour `etat='clôturé'`)

| `type_acte` | Formule |
|---|---|
| Aucune suspension | `date_cloture − date_chorus` |
| `avis` avec suspensions | `(date_cloture − date_chorus) − somme des durées de suspension` |
| `visa` / `TF` avec suspensions | `date_cloture − date_reprise_dernière_suspension` |
| `clôturé après pré-instruction` | `today − created_at` |

---

## 5. Acteurs

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `user_id` | bigint NOT NULL | ✅ Oui | FK vers `users` | — | Non |
| `instructeur` | string | ❌ Non | Texte libre | NULL | Non |
| `valideur` | string | ⚠️ Conditionnel | Texte libre. Remis à `NULL` si `etat` repasse à `'en pré-instruction'` ou `'en cours d'instruction'` | NULL | Non |
| `ordonnateur` | string | ❌ Non | Texte libre | NULL | Non |
| `beneficiaire` | string | ❌ Non | Texte libre | NULL | Non |

---

## 6. Nature et montants

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `nature` | string | ❌ Non | Valeur de liste — varie selon `perimetre` + `categorie_organisme` + `type_acte` (voir §11) | NULL | Non |
| `montant_ae` | float | ❌ Non | Nombre décimal positif (montant AE en euros) | NULL | **Oui** — pour certains `type_engagement` initiaux, `montant_global` est copié depuis `montant_ae` à l'import |
| `montant_global` | float | ❌ Non | Nombre décimal (peut être négatif pour les retraits) | NULL | Non |
| `type_montant` | string NOT NULL | ❌ Non | `'TTC'`, `'HT'` | `'TTC'` | Non |
| `type_engagement` | string | ❌ Non | Valeur de liste — varie selon `perimetre` + `type_acte` (voir §11) | NULL | Non |
| `objet` | text | ❌ Non | Texte libre | NULL | Non |

---

## 7. Localisation budgétaire (périmètre État)

Ces champs sont principalement pertinents pour `perimetre='etat'`.

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `centre_financier_code` | string | ❌ Non | Code en majuscules (normalisé automatiquement). Espaces en début/fin supprimés. Déclenche association avec `CentreFinancier` | NULL | **Oui** — associe automatiquement un `CentreFinancier` (créé avec statut `'non valide'` si inconnu) |
| `action` | string | ❌ Non | Texte libre | NULL | Non |
| `sous_action` | string | ❌ Non | Texte libre | NULL | Non |
| `activite` | string | ❌ Non | Texte libre | NULL | Non |
| `categorie` | string | ❌ Non | Valeur parmi : `'23','3','31','32','4','41','42','43','5','51','52','53','6','61','62','63','64','65','7','71','72','73'` | NULL | Non |
| `groupe_marchandises` | string | ❌ Non | Texte libre | NULL | Non |
| `destination` | string | ❌ Non | Texte libre | NULL | Non |
| `nomenclature` | string | ❌ Non | Texte libre | NULL | Non |
| `flux` | string | ❌ Non | Texte libre | NULL | Non |
| `operation_budgetaire` | string | ❌ Non | Texte libre | NULL | Non |

---

## 8. Champs spécifiques périmètre Organisme

Ces champs sont actifs uniquement lorsque `perimetre = 'organisme'`.

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `nom_organisme` | string | ⚠️ Conditionnel | Format recommandé : `"Acronyme - Nom"` ou `"Nom"`. Espaces en début/fin supprimés automatiquement | NULL | **Oui** — déclenche l'association avec l'`Organisme` correspondant (recherche par nom extrait après `" - "`) |
| `nature_categorie_organisme` | string | ❌ Non | Texte libre | NULL | Non |
| `operation_compte_tiers` | boolean NOT NULL | ❌ Non | true / false | `false` | Non |

---

## 9. Contrôles budgétaires (cases à cocher)

Ces champs sont des indicateurs Oui/Non issus de l'instruction.

| Champ | Type BDD | Obligatoire | Défaut | Description |
|---|---|---|---|---|
| `disponibilite_credits` | boolean | ❌ Non | NULL | Disponibilité des crédits vérifiée |
| `imputation_depense` | boolean | ❌ Non | NULL | Imputation de la dépense correcte |
| `consommation_credits` | boolean | ❌ Non | NULL | Consommation des crédits conforme |
| `programmation` | boolean | ❌ Non | NULL | Compatibilité avec la programmation |
| `programmation_prevue` | boolean NOT NULL | ❌ Non | `false` | Programmation prévue |
| `avis_programmation` | boolean NOT NULL | ❌ Non | `true` | Avis de programmation |
| `soutenabilite` | boolean NOT NULL | ❌ Non | `true` | Soutenabilité budgétaire |
| `conformite` | boolean NOT NULL | ❌ Non | `true` | Conformité |
| `concordance_recettes_tiers` | boolean NOT NULL | ❌ Non | `true` | Concordance des recettes tiers |
| `autorisation_tutelle` | boolean | ❌ Non | NULL | Autorisation de tutelle |
| `budget_executoire` | boolean NOT NULL | ❌ Non | `true` | Budget exécutoire |
| `gestion_anticipee` | boolean NOT NULL | ❌ Non | `false` | Gestion anticipée |
| `renvoie_instruction` | boolean NOT NULL | ❌ Non | `false` | Renvoi en instruction |
| `services_votes` | boolean NOT NULL | ❌ Non | `false` | Services votés |
| `liste_actes` | boolean NOT NULL | ❌ Non | `false` | **Oui — conditionne** `nombre_actes` : si `true`, `nombre_actes` devrait être > 1 |
| `nombre_actes` | integer | ⚠️ Conditionnel | NULL | Pertinent si `liste_actes = true` |

---

## 10. Délibérations et commissions

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `deliberation_ca` | boolean NOT NULL | ❌ Non | `false` | **Oui** — si `true`, active `numero_deliberation_ca`, `date_deliberation_ca`, `observations_deliberation_ca` |
| `numero_deliberation_ca` | string | ⚠️ Conditionnel | Texte libre. Attendu si `deliberation_ca = true` | NULL | Non |
| `date_deliberation_ca` | date | ⚠️ Conditionnel | Date. Attendue si `deliberation_ca = true` | NULL | Non |
| `observations_deliberation_ca` | text | ❌ Non | Texte libre | NULL | Non |

---

## 11. Décisions

| Champ | Type BDD | Obligatoire | Valeurs autorisées | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `proposition_decision` | string | ❌ Non | Dépend de `type_acte` (voir tableau ci-dessous) | NULL | **Oui** — copié dans `decision_finale` automatiquement si `etat` passe à `'clôturé'` et `decision_finale` est vide |
| `decision_finale` | string | ⚠️ Conditionnel | Mêmes valeurs que `proposition_decision`. Remis à `NULL` si `etat` repasse en instruction | NULL | Non |
| `commentaire_proposition_decision` | text | ❌ Non | Texte libre | NULL | Non |

### Valeurs de `proposition_decision` / `decision_finale` selon `type_acte`

| `type_acte` | Valeurs autorisées |
|---|---|
| `avis` | `"Favorable"`, `"Favorable avec observations"`, `"Défavorable"`, `"Retour sans décision (sans suite)"`, `"Saisine a posteriori"` |
| `visa` / `TF` | `"Visa accordé"`, `"Visa accordé avec observations"`, `"Refus de visa"`, `"Retour sans décision (sans suite)"`, `"Saisine a posteriori"` |

---

## 12. Observations et précisions

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Conditionne d'autres champs |
|---|---|---|---|---|---|
| `type_observations` | string[] (array) NOT NULL | ❌ Non | Tableau de valeurs de liste — varie selon `perimetre` + `categorie_organisme` + `type_acte` (voir §13) | `[]` | Non |
| `observations` | text | ❌ Non | Texte libre | NULL | Non |
| `precisions_acte` | text | ❌ Non | Texte libre | NULL | Non |
| `commentaire_disponibilite_credits` | rich text | ❌ Non | Texte enrichi (ActionText) | NULL | Non |

---

## 13. Listes de valeurs contextuelles

### Natures (`nature`)

| Contexte | Valeurs disponibles |
|---|---|
| `etat` + `avis` | Accord cadre à bons de commande, Accord cadre à marchés subséquents, Autre contrat, Convention, Marché subséquent à bons de commande, MAPA à bons de commande, Transaction, Autre |
| `etat` + `visa` | Autre contrat, Bail, Bon de commande, Convention, Décision diverse, Dotation en fonds propres, Marché unique, Marché à tranches, Marché mixte, MAPA unique, MAPA à tranches, MAPA mixte, Prêt ou avance, Remboursement de mise à disposition T3, Subvention, Subvention pour charges d'investissement, Subvention pour charges de service public, Transaction, Transfert, Autre |
| `etat` + `TF` | *(pas de liste de natures)* |
| `organisme` + `depense` | Accord cadre à bons de commande, Acquisition d'œuvres, Acquisition immobilière, Attribution de garanties, Autre contrat, Bail, Bon de commande, Conseil, Convention, Décision diverse, Intervention, Mandat, Marché à tranches, Marché mixte, Marché subséquent à bons de commande, Marché unique, MAPA à tranches, MAPA mixte, MAPA unique, Participation et apport à toute entité, Prêt ou avance, Remboursement de mise à disposition T3, Subvention, Transaction, Autre |
| `organisme` + `recette` | Aliénation immobilière, Cession de participation et retrait d'apport à toute entité, Convention et contrat en recette, Emprunt, Autre |

### Types d'engagement (`type_engagement`)

| Contexte | Valeurs disponibles |
|---|---|
| `etat` + `avis` | Engagement initial prévisionnel, Engagement complémentaire prévisionnel |
| `etat` + `visa` | Engagement initial, Engagement complémentaire, Retrait d'engagement |
| `etat` + `TF` | Affectation initiale, Affectation complémentaire, Retrait |
| `organisme` + `depense` | Engagement initial, Engagement initial prévisionnel, Engagement complémentaire, Engagement complémentaire prévisionnel, Retrait d'engagement |
| `organisme` + `recette` | *(aucun type d'engagement)* |

### Types d'observations (`type_observations`)

| Contexte | Valeurs disponibles |
|---|---|
| `etat` + `avis` | Acte non soumis au contrôle, Alerte contrôle interne, Compatibilité avec la programmation, Construction de l'EJ, Disponibilité des crédits, Évaluation de la consommation des crédits, Fondement juridique, Hors périmètre du CBR/DCB, Imputation, Pièce(s) manquante(s), Problème dans la rédaction de l'acte, Risque au titre de la RGP, Saisine a posteriori, Saisine en dessous du seuil de soumission au contrôle, Autre |
| `etat` + `visa` | + Non-conformité du bon de commande avec les prix du BPU ou du marché (14 valeurs) |
| `etat` + `TF` | Acte non soumis au contrôle, Alerte contrôle interne, Compatibilité avec la programmation, Disponibilité des crédits, Évaluation de la consommation des crédits, Fondement juridique, Hors périmètre du CBR/DCB, Imputation, Pièce(s) manquante(s), Problème dans la rédaction de l'acte, Risque au titre de la RGP, Saisine a posteriori, Saisine en dessous du seuil de soumission au contrôle, Autre |
| `organisme` + `depense` | Acte non soumis au contrôle, Alerte contrôle interne, Compatibilité avec la programmation, Disponibilité des crédits, Évaluation de la consommation des crédits, Fondement juridique, Hors périmètre du CBR/DCB, Impact à prendre en compte dans le prochain budget, Imputation, Non-conformité du bon de commande avec les prix du BPU ou du marché, Pièce(s) manquante(s), Problème dans la rédaction de l'acte, Risque au titre de la RGP, Saisine a posteriori, Saisine en dessous du seuil de soumission au contrôle, Autre |
| `organisme` + `recette` | Acte non soumis au contrôle, Alerte contrôle interne, Fondement juridique, Hors périmètre du CBR/DCB, Impact à prendre en compte dans le prochain budget, Imputation, Pièce(s) manquante(s), Problème dans la rédaction de l'acte, Risque au titre de la RGP, Saisine a posteriori, Saisine en dessous du seuil de soumission au contrôle, Autre |

### Motifs de suspension (`suspension.motif`)

| Contexte | Valeurs disponibles |
|---|---|
| `etat` (tous types) | Défaut du circuit d'approbation Chorus, Demande d'éléments complémentaires, Demande de mise en cohérence EJ/PJ, Erreur d'imputation, Erreur dans la construction de l'EJ, Mauvaise évaluation de la consommation des crédits, Pièce(s) manquante(s), Non conformité des pièces, Problématique de compatibilité avec la programmation, Problématique de disponibilité des crédits, Problématique de soutenabilité, Saisine a posteriori, Autre |
| `organisme` + `depense` | Demande de précisions, Erreur d'imputation, Mauvaise évaluation de la consommation des crédits, Non conformité des pièces, Pièce(s) manquante(s), Problématique de compatibilité avec la programmation, Problématique de disponibilité des crédits, Problématique de soutenabilité, Saisine a posteriori, Autre |
| `organisme` + `recette` | Demande de précisions, Erreur d'imputation, Non conformité des pièces, Pièce(s) manquante(s), Saisine a posteriori, Autre |

---

## 14. Données structurées associées (objets imbriqués)

### Suspensions (`suspensions_attributes`)

Un acte peut avoir plusieurs suspensions. Une suspension est rejetée si `date_suspension` est vide ou si `motif` est vide.

| Champ | Type | Obligatoire | Format / Contraintes |
|---|---|---|---|
| `date_suspension` | date | ✅ Oui | Date de début de suspension |
| `motif` | string[] | ✅ Oui | Tableau d'au moins une valeur (voir listes par contexte §13) |
| `date_reprise` | date | ❌ Non | Date de reprise de l'instruction. Si `NULL` → acte passe à `'suspendu'` automatiquement |
| `observations` | text | ❌ Non | Texte libre |
| `commentaire_reprise` | text | ❌ Non | Texte libre |

> **Effet sur l'état** : tant qu'une suspension a `date_reprise = NULL`, `etat` est forcé à `'suspendu'`.

### Échéanciers (`echeanciers_attributes`)

Prévisions de consommation annuelle. Rejeté si `annee` ou `montant_ae` est vide.

| Champ | Type | Obligatoire | Format / Contraintes |
|---|---|---|---|
| `annee` | integer | ✅ Oui | Année entière |
| `montant_ae` | float | ✅ Oui | Montant AE en euros |
| `montant_cp` | float | ❌ Non | Montant CP en euros |

### Lignes de poste (`poste_lignes_attributes`)

Détail de l'imputation budgétaire. Rejeté si `centre_financier_code` est vide.

| Champ | Type | Obligatoire | Format / Contraintes |
|---|---|---|---|
| `centre_financier_code` | string | ✅ Oui | Code centre financier (clé de rejet) |
| `numero` | string | ❌ Non | Numéro de ligne |
| `montant` | float | ❌ Non | Montant de la ligne |
| `domaine_fonctionnel` | string | ❌ Non | Texte libre |
| `fonds` | string | ❌ Non | Texte libre |
| `compte_budgetaire` | string | ❌ Non | Texte libre |
| `code_activite` | string | ❌ Non | Texte libre |
| `axe_ministeriel` | string | ❌ Non | Texte libre |
| `flux` | string | ❌ Non | Texte libre |
| `groupe_marchandises` | string | ❌ Non | Texte libre |
| `numero_tf` | string | ❌ Non | Texte libre |

---

## 15. Divers

| Champ | Type BDD | Obligatoire | Format / Contraintes | Défaut | Notes |
|---|---|---|---|---|---|
| `sheet_data` | jsonb NOT NULL | ❌ Non | JSON : `{"data": [...]}` | `{"data": []}` | Données de la feuille de calcul intégrée (jspreadsheet) |
| `delai_traitement` | integer | ❌ Non | En jours. Calculé automatiquement. Remis à `NULL` si état repasse en instruction | NULL | Calculé seulement pour `etat='clôturé'` ou `'clôturé après pré-instruction'` |
| `created_at` | datetime NOT NULL | Auto | — | Auto | Non modifiable |
| `updated_at` | datetime NOT NULL | Auto | — | Auto | Non modifiable |

---

## 16. Callbacks et automatismes résumés

| Événement | Déclencheur | Effet |
|---|---|---|
| `before_save` | Toujours | Suppression des espaces `nom_organisme` et `centre_financier_code`, mise en majuscule de `centre_financier_code` |
| `after_save` | Toujours | `set_etat_acte` : force l'état cohérent selon les suspensions |
| `after_save` | Si `annee` change | Génère `numero_utilisateur` et `numero_formate` |
| `after_save` | Toujours | Recalcule `date_limite` si conditions remplies |
| `after_save` | Si `centre_financier_code` change | Associe ou crée un `CentreFinancier` |
| `after_save` | Si `nom_organisme` change | Associe l'`Organisme` correspondant |
| `after_save` | Si état est clôturé | Calcule `delai_traitement` |
| `after_save` | Si modification | Supprime les PDFs attachés et remet `pdf_generation_status` à `'none'` (sauf si seul `pdf_generation_status` a changé) |

---

## 17. Règles métier importantes

- **Édition** : un acte ne peut être modifié que si `etat` ∈ `['en cours d'instruction', 'suspendu', 'en pré-instruction', 'à suspendre']`.
- **Regroupement Chorus** : les actes du même `numero_chorus` pour un même `user_id` et `perimetre` (et `categorie_organisme` + `nom_organisme` pour périmètre organisme) sont regroupés. Le rang dans ce groupe est le `numero_saisine`.
- **PDF** : tout changement de champ (hors `pdf_generation_status`) invalide et supprime le PDF généré.
- **Import Excel** : les champs `numero_utilisateur`, `numero_formate` et `delai_traitement` sont toujours recalculés, jamais importés tels quels.

---

## 18. Tableau de référence — Périmètre État

> Chaque colonne = un champ. Les lignes sont dans l'ordre : **Étape du formulaire** / **Champ BDD** / **Label affiché dans l'outil** / **Format · Contrainte · Défaut** / **Obligatoire** / **Conditionne d'autres champs**
>
> Légende : ✅ Obligatoire · ⚠️ Conditionnel · ❌ Optionnel · 🔒 Calculé automatiquement (non à saisir)

| Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Validation | Validation | Validation | Validation | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `type_acte` | `instructeur` | `nature` | `type_engagement` | `centre_financier_code` | `montant_ae` | `montant_global` | `annee` | `date_chorus` | `numero_chorus` | `beneficiaire` | `numero_tf` | `objet` | `ordonnateur` | `gestion_anticipee` | `pre_instruction` | `liste_actes` | `nombre_actes` | `precisions_acte` | `categorie` | `action` | `activite` | `numero_marche` | `groupe_marchandises` | `services_votes` | `avis_programmation` | `programmation_prevue` | `disponibilite_credits` | `imputation_depense` | `consommation_credits` | `programmation` | `proposition_decision` | `date_cloture` | `commentaire_proposition_decision` | `observations` | `type_observations` | `valideur` | `decision_finale` | `commentaire_proposition_decision` | `date_cloture` | `etat` | `numero_formate` | `date_limite` | `delai_traitement` | `numero_utilisateur` |
| Type d'acte | Initiales de l'instructeur | Nature de l'acte | Type d'engagement / Type d'affectation | Centre financier | Montant de l'acte (AE) | Montant estimatif global (AE) | Exercice | Date de saisine | N° Chorus | Bénéficiaire / SIRET | N° d'affectation | Objet / Opération d'investissement | Ordonnateur | Acte en gestion anticipée | Préinstruction | Cette instruction concerne une liste d'actes | Nombre d'actes | Précisions sur l'acte | Titre / Catégorie | Action / Sous-action | Code activité | Numéro de marché | Groupe de marchandises | Cet acte a été réalisé en période de services votés | Programmation initiale transmise | L'acte figure dans le dernier document de programmation | Disponibilité des crédits | Imputation de la dépense | Exactitude de l'évaluation de la consommation des crédits | Compatibilité avec la programmation / Éligibilité gestion services votés | Proposition de décision de contrôle | Date de clôture | Commentaire interne sur la décision | Propositions d'observations à l'ordonnateur | Type d'observations | Initiales du valideur | Décision finale de contrôle | Commentaire interne sur la décision | Date de clôture | État | Numéro formaté | Date limite | Délai de traitement (jours) | Numéro utilisateur |
| `'avis'`, `'visa'`, `'TF'` | Texte libre | Liste selon `type_acte` (§13) · absent pour TF | Liste selon `type_acte` (§13) | Majuscules, espaces supprimés | Décimal ≥ 0 | Décimal | Entier ex. `2024` | Date JJ/MM/AAAA · absent si pré-instruction | Texte libre · pour TF : doit commencer par TF | Texte libre · absent pour TF | Texte libre · TF uniquement (N° d'affectation, commence par 30, 10 car.) · avis/visa uniquement (Numéro Chorus de la TF, commence par TF, 8 car.) | Texte libre | Texte libre | Oui / Non · défaut Non | Oui / Non | Oui / Non · défaut Non | Entier · si liste_actes=Oui | Texte libre | Parmi 23 valeurs (§7) | Texte libre | Texte libre | Texte libre · absent pour TF | Texte libre · absent pour TF | Oui / Non · défaut Oui si phase="services votés", sinon Non | Oui / Non · défaut Oui · masqué si services_votés=Oui | Oui / Non · défaut Non | Oui / Non | Oui / Non | Oui / Non | Oui / Non · libellé varie si services_votes=Oui | Liste selon `type_acte` (§11) | Date JJ/MM/AAAA | Texte libre | Texte libre | Valeurs multiples (§13) | Texte libre | Liste selon `type_acte` (§11) | Texte libre | Date JJ/MM/AAAA | Voir §3 | Format `AA-NNNN` | Date JJ/MM/AAAA | Entier | Entier |
| ✅ | ✅ | ✅ si présent (absent pour TF) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ si présent (absent si pré-instruction) | ❌ | ❌ si présent (absent pour TF) | ❌ si présent · visible pour TF (N° affectation) ET pour avis/visa (N° Chorus TF) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ si présent (si liste_actes=Oui) | ❌ | ❌ | ❌ | ❌ | ❌ si présent (absent pour TF) | ❌ si présent (absent pour TF) | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ si présent (si services_votes=Oui) | ⚠️ si etat=en cours d'instruction | ✅ si présent (si clôture) | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ si présent (si clôture) | 🔒 | 🔒 | 🔒 | 🔒 | 🔒 |
| Détermine listes natures, engagements, décisions, calcul date_limite | — | — | — | Associe / crée un CentreFinancier | — | — | Génère numero_formate | Déclenche calcul date_limite | Regroupe les actes d'un même dossier Chorus | — | — | — | — | — | pre_instruction=Oui si etat=pré-instruction | Active nombre_actes | — | — | — | — | — | — | — | — | — | — | — | — | — | — | Copié dans decision_finale à la clôture si vide | Requis pour délai_traitement | — | — | — | Remis à vide si état repasse en instruction | — | — | Requis pour délai_traitement | Forcé selon suspensions · clôturé → copie proposition_decision | Généré depuis annee | Calculée selon type_acte + suspensions | Calculé à la clôture | Généré depuis annee |

---

## 19. Tableau de référence — Périmètre Organisme

> Même structure que §18.
>
> Légende : ✅ Obligatoire · ⚠️ Conditionnel · ❌ Optionnel · 🔒 Calculé automatiquement (non à saisir)

| Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Informations | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 1 — Infos complémentaires | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 2 — Critères | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Étape 3 — Décision | Validation | Validation | Validation | Validation | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé | 🔒 Calculé |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `type_acte` | `categorie_organisme` | `instructeur` | `nature` | `type_engagement` | `nom_organisme` | `annee` | `date_chorus` | `montant_ae` | `type_montant` | `montant_global` | `operation_compte_tiers` | `operation_budgetaire` | `nature_categorie_organisme` | `budget_executoire` | `numero_chorus` | `beneficiaire` | `objet` | `ordonnateur` | `pre_instruction` | `liste_actes` | `nombre_actes` | `precisions_acte` | `deliberation_ca` | `numero_deliberation_ca` | `date_deliberation_ca` | `observations_deliberation_ca` | `destination` | `nomenclature` | `flux` | `services_votes` | `programmation_prevue` | `disponibilite_credits` | `imputation_depense` | `consommation_credits` | `soutenabilite` | `conformite` | `concordance_recettes_tiers` | `programmation` | `autorisation_tutelle` | `proposition_decision` | `date_cloture` | `commentaire_proposition_decision` | `observations` | `type_observations` | `valideur` | `decision_finale` | `commentaire_proposition_decision` | `date_cloture` | `etat` | `numero_formate` | `date_limite` | `delai_traitement` | `numero_utilisateur` |
| Type d'acte | Catégorie organisme | Initiales de l'instructeur | Nature de l'acte | Type d'engagement | Nom de l'organisme | Exercice | Date de saisine | Montant de l'acte (AE) | Type de montant | Montant total | Opération pour compte de tiers | Opération budgétaire | Nature de la dépense / Affectation de la recette | Budget exécutoire | N° de l'acte interne à l'organisme | Bénéficiaire / SIRET / Partie versante | Objet de la dépense / recette | Service ordonnateur | Préinstruction | Cette instruction concerne une liste d'actes | Nombre d'actes | Précisions sur l'acte | Délibération en CA nécessaire | N° délibération | Date délibération | Observations sur la délibération | Destination | Nomenclature achat / recette | Flux | Cet acte a été réalisé en période de services votés | L'acte figure dans le dernier budget | Disponibilité des fonds / crédits | Imputation de la dépense / recette | Exactitude de l'évaluation de la consommation des crédits | Caractère soutenable de la gestion | Conformité au seuil de contrôle | Concordance recettes encaissées pour compte de tiers et reversements | Engagement éligible à la gestion des services votés | Opération autorisée par les autorités de tutelle | Proposition de décision de contrôle | Date de clôture | Commentaire interne sur la décision | Propositions d'observations à l'ordonnateur | Type d'observations | Initiales du valideur | Décision finale de contrôle | Commentaire interne sur la décision | Date de clôture | État | Numéro formaté | Date limite | Délai de traitement (jours) | Numéro utilisateur |
| `'avis'`, `'visa'`, `'TF'` | `'depense'` ou `'recette'` | Texte libre | Liste selon categorie_organisme (§13) | Liste selon categorie_organisme + type_acte (§13) · absent si recette | Format `"Acronyme - Nom"` ou `"Nom"` | Entier ex. `2024` | Date JJ/MM/AAAA · absent si pré-instruction | Décimal ≥ 0 | `'TTC'` ou `'HT'` · défaut TTC | Décimal · si depense | Oui / Non · défaut Non | `'Globalisée'` ou `'Fléchée'` · masqué si operation_compte_tiers=Oui | `'Investissement'`, `'Fonctionnement'`, `'Intervention'`, `'Mixte'` · masqué si operation_compte_tiers=Oui | Oui / Non · défaut Oui | Texte libre | Texte libre | Texte libre | Texte libre · si depense | Oui / Non | Oui / Non · défaut Non | Entier · si liste_actes=Oui | Texte libre | Oui / Non · défaut Non | Texte libre · si deliberation_ca=Oui | Date JJ/MM/AAAA · si deliberation_ca=Oui | Texte libre · si deliberation_ca=Oui | Texte libre · si depense | Texte libre | Texte libre · si depense | Oui / Non · défaut Oui si phase="services votés", sinon Non | Oui / Non · défaut Non | Oui / Non · défaut Oui · si depense | Oui / Non · défaut Oui · masqué si operation_compte_tiers=Oui (depense et recette) | Oui / Non · défaut Oui · si depense | Oui / Non · défaut Oui · masqué si operation_compte_tiers=Oui | Oui / Non · défaut Oui | Oui / Non · défaut Oui · si recette et compte_tiers=Oui | Oui / Non · si depense et services_votes=Oui | Oui / Non · si budget_executoire=Non | Liste selon type_acte (§11) | Date JJ/MM/AAAA | Texte libre | Texte libre | Valeurs multiples (§13) | Texte libre | Liste selon type_acte (§11) | Texte libre | Date JJ/MM/AAAA | Voir §3 | Format `AA-NNNN` | Date JJ/MM/AAAA | Entier | Entier |
| ✅ | ✅ | ✅ | ✅ | ✅ si présent (absent si recette) | ✅ | ✅ | ✅ si présent (absent si pré-instruction) | ✅ | ✅ | ❌ si présent (si depense) | ✅ | ❌ si présent (sauf si operation_compte_tiers=Oui) | ❌ si présent (sauf si operation_compte_tiers=Oui) | ✅ | ❌ | ❌ | ❌ | ❌ si présent (si depense) | ❌ | ❌ | ✅ si présent (si liste_actes=Oui) | ❌ | ❌ | ❌ si présent (si deliberation_ca=Oui) | ❌ si présent (si deliberation_ca=Oui) | ❌ | ❌ si présent (si depense) | ❌ | ❌ si présent (si depense) | ❌ | ❌ | ✅ si présent (si depense) | ✅ si présent (sauf si compte_tiers=Oui) | ✅ si présent (si depense) | ✅ si présent (sauf si compte_tiers=Oui) | ✅ | ✅ si présent (si recette et compte_tiers=Oui) | ✅ si présent (si depense et services_votes=Oui) | ✅ si présent (si budget_executoire=Non) | ⚠️ si etat=en cours d'instruction | ✅ si présent (si clôture) | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ si présent (si clôture) | 🔒 | 🔒 | 🔒 | 🔒 | 🔒 |
| Détermine listes décisions, calcul date_limite | Détermine listes natures, engagements, motifs, observations | — | — | Absent si recette | Associe l'Organisme correspondant par nom | Génère numero_formate | Déclenche calcul date_limite | — | — | — | Masque operation_budgetaire et nature_categorie_organisme · masque critères imputation_depense et soutenabilite · active concordance_recettes_tiers (si recette) | — | — | Active autorisation_tutelle si Non | Regroupe les actes d'un même dossier Chorus | — | — | — | pre_instruction=Oui si etat=pré-instruction | Active nombre_actes | — | — | Active numero_deliberation_ca, date_deliberation_ca, observations_deliberation_ca | — | — | — | — | — | — | — | — | — | Masqué si operation_compte_tiers=Oui | — | Masqué si operation_compte_tiers=Oui | — | — | — | — | Copié dans decision_finale à la clôture si vide | Requis pour délai_traitement | — | — | — | Remis à vide si état repasse en instruction | — | — | Requis pour délai_traitement | Forcé selon suspensions · clôturé → copie proposition_decision | Généré depuis annee | Calculée selon type_acte + suspensions | Calculé à la clôture | Généré depuis annee |
