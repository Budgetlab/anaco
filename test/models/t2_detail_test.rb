require "test_helper"

class T2DetailTest < ActiveSupport::TestCase
  test "table_name is t2_details" do
    assert_equal "t2_details", T2Detail.table_name
  end

  test "belongs_to :acte is required — acte_id nil makes record invalid" do
    detail = T2Detail.new
    assert_not detail.valid?
    assert detail.errors[:acte].any?, "Expected validation error on :acte"
  end

  test "acte_id column is non-nullable" do
    column = T2Detail.columns_hash["acte_id"]
    assert_not_nil column
    assert_equal false, column.null
  end

  test "unique index exists on acte_id" do
    indexes = ActiveRecord::Base.connection.indexes("t2_details")
    acte_index = indexes.find { |i| i.columns == ["acte_id"] }
    assert_not_nil acte_index, "Expected index on acte_id"
    assert acte_index.unique, "Expected acte_id index to be unique"
  end

  test "foreign key constraint exists from t2_details to actes" do
    fks = ActiveRecord::Base.connection.foreign_keys("t2_details")
    fk = fks.find { |f| f.to_table == "actes" && f.column == "acte_id" }
    assert_not_nil fk, "Expected FK t2_details.acte_id → actes.id"
  end

  test "string array columns default to empty array" do
    detail = T2Detail.new
    assert_equal [], detail.grade
    assert_equal [], detail.isp_cercle1_natures
    assert_equal [], detail.isp_cercle2_natures
    assert_equal [], detail.perimetre_mesure
    assert_equal [], detail.origine_financement
  end

  test "all expected columns are present" do
    expected = %w[
      id acte_id created_at updated_at
      effectifs effectifs_complementaire corps grade date_arrete_concours
      date_effet_acte impact_schema_emplois impact_autre_cbcm
      isp_cercle1 isp_cercle1_natures isp_cercle1_montant
      isp_cercle1_enveloppe_sgg isp_cercle1_consommation
      isp_cercle2 isp_cercle2_natures isp_cercle2_montant
      isp_cercle2_enveloppe_sgg isp_cercle2_consommation
      fa_technique enveloppe_abondee accord_rffim sollicitation_db avis_cbcm
      perimetre_mesure statut_agents impact_financier_n1 origine_financement
      montant_enveloppe_n1 impact_maximal_sans_enveloppe
      referentiel_type
      inscription_pap respect_plafond_emplois respect_schema_emplois
      controle_modalites respect_enveloppe risque_reconventionnel
    ]
    missing = expected - T2Detail.column_names
    assert_empty missing, "Missing columns on t2_details: #{missing.inspect}"
  end
end
