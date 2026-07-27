require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  # ---- sum_chiffres_avis_instance ----
  # Ordre des 8 agrégats : [ae_i, cp_i, t2_i, etpt_i, ae_f, cp_f, t2_f, etpt_f]

  def avi_pour(phase_fixture, chiffres = {}, **attrs)
    Avi.new({
      phase: phase_fixture.nom, phase_id: phase_fixture.id, annee: phase_fixture.annee,
      user: users(:cbr_1), bop: bops(:bop_1)
    }.merge(chiffres).merge(attrs))
  end

  test "sum_chiffres_avis_instance : n'agrège que les avis de l'instance ciblée" do
    sv1 = phases(:sv1_2027)
    sv2 = phases(:sv2_2027)
    avis = [
      avi_pour(sv1, ae_i: 10, cp_i: 1, t2_i: 0, etpt_i: 0, ae_f: 5, cp_f: 0, t2_f: 0, etpt_f: 0),
      avi_pour(sv1, ae_i: 20, cp_i: 2, t2_i: 0, etpt_i: 0, ae_f: 5, cp_f: 0, t2_f: 0, etpt_f: 0),
      avi_pour(sv2, ae_i: 99, cp_i: 9, t2_i: 0, etpt_i: 0, ae_f: 9, cp_f: 0, t2_f: 0, etpt_f: 0)
    ]

    # SV1 : somme des deux premiers uniquement (SV2 exclu)
    assert_equal [30, 3, 0, 0, 10, 0, 0, 0], sum_chiffres_avis_instance(avis, sv1)
    # SV2 : le troisième uniquement
    assert_equal [99, 9, 0, 0, 9, 0, 0, 0], sum_chiffres_avis_instance(avis, sv2)
  end

  test "sum_chiffres_avis_instance : zéros si aucun avis pour l'instance" do
    assert_equal [0, 0, 0, 0, 0, 0, 0, 0], sum_chiffres_avis_instance([], phases(:sv1_2027))
  end

  test "sum_chiffres_avis_instance : CRG1 inclut la prog. initiale finalisée sans CRG1" do
    crg1  = phases(:crg1_2026)
    debut = phases(:debut_2026)
    avis = [
      avi_pour(crg1,  ae_i: 10, cp_i: 0, t2_i: 0, etpt_i: 0, ae_f: 0, cp_f: 0, t2_f: 0, etpt_f: 0),
      # prog. initiale sans CRG1 → doit être ajoutée à l'instance CRG1
      avi_pour(debut, ae_i: 5,  cp_i: 0, t2_i: 0, etpt_i: 0, ae_f: 0, cp_f: 0, t2_f: 0, etpt_f: 0, is_crg1: false),
      # prog. initiale AVEC CRG1 → NE doit PAS être ajoutée à CRG1
      avi_pour(debut, ae_i: 7,  cp_i: 0, t2_i: 0, etpt_i: 0, ae_f: 0, cp_f: 0, t2_f: 0, etpt_f: 0, is_crg1: true)
    ]

    assert_equal [15, 0, 0, 0, 0, 0, 0, 0], sum_chiffres_avis_instance(avis, crg1)
  end

  test "sum_chiffres_avis_instance : traite les chiffres nil comme 0" do
    sv1 = phases(:sv1_2027)
    avis = [avi_pour(sv1, ae_i: nil, cp_i: 3, t2_i: nil, etpt_i: nil, ae_f: nil, cp_f: nil, t2_f: nil, etpt_f: nil)]
    assert_equal [0, 3, 0, 0, 0, 0, 0, 0], sum_chiffres_avis_instance(avis, sv1)
  end
end
