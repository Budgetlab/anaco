require "test_helper"

class PhasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)   # statut 'admin' dans la fixture
    @cbr   = users(:cbr_1) # statut 'CBR'
  end

  test "index : accès admin OK, affiche l'année courante en onglet actif par défaut" do
    sign_in @admin
    get phases_path
    assert_response :success
    assert_select 'h1', text: /Calendrier des phases de saisie/
    # Onglet 2026 actif
    assert_select 'button#tab-phase-2026[aria-selected="true"]'
  end

  test "index : non-admin redirigé" do
    sign_in @cbr
    get phases_path
    assert_response :redirect
  end

  test "index : annee param sélectionne l'onglet correspondant" do
    sign_in @admin
    get phases_path(annee: 2027)
    assert_select 'button#tab-phase-2027[aria-selected="true"]'
  end

  test "create : ajoute une phase et redirige vers l'onglet de l'année courante" do
    sign_in @admin
    annee = Date.today.year
    # Date qui n'entre pas en conflit avec les phases déjà au fixture pour l'année.
    date_libre = Date.new(annee, 11, 1)
    assert_difference -> { Phase.count } do
      post phases_path, params: { phase: { nom: 'CRG2', annee: annee, date_debut: date_libre.to_s } }
    end
    assert_redirected_to phases_path(annee: annee)
    assert_equal date_libre, Phase.last.date_debut
  end

  test "create : refuse si nom invalide" do
    sign_in @admin
    annee = Date.today.year
    assert_no_difference -> { Phase.count } do
      post phases_path, params: { phase: { nom: 'invalide', annee: annee, date_debut: "#{annee}-06-01" } }
    end
    assert_redirected_to phases_path(annee: annee)
    assert_match(/Impossible d'ajouter/, flash[:alert])
  end

  test "create : refuse l'ajout pour une année différente de l'année en cours" do
    sign_in @admin
    assert_no_difference -> { Phase.count } do
      post phases_path, params: { phase: { nom: 'CRG1', annee: 2030, date_debut: '2030-06-01' } }
    end
    assert_redirected_to phases_path(annee: 2030)
    assert_match(/année en cours/, flash[:alert])
  end

  test "update : modifie la date_debut sur l'année courante" do
    sign_in @admin
    phase = phases(:debut_2026)
    patch phase_path(phase), params: { phase: { date_debut: '2026-02-25' } }
    assert_redirected_to phases_path(annee: 2026)
    assert_equal Date.new(2026, 2, 25), phase.reload.date_debut
  end

  test "update : refuse de modifier une phase d'une année passée" do
    sign_in @admin
    annee_passee = Date.today.year - 1
    phase = Phase.create!(nom: 'CRG1', annee: annee_passee, date_debut: Date.new(annee_passee, 6, 1))
    patch phase_path(phase), params: { phase: { date_debut: "#{annee_passee}-07-01" } }
    assert_redirected_to phases_path(annee: annee_passee)
    assert_match(/année en cours/, flash[:alert])
    assert_equal Date.new(annee_passee, 6, 1), phase.reload.date_debut
  end

  test "destroy : supprime une phase sans avis lié sur l'année courante" do
    sign_in @admin
    annee = Date.today.year
    # Date libre (pas de conflit avec les fixtures de l'année courante)
    phase = Phase.create!(nom: 'CRG2', annee: annee, date_debut: Date.new(annee, 11, 15))
    assert_difference -> { Phase.count }, -1 do
      delete phase_path(phase)
    end
    assert_redirected_to phases_path(annee: annee)
    assert_match(/supprimée/, flash[:notice])
  end

  test "destroy : refuse de supprimer une phase référencée par des avis" do
    sign_in @admin
    phase = phases(:debut_2026) # liée à avis(:avis_debut_lu) via fixture
    assert_no_difference -> { Phase.count } do
      delete phase_path(phase)
    end
    assert_redirected_to phases_path(annee: 2026)
    assert_match(/Impossible de supprimer/, flash[:alert])
  end

  test "destroy : refuse de supprimer une phase d'une année passée" do
    sign_in @admin
    annee_passee = Date.today.year - 1
    phase = Phase.create!(nom: 'CRG1', annee: annee_passee, date_debut: Date.new(annee_passee, 6, 1))
    assert_no_difference -> { Phase.count } do
      delete phase_path(phase)
    end
    assert_redirected_to phases_path(annee: annee_passee)
    assert_match(/année en cours/, flash[:alert])
  end
end
