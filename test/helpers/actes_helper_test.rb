require "test_helper"

class ActesHelperTest < ActionView::TestCase
  include ActesHelper

  # Story 3.1 — badge_titre helper unit tests

  test "badge_titre returns single span with HT2 label and fr-tag--ht2 class" do
    acte = Acte.new(titre: 'HT2')
    fragment = Nokogiri::HTML.fragment(badge_titre(acte))
    spans = fragment.css('span')
    assert_equal 1, spans.size, "Le helper doit retourner exactement un <span>"
    span = spans.first
    assert_equal 'HT2', span.text
    classes = span['class'].split
    assert_includes classes, 'fr-tag'
    assert_includes classes, 'fr-tag--static'
    assert_includes classes, 'fr-tag--ht2'
    refute_includes classes, 'fr-tag--t2'
  end

  test "badge_titre returns single span with T2 label and fr-tag--t2 class" do
    acte = Acte.new(titre: 'T2')
    fragment = Nokogiri::HTML.fragment(badge_titre(acte))
    spans = fragment.css('span')
    assert_equal 1, spans.size, "Le helper doit retourner exactement un <span>"
    span = spans.first
    assert_equal 'T2', span.text
    classes = span['class'].split
    assert_includes classes, 'fr-tag'
    assert_includes classes, 'fr-tag--static'
    assert_includes classes, 'fr-tag--t2'
    refute_includes classes, 'fr-tag--ht2'
  end

  test "badge_titre returns empty string when titre blank" do
    [nil, ''].each do |val|
      acte = Acte.new(titre: val)
      assert_equal '', badge_titre(acte),
        "badge_titre devrait retourner '' pour titre=#{val.inspect}"
    end
  end

  # Story 3.2 — perimetre_exclusively? helper unit tests

  test "perimetre_exclusively? returns true when only target perimetre is selected" do
    assert perimetre_exclusively?({ perimetre_in: ['etat'] }, 'etat')
    assert perimetre_exclusively?({ perimetre_in: ['organisme'] }, 'organisme')
  end

  test "perimetre_exclusively? returns false when both perimetres are selected (vue consolidée)" do
    refute perimetre_exclusively?({ perimetre_in: ['etat', 'organisme'] }, 'etat')
    refute perimetre_exclusively?({ perimetre_in: ['etat', 'organisme'] }, 'organisme')
  end

  test "perimetre_exclusively? returns false when no perimetre is selected (vue consolidée)" do
    refute perimetre_exclusively?({}, 'etat')
    refute perimetre_exclusively?({ perimetre_in: [] }, 'etat')
    refute perimetre_exclusively?({ perimetre_in: [''] }, 'etat')
  end

  test "perimetre_exclusively? is robust to nil q_params" do
    refute perimetre_exclusively?(nil, 'etat')
  end

  test "perimetre_exclusively? returns false when target perimetre is not selected" do
    refute perimetre_exclusively?({ perimetre_in: ['organisme'] }, 'etat')
    refute perimetre_exclusively?({ perimetre_in: ['etat'] }, 'organisme')
  end
end
