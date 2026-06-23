require "test_helper"

class PhaseTest < ActiveSupport::TestCase
  # ---- Validations ----

  test "nom doit appartenir à NOMS_CONNUS" do
    phase = Phase.new(nom: 'inexistante', annee: 2026, date_debut: Date.new(2026, 1, 1))
    refute phase.valid?
    assert_includes phase.errors[:nom].join, 'doit être un des suivants'
  end

  test "annee doit être un entier dans la plage 2020..2100" do
    refute Phase.new(nom: 'CRG1', annee: 2019, date_debut: Date.new(2019, 6, 1)).valid?
    refute Phase.new(nom: 'CRG1', annee: 2101, date_debut: Date.new(2101, 6, 1)).valid?
  end

  test "date_debut doit appartenir à l'année renseignée" do
    phase = Phase.new(nom: 'CRG1', annee: 2026, date_debut: Date.new(2027, 6, 1))
    refute phase.valid?
    assert_includes phase.errors[:date_debut].join, "année 2026"
  end

  test "uniqueness sur (annee, nom, date_debut)" do
    existing = phases(:debut_2026)
    duplicate = Phase.new(nom: existing.nom, annee: existing.annee, date_debut: existing.date_debut)
    refute duplicate.valid?
    assert_includes duplicate.errors[:date_debut].join, 'unique'
  end

  # ---- numero_dans_annee + libelle_avec_numero ----

  test "numero_dans_annee : 1 quand phase unique pour ce nom dans l'année" do
    assert_equal 1, phases(:debut_2026).numero_dans_annee
  end

  test "numero_dans_annee : ordonné par date_debut quand plusieurs phases identiques" do
    assert_equal 1, phases(:sv1_2027).numero_dans_annee
    assert_equal 2, phases(:sv2_2027).numero_dans_annee
  end

  test "libelle_avec_numero : pas de numéro quand phase unique" do
    assert_equal 'début de gestion', phases(:debut_2026).libelle_avec_numero
  end

  test "libelle_avec_numero : numéro affiché quand plusieurs phases du même nom" do
    assert_equal 'services votés 1', phases(:sv1_2027).libelle_avec_numero
    assert_equal 'services votés 2', phases(:sv2_2027).libelle_avec_numero
  end

  test "libelle_court_avec_numero : abréviation + numéro pour SV et DG, nom sinon" do
    assert_equal 'SV1', phases(:sv1_2027).libelle_court_avec_numero
    assert_equal 'SV2', phases(:sv2_2027).libelle_court_avec_numero
    assert_equal 'DG1', phases(:debut_2026).libelle_court_avec_numero
    assert_equal 'CRG11', phases(:crg1_2026).libelle_court_avec_numero
  end

  # ---- ouverte? + courante_pour ----

  test "ouverte? : true si date_debut <= reference_date" do
    phase = phases(:debut_2026)
    assert phase.ouverte?(Date.new(2026, 2, 20))
    assert phase.ouverte?(Date.new(2026, 12, 31))
    refute phase.ouverte?(Date.new(2026, 2, 19))
  end

  test "courante_pour : retourne la dernière phase ouverte de l'année" do
    # Le 1er juin 2026, SV/début/CRG1 sont ouvertes → CRG1 (la plus récente) est courante.
    assert_equal phases(:crg1_2026), Phase.courante_pour(2026, Date.new(2026, 6, 1))
    # Le 15 mars 2026, SV et début sont ouvertes → début (la plus récente).
    assert_equal phases(:debut_2026), Phase.courante_pour(2026, Date.new(2026, 3, 15))
    # Avant toute phase de l'année 2026, retourne nil.
    assert_nil Phase.courante_pour(2026, Date.new(2025, 12, 31))
  end

  # ---- Association avis ----

  test "has_many :avis via foreign_key phase_id" do
    phase = phases(:debut_2026)
    assert_respond_to phase, :avis
    assert_kind_of ActiveRecord::Relation, phase.avis
  end
end
