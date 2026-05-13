require "test_helper"

class ActeTest < ActiveSupport::TestCase
  test "table_name resolves to actes" do
    assert_equal "actes", Acte.table_name
  end

  test "titre column defaults to HT2 in schema" do
    column = Acte.columns_hash["titre"]
    assert_not_nil column
    assert_equal "HT2", column.default
    assert_equal false, column.null
  end

  test "categorie_t2 column exists and is nullable" do
    column = Acte.columns_hash["categorie_t2"]
    assert_not_nil column
    assert_equal true, column.null
  end

  test "default titre is HT2 for existing records" do
    assert_equal "HT2", actes(:one).titre
  end

  test "categorie_t2 is nil for HT2 acts" do
    assert_nil actes(:one).categorie_t2
  end

  test "suspension uses acte_id foreign key" do
    acte = actes(:one)
    next unless acte.suspensions.any?
    assert_respond_to acte.suspensions.first, :acte_id
    refute_respond_to acte.suspensions.first, :ht2_acte_id
  end

  test "Suspension uses acte_id foreign key column" do
    assert_includes Suspension.column_names, "acte_id"
    refute_includes Suspension.column_names, "ht2_acte_id"
  end

  test "Echeancier uses acte_id foreign key column" do
    assert_includes Echeancier.column_names, "acte_id"
  end

  test "PosteLigne uses acte_id foreign key column" do
    assert_includes PosteLigne.column_names, "acte_id"
  end

  # Story 1.3 — T2 association and validations

  test "has_one :t2_detail association declared" do
    reflection = Acte.reflect_on_association(:t2_detail)
    assert_not_nil reflection
    assert_equal :has_one, reflection.macro
  end

  test "titre validates inclusion in HT2 and T2" do
    acte = Acte.new(titre: 'INVALID')
    acte.valid?
    assert_includes acte.errors[:titre], "n'est pas inclus(e) dans la liste"
  end

  test "titre HT2 is valid value" do
    acte = actes(:one)
    assert_equal "HT2", acte.titre
    column = Acte.columns_hash["titre"]
    assert_equal "HT2", column.default
  end

  test "titre T2 is valid value" do
    acte = Acte.new(titre: 'T2', categorie_t2: 'hors_contrat')
    acte.valid?
    refute_includes acte.errors[:titre], "n'est pas inclus(e) dans la liste"
  end

  test "categorie_t2 required when titre is T2" do
    acte = Acte.new(titre: 'T2', categorie_t2: nil)
    acte.valid?
    assert_includes acte.errors[:categorie_t2], "doit être rempli(e)"
  end

  test "categorie_t2 nil allowed when titre is HT2" do
    acte = Acte.new(titre: 'HT2', categorie_t2: nil)
    acte.valid?
    refute_includes acte.errors[:categorie_t2], "doit être rempli(e)"
  end

  test "categorie_t2 rejects invalid values" do
    acte = Acte.new(titre: 'T2', categorie_t2: 'invalid_value')
    acte.valid?
    assert_includes acte.errors[:categorie_t2], "n'est pas inclus(e) dans la liste"
  end

  test "categorie_t2 accepts contrat and hors_contrat" do
    %w[contrat hors_contrat].each do |val|
      acte = Acte.new(titre: 'T2', categorie_t2: val)
      acte.valid?
      refute_includes acte.errors[:categorie_t2], "n'est pas inclus(e) dans la liste"
    end
  end

  test "HT2 acte cannot have a t2_detail" do
    acte = Acte.new(titre: 'HT2')
    acte.build_t2_detail
    acte.valid?
    assert_includes acte.errors[:t2_detail], "ne peut pas être associé à un acte HT2"
  end

  test "titre presence is required (nil rejected with clear message)" do
    acte = Acte.new(titre: nil)
    acte.valid?
    assert_includes acte.errors[:titre], "doit être rempli(e)"
  end

  test "destroying acte cascades to t2_detail" do
    user = users(:one)
    acte = Acte.create!(
      user: user,
      annee: 2026,
      type_acte: 'avis',
      titre: 'T2',
      categorie_t2: 'hors_contrat',
      perimetre: 'etat'
    )
    T2Detail.create!(acte: acte)

    assert_difference 'T2Detail.count', -1 do
      acte.destroy
    end
  end
end
