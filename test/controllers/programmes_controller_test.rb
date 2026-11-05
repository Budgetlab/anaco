require "test_helper"

class ProgrammesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one) # admin
    @programme = programmes(:programme_1)
    sign_in @admin
  end

  test "show_avis : un onglet par instance de phase (SV1 et SV2 distincts en 2023)" do
    # 2023 (année passée, donc toutes les phases visibles) possède deux instances
    # 'services votés' (sv1_2023, sv2_2023) → deux onglets distincts numérotés.
    get avis_programme_path(@programme, date: 2023)
    assert_response :success
    assert_select ".fr-tabs__tab", text: /services votés 1/
    assert_select ".fr-tabs__tab", text: /services votés 2/
    # La programmation initiale (instance unique) reste sans numéro.
    assert_select ".fr-tabs__tab", text: /\Aprogrammation initiale\z/
  end

  test "show_avis : liste des BOP affiche un tag par avis présent et 'pas de CRG1'" do
    # 2026, bop_1 (actif) : avis prog. initiale (Favorable, is_crg1=false) + CRG2 (Non reçu).
    # Le brouillon CRG1 est exclu de @avis.
    get avis_programme_path(@programme, date: 2026)
    assert_response :success

    within_header = "##{"accordion-#{bops(:bop_1).id}"}"
    # En-tête : tags des avis présents avec la classe de statut correspondante.
    assert_select "button.fr-accordion__btn .fr-badge--success", text: /programmation initiale/
    assert_select "button.fr-accordion__btn .fr-badge--brown-caramel", text: /CRG2/
    # Tag "pas de CRG1" présent car l'avis prog. initiale a is_crg1 == false.
    assert_select "button.fr-accordion__btn .fr-badge", text: "pas de CRG1"

    # Contenu de l'accordéon : un bouton-lien par avis présent, aucun bouton désactivé.
    assert_select "#{within_header} a.fr-btn", 2
    assert_select "#{within_header} button.fr-btn[disabled]", false
  end

  test "show_avis : BOP inactif affiche seulement le badge inactif (pas de tags d'avis)" do
    # bop_1 est actif depuis 2024 → inactif en 2023 avant sa date de début d'activité.
    get avis_programme_path(@programme, date: 2023)
    assert_response :success
    assert_select "button.fr-accordion__btn", text: /BOP inactif/
  end

  # ---- Robustesse : aucune erreur 500 sur les cas limites ----

  test "show_avis : rend sans erreur serveur sur toutes les années valides" do
    (2023..Date.today.year).each do |annee|
      get avis_programme_path(@programme, date: annee)
      assert_response :success, "show_avis a échoué pour l'année #{annee}"
    end
  end

  test "show_avis : rend sans erreur même sans avis ni BOP pour l'année" do
    # Programme sans BOP → aucune boucle @bops, aucun avis : la page doit rendre.
    programme_vide = Programme.create!(numero: '999', nom: 'Programme sans BOP',
                                       statut: 'Actif', deconcentre: true,
                                       user: users(:one), mission: missions(:mission_1),
                                       ministere: ministeres(:ministere_1))
    get avis_programme_path(programme_vide, date: Date.today.year)
    assert_response :success
  end

  test "show_avis : phase_periode nil sur un avis ne provoque pas d'erreur" do
    # Avis sans phase_periode (phase_id nil) : le tri et l'affichage doivent rester
    # défensifs (phase_periode&... + fallback).
    # bop_2 n'a pas d'avis en fixtures → libre pour créer un avis sans phase_periode.
    Avi.create!(bop: bops(:bop_2), user: users(:cbr_1), phase: 'programmation initiale',
                phase_id: nil, annee: Date.today.year, etat: 'Lu', statut: 'Favorable',
                avis_recu: true)
    get avis_programme_path(@programme, date: Date.today.year)
    assert_response :success
  end

  test "show_avis : programme introuvable ne renvoie pas 500 (redirection gérée)" do
    get avis_programme_path(id: 0, date: Date.today.year)
    assert_response :redirect
  end
end
