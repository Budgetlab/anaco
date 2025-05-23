require "test_helper"

class Ht2ActeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    # Skip loading fixtures
    ActiveRecord::FixtureSet.reset_cache
  end
  test "a simple assertion" do
    assert_equal 2, 1 + 1
  end

  test "Ht2Acte class exists" do
    assert_kind_of Class, Ht2Acte
  end

  test "Ht2Acte has expected methods" do
    assert Ht2Acte.respond_to?(:echeance_courte)
    assert Ht2Acte.respond_to?(:count_current_with_long_delay)
    assert Ht2Acte.method_defined?(:tous_actes_meme_chorus)
  end
end
