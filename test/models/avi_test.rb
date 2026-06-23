require "test_helper"

class AviTest < ActiveSupport::TestCase
  setup do
    @bop = bops(:bop_1)
    @user = users(:cbr_1)
  end

  test "before_validation : phase_id déduit depuis (annee + phase nom) si absent" do
    avi = Avi.new(bop: @bop, user: @user, annee: 2026, phase: 'CRG1', etat: 'Brouillon')
    assert_nil avi.phase_id
    avi.valid?
    assert_equal phases(:crg1_2026).id, avi.phase_id
  end

  test "before_validation : phase_id explicite n'est pas écrasé" do
    # Cible explicitement SV2_2027 même si nom + annee pourraient pointer sur SV1.
    avi = Avi.new(bop: @bop, user: @user, annee: 2027, phase: 'services votés',
                  phase_id: phases(:sv2_2027).id, etat: 'Brouillon')
    avi.valid?
    assert_equal phases(:sv2_2027).id, avi.phase_id
  end

  test "before_validation : phase_id reste nil si aucune Phase ne correspond" do
    # Pas de fixture pour CRG1 2022 → phase_id reste nil après validation.
    avi = Avi.new(bop: @bop, user: @user, annee: 2022, phase: 'CRG1', etat: 'Brouillon')
    avi.valid?
    assert_nil avi.phase_id
  end

  test "before_validation : multi-instances → prend la première (oldest) par défaut" do
    avi = Avi.new(bop: @bop, user: @user, annee: 2027, phase: 'services votés', etat: 'Brouillon')
    avi.valid?
    assert_equal phases(:sv1_2027).id, avi.phase_id
  end
end
