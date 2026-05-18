require "test_helper"

class SuspensionsControllerTest < ActionDispatch::IntegrationTest
  # Story 2.11 — AC3: Reprise d'un acte T2 suspendu

  test "update suspension resumes T2 acte and redirects to edit step 2 (AC3)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    suspension = acte.suspensions.create!(
      date_suspension: Date.today - 2,
      motif: ['Demande de précision']
    )
    # Force l'acte en état "suspendu" — set_etat_acte le confirmera grâce à la suspension ouverte
    acte.save!
    acte.reload
    assert_equal 'suspendu', acte.etat, "Précondition AC3 : l'acte doit être en état suspendu avant le PATCH"

    patch acte_suspension_path(acte, suspension), params: {
      suspension: {
        date_reprise: Date.today.strftime('%Y-%m-%d'),
        commentaire_reprise: 'Pièces reçues'
      }
    }

    suspension.reload
    acte.reload
    assert_equal Date.today, suspension.date_reprise
    assert_equal 'Pièces reçues', suspension.commentaire_reprise
    assert_equal "en cours d'instruction", acte.etat
    assert_redirected_to edit_acte_path(acte, etape: 2)
  end
end
