require "test_helper"

class AvisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cbr = users(:cbr_1)
    @bop = bops(:bop_2) # bop_2 n'a pas d'avis en fixture → libre pour tester create
    sign_in @cbr
  end

  test "create avec avis_recu=false force statut=Non reçu et etat=Lu" do
    assert_difference -> { Avi.count } do
      post bop_avis_path(@bop), params: { avi: {
        phase_id: phases(:debut_2026).id,
        etat: "Brouillon",
        avis_recu: "false",
        motif_absence: "Absence de dossier transmis par le RBOP"
      } }
    end

    avi = Avi.order(:created_at).last
    assert_equal "Non reçu", avi.statut
    assert_equal "Lu",       avi.etat
    assert_equal false,      avi.avis_recu
    assert_equal "Absence de dossier transmis par le RBOP", avi.motif_absence
    assert_equal true,       avi.is_crg1, "programmation initiale non reçu doit programmer un CRG1"
    assert_nil avi.date_envoi
    assert_nil avi.date_reception
    assert_nil avi.ae_i
    assert_nil avi.cp_f
    assert_nil avi.commentaire
  end

  test "update d'un avis Lu avec avis_recu=false force Non reçu et nullifie les champs" do
    avi = avis(:avis_debut_lu)

    patch bop_avi_path(bop_id: avi.bop_id, id: avi.id), params: { avi: {
      etat: "Lu",
      avis_recu: "false",
      motif_absence: "Dossier transmis tardivement par le RBOP"
    } }

    avi.reload
    assert_equal "Non reçu", avi.statut
    assert_equal "Lu",       avi.etat
    assert_equal false,      avi.avis_recu
    assert_equal "Dossier transmis tardivement par le RBOP", avi.motif_absence
    assert_equal true,       avi.is_crg1, "programmation initiale non reçu doit programmer un CRG1"
    assert_nil avi.date_envoi
    assert_nil avi.date_reception
    assert_nil avi.ae_i
    assert_nil avi.commentaire
  end

  test "restitutions répond avec succès et affiche le bloc de filtres" do
    sign_in users(:one) # admin
    get restitutions_path
    assert_response :success
    assert_select "button[aria-controls=modal-btn-filtrer]", text: /Filtrer les résultats/
    assert_select "h6", text: /Filtres appliqués/
    assert_select "p.fr-tag--filtres", text: Date.today.year.to_s
  end

  test "restitutions filtre l'exercice via q[annee_eq]" do
    sign_in users(:one)
    get restitutions_path(q: { annee_eq: 2024 })
    assert_response :success
    assert_select "p.fr-tag--filtres", text: "2024"
  end

  test "restitutions filtre par code BOP affiche le tag correspondant" do
    sign_in users(:one)
    get restitutions_path(q: { annee_eq: 2024, bop_code_cont: "0100" })
    assert_response :success
    assert_select "p.fr-tag--filtres", text: /BOP : 0100/
  end

  test "restitutions admin filtre par profil et contrôleur" do
    sign_in users(:one)
    get restitutions_path(q: { annee_eq: 2024, user_statut_eq: "CBR", user_nom_in: ["CBR Un"] })
    assert_response :success
    assert_select "p.fr-tag--filtres", text: "CBR"
    assert_select "p.fr-tag--filtres", text: "CBR Un"
  end

  test "restitutions n'affiche pas le filtre profil pour un non-admin" do
    sign_in @cbr
    get restitutions_path
    assert_response :success
    assert_select "select#q_user_statut_eq", count: 0
  end

  test "restitutions : pour un CBR, Mon périmètre est coché par défaut" do
    sign_in @cbr
    get restitutions_path
    assert_response :success
    assert_select "input#perimetre-perimetre[checked]"
    assert_select "input#perimetre-national[checked]", count: 0
  end

  test "restitutions : un CBR peut choisir explicitement le périmètre national" do
    sign_in @cbr
    get restitutions_path(perimetre: 'national')
    assert_response :success
    assert_select "input#perimetre-national[checked]"
    assert_select "input#perimetre-perimetre[checked]", count: 0
  end

  test "restitutions : l'admin reste sur le périmètre national (pas de radios)" do
    sign_in users(:one)
    get restitutions_path
    assert_response :success
    assert_select "#perimetre-radios", count: 0
  end

  test "restitutions : tableaux de données affichés sous les graphes" do
    sign_in users(:one)
    get restitutions_path(q: { annee_eq: 2026 })
    assert_response :success
    # Accordéons "Tableau des données" présents (activité, calendrier, soutenabilité, répartitions)
    assert_select "button.fr-accordion__btn", text: "Tableau des données", minimum: 3
    assert_select "#accordion-activite-avis"
    assert_select "#accordion-calendrier"
    assert_select "#accordion-soutenabilite"
  end

  # ---- bop_avis (page consolidée par BOP + année) ----

  test "bop_avis : affiche un onglet par avis de l'année, actif sur l'avis ciblé" do
    sign_in @cbr
    get consultation_bop_avis_path(avis(:avis_non_recu))
    assert_response :success
    # bop_1 a 2 avis non-brouillon + 1 brouillon en 2026 → 3 onglets
    assert_select "button[role=tab]", count: 3
    # L'onglet ciblé est actif
    assert_select "button#tab-avis-#{avis(:avis_non_recu).id}[aria-selected=true]"
    assert_select "#tab-avis-#{avis(:avis_non_recu).id}-panel.fr-tabs__panel--selected"
  end

  test "bop_avis : onglets triés par ordre de phase (date_debut), pas par created_at" do
    sign_in @cbr
    get consultation_bop_avis_path(avis(:avis_debut_lu))
    assert_response :success
    # Ordre attendu 2026 : programmation initiale (02-20) → CRG1 (06-01) → CRG2 (09-01)
    ids_dom = css_select("button[role=tab]").map { |btn| btn["id"] }
    attendu = [avis(:avis_debut_lu).id, avis(:avis_brouillon).id, avis(:avis_non_recu).id]
                .map { |id| "tab-avis-#{id}" }
    assert_equal attendu, ids_dom
  end

  test "bop_avis : bouton Modifier visible pour le propriétaire" do
    sign_in @cbr # cbr_1 est le user des avis de bop_1
    get consultation_bop_avis_path(avis(:avis_debut_lu))
    assert_response :success
    assert_select "a", text: "Modifier"
  end

  test "bop_avis : reprendre le brouillon proposé au propriétaire" do
    sign_in @cbr
    get consultation_bop_avis_path(avis(:avis_brouillon))
    assert_response :success
    assert_select "a", text: "Reprendre le brouillon"
  end

  test "bop_avis : accès refusé à un utilisateur non concerné" do
    sign_in users(:two) # CBR Auvergne, ni contrôleur ni DCB de bop_1
    get consultation_bop_avis_path(avis(:avis_debut_lu))
    assert_redirected_to remplissage_avis_path
  end

  # ---- export xlsx de l'historique ----

  test "export xlsx : inclut les brouillons et affiche le libellé de phase" do
    sign_in @cbr # cbr_1 : 3 avis en 2026 dont 1 brouillon
    get historique_path(format: :xlsx, q: { annee_in: ["2026"] })
    assert_response :success

    sheet = parse_export_xlsx(response.body)

    # Ligne 1 = en-tête, puis 1 ligne par avis. Les 3 avis 2026 de cbr_1 (dont brouillon) sont présents.
    assert_equal 4, sheet.last_row, "les brouillons doivent être inclus (3 avis + en-tête)"

    # Colonne Phase (A) : libellé via phase_periode
    phases_exportees = (2..sheet.last_row).map { |r| sheet.cell(r, 1) }
    assert_includes phases_exportees, avis(:avis_brouillon).phase_periode&.libelle_avec_numero || "CRG1"
  end

  test "export xlsx : N/A pour les colonnes sans objet selon phase et avis_recu" do
    sign_in @cbr
    get historique_path(format: :xlsx, q: { annee_in: ["2026"] })
    assert_response :success

    sheet = parse_export_xlsx(response.body)
    # Index des lignes par phase (colonne A = libellé de phase)
    ligne_par_phase = {}
    (2..sheet.last_row).each { |r| ligne_par_phase[sheet.cell(r, 1)] = r }

    # Colonnes (1-based) : H=8 date réception, K=11 CRG1 programmé, J=10 Delai, U=21 motif, V=22 commentaire
    pi = ligne_par_phase[avis(:avis_debut_lu).phase_periode.libelle_avec_numero]     # programmation initiale, reçu
    crg1 = ligne_par_phase[avis(:avis_brouillon).phase_periode.libelle_avec_numero]  # CRG1, reçu (brouillon)
    crg2_non_recu = ligne_par_phase[avis(:avis_non_recu).phase_periode.libelle_avec_numero] # CRG2, non reçu

    # PI reçu : motif d'absence = N/A ; CRG1 programmé rempli (oui/non)
    assert_equal "N/A", sheet.cell(pi, 21)
    assert_includes ["oui", "non"], sheet.cell(pi, 11)

    # CRG1 reçu : date réception = N/A, CRG1 programmé = N/A, Delai = N/A
    assert_equal "N/A", sheet.cell(crg1, 8)
    assert_equal "N/A", sheet.cell(crg1, 11)
    assert_equal "N/A", sheet.cell(crg1, 10)

    # CRG2 non reçu : tout N/A à partir de date réception sauf le motif
    assert_equal "N/A", sheet.cell(crg2_non_recu, 8)   # date réception
    assert_equal "N/A", sheet.cell(crg2_non_recu, 22)  # commentaire
    assert_equal avis(:avis_non_recu).motif_absence, sheet.cell(crg2_non_recu, 21) # motif rempli
  end

  # ---- export xlsx de la consultation DCB ----

  test "export consultation xlsx : design aligné et N/A selon phase/avis_recu" do
    sign_in users(:dcb_1) # DCB responsable de bop_1, consulte les avis Lu
    get consultation_path(format: :xlsx, q: { annee_in: ["2026"] })
    assert_response :success

    sheet = parse_export_xlsx(response.body, "Avis lus")
    ligne_par_phase = {}
    (2..sheet.last_row).each { |r| ligne_par_phase[sheet.cell(r, 1)] = r }

    # Colonnes (1-based, décalées de +1 vs index à cause de la colonne Etat) :
    # G=7 Etat, I=9 date réception, L=12 CRG1 programmé, K=11 Delai, V=22 motif, W=23 commentaire
    pi = ligne_par_phase[avis(:avis_debut_lu).phase_periode.libelle_avec_numero]           # PI, reçu
    crg2_non_recu = ligne_par_phase[avis(:avis_non_recu).phase_periode.libelle_avec_numero] # CRG2, non reçu

    # Colonne Etat présente et remplie
    assert_equal "Lu", sheet.cell(pi, 7)

    # PI reçu : motif = N/A, CRG1 programmé rempli
    assert_equal "N/A", sheet.cell(pi, 22)
    assert_includes ["oui", "non"], sheet.cell(pi, 12)

    # CRG2 non reçu : N/A à partir de date réception sauf motif
    assert_equal "N/A", sheet.cell(crg2_non_recu, 9)    # date réception
    assert_equal "N/A", sheet.cell(crg2_non_recu, 23)   # commentaire
    assert_equal avis(:avis_non_recu).motif_absence, sheet.cell(crg2_non_recu, 22) # motif rempli
  end

  private

  def parse_export_xlsx(body, sheet_name = "Historique")
    require "roo"
    @export_tmp = Tempfile.new(["export", ".xlsx"], binmode: true)
    @export_tmp.write(body)
    @export_tmp.rewind
    Roo::Excelx.new(@export_tmp.path).sheet(sheet_name)
  end
end
