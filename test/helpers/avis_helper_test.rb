require "test_helper"

class AvisHelperTest < ActionView::TestCase
  include AvisHelper

  # ---- phase_ouverte? ----

  test "phase_ouverte? : true si la phase existe dans l'année et date_debut passée" do
    # Fixture debut_2026 : nom='programmation initiale', date_debut=2026-02-20
    assert phase_ouverte?('programmation initiale', 2026, Date.new(2026, 2, 20))
    assert phase_ouverte?('programmation initiale', 2026, Date.new(2026, 12, 31))
  end

  test "phase_ouverte? : false si date_debut pas encore passée" do
    refute phase_ouverte?('programmation initiale', 2026, Date.new(2026, 2, 19))
  end

  test "phase_ouverte? : false si la phase n'existe pas dans le calendrier de l'année" do
    # Aucune fixture 'services votés' en 2024 (cohérent avec le seed réel).
    refute phase_ouverte?('services votés', 2024, Date.new(2024, 6, 1))
  end

  test "phase_ouverte? : true si plusieurs instances dont au moins une ouverte" do
    # Fixtures sv1_2027 (2027-01-01) et sv2_2027 (2027-06-15)
    assert phase_ouverte?('services votés', 2027, Date.new(2027, 1, 1))   # SV1 seule ouverte
    assert phase_ouverte?('services votés', 2027, Date.new(2027, 12, 31)) # les deux ouvertes
    refute phase_ouverte?('services votés', 2027, Date.new(2026, 12, 31)) # aucune ouverte
  end

  # ---- next_phase_to_fill (retourne un objet Phase) ----

  test "next_phase_to_fill : SV en premier si manquante et ouverte" do
    avis_bop = []
    # SV1_2027 ouverte au 1er janvier 2027 → next = SV1
    assert_equal phases(:sv1_2027), next_phase_to_fill(avis_bop, 2027, Date.new(2027, 1, 1))
  end

  test "next_phase_to_fill : SV2 si SV1 transmise" do
    sv1 = Avi.new(phase: 'services votés', phase_id: phases(:sv1_2027).id, etat: 'Lu',
                  annee: 2027, user: users(:cbr_1), bop: bops(:bop_1))
    # Au 15 juin 2027, SV1 et SV2 sont ouvertes ; SV1 transmise → next = SV2
    assert_equal phases(:sv2_2027), next_phase_to_fill([sv1], 2027, Date.new(2027, 6, 15))
  end

  test "next_phase_to_fill : début si SV transmise et début ouvert" do
    sv = Avi.new(phase: 'services votés', phase_id: phases(:sv_2026).id, etat: 'Lu',
                 annee: 2026, user: users(:cbr_1), bop: bops(:bop_1))
    avis_bop = [sv]
    assert_equal phases(:debut_2026), next_phase_to_fill(avis_bop, 2026, Date.new(2026, 2, 20))
  end

  test "next_phase_to_fill : nil si toutes les phases transmises" do
    avis_bop = [
      Avi.new(phase: 'services votés',   phase_id: phases(:sv_2026).id,   etat: 'Lu', annee: 2026, user: users(:cbr_1), bop: bops(:bop_1)),
      Avi.new(phase: 'programmation initiale', phase_id: phases(:debut_2026).id, etat: 'Lu', annee: 2026, user: users(:cbr_1), bop: bops(:bop_1)),
      Avi.new(phase: 'CRG1',             phase_id: phases(:crg1_2026).id, etat: 'Lu', annee: 2026, user: users(:cbr_1), bop: bops(:bop_1)),
      Avi.new(phase: 'CRG2',             phase_id: phases(:crg2_2026).id, etat: 'Lu', annee: 2026, user: users(:cbr_1), bop: bops(:bop_1))
    ]
    assert_nil next_phase_to_fill(avis_bop, 2026, Date.new(2026, 9, 1))
  end

  test "next_phase_to_fill : CRG1 sauté si début.is_crg1 == false" do
    sv    = Avi.new(phase: 'services votés',   phase_id: phases(:sv_2026).id,   etat: 'Lu', annee: 2026, user: users(:cbr_1), bop: bops(:bop_1))
    debut = Avi.new(phase: 'programmation initiale', phase_id: phases(:debut_2026).id, etat: 'Lu', is_crg1: false, annee: 2026, user: users(:cbr_1), bop: bops(:bop_1))
    avis_bop = [sv, debut]
    # Au 1er juin 2026 : CRG1 ouverte mais début dit N/A → tout est traité → nil
    assert_nil next_phase_to_fill(avis_bop, 2026, Date.new(2026, 6, 1))
    # Au 1er sept 2026 : CRG2 ouverte et manquante → next = CRG2
    assert_equal phases(:crg2_2026), next_phase_to_fill(avis_bop, 2026, Date.new(2026, 9, 1))
  end

  test "next_phase_to_fill : brouillon compte comme phase à reprendre" do
    sv = Avi.new(phase: 'services votés', phase_id: phases(:sv_2026).id, etat: 'Brouillon',
                 annee: 2026, user: users(:cbr_1), bop: bops(:bop_1))
    assert_equal phases(:sv_2026), next_phase_to_fill([sv], 2026, Date.new(2026, 6, 1))
  end

  # ---- phases_groupees_par_nom ----

  test "phases_groupees_par_nom : regroupe par nom, instances triées par date_debut" do
    h = phases_groupees_par_nom(2027)
    assert_equal ['services votés'], h.keys
    assert_equal [phases(:sv1_2027), phases(:sv2_2027)], h['services votés']
  end

  # ---- avis_pour_phase ----

  test "avis_pour_phase : match exact via phase_id" do
    phase = phases(:debut_2026)
    avis_match    = Avi.new(phase_id: phase.id, phase: 'programmation initiale', annee: 2026,
                            user: users(:cbr_1), bop: bops(:bop_1))
    avis_autre    = Avi.new(phase_id: phases(:crg1_2026).id, phase: 'CRG1', annee: 2026,
                            user: users(:cbr_1), bop: bops(:bop_1))
    assert_equal avis_match, avis_pour_phase([avis_match, avis_autre], phase)
  end

  test "avis_pour_phase : nil si aucun avis n'a ce phase_id" do
    assert_nil avis_pour_phase([], phases(:debut_2026))
  end

  # ---- phase_status_badge avec prefix ----

  test "phase_status_badge : préfixe ajouté quand fourni (cas SV1/SV2)" do
    html = phase_status_badge(nil, 'services votés', true, prefix: 'SV1')
    assert_includes html, 'SV1 À rédiger'
  end

  test "phase_status_badge : pas de préfixe quand absent" do
    html = phase_status_badge(nil, 'services votés', true)
    assert_includes html, 'À rédiger'
    refute_includes html, 'SV1'
  end
end
