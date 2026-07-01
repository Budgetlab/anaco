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
end
