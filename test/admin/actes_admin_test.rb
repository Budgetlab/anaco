require "test_helper"

# Story 3.4 — Gestion des actes T2 dans ActiveAdmin
#
# Couvre l'ensemble des AC :
# - AC1/AC2 : colonnes & filtres Titre / Catégorie T2 / Nature
# - AC3/AC4 : show page (rows + panel "Détails T2" conditionnel)
# - AC5     : edit form + permit_params
# - AC6     : ransackable T2Detail et association Acte
# - AC7     : non-régression HT2
class ActesAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admin_users(:one)
    sign_in @admin

    @ht2_acte = Acte.create!(
      user: users(:two),
      titre: "HT2",
      annee: 2026,
      type_acte: "visa",
      etat: "en cours d'instruction",
      perimetre: "etat",
      nature: "Marché unique",
      numero_formate: "HT2-TEST-001",
      instructeur: "Alice"
    )

    @t2_acte = Acte.create!(
      user: users(:two),
      titre: "T2",
      categorie_t2: "hors contrat",
      annee: 2026,
      type_acte: "avis",
      etat: "en cours d'instruction",
      perimetre: "etat",
      nature: "ISP",
      numero_formate: "T2-TEST-001",
      instructeur: "Bob"
    )
    @t2_detail = T2Detail.create!(
      acte: @t2_acte,
      isp_cercle1: true,
      isp_cercle1_montant: 1500,
      grade: ["A", "B"]
    )

    @t2_acte_no_detail = Acte.create!(
      user: users(:two),
      titre: "T2",
      categorie_t2: "hors contrat",
      annee: 2026,
      type_acte: "avis",
      etat: "en cours d'instruction",
      perimetre: "etat",
      nature: "Marché",
      montant_ae: 5000,
      numero_formate: "T2-TEST-002",
      instructeur: "Carol"
    )
  end

  # ─── AC1 — Index columns ─────────────────────────────────────────────

  test "admin index includes Titre and Catégorie T2 columns for HT2 and T2 actes" do
    get "/anaco/admin/actes"
    assert_response :success
    # Both actes present (nature is rendered in the index)
    assert_includes @response.body, "Marché unique" # HT2 nature
    assert_includes @response.body, "ISP" # T2 nature
    # Titre + Catégorie T2 column headers (ActiveAdmin renders col- CSS classes)
    assert_includes @response.body, "col-titre"
    assert_includes @response.body, "col-categorie_t2"
    # T2 catégorie value rendered in the table
    assert_includes @response.body, "hors contrat"
  end

  # ─── AC2 — Filters ──────────────────────────────────────────────────

  test "admin index filter by titre returns only T2 actes" do
    get "/anaco/admin/actes", params: { q: { titre_eq: "T2" } }
    assert_response :success
    # Compte des lignes de données (chaque tr a id="acte_<id>")
    row_ids = @response.body.scan(/id="acte_(\d+)"/).flatten.map(&:to_i)
    assert_includes row_ids, @t2_acte.id
    assert_includes row_ids, @t2_acte_no_detail.id
    assert_not_includes row_ids, @ht2_acte.id
  end

  test "admin index filter by titre HT2 returns only HT2 actes" do
    get "/anaco/admin/actes", params: { q: { titre_eq: "HT2" } }
    assert_response :success
    row_ids = @response.body.scan(/id="acte_(\d+)"/).flatten.map(&:to_i)
    assert_includes row_ids, @ht2_acte.id
    assert_not_includes row_ids, @t2_acte.id
    assert_not_includes row_ids, @t2_acte_no_detail.id
  end

  test "admin index exposes filter inputs for titre, categorie_t2 and nature" do
    get "/anaco/admin/actes"
    assert_response :success
    assert_match(/name="q\[titre_eq\]"/, @response.body)
    assert_match(/name="q\[categorie_t2_eq\]"/, @response.body)
    # nature is now a select (eq predicate) — was previously a substring text input
    assert_match(/name="q\[nature_eq\]"/, @response.body)
  end

  # ─── AC3 / AC4 — Show page ──────────────────────────────────────────

  test "admin show page for T2 acte renders Détails T2 panel with t2_detail data" do
    get "/anaco/admin/actes/#{@t2_acte.id}"
    assert_response :success
    assert_includes @response.body, "Détails T2"
    # number_to_currency formats as "1 500,00 €" — assert € presence to guard against
    # accidental loss of formatting (raw "1500.0" would still pass a loose number match)
    assert_match(/1[\s ]500,00\s?€/, @response.body)
    # array column grade joined
    assert_includes @response.body, "A, B"
  end

  test "admin show page for HT2 acte does NOT render Détails T2 panel" do
    get "/anaco/admin/actes/#{@ht2_acte.id}"
    assert_response :success
    assert_not_includes @response.body, "Détails T2"
  end

  test "admin show page for T2 acte without t2_detail renders panel with fallback message" do
    get "/anaco/admin/actes/#{@t2_acte_no_detail.id}"
    assert_response :success
    assert_includes @response.body, "Détails T2"
    assert_includes @response.body, "Aucun T2Detail associé"
  end

  test "admin show page exposes titre and categorie_t2 rows" do
    get "/anaco/admin/actes/#{@t2_acte.id}"
    assert_response :success
    # The attributes_table rendered new rows
    assert_match(/row-titre/, @response.body)
    assert_match(/row-categorie_t2/, @response.body)
    assert_includes @response.body, "hors contrat"
  end

  # ─── AC5 — Edit form ────────────────────────────────────────────────

  test "admin edit form for T2 acte exposes titre and categorie_t2 inputs" do
    get "/anaco/admin/actes/#{@t2_acte.id}/edit"
    assert_response :success
    assert_match(/name="acte\[titre\]"/, @response.body)
    assert_match(/name="acte\[categorie_t2\]"/, @response.body)
  end

  test "admin update successfully changes categorie_t2" do
    patch "/anaco/admin/actes/#{@t2_acte.id}", params: {
      acte: { categorie_t2: "contrat" }
    }
    assert_response :redirect
    @t2_acte.reload
    assert_equal "contrat", @t2_acte.categorie_t2
  end

  test "admin update fails when trying to set titre HT2 while t2_detail exists" do
    patch "/anaco/admin/actes/#{@t2_acte.id}", params: {
      acte: { titre: "HT2" }
    }
    # Validation no_t2_detail_for_ht2 → form re-rendered (success status = 200 from AA)
    # The titre should NOT have been persisted
    @t2_acte.reload
    assert_equal "T2", @t2_acte.titre
  end

  # ─── Édition T2Detail depuis le formulaire admin ───────────────────

  test "admin edit form for T2 acte exposes t2_detail inputs" do
    get "/anaco/admin/actes/#{@t2_acte.id}/edit"
    assert_response :success
    assert_match(/name="acte\[t2_detail_attributes\]\[isp_cercle1_montant\]"/, @response.body)
    assert_match(/name="acte\[t2_detail_attributes\]\[fa_technique\]"/, @response.body)
    assert_match(/name="acte\[t2_detail_attributes\]\[grade\]"/, @response.body)
  end

  test "admin update persists scalar t2_detail fields" do
    patch "/anaco/admin/actes/#{@t2_acte.id}", params: {
      acte: {
        t2_detail_attributes: {
          id: @t2_detail.id,
          isp_cercle1_montant: "2500",
          fa_technique: "1"
        }
      }
    }
    assert_response :redirect
    @t2_detail.reload
    assert_equal 2500, @t2_detail.isp_cercle1_montant
    assert_equal true, @t2_detail.fa_technique
  end

  test "admin update converts CSV string to array for grade field" do
    patch "/anaco/admin/actes/#{@t2_acte.id}", params: {
      acte: {
        t2_detail_attributes: {
          id: @t2_detail.id,
          grade: "C, D, E"
        }
      }
    }
    assert_response :redirect
    @t2_detail.reload
    assert_equal ["C", "D", "E"], @t2_detail.grade
  end

  test "admin edit form for HT2 acte does NOT expose t2_detail inputs" do
    get "/anaco/admin/actes/#{@ht2_acte.id}/edit"
    assert_response :success
    assert_no_match(/name="acte\[t2_detail_attributes\]/, @response.body)
  end

  test "admin show page renders date_arrete_concours in FR format dd/mm/yyyy" do
    @t2_detail.update!(date_arrete_concours: Date.new(2026, 5, 19))
    get "/anaco/admin/actes/#{@t2_acte.id}"
    assert_response :success
    assert_includes @response.body, "19/05/2026"
    assert_not_includes @response.body, "2026-05-19"
  end

  test "admin edit on T2 acte without t2_detail can create one by saving a single field" do
    # Sanity: build_t2_detail path — admin opens edit on a Marché-style T2 with no detail,
    # saves a single field → a t2_detail row must be persisted (reject_if: :all_blank lets it through)
    assert_nil @t2_acte_no_detail.t2_detail
    patch "/anaco/admin/actes/#{@t2_acte_no_detail.id}", params: {
      acte: {
        t2_detail_attributes: { respect_plafond_emplois: "1" }
      }
    }
    assert_response :redirect
    @t2_acte_no_detail.reload
    assert_not_nil @t2_acte_no_detail.t2_detail
    assert_equal true, @t2_acte_no_detail.t2_detail.respect_plafond_emplois
  end

  test "admin update with foreign t2_detail id does not corrupt the foreign row" do
    # IDOR guard: posting another acte's t2_detail.id under t2_detail_attributes must
    # never silently update the foreign record. accepts_nested_attributes_for :t2_detail
    # with update_only: true keeps the nested record scoped to its owning acte —
    # this test pins down that contract.
    foreign_id = @t2_detail.id # belongs to @t2_acte
    original_montant = @t2_detail.isp_cercle1_montant
    patch "/anaco/admin/actes/#{@t2_acte_no_detail.id}", params: {
      acte: {
        t2_detail_attributes: { id: foreign_id, isp_cercle1_montant: "99999" }
      }
    }
    # Whether the request 200s or redirects, the foreign t2_detail MUST be untouched.
    @t2_detail.reload
    assert_equal original_montant, @t2_detail.isp_cercle1_montant,
                 "Foreign t2_detail must not be modified by another acte's update"
  end

  # ─── AC6 — Ransackable foundation ───────────────────────────────────

  test "T2Detail.ransackable_attributes includes all 32+ data columns" do
    attrs = T2Detail.ransackable_attributes
    # Core sanity: pick a handful from each functional group
    %w[id acte_id type_acte_t2 effectifs grade isp_cercle1 fa_technique
       perimetre_mesure referentiel_type inscription_pap
       created_at updated_at].each do |col|
      assert_includes attrs, col, "Expected #{col} in T2Detail.ransackable_attributes"
    end
    # Should be at least 36 entries (32 data + id + acte_id + timestamps)
    assert_operator attrs.size, :>=, 36
  end

  test "T2Detail.ransackable_associations includes acte" do
    assert_includes T2Detail.ransackable_associations, "acte"
  end

  test "Acte.ransackable_associations includes t2_detail" do
    assert_includes Acte.ransackable_associations, "t2_detail"
  end
end
