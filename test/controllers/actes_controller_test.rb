require "test_helper"

class ActesControllerTest < ActionDispatch::IntegrationTest
  # Smoke test: garantit que les partials rendus par `actes#show` /
  # `actes#export` / `actes#export_pdf` existent bien sur disque.
  # Régression historique : le rename `_ht2_acte_details*` → `_acte_details*`
  # a été oublié, provoquant ActionView::MissingTemplate en prod.
  test "show partials exist on disk" do
    view_root = Rails.root.join("app/views/actes")
    assert File.exist?(view_root.join("_acte_details.html.erb")),
           "Partial _acte_details.html.erb manquant (rendu par show/export/export_pdf)"
    assert File.exist?(view_root.join("_acte_details_organisme.html.erb")),
           "Partial _acte_details_organisme.html.erb manquant (rendu par show)"
  end
end
