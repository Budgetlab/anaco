require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one) # admin
    sign_in @admin
  end

  test "index affiche la fenêtre d'ouverture dérivée de la phase courante" do
    # Aujourd'hui = 2026-07-27 (cf. currentDate) → phase courante = CRG1
    # (début 2026-06-01, phase suivante CRG2 le 2026-09-01 → fermeture 2026-08-31).
    get root_path
    assert_response :success
    # Phase CRG1 : ouverture au 1er juin, fermeture la veille de CRG2 (31 août).
    assert_select "p.fr-card__detail", text: "Du 1 juin au 31 août 2026"
  end
end
