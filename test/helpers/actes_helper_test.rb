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
end
