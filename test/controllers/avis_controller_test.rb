require "test_helper"

class AvisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cbr = users(:cbr_1)
    @bop = bops(:bop_1)
    sign_in @cbr
  end

  test "create avec avis_recu=false force statut=Non reçu et etat=Lu" do
    assert_difference -> { Avi.count } do
      post bop_avis_path(@bop), params: { avi: {
        phase: "début de gestion",
        annee: 2026,
        user_id: @cbr.id,
        bop_id: @bop.id,
        etat: "Brouillon",
        avis_recu: "false",
        motif_absence: "Absence de dossier transmis par le RBOP"
      } }
    end

    avi = Avi.order(:created_at).last
    assert_equal "Non reçu", avi.statut
    assert_equal "Lu",       avi.etat
    assert_equal false,      avi.avis_recu
    assert_equal "Absence de dossier transmis par le RBOP", avi.motif_absence
    assert_equal true,       avi.is_crg1, "début de gestion non reçu doit programmer un CRG1"
    assert_nil avi.date_envoi
    assert_nil avi.date_reception
    assert_nil avi.ae_i
    assert_nil avi.cp_f
    assert_nil avi.commentaire
  end

  test "update d'un avis Lu avec avis_recu=false force Non reçu et nullifie les champs" do
    avi = avis(:avis_debut_lu)

    patch bop_avi_path(bop_id: avi.bop_id, id: avi.id), params: { avi: {
      phase: "début de gestion",
      etat: "Lu",
      avis_recu: "false",
      motif_absence: "Dossier transmis tardivement par le RBOP"
    } }

    avi.reload
    assert_equal "Non reçu", avi.statut
    assert_equal "Lu",       avi.etat
    assert_equal false,      avi.avis_recu
    assert_equal "Dossier transmis tardivement par le RBOP", avi.motif_absence
    assert_equal true,       avi.is_crg1, "début de gestion non reçu doit programmer un CRG1"
    assert_nil avi.date_envoi
    assert_nil avi.date_reception
    assert_nil avi.ae_i
    assert_nil avi.commentaire
  end
end
