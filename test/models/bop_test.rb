require "test_helper"

class BopTest < ActiveSupport::TestCase
  setup do
    @bop = bops(:bop_1) # date_debut_activite = 2024-01-01, date_fin_activite = nil
  end

  test "actif_en? : actif sur année postérieure au début, sans date de fin" do
    assert @bop.actif_en?(2024)
    assert @bop.actif_en?(2025)
    assert @bop.actif_en?(2026)
  end

  test "actif_en? : inactif sur année antérieure au début" do
    refute @bop.actif_en?(2023)
  end

  test "actif_en? : avec date de fin, actif l'année de la fin" do
    @bop.update!(date_fin_activite: Date.new(2025, 6, 30))
    assert @bop.actif_en?(2024)
    assert @bop.actif_en?(2025)
    refute @bop.actif_en?(2026)
  end

  test "actif_en? : false si date_debut_activite nil" do
    @bop.update!(date_debut_activite: nil)
    refute @bop.actif_en?(2025)
  end

  test "scope actifs_en : inclut bop actif et exclut bop terminé" do
    actifs = Bop.actifs_en(2025).pluck(:id)
    assert_includes actifs, @bop.id

    @bop.update!(date_fin_activite: Date.new(2024, 12, 31))
    refute_includes Bop.actifs_en(2025).pluck(:id), @bop.id
  end

  test "scope inactifs_en : capture bop terminé avant l'année" do
    @bop.update!(date_fin_activite: Date.new(2024, 12, 31))
    assert_includes Bop.inactifs_en(2025).pluck(:id), @bop.id
  end

  test "scope inactifs_en : capture bop débutant après l'année" do
    @bop.update!(date_debut_activite: Date.new(2027, 1, 1))
    assert_includes Bop.inactifs_en(2026).pluck(:id), @bop.id
  end
end
