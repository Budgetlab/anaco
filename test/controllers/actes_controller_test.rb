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

  # Story 2.1 — Smoke regression tests : la route `new` doit répondre 200
  # pour toutes les combinaisons titre/categorie_t2 valides issues du modal,
  # et tolérer les valeurs hors whitelist sans crasher.

  test "new without titre param succeeds (HT2 default branch)" do
    sign_in users(:two)
    get new_acte_path
    assert_response :success
  end

  test "new with titre=T2 succeeds (T2 + hors contrat branch)" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'T2' }
    assert_response :success
  end

  test "new with titre=T2 and explicit categorie_t2=hors contrat succeeds" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'T2', categorie_t2: 'hors contrat' }
    assert_response :success
  end

  test "new with invalid titre falls back to HT2 without crashing" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'INVALID' }
    assert_response :success
  end

  test "new with HT2 and stray categorie_t2 param succeeds (ignored)" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'HT2', categorie_t2: 'hors contrat' }
    assert_response :success
  end

  test "new with T2 and categorie_t2=contrat does not raise (Contrat hors-périmètre)" do
    sign_in users(:two)
    # Story 2.1 : Contrat est hors-périmètre. La requête doit aboutir sans planter
    # (la valeur 'contrat' doit être ignorée et 'hors contrat' substitué).
    get new_acte_path, params: { titre: 'T2', categorie_t2: 'contrat' }
    assert_response :success
  end

  # Story 2.2 — T2 form routing and nature lists

  test "new T2 renders form_informations_t2 partial" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    # Note : le bandeau read-only `fr-callout` initialement prévu en story 2.2
    # (texte "Hors contrat / T2 — Actes de personnel") a été retiré du partial
    # par décision produit. Assertions correspondantes supprimées.
    # Les 7 placeholders de sections nature — uniques au partial T2 (AC5)
    %w[annexe-financiere enveloppe-limitative fongibilite-asymetrique isp marche mesure-transversale referentiel].each do |slug|
      assert_select "div#t2-section-#{slug}.fr-hidden"
    end
    # Hidden fields obligatoires (AC8)
    assert_select "input[type=hidden][name='acte[titre]'][value=?]", 'T2'
    assert_select "input[type=hidden][name='acte[categorie_t2]'][value=?]", 'hors contrat'
  end

  test "new T2 etat CBR user gets only Fongibilité asymétrique in nature list" do
    sign_in users(:two) # statut: CBR
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    assert_select "select#nature option", text: "Fongibilité asymétrique"
    assert_select "select#nature option", { count: 0, text: "ISP" }
    assert_select "select#nature option", { count: 0, text: "Annexe financière" }
  end

  test "new T2 etat DCB user gets full nature list including ISP" do
    sign_in users(:three) # statut: DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    # On teste la valeur canonique de l'option : le libellé affiché est enrichi
    # (ex. "ISP (cabinet ministériel)") mais la value reste la nature brute.
    assert_select "select#nature option[value='Fongibilité asymétrique']"
    assert_select "select#nature option[value='ISP']"
    assert_select "select#nature option[value='Annexe financière']"
    assert_select "select#nature option[value='Référentiel']"
  end

  test "new T2 organisme user does not get ISP in nature list" do
    sign_in users(:three) # statut: DCB, but organisme excludes ISP regardless
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme' }
    assert_response :success
    assert_select "select#nature option[value='Fongibilité asymétrique']"
    assert_select "select#nature option[value='Annexe financière']"
    assert_select "select#nature option[value='ISP']", count: 0
  end

  test "new HT2 still uses original nature list (no regression)" do
    sign_in users(:two)
    get new_acte_path, params: { titre: 'HT2', type_acte: 'visa', perimetre: 'etat' }
    assert_response :success
    assert_select "select#nature option", text: "Autre contrat"
    assert_select "select#nature option", { count: 0, text: "ISP" }
  end

  test "acte_params permits titre and categorie_t2" do
    sign_in users(:three)
    post actes_path, params: {
      acte: {
        titre: 'T2',
        categorie_t2: 'hors contrat',
        type_acte: 'visa',
        etat: "en cours d'instruction",
        perimetre: 'etat',
        instructeur: 'AB',
        nature: 'Fongibilité asymétrique',
        annee: Date.today.year,
        date_saisine: Date.today.strftime('%d/%m/%Y'),
        pre_instruction: false
      }
    }
    acte = Acte.last
    assert_equal 'T2', acte.titre
    assert_equal 'hors contrat', acte.categorie_t2
  end

  # Story 2.2 — Smoke E2E : création T2 étape 1 État + Organisme (couvre AC9)

  test "create T2 etat persists common fields and auto-generates numero/date_limite" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      post actes_path, params: {
        acte: {
          titre: 'T2', categorie_t2: 'hors contrat',
          type_acte: 'visa', etat: "en cours d'instruction",
          perimetre: 'etat',
          instructeur: 'JD',
          nature: 'Annexe financière',
          annee: Date.today.year,
          date_saisine: Date.today.strftime('%d/%m/%Y'),
          pre_instruction: false
        }
      }
    end
    acte = Acte.last
    assert_equal 'T2', acte.titre
    assert_equal 'Annexe financière', acte.nature
    assert_not_nil acte.numero_utilisateur, "numero_utilisateur doit être auto-généré (AC7)"
    assert_not_nil acte.date_limite, "date_limite doit être auto-calculée (AC7)"
  end

  test "create T2 organisme persists nom_organisme and excludes ISP from list" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      post actes_path, params: {
        acte: {
          titre: 'T2', categorie_t2: 'hors contrat',
          type_acte: 'avis', etat: "en cours d'instruction",
          perimetre: 'organisme',
          instructeur: 'JD',
          nature: 'Marché',
          nom_organisme: 'Organisme Test',
          annee: Date.today.year,
          date_saisine: Date.today.strftime('%d/%m/%Y'),
          pre_instruction: false
        }
      }
    end
    acte = Acte.last
    assert_equal 'organisme', acte.perimetre
    assert_equal 'Organisme Test', acte.nom_organisme
  end

  # Story 2.3 — Annexe financière section

  test "new T2 Annexe financière renders fields_for t2_detail with effectifs" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Annexe financière' }
    assert_response :success
    # La section Annexe financière doit être présente (masquée par défaut — Stimulus gère l'affichage)
    assert_select "div#t2-section-annexe-financiere"
    # fields_for :t2_detail génère acte[t2_detail_attributes][effectifs]
    assert_select "input[name='acte[t2_detail_attributes][effectifs]']"
    assert_select "input[name='acte[t2_detail_attributes][effectifs_complementaire]']"
    assert_select "input[name='acte[t2_detail_attributes][corps]']"
    assert_select "select[name='acte[t2_detail_attributes][type_acte_t2]']"
  end

  test "new T2 Annexe financière etat does not show budget_executoire or deliberation_ca" do
    sign_in users(:three)
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    # budget_executoire radio Oui/Non ne doit pas apparaître dans le formulaire T2 état
    assert_select "input#budget_executoire_oui", count: 0
    assert_select "fieldset[aria-labelledby='deliberation-ca-legend']", count: 0
  end

  test "new T2 Annexe financière organisme shows budget_executoire and deliberation_ca" do
    sign_in users(:three)
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme' }
    assert_response :success
    assert_select "div#t2-section-annexe-financiere"
    assert_select "input#budget_executoire_oui"
    assert_select "input#budget_executoire_non"
    assert_select "fieldset[aria-labelledby='deliberation-ca-legend']"
    # deliberation_ca défaut Non → sous-champs cachés
    assert_select "input#deliberation_ca_non[checked]"
    assert_select "div[data-conditional-field-target='field'].fr-hidden"
  end

  test "create T2 Annexe financière saves t2_detail fields" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Annexe financière',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              type_acte_t2: 'Initial',
              effectifs: '12.5',
              effectifs_complementaire: '3.0',
              corps: 'Ingénieurs',
              grade: 'A+,B',
              date_arrete_concours: '15/03/2026',
              date_effet_acte: '01/04/2026',
              impact_schema_emplois: 'true',
              impact_autre_cbcm: 'false'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Annexe financière', acte.nature
    assert_nil acte.type_engagement, "type_engagement ne doit pas être pollué par le flux T2"
    assert_not_nil acte.t2_detail
    assert_equal 'Initial', acte.t2_detail.type_acte_t2
    assert_equal 12.5, acte.t2_detail.effectifs
    assert_equal 3.0, acte.t2_detail.effectifs_complementaire
    assert_equal 'Ingénieurs', acte.t2_detail.corps
    assert_equal %w[A+ B], acte.t2_detail.grade
    assert_equal Date.new(2026, 3, 15), acte.t2_detail.date_arrete_concours
    assert_equal '01/04/2026', acte.t2_detail.date_effet_acte
    assert_equal true, acte.t2_detail.impact_schema_emplois
    assert_equal false, acte.t2_detail.impact_autre_cbcm
  end

  test "create T2 organisme Annexe financière saves budget_executoire and deliberation_ca" do
    sign_in users(:three)
    assert_difference -> { Acte.count }, 1 do
      post actes_path, params: {
        acte: {
          titre: 'T2', categorie_t2: 'hors contrat',
          type_acte: 'avis', etat: "en cours d'instruction",
          perimetre: 'organisme',
          instructeur: 'AB',
          nature: 'Annexe financière',
          nom_organisme: 'Organisme Test',
          annee: Date.today.year,
          date_saisine: Date.today.strftime('%d/%m/%Y'),
          pre_instruction: false,
          budget_executoire: 'false',
          deliberation_ca: 'true',
          numero_deliberation_ca: 'DEL-2026-001',
          date_deliberation_ca: '20/04/2026',
          observations_deliberation_ca: 'Observations test',
          t2_detail_attributes: {
            type_acte_t2: 'Complémentaire',
            effectifs: '5.0',
            impact_schema_emplois: 'false',
            impact_autre_cbcm: 'false'
          }
        }
      }
    end
    acte = Acte.last
    assert_equal 'organisme', acte.perimetre
    assert_equal false, acte.budget_executoire
    assert_equal true, acte.deliberation_ca
    assert_equal 'DEL-2026-001', acte.numero_deliberation_ca
    assert_equal Date.new(2026, 4, 20), acte.date_deliberation_ca
    assert_equal 'Observations test', acte.observations_deliberation_ca
    assert_not_nil acte.t2_detail
    assert_equal 'Complémentaire', acte.t2_detail.type_acte_t2
    assert_equal 5.0, acte.t2_detail.effectifs
  end

  test "HT2 create is unaffected by T2 changes (no regression)" do
    sign_in users(:two)
    assert_difference -> { Acte.count }, 1 do
      post actes_path, params: {
        acte: {
          titre: 'HT2',
          type_acte: 'visa',
          etat: "en cours d'instruction",
          perimetre: 'etat',
          instructeur: 'AB',
          nature: 'Engagement juridique',
          annee: Date.today.year,
          date_saisine: Date.today.strftime('%d/%m/%Y'),
          pre_instruction: false
        }
      }
    end
    acte = Acte.last
    assert_equal 'HT2', acte.titre
    assert_nil acte.t2_detail
  end

  # Story 2.4 — ISP section

  test "new T2 ISP renders isp section with cercle1 and cercle2 fields" do
    sign_in users(:three) # DCB — ISP only available for état DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-isp"
    # Section ISP présente dans le DOM (cachée par Stimulus par défaut)
    assert_select "div#t2-section-isp.fr-hidden"
    # Champs Cercle 1
    assert_select "input#isp_cercle1_oui"
    assert_select "input#isp_cercle1_non"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle1_montant]']"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle1_enveloppe_sgg]']"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle1_consommation]']"
    # Champs Cercle 2
    assert_select "input#isp_cercle2_oui"
    assert_select "input#isp_cercle2_non"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle2_montant]']"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle2_enveloppe_sgg]']"
    assert_select "input[name='acte[t2_detail_attributes][isp_cercle2_consommation]']"
    # date_effet_acte dans la section ISP
    assert_select "input[name='acte[t2_detail_attributes][date_effet_acte]']"
  end

  test "new HT2 does not render ISP section" do
    sign_in users(:three)
    get new_acte_path, params: { titre: 'HT2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-isp", count: 0
  end

  test "new T2 organisme does not include ISP in nature list" do
    sign_in users(:three)
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme' }
    assert_response :success
    assert_select "select#nature option", { text: "ISP", count: 0 }
  end

  test "create T2 ISP saves t2_detail isp fields" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'ISP',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              date_effet_acte: '01/09/2026',
              isp_cercle1: 'true',
              isp_cercle1_natures: 'Mensuelle,Exceptionnelle',
              isp_cercle1_montant: '15000.50',
              isp_cercle1_enveloppe_sgg: '200000',
              isp_cercle1_consommation: '50000',
              isp_cercle2: 'false',
              isp_cercle2_natures: '',
              isp_cercle2_montant: '',
              isp_cercle2_enveloppe_sgg: '',
              isp_cercle2_consommation: ''
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'ISP', acte.nature
    assert_not_nil acte.t2_detail
    assert_equal '01/09/2026', acte.t2_detail.date_effet_acte
    assert_equal true,  acte.t2_detail.isp_cercle1
    assert_equal %w[Mensuelle Exceptionnelle], acte.t2_detail.isp_cercle1_natures
    assert_equal 15000.5, acte.t2_detail.isp_cercle1_montant.to_f
    assert_equal 200000,  acte.t2_detail.isp_cercle1_enveloppe_sgg.to_f
    assert_equal 50000,   acte.t2_detail.isp_cercle1_consommation.to_f
    assert_equal false, acte.t2_detail.isp_cercle2
    assert_equal [],    acte.t2_detail.isp_cercle2_natures
  end

  test "update T2 nature change from ISP to Annexe financière clears ISP fields" do
    sign_in users(:three)
    # Créer un acte ISP via POST
    post actes_path, params: {
      acte: {
        titre: 'T2', categorie_t2: 'hors contrat', type_acte: 'visa',
        etat: "en cours d'instruction", perimetre: 'etat', instructeur: 'AB',
        nature: 'ISP', annee: Date.today.year,
        date_saisine: Date.today.strftime('%d/%m/%Y'), pre_instruction: false,
        t2_detail_attributes: {
          date_effet_acte: '01/09/2026',
          isp_cercle1: 'true', isp_cercle1_natures: 'Mensuelle,Exceptionnelle',
          isp_cercle1_montant: '15000.50', isp_cercle1_enveloppe_sgg: '200000',
          isp_cercle1_consommation: '50000', isp_cercle2: 'false'
        }
      }
    }
    acte = Acte.last

    # Changer la nature vers Annexe financière
    patch acte_path(acte), params: {
      etape: 1,
      acte: {
        nature: 'Annexe financière',
        t2_detail_attributes: {
          id: acte.t2_detail.id,
          type_acte_t2: 'Initial', effectifs: '5',
          date_effet_acte: '15/09/2026'
        }
      }
    }

    acte.reload
    assert_equal 'Annexe financière', acte.nature
    assert_equal 'Initial', acte.t2_detail.type_acte_t2
    assert_equal '15/09/2026', acte.t2_detail.date_effet_acte
    assert_nil acte.t2_detail.isp_cercle1
    assert_equal [], acte.t2_detail.isp_cercle1_natures
    assert_nil acte.t2_detail.isp_cercle1_montant
    assert_nil acte.t2_detail.isp_cercle1_enveloppe_sgg
    assert_nil acte.t2_detail.isp_cercle1_consommation
    assert_nil acte.t2_detail.isp_cercle2
  end

  test "update T2 nature change from Annexe financière to ISP clears Annexe fields" do
    sign_in users(:three)
    post actes_path, params: {
      acte: {
        titre: 'T2', categorie_t2: 'hors contrat', type_acte: 'visa',
        etat: "en cours d'instruction", perimetre: 'etat', instructeur: 'AB',
        nature: 'Annexe financière', annee: Date.today.year,
        date_saisine: Date.today.strftime('%d/%m/%Y'), pre_instruction: false,
        t2_detail_attributes: {
          type_acte_t2: 'Initial', effectifs: '8',
          corps: 'Ingénieurs', grade: 'A,B',
          date_effet_acte: '01/06/2026',
          impact_schema_emplois: 'true', impact_autre_cbcm: 'false'
        }
      }
    }
    acte = Acte.last

    patch acte_path(acte), params: {
      etape: 1,
      acte: {
        nature: 'ISP',
        t2_detail_attributes: {
          id: acte.t2_detail.id,
          isp_cercle1: 'true',
          isp_cercle1_montant: '5000',
          date_effet_acte: '01/09/2026'
        }
      }
    }

    acte.reload
    assert_equal 'ISP', acte.nature
    assert_equal '01/09/2026', acte.t2_detail.date_effet_acte
    assert_equal true, acte.t2_detail.isp_cercle1
    assert_nil acte.t2_detail.type_acte_t2
    assert_nil acte.t2_detail.effectifs
    assert_nil acte.t2_detail.corps
    assert_equal [], acte.t2_detail.grade
    assert_nil acte.t2_detail.impact_schema_emplois
    assert_nil acte.t2_detail.impact_autre_cbcm
  end

  # Story 2.5 — Fongibilité asymétrique section

  test "new T2 Fongibilité asymétrique état DCB renders fa_technique, accord_rffim and sollicitation_db" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Fongibilité asymétrique' }
    assert_response :success
    assert_select "div#t2-section-fongibilite-asymetrique"
    # Montant au contrôle (sur acte, pas t2_detail)
    assert_select "input[name='acte[montant_ae]']"
    # N° Chorus (état uniquement)
    assert_select "input[name='acte[numero_chorus]']"
    # FA Technique radios
    assert_select "input#fa_technique_oui"
    assert_select "input#fa_technique_non"
    # Accord RFFIM/RPROG (DCB uniquement)
    assert_select "input#accord_rffim_oui"
    assert_select "input#accord_rffim_non"
    # Sollicitation DB/BS dropdown (DCB uniquement)
    assert_select "select[name='acte[t2_detail_attributes][sollicitation_db]']"
    assert_select "select#t2_detail_sollicitation_db option", text: "Favorable"
    assert_select "select#t2_detail_sollicitation_db option", text: "Non favorable"
    assert_select "select#t2_detail_sollicitation_db option", text: "Non sollicité"
    # Enveloppe abondée absent pour état
    assert_select "select#t2_detail_enveloppe_abondee", count: 0
  end

  test "new T2 Fongibilité asymétrique état CBR renders CBCM dropdown but not accord_rffim" do
    sign_in users(:two) # CBR
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Fongibilité asymétrique' }
    assert_response :success
    assert_select "div#t2-section-fongibilite-asymetrique"
    assert_select "input[name='acte[montant_ae]']"
    # N° Chorus présent pour état (AC3 : périmètre état, profil-indépendant)
    assert_select "input[name='acte[numero_chorus]']"
    # FA Technique présent
    assert_select "input#fa_technique_oui"
    assert_select "input#fa_technique_non"
    # Sollicitation CBCM présente (champ avis_cbcm distinct de sollicitation_db)
    assert_select "select[name='acte[t2_detail_attributes][avis_cbcm]']"
    # Accord RFFIM absent pour CBR
    assert_select "input#accord_rffim_oui", count: 0
    assert_select "input#accord_rffim_non", count: 0
    # Enveloppe abondée absent pour état
    assert_select "select#t2_detail_enveloppe_abondee", count: 0
  end

  test "new T2 Fongibilité asymétrique organisme renders enveloppe_abondee but not accord_rffim or sollicitation_db" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Fongibilité asymétrique' }
    assert_response :success
    assert_select "div#t2-section-fongibilite-asymetrique"
    assert_select "input[name='acte[montant_ae]']"
    # FA Technique présent
    assert_select "input#fa_technique_oui"
    assert_select "input#fa_technique_non"
    # Enveloppe abondée présente pour organisme
    assert_select "select#t2_detail_enveloppe_abondee"
    assert_select "select#t2_detail_enveloppe_abondee option", text: "Fonctionnement"
    assert_select "select#t2_detail_enveloppe_abondee option", text: "Investissement"
    assert_select "select#t2_detail_enveloppe_abondee option", text: "Intervention"
    # Accord RFFIM absent pour organisme
    assert_select "input#accord_rffim_oui", count: 0
    # N° Chorus absent pour organisme
    assert_select "input[name='acte[numero_chorus]']", count: 0
    # Sollicitation DB/BS absent pour organisme
    assert_select "select#t2_detail_sollicitation_db", count: 0
  end

  test "create T2 Fongibilité asymétrique DCB saves fa_technique, accord_rffim and sollicitation_db" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Fongibilité asymétrique',
            montant_ae: '75000.50',
            numero_chorus: 'CHO-2026-001',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              fa_technique: 'true',
              accord_rffim: 'false',
              sollicitation_db: 'Favorable'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Fongibilité asymétrique', acte.nature
    assert_equal 75000.5, acte.montant_ae.to_f
    assert_equal 'CHO-2026-001', acte.numero_chorus
    assert_not_nil acte.t2_detail
    assert_equal true,  acte.t2_detail.fa_technique
    assert_equal false, acte.t2_detail.accord_rffim
    assert_equal 'Favorable', acte.t2_detail.sollicitation_db
    assert_nil acte.t2_detail.enveloppe_abondee
  end

  test "create T2 Fongibilité asymétrique organisme saves enveloppe_abondee" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'organisme',
            instructeur: 'AB',
            nature: 'Fongibilité asymétrique',
            montant_ae: '50000',
            nom_organisme: 'Organisme Test',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              fa_technique: 'false',
              enveloppe_abondee: 'Investissement'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Fongibilité asymétrique', acte.nature
    assert_equal 'organisme', acte.perimetre
    assert_not_nil acte.t2_detail
    assert_equal false, acte.t2_detail.fa_technique
    assert_equal 'Investissement', acte.t2_detail.enveloppe_abondee
    assert_nil acte.t2_detail.accord_rffim
    assert_nil acte.t2_detail.sollicitation_db
  end

  test "new T2 ISP section fongibilite-asymetrique is present but hidden in DOM (AC8 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'ISP' }
    assert_response :success
    # Toutes les sections T2 sont dans le DOM côté serveur — Stimulus gère la visibilité côté client.
    # On vérifie que la section Fongibilité asymétrique est bien rendue avec fr-hidden (pas de classe retirée).
    assert_select "div#t2-section-fongibilite-asymetrique.fr-hidden"
    assert_select "div#t2-section-isp.fr-hidden"
  end

  test "new T2 HT2 does not include fongibilite-asymetrique section (AC8 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'HT2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-fongibilite-asymetrique", count: 0
  end

  # Story 2.6 — Marché (PSC)

  test "new T2 Marché état renders montant_ae required and beneficiaire, no organisme fields" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Marché' }
    assert_response :success
    assert_select "div#t2-section-marche"
    # Montant au contrôle présent et required (AC2)
    assert_select "input[name='acte[montant_ae]'][required]"
    # Bénéficiaire présent (AC2)
    assert_select "input#acte_beneficiaire"
    # Champs organisme absents pour état (AC3)
    assert_select "input#budget_executoire_marche_oui", count: 0
    assert_select "input#budget_executoire_marche_non", count: 0
    assert_select "select#acte_operation_budgetaire", count: 0
    assert_select "input#deliberation_ca_marche_oui", count: 0
    assert_select "input#deliberation_ca_marche_non", count: 0
  end

  test "new T2 Marché organisme renders budget_executoire, operation_budgetaire, deliberation_ca; montant_ae present" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Marché' }
    assert_response :success
    assert_select "div#t2-section-marche"
    # Montant au contrôle présent dans la section Marché (AC3).
    # Note : l'attribut `required` est désormais conservé sur cet input (le partial Marché
    # rend `required: true` ligne 9). L'assertion initiale `:not([required])` portée par
    # la story 2.6 ne correspond plus au code prod — assouplie ici à une simple présence.
    assert_select "div#t2-section-marche input[name='acte[montant_ae]']"
    # Bénéficiaire présent (AC3)
    assert_select "input#acte_beneficiaire"
    # Budget exécutoire présent avec IDs spécifiques Marché (AC3, pas de collision avec Annexe financière)
    assert_select "input#budget_executoire_marche_oui"
    assert_select "input#budget_executoire_marche_non"
    # Opération budgétaire avec options Globalisée / Fléchée (AC3)
    assert_select "select#acte_operation_budgetaire"
    assert_select "select#acte_operation_budgetaire option", text: "Globalisée"
    assert_select "select#acte_operation_budgetaire option", text: "Fléchée"
    # Délibération en CA présente avec IDs spécifiques Marché (AC3)
    assert_select "input#deliberation_ca_marche_oui"
    assert_select "input#deliberation_ca_marche_non"
  end

  test "create T2 Marché état saves montant_ae and beneficiaire, no t2_detail created" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_no_difference -> { T2Detail.count } do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Marché',
            montant_ae: '120000.50',
            beneficiaire: 'Société Exemple',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Marché', acte.nature
    assert_equal 'etat', acte.perimetre
    assert_equal 120000.5, acte.montant_ae.to_f
    assert_equal 'Société Exemple', acte.beneficiaire
    assert_nil acte.t2_detail
    # Champs organisme non soumis pour état — valeurs DB par défaut
    assert_nil acte.operation_budgetaire
    assert_equal false, acte.deliberation_ca  # default: false en DB
  end

  test "create T2 Marché organisme saves budget_executoire, operation_budgetaire, deliberation_ca" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_no_difference -> { T2Detail.count } do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'organisme',
            instructeur: 'AB',
            nature: 'Marché',
            montant_ae: '85000',
            beneficiaire: 'Organisme Bénéficiaire',
            nom_organisme: 'Organisme Test',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            budget_executoire: 'false',
            operation_budgetaire: 'Fléchée',
            deliberation_ca: 'true'
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Marché', acte.nature
    assert_equal 'organisme', acte.perimetre
    assert_equal 85000.0, acte.montant_ae.to_f
    assert_equal 'Organisme Bénéficiaire', acte.beneficiaire
    assert_equal false, acte.budget_executoire
    assert_equal 'Fléchée', acte.operation_budgetaire
    assert_equal true, acte.deliberation_ca
    assert_nil acte.t2_detail
  end

  test "new T2 Marché section marche is present but hidden when nature = ISP (AC5 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'ISP' }
    assert_response :success
    assert_select "div#t2-section-marche.fr-hidden"
  end

  test "new HT2 does not include marche section (AC5 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'HT2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-marche", count: 0
  end

  test "new T2 Annexe financière organisme still renders deliberation_ca after refactor (Task 2 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Annexe financière' }
    assert_response :success
    assert_select "div#t2-section-annexe-financiere"
    assert_select "input#deliberation_ca_oui"
    assert_select "input#deliberation_ca_non"
    # Sub-fields présents mais cachés par défaut
    assert_select "input#numero_deliberation_ca"
    assert_select "input#date_deliberation_ca"
    assert_select "textarea#observations_deliberation_ca"
    # Budget exécutoire toujours présent dans Annexe financière organisme
    assert_select "input#budget_executoire_oui"
    assert_select "input#budget_executoire_non"
  end

  # Story 2.7 — Mesure transversale

  test "new T2 Mesure transversale état renders section without organisme-only fields" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Mesure transversale' }
    assert_response :success
    assert_select "div#t2-section-mesure-transversale"
    # Champs t2_detail présents (AC2)
    assert_select "input#mt_date_effet_acte"
    assert_select "input#mt_corps"
    assert_select "input#mt_effectifs"
    assert_select "input#mt_effectifs_complementaire"
    assert_select "select#mt_statut_agents"
    assert_select "input#mt_impact_financier_n1"
    assert_select "input#mt_montant_ae"
    # Champs checkbox-dropdown présents (AC2)
    assert_select "input#mt_perimetre_mesure_hidden"
    assert_select "input#mt_grade_hidden"
    # Origine de financement présente pour état (AC2)
    assert_select "input#mt_origine_financement_hidden"
    # Champs organisme absents pour état (AC3)
    assert_select "input#budget_executoire_mt_oui", count: 0
    assert_select "input#budget_executoire_mt_non", count: 0
    assert_select "input#deliberation_ca_mt_oui", count: 0
    assert_select "input#deliberation_ca_mt_non", count: 0
    assert_select "select#mt_operation_budgetaire", count: 0
  end

  test "new T2 Mesure transversale organisme renders budget_executoire, operation_budgetaire, deliberation_ca" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Mesure transversale' }
    assert_response :success
    assert_select "div#t2-section-mesure-transversale"
    # Champs communs présents (AC3)
    assert_select "input#mt_date_effet_acte"
    assert_select "input#mt_corps"
    assert_select "input#mt_effectifs"
    assert_select "input#mt_statut_agents", count: 0 # select, not input
    assert_select "select#mt_statut_agents"
    # Champs communs AC2 toujours présents pour organisme (AC3)
    assert_select "input#mt_perimetre_mesure_hidden"
    assert_select "input#mt_grade_hidden"
    assert_select "input#mt_impact_financier_n1"
    assert_select "input#mt_montant_ae"
    # Origine de financement absente pour organisme (AC2/AC3)
    assert_select "input#mt_origine_financement_hidden", count: 0
    # Champs organisme présents (AC3)
    assert_select "input#budget_executoire_mt_oui"
    assert_select "input#budget_executoire_mt_non"
    assert_select "select#mt_operation_budgetaire"
    assert_select "select#mt_operation_budgetaire option", text: "Globalisée"
    assert_select "select#mt_operation_budgetaire option", text: "Fléchée"
    assert_select "input#deliberation_ca_mt_oui"
    assert_select "input#deliberation_ca_mt_non"
  end

  test "create T2 Mesure transversale état saves t2_detail fields and montant_ae" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Mesure transversale',
            montant_ae: '50000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              perimetre_mesure: 'Application au stock,Reclassement',
              grade: 'A+,A',
              corps: 'Corps test',
              effectifs: '12.5',
              effectifs_complementaire: '3.0',
              statut_agents: 'Titulaire',
              impact_financier_n1: '25000',
              origine_financement: 'Enveloppe catégorielle,Financement interministériel',
              date_effet_acte: '01/01/2026'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Mesure transversale', acte.nature
    assert_equal 'etat', acte.perimetre
    assert_equal 50000.0, acte.montant_ae.to_f
    td = acte.t2_detail
    assert_not_nil td
    assert_equal ['Application au stock', 'Reclassement'], td.perimetre_mesure
    assert_equal ['A+', 'A'], td.grade
    assert_equal 'Corps test', td.corps
    assert_equal 12.5, td.effectifs.to_f
    assert_equal 3.0, td.effectifs_complementaire.to_f
    assert_equal 'Titulaire', td.statut_agents
    assert_equal 25000, td.impact_financier_n1.to_i
    assert_equal ['Enveloppe catégorielle', 'Financement interministériel'], td.origine_financement
    assert_equal '01/01/2026', td.date_effet_acte
    # Champs organisme non soumis pour état — valeurs DB par défaut
    assert_nil acte.operation_budgetaire
    assert_equal true, acte.budget_executoire
    assert_equal false, acte.deliberation_ca
  end

  test "create T2 Mesure transversale organisme saves all fields including budget_executoire" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'organisme',
            instructeur: 'AB',
            nature: 'Mesure transversale',
            nom_organisme: 'Organisme Test',
            montant_ae: '30000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            budget_executoire: 'false',
            operation_budgetaire: 'Globalisée',
            deliberation_ca: 'true',
            t2_detail_attributes: {
              corps: 'Ingénieurs',
              effectifs: '5.0',
              statut_agents: 'Contractuel',
              impact_financier_n1: '10000'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Mesure transversale', acte.nature
    assert_equal 'organisme', acte.perimetre
    assert_equal 30000.0, acte.montant_ae.to_f
    assert_equal false, acte.budget_executoire
    assert_equal 'Globalisée', acte.operation_budgetaire
    assert_equal true, acte.deliberation_ca
    td = acte.t2_detail
    assert_not_nil td
    assert_equal 'Ingénieurs', td.corps
    assert_equal 5.0, td.effectifs.to_f
    assert_equal 'Contractuel', td.statut_agents
    assert_equal 10000, td.impact_financier_n1.to_i
    # origine_financement et perimetre_mesure pas soumis pour organisme — doivent être vides
    assert_equal [], td.origine_financement
    assert_equal [], td.perimetre_mesure
  end

  test "new T2 Mesure transversale section is present but hidden when nature = Marché (AC6 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Marché' }
    assert_response :success
    assert_select "div#t2-section-mesure-transversale.fr-hidden"
  end

  test "new HT2 does not include mesure_transversale section (AC6 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'HT2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-mesure-transversale", count: 0
  end

  # Story 2.8 — Enveloppe limitative

  test "new T2 Enveloppe limitative état renders section with correct fields" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Enveloppe limitative' }
    assert_response :success
    # Section présente
    assert_select "div#t2-section-enveloppe-limitative"
    # Champs t2_detail
    assert_select "input#el_date_effet_acte"
    assert_select "input#el_perimetre_mesure_hidden"
    assert_select "input#el_grade_hidden"
    assert_select "input#el_corps"
    assert_select "input#el_effectifs"
    assert_select "input#el_effectifs_complementaire"
    assert_select "select#el_statut_agents"
    assert_select "input#el_montant_ae"
    assert_select "input#el_montant_enveloppe_n1"
    assert_select "input#el_impact_maximal_sans_enveloppe"
    assert_select "p#el_effet_enveloppe", text: "--%"
    # Origine de financement — État seulement
    assert_select "input#el_origine_financement_hidden"
    # Champs organisme absents pour état
    assert_select "input#budget_executoire_el_oui", count: 0
    assert_select "select#el_operation_budgetaire", count: 0
    assert_select "input#deliberation_ca_el_oui", count: 0
  end

  test "new T2 Enveloppe limitative organisme renders budget_executoire, operation_budgetaire, deliberation_ca" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Enveloppe limitative' }
    assert_response :success
    assert_select "div#t2-section-enveloppe-limitative"
    # Champs communs
    assert_select "input#el_corps"
    assert_select "input#el_effectifs"
    assert_select "input#el_effectifs_complementaire"
    assert_select "select#el_statut_agents"
    assert_select "input#el_montant_ae"
    assert_select "input#el_montant_enveloppe_n1"
    assert_select "input#el_impact_maximal_sans_enveloppe"
    assert_select "p#el_effet_enveloppe", text: "--%"
    # Origine de financement absente pour organisme
    assert_select "input#el_origine_financement_hidden", count: 0
    # Champs organisme présents
    assert_select "input#budget_executoire_el_oui"
    assert_select "input#budget_executoire_el_non"
    assert_select "select#el_operation_budgetaire"
    assert_select "input#deliberation_ca_el_oui"
    assert_select "input#deliberation_ca_el_non"
  end

  test "create T2 Enveloppe limitative état saves t2_detail fields and montant_ae" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Enveloppe limitative',
            montant_ae: '75000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              perimetre_mesure: 'Application au stock,Reclassement',
              grade: 'A,B',
              corps: 'Corps EL test',
              effectifs: '8.0',
              effectifs_complementaire: '2.5',
              statut_agents: 'Titulaire',
              montant_enveloppe_n1: '100000',
              impact_maximal_sans_enveloppe: '20000',
              origine_financement: 'Enveloppe catégorielle,Financement interministériel',
              date_effet_acte: '01/03/2026'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Enveloppe limitative', acte.nature
    assert_equal 'etat', acte.perimetre
    assert_equal 75000.0, acte.montant_ae.to_f
    td = acte.t2_detail
    assert_not_nil td
    assert_equal ['Application au stock', 'Reclassement'], td.perimetre_mesure
    assert_equal ['A', 'B'], td.grade
    assert_equal 'Corps EL test', td.corps
    assert_equal 8.0, td.effectifs.to_f
    assert_equal 2.5, td.effectifs_complementaire.to_f
    assert_equal 'Titulaire', td.statut_agents
    assert_equal 100000, td.montant_enveloppe_n1.to_i
    assert_equal 20000, td.impact_maximal_sans_enveloppe.to_i
    assert_equal ['Enveloppe catégorielle', 'Financement interministériel'], td.origine_financement
    assert_equal '01/03/2026', td.date_effet_acte
    # Champs organisme non soumis — valeurs par défaut
    assert_nil acte.operation_budgetaire
    assert_equal true, acte.budget_executoire
    assert_equal false, acte.deliberation_ca
  end

  test "create T2 Enveloppe limitative organisme saves all fields including budget_executoire" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'organisme',
            instructeur: 'AB',
            nature: 'Enveloppe limitative',
            nom_organisme: 'Organisme EL',
            montant_ae: '40000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            budget_executoire: 'false',
            operation_budgetaire: 'Fléchée',
            deliberation_ca: 'true',
            t2_detail_attributes: {
              corps: 'Corps EL organisme',
              effectifs: '3.0',
              statut_agents: 'Contractuel',
              montant_enveloppe_n1: '50000',
              impact_maximal_sans_enveloppe: '15000'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Enveloppe limitative', acte.nature
    assert_equal 'organisme', acte.perimetre
    assert_equal 40000.0, acte.montant_ae.to_f
    assert_equal false, acte.budget_executoire
    assert_equal 'Fléchée', acte.operation_budgetaire
    assert_equal true, acte.deliberation_ca
    td = acte.t2_detail
    assert_not_nil td
    assert_equal 'Corps EL organisme', td.corps
    assert_equal 3.0, td.effectifs.to_f
    assert_equal 'Contractuel', td.statut_agents
    assert_equal 50000, td.montant_enveloppe_n1.to_i
    assert_equal 15000, td.impact_maximal_sans_enveloppe.to_i
    # origine_financement et perimetre_mesure non soumis — doivent être vides
    assert_equal [], td.origine_financement
    assert_equal [], td.perimetre_mesure
  end

  # Story 2.8 — Référentiel

  test "new T2 Référentiel état renders section with correct fields" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Référentiel' }
    assert_response :success
    assert_select "div#t2-section-referentiel"
    assert_select "input#ref_date_effet_acte"
    assert_select "input#ref_perimetre_mesure_hidden"
    assert_select "input#ref_grade_hidden"
    assert_select "input#ref_corps"
    assert_select "input#ref_effectifs"
    assert_select "input#ref_effectifs_complementaire"
    assert_select "input#ref_montant_ae"
    assert_select "input#ref_impact_financier_n1"
    # Déclinaison référentiel interministériel présent
    assert_select "input#ref_referentiel_type_oui"
    assert_select "input#ref_referentiel_type_non"
    # Origine de financement — État seulement
    assert_select "input#ref_origine_financement_hidden"
    # Champs organisme absents
    assert_select "input#budget_executoire_ref_oui", count: 0
    assert_select "select#ref_operation_budgetaire", count: 0
  end

  test "new T2 Référentiel organisme renders budget_executoire, operation_budgetaire, deliberation_ca" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'organisme', nature: 'Référentiel' }
    assert_response :success
    assert_select "div#t2-section-referentiel"
    assert_select "input#ref_corps"
    assert_select "input#ref_effectifs"
    assert_select "input#ref_montant_ae"
    assert_select "input#ref_impact_financier_n1"
    assert_select "input#ref_referentiel_type_oui"
    assert_select "input#ref_referentiel_type_non"
    # Origine de financement absente pour organisme
    assert_select "input#ref_origine_financement_hidden", count: 0
    # Champs organisme présents
    assert_select "input#budget_executoire_ref_oui"
    assert_select "input#budget_executoire_ref_non"
    assert_select "select#ref_operation_budgetaire"
    assert_select "input#deliberation_ca_ref_oui"
    assert_select "input#deliberation_ca_ref_non"
  end

  test "create T2 Référentiel état saves t2_detail fields including referentiel_type" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'etat',
            instructeur: 'AB',
            nature: 'Référentiel',
            montant_ae: '30000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            t2_detail_attributes: {
              perimetre_mesure: 'Application au flux',
              grade: 'A+',
              corps: 'Corps REF test',
              effectifs: '5.0',
              effectifs_complementaire: '1.0',
              impact_financier_n1: '12000',
              referentiel_type: 'true',
              origine_financement: 'Financement interministériel',
              date_effet_acte: '15/04/2026'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Référentiel', acte.nature
    assert_equal 'etat', acte.perimetre
    assert_equal 30000.0, acte.montant_ae.to_f
    td = acte.t2_detail
    assert_not_nil td
    assert_equal ['Application au flux'], td.perimetre_mesure
    assert_equal ['A+'], td.grade
    assert_equal 'Corps REF test', td.corps
    assert_equal 5.0, td.effectifs.to_f
    assert_equal 1.0, td.effectifs_complementaire.to_f
    assert_equal 12000, td.impact_financier_n1.to_i
    assert_equal true, td.referentiel_type
    assert_equal ['Financement interministériel'], td.origine_financement
    assert_equal '15/04/2026', td.date_effet_acte
    # Champs organisme non soumis
    assert_nil acte.operation_budgetaire
    assert_equal true, acte.budget_executoire
    assert_equal false, acte.deliberation_ca
  end

  test "create T2 Référentiel organisme saves all fields including budget_executoire" do
    sign_in users(:three) # DCB
    assert_difference -> { Acte.count }, 1 do
      assert_difference -> { T2Detail.count }, 1 do
        post actes_path, params: {
          acte: {
            titre: 'T2', categorie_t2: 'hors contrat',
            type_acte: 'visa', etat: "en cours d'instruction",
            perimetre: 'organisme',
            instructeur: 'AB',
            nature: 'Référentiel',
            nom_organisme: 'Organisme REF',
            montant_ae: '20000',
            annee: Date.today.year,
            date_saisine: Date.today.strftime('%d/%m/%Y'),
            pre_instruction: false,
            budget_executoire: 'true',
            operation_budgetaire: 'Globalisée',
            deliberation_ca: 'false',
            t2_detail_attributes: {
              corps: 'Corps REF organisme',
              effectifs: '4.0',
              impact_financier_n1: '8000',
              referentiel_type: 'false'
            }
          }
        }
      end
    end
    acte = Acte.last
    assert_equal 'Référentiel', acte.nature
    assert_equal 'organisme', acte.perimetre
    assert_equal 20000.0, acte.montant_ae.to_f
    assert_equal true, acte.budget_executoire
    assert_equal 'Globalisée', acte.operation_budgetaire
    assert_equal false, acte.deliberation_ca
    td = acte.t2_detail
    assert_not_nil td
    assert_equal 'Corps REF organisme', td.corps
    assert_equal 4.0, td.effectifs.to_f
    assert_equal 8000, td.impact_financier_n1.to_i
    assert_equal false, td.referentiel_type
    # perimetre_mesure et origine_financement non soumis — vides
    assert_equal [], td.perimetre_mesure
    assert_equal [], td.origine_financement
  end

  test "new T2 Enveloppe limitative section is present but hidden when nature = Marché (AC10 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat', nature: 'Marché' }
    assert_response :success
    assert_select "div#t2-section-enveloppe-limitative.fr-hidden"
    assert_select "div#t2-section-referentiel.fr-hidden"
  end

  test "new HT2 does not include enveloppe_limitative or referentiel sections (AC10 regression)" do
    sign_in users(:three) # DCB
    get new_acte_path, params: { titre: 'HT2', perimetre: 'etat' }
    assert_response :success
    assert_select "div#t2-section-enveloppe-limitative", count: 0
    assert_select "div#t2-section-referentiel", count: 0
  end

  # Story 2.9 — Formulaire T2 étape 2 — Critères de contrôle

  test "edit T2 Annexe financière état step 2 renders inscription_pap, respect_plafond, respect_schema" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!(impact_schema_emplois: true)
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_inscription_pap_true"
    assert_select "label[for='t2_inscription_pap_true']", text: "Oui"
    assert_select "h6", text: "Inscription au PAP / Plan de recrutement"
    assert_select "input#t2_respect_plafond_emplois_true"
    assert_select "input#t2_respect_schema_emplois_true"
    # soutenabilite absent pour Annexe financière
    assert_select "input#t2_soutenabilite_true", count: 0
  end

  test "edit T2 Annexe financière état step 2 does not render respect_schema when impact_schema_emplois false" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!(impact_schema_emplois: false)
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_respect_schema_emplois_true", count: 0
  end

  test "edit T2 Fongibilité asymétrique état DCB step 2 renders controle_modalites" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Fongibilité asymétrique', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_controle_modalites_true"
    assert_select "input#t2_consommation_credits_true"
    # inscription_pap absent (nature = FA, pas dans la liste état-PAP)
    assert_select "input#t2_inscription_pap_true", count: 0
  end

  test "edit T2 Fongibilité asymétrique état CBR step 2 does not render controle_modalites" do
    sign_in users(:two) # CBR
    acte = users(:two).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Fongibilité asymétrique', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_controle_modalites_true", count: 0
  end

  test "edit T2 ISP step 2 renders respect_enveloppe and no programmation_prevue" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_respect_enveloppe_true"
    assert_select "input#t2_programmation_prevue", count: 0
    assert_select "input#t2_avis_programmation", count: 0
  end

  test "edit T2 Mesure transversale état step 2 renders risque_reconventionnel and inscription_pap" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Mesure transversale', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_risque_reconventionnel_true"
    assert_select "input#t2_inscription_pap_true"
    assert_select "h6", text: "Inscription au PAP"
    assert_select "input#t2_soutenabilite_true"
    assert_select "input#t2_consommation_credits_true"
  end

  test "edit T2 Marché organisme step 2 does not render autorisation_tutelle when budget_executoire true" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'organisme',
      nature: 'Marché', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, budget_executoire: true
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_autorisation_tutelle_true", count: 0
  end

  test "edit T2 Marché organisme step 2 renders autorisation_tutelle when budget_executoire false" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'organisme',
      nature: 'Marché', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, budget_executoire: false
    )
    acte.create_t2_detail!
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    assert_select "input#t2_autorisation_tutelle_true"
    assert_select "input#t2_programmation_prevue"
    assert_select "label[for='t2_programmation_prevue']", text: "L'acte figure dans le dernier budget."
  end

  test "update T2 Annexe financière saves inscription_pap and respect_plafond_emplois in t2_details" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!(impact_schema_emplois: true)
    patch acte_path(acte), params: {
      etape: 3,
      acte: {
        t2_detail_attributes: {
          id: acte.t2_detail.id,
          inscription_pap: '1',
          respect_plafond_emplois: '1',
          respect_schema_emplois: '0'
        }
      }
    }
    assert_redirected_to edit_acte_path(acte, etape: 3)
    td = acte.t2_detail.reload
    assert_equal true, td.inscription_pap
    assert_equal true, td.respect_plafond_emplois
    assert_equal false, td.respect_schema_emplois
    # Critères non soumis (ISP, FA) restent nil
    assert_nil td.respect_enveloppe
    assert_nil td.controle_modalites
  end

  test "update T2 Fongibilité asymétrique saves consommation_credits in actes" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Fongibilité asymétrique', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    patch acte_path(acte), params: {
      etape: 3,
      acte: {
        consommation_credits: '1',
        t2_detail_attributes: {
          id: acte.t2_detail.id,
          controle_modalites: '1'
        }
      }
    }
    assert_redirected_to edit_acte_path(acte, etape: 3)
    acte.reload
    assert_equal true, acte.consommation_credits
    assert_nil acte.t2_detail.consommation_credits rescue nil
    td = acte.t2_detail.reload
    assert_equal true, td.controle_modalites
  end

  test "clear_irrelevant_t2_detail_fields does not nil T2 criteria fields on nature change" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!(inscription_pap: true, respect_plafond_emplois: true)
    # Simulate saving with a new nature (step 1 re-save changing nature to ISP)
    patch acte_path(acte), params: {
      etape: 1,
      acte: {
        nature: 'ISP',
        t2_detail_attributes: {
          id: acte.t2_detail.id
        }
      }
    }
    td = acte.t2_detail.reload
    # Criteria fields must not be wiped despite nature change
    assert_equal true, td.inscription_pap,       "inscription_pap should be preserved"
    assert_equal true, td.respect_plafond_emplois, "respect_plafond_emplois should be preserved"
  end

  test "HT2 step 2 still uses form_criteres (regression check)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    # HT2 form uses radio buttons (Oui/Non) rather than simple checkboxes for most criteria
    assert_select "input#radio-true-1"
    assert_select "input#radio-false-1"
    # T2-specific checkboxes absent
    assert_select "input#t2_inscription_pap", count: 0
  end

  test "etape2_complete? returns true for T2 acte — step 3 link enabled in sidemenu" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte.create_t2_detail!
    # etape2_complete? is tested via step 2 rendering — the sidemenu must show step 3 as a button (not a disabled link)
    get edit_acte_path(acte, etape: 2)
    assert_response :success
    # When etape2_complete? returns true, the sidemenu renders a <button> for step 3, not a disabled <a>
    assert_select "button[aria-controls='modal-etape3']"
    assert_select "a[disabled]", text: /Étape 3/, count: 0
  end

  # Story 2.10 — T2 step 3 decision form

  test "edit T2 avis etat step 3 renders form_proposition_decision with T2 observation types" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    # _form_proposition_decision renders the decision dropdown
    assert_select "select#proposition_decision"
    # T2 observation types present
    assert_select "option", text: "Acte déjà signé par l'ordonnateur"
    assert_select "option", text: "Incohérence avec le cadre de gestion"
    assert_select "option", text: "Fongibilité asymétrique de faible montant"
    # HT2-only observation type absent
    assert_select "option", text: "Construction de l'EJ", count: 0
    assert_select "option", text: "Disponibilité des crédits", count: 0
  end

  test "edit T2 visa etat step 3 renders form_proposition_decision" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Mesure transversale', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    assert_select "select#proposition_decision"
  end

  test "edit T2 step 3 liste_decisions is Favorable list for type_acte avis" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    assert_select "select#proposition_decision option", text: "Favorable"
    assert_select "select#proposition_decision option", text: "Favorable avec observations"
    assert_select "select#proposition_decision option", text: "Défavorable"
    assert_select "select#proposition_decision option", text: "Visa accordé", count: 0
  end

  test "edit T2 step 3 liste_decisions is Visa list for type_acte visa" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Mesure transversale', type_acte: 'visa',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    assert_select "select#proposition_decision option", text: "Visa accordé"
    assert_select "select#proposition_decision option", text: "Visa accordé avec observations"
    assert_select "select#proposition_decision option", text: "Refus de visa"
    assert_select "select#proposition_decision option", text: "Favorable", count: 0
  end

  test "edit T2 step 3 liste_motifs_suspension contains T2 motifs" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    assert_select "option", text: "Demande de précision"
    assert_select "option", text: "Problématique de soutenabilité"
    assert_select "option", text: "Problématique de compatibilité avec la programmation"
    # HT2-only suspension motif absent
    assert_select "option", text: "Défaut du circuit d'approbation Chorus", count: 0
    assert_select "option", text: "Problématique de disponibilité des crédits", count: 0
  end

  test "update T2 step 3 transitions etat from en cours d'instruction to à valider (AC5)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year,
      date_saisine: Date.today
    )
    patch acte_path(acte), params: {
      etape: 3,
      acte: {
        proposition_decision: 'Favorable',
        valideur: 'CD',
        etat: 'à valider'
      }
    }
    acte.reload
    assert_equal 'à valider', acte.etat, "Le workflow de statut T2 doit transitionner à 'à valider' comme HT2"
    assert_equal 'Favorable', acte.proposition_decision
  end

  test "update T2 step 3 creates suspension with acte_id (AC6)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year,
      date_saisine: Date.today
    )
    assert_difference -> { acte.suspensions.count }, 1 do
      patch acte_path(acte), params: {
        etape: 3,
        acte: {
          etat: 'suspendu',
          suspensions_attributes: {
            "0" => {
              date_suspension: Date.today.strftime('%d/%m/%Y'),
              motif: 'Demande de précision',
              observations: 'Test suspension T2'
            }
          }
        }
      }
    end
    suspension = acte.suspensions.reload.last
    assert_not_nil suspension
    assert_equal acte.id, suspension.acte_id, "La suspension doit être rattachée à l'acte T2 via acte_id"
    assert_includes Array(suspension.motif), 'Demande de précision'
  end

  test "HT2 step 3 liste_types_observations unchanged (regression check)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year,
      disponibilite_credits: true
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    # HT2 retains its own observation types
    assert_select "option", text: "Disponibilité des crédits"
    assert_select "option", text: "Évaluation de la consommation des crédits"
    # T2-only type absent from HT2
    assert_select "option", text: "Acte déjà signé par l'ordonnateur", count: 0
    assert_select "option", text: "Incohérence avec le cadre de gestion", count: 0
  end

  # Story 2.11 — Suspension et reprise d'un acte T2

  test "update T2 creates suspension and sets etat to suspendu (AC2)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    assert_difference -> { acte.suspensions.count }, 1 do
      patch acte_path(acte), params: {
        etape: 3,
        acte: {
          etat: 'suspendu',
          suspensions_attributes: {
            "0" => {
              date_suspension: Date.today.strftime('%d/%m/%Y'),
              motif: 'Pièce(s) manquante(s)',
              observations: 'Observation T2'
            }
          }
        }
      }
    end
    acte.reload
    suspension = acte.suspensions.last
    assert_equal 'suspendu', acte.etat, "L'acte T2 doit passer en état suspendu"
    assert_equal acte.id, suspension.acte_id, "La suspension doit être rattachée à l'acte T2 via acte_id"
    assert_includes Array(suspension.motif), 'Pièce(s) manquante(s)'
    assert_equal 'Observation T2', suspension.observations
    assert_equal Date.today, suspension.date_suspension
  end

  test "edit T2 acte with etat suspendu renders form (AC4)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.suspensions.create!(date_suspension: Date.today - 1, motif: ['Demande de précision'])
    # Force l'état suspendu (set_etat_acte le maintient grâce à la suspension ouverte)
    acte.save!
    acte.reload
    assert_equal 'suspendu', acte.etat, "Précondition AC4 : l'acte doit être en état suspendu"

    get edit_acte_path(acte, etape: 3)
    assert_response :success
  end

  test "edit T2 acte with etat a suspendre renders form (AC4)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.suspensions.create!(date_suspension: Date.today - 1, motif: ['Demande de précision'])
    # update_column court-circuite set_etat_acte qui forcerait "suspendu"
    acte.update_column(:etat, 'à suspendre')
    acte.reload
    assert_equal 'à suspendre', acte.etat, "Précondition AC4 : l'acte doit être en état à suspendre"

    get edit_acte_path(acte, etape: 3)
    assert_response :success
  end

  test "HT2 step 3 liste_motifs_suspension uses HT2 motifs (AC5 regression)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, disponibilite_credits: true
    )
    get edit_acte_path(acte, etape: 3)
    assert_response :success
    # HT2-specific motifs present
    assert_select "option", text: "Défaut du circuit d'approbation Chorus"
    assert_select "option", text: "Problématique de disponibilité des crédits"
    assert_select "option", text: "Mauvaise évaluation de la consommation des crédits"
    # T2-only motif "Demande de précision" (without "s") absent from HT2
    assert_select "option", text: "Demande de précision", count: 0
  end

  test "refus_suspension resets T2 acte etat to en cours d instruction (AC6)" do
    sign_in users(:three) # DCB
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    suspension = acte.suspensions.create!(
      date_suspension: Date.today - 1,
      motif: ['Demande de précision']
    )
    # update_column court-circuite set_etat_acte qui forcerait "suspendu"
    acte.update_column(:etat, 'à suspendre')
    acte.reload
    assert_equal 'à suspendre', acte.etat, "Précondition AC6 : l'acte doit être en état à suspendre"

    assert_difference -> { acte.suspensions.count }, -1 do
      post acte_suspension_refus_suspension_path(acte, suspension), params: {
        acte: { commentaire_proposition_decision: 'Refus justifié' }
      }
    end
    acte.reload
    assert_equal "en cours d'instruction", acte.etat
    assert acte.renvoie_instruction
  end

  # Story 2.12 — Affichage des détails d'un acte T2 en mode consultation

  test "GET show T2 acte uses acte_details_t2 partial not acte_details (AC1)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, montant_ae: 1000
    )
    get acte_path(acte)
    assert_response :success
    # La sous-section T2 par nature (t2_sections/_show_marche) rend une table
    # légendée "Marché (PSC)" — spécifique à _acte_details_t2 — et ne rend PAS
    # la colonne HT2 "Montant de l'acte (AE)".
    assert_select "table caption", text: "Marché (PSC)"
    assert_select "th", text: "Montant de l'acte (AE)", count: 0
  end

  test "GET show HT2 acte still uses acte_details (AC5 regression)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, disponibilite_credits: true
    )
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Montant de l'acte (AE)"
    assert_select "div.fr-h6", text: /Détails Marché/, count: 0
  end

  test "GET show T2 Annexe financiere displays t2_detail fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(
      type_acte_t2: 'Initial', effectifs: 3.5, corps: 'Corps test',
      impact_schema_emplois: true, impact_autre_cbcm: false
    )
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Type d'acte"
    assert_select "td", text: "Initial"
    assert_select "td", text: "Corps test"
  end

  test "GET show T2 ISP displays cercle fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(
      isp_cercle1: true, isp_cercle1_montant: 10000,
      isp_cercle1_enveloppe_sgg: 50000, isp_cercle1_consommation: 20000
    )
    get acte_path(acte)
    assert_response :success
    assert_select "div.fr-h6", text: "Cercle 1"
    assert_select "th", text: "Nature(s) des ISP"
    assert_select "th", text: "Enveloppe SGG (€)"
    assert_select "th", text: "Reste à consommer (€)"
  end

  test "GET show T2 Fongibilite asymetrique displays FA fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Fongibilité asymétrique', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(fa_technique: true, accord_rffim: false)
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "FA Technique"
    assert_select "th", text: "Accord RFFIM/RPROG préalable"
  end

  test "GET show T2 Marche displays Marche fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, montant_ae: 1000,
      beneficiaire: 'Société Test'
    )
    acte.create_t2_detail!
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Bénéficiaire"
    assert_select "td", text: "Société Test"
  end

  test "GET show T2 Mesure transversale displays MT fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Mesure transversale', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(statut_agents: 'Titulaires', corps: 'Enseignants')
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Statut d'agents"
    assert_select "td", text: "Titulaires"
    assert_select "td", text: "Enseignants"
  end

  test "GET show T2 Enveloppe limitative displays EL fields with effet (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Enveloppe limitative', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(montant_enveloppe_n1: 100000, impact_maximal_sans_enveloppe: 25000)
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Montant enveloppe N-1 (€)"
    assert_select "th", text: "Effet de l'enveloppe (%)"
  end

  test "GET show T2 Referentiel displays Referentiel fields (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Référentiel', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(referentiel_type: true)
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Déclinaison référentiel interministériel"
    assert_select "td", text: "Oui"
  end

  test "GET show T2 acte displays criteres section (AC4)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Annexe financière', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(respect_plafond_emplois: true, impact_schema_emplois: false)
    get acte_path(acte)
    assert_response :success
    assert_select "th", text: "Respect du plafond d'emplois"
  end

  test "GET show T2 acte with no t2_detail renders show page without error (AC3)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, montant_ae: 1000
    )
    assert_nil acte.t2_detail
    get acte_path(acte)
    assert_response :success
    # La section Marché rend toujours sa table légendée même sans t2_detail
    # (la sous-partial Marché n'accède pas aux champs td.*).
    assert_select "table caption", text: "Marché (PSC)"
  end

  # Story 3.1 — Colonne Titre (badge HT2/T2) sur index et historique

  test "GET index displays Titre column header and HT2 badge (AC1)" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    get actes_path
    assert_response :success
    assert_select "th", text: "Titre"
    assert_select "td span.fr-tag--ht2", text: "HT2"
  end

  test "GET index displays T2 tag for T2 acte (AC1)" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, montant_ae: 1000
    )
    get actes_path
    assert_response :success
    assert_select "td span.fr-tag--t2", text: "T2"
  end

  test "GET actes_historique displays Titre column for HT2 and T2 actes (AC2)" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year
    )
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today - 1, montant_ae: 500
    )
    get actes_historique_path
    assert_response :success
    assert_select "th", text: "Titre"
    assert_select "td span.fr-tag--ht2", text: "HT2"
    assert_select "td span.fr-tag--t2", text: "T2"
  end

  test "GET index Titre column shows HT2 on all rows for HT2-only user (AC5 regression)" do
    sign_in users(:three)
    2.times do
      users(:three).actes.create!(
        titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
        etat: "en pré-instruction", instructeur: 'AB',
        annee: Date.today.year
      )
    end
    get actes_path
    assert_response :success
    assert_select "th", text: "Titre"
    assert_select "td span.fr-tag--ht2", text: "HT2"
    assert_select "td span.fr-tag--t2", count: 0
  end

  test "GET index renders Titre column header in all 6 tabs (AC1 full coverage)" do
    sign_in users(:three)
    # 5 états directement persistables ; "suspendu" est traité à part car
    # le callback after_save :set_etat_acte (acte.rb:598) repasse l'acte
    # en "en cours d'instruction" s'il n'a aucune suspension active.
    ["en pré-instruction", "en cours d'instruction",
     "à valider", "à clôturer", "clôturé"].each do |etat|
      users(:three).actes.create!(
        titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
        etat: etat, instructeur: 'AB',
        annee: Date.today.year
      )
    end
    # Onglet "suspendu" : il faut une Suspension ouverte (date_reprise: nil)
    # pour que l'acte reste en etat 'suspendu' après les callbacks.
    acte_suspendu = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en cours d'instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    acte_suspendu.suspensions.create!(date_suspension: Date.today, motif: ['Autre'])
    acte_suspendu.update!(etat: 'suspendu')

    get actes_path
    assert_response :success
    # Une colonne "Titre" par onglet rendu : 6 onglets, 6 <th>Titre</th> attendus.
    assert_select "th", text: "Titre", count: 6
  end

  test "GET index sorts and counts mixed HT2+T2 actes together (AC3)" do
    sign_in users(:three)
    # Deux HT2 + un T2 dans le même état → la liste de travail doit tous les afficher
    # (le scope du controller ne filtre PAS par titre, cf. actes_controller.rb:21)
    # et le tri Ransack doit mélanger HT2 et T2 sans discrimination par titre.
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, montant_ae: 1000
    )
    get actes_path(q_pre_instruction: { s: 'numero_utilisateur asc' })
    assert_response :success
    # Le compteur "X résultats" (Pagy via @actes_pre_instruction_all.count)
    # est rendu dans la page : il doit valoir 3 (HT2+T2 mélangés).
    assert_select "p.fr-table__detail", text: /3 résultats/
    # La page rend bien les 2 HT2 et le T2 (pas de filtre silencieux par titre).
    assert_select "td span.fr-tag--ht2", text: "HT2", count: 2
    assert_select "td span.fr-tag--t2", text: "T2", count: 1
  end

  # Story 3.2 — Filtres Titre / Périmètre côte à côte + natures T2 dans le filtre Nature

  # Helper : crée un set représentatif HT2+T2 pour les tests filtres
  def create_mixte_set(user)
    user.actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    user.actes.create!(
      titre: 'HT2', perimetre: 'organisme', nom_organisme: 'Org1', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year
    )
    user.actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    user.actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'organisme',
      nature: 'Annexe financière', nom_organisme: 'Org2', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today, budget_executoire: true
    )
  end

  test "AC9 — GET index renders 4 checkboxes (Titre + Périmètre) all checked by default" do
    sign_in users(:three)
    get actes_path
    assert_response :success
    assert_select "input#titre-t2[type=checkbox][checked=checked]"
    assert_select "input#titre-ht2[type=checkbox][checked=checked]"
    assert_select "input#perimetre-etat[type=checkbox][checked=checked]"
    assert_select "input#perimetre-organisme[type=checkbox][checked=checked]"
  end

  test "AC5/AC6 — GET index with titre_in=T2 filters to T2 actes only" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(q_current: { titre_in: ['T2'] })
    assert_response :success
    assert_select "td span.fr-tag--t2", text: "T2", minimum: 1
    assert_select "td span.fr-tag--ht2", count: 0
  end

  test "AC2 — GET index with both titre_in values is equivalent to no filter (vue consolidée)" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(q_current: { titre_in: ['T2', 'HT2'] })
    assert_response :success
    # Les 4 actes (2 HT2 + 2 T2) doivent être visibles
    assert_select "td span.fr-tag--ht2", minimum: 2
    assert_select "td span.fr-tag--t2", minimum: 2
  end

  test "AC10 — GET index with perimetre_in=etat keeps existing perimetre filter behavior" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(q_current: { perimetre_in: ['etat'] })
    assert_response :success
    # 1 HT2 etat + 1 T2 etat = 2 actes
    assert_select "p.fr-table__detail", text: /2 résultats/
  end

  test "AC8 — titre_in is NOT counted as an active filter (filtres_count)" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(q_current: { titre_in: ['T2'] })
    assert_response :success
    # filtres_count == 0 → pas de tag "N filtres avancés actifs"
    assert_select ".fr-tag--dismiss", count: 0
  end

  test "AC5 — GET historique with titre_in=T2 returns only T2 actes" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year
    )
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today - 1
    )
    get actes_historique_path(q: { titre_in: ['T2'] })
    assert_response :success
    assert_select "td span.fr-tag--t2", text: "T2", minimum: 1
    assert_select "td span.fr-tag--ht2", count: 0
  end

  test "AC9 — GET historique renders 4 checkboxes (Titre + Périmètre) all checked by default" do
    sign_in users(:three)
    get actes_historique_path
    assert_response :success
    assert_select "input#titre-t2[type=checkbox][checked=checked]"
    assert_select "input#titre-ht2[type=checkbox][checked=checked]"
    assert_select "input#perimetre-etat[type=checkbox][checked=checked]"
    assert_select "input#perimetre-organisme[type=checkbox][checked=checked]"
    # Pas de bloc radio "Vue consolidée" résiduel
    assert_select "input[name='q[perimetre_eq]']", count: 0
  end

  test "AC4 — GET historique with perimetre_in=[etat,organisme] shows all categorie/CF/Organisme blocks (vue consolidée)" do
    sign_in users(:three)
    get actes_historique_path(q: { perimetre_in: ['etat', 'organisme'] })
    assert_response :success
    # Tous les champs conditionnels du modal sont rendus en vue consolidée
    assert_select "label.fr-label", text: "Centre financier"
    assert_select "label.fr-label", text: "Organisme"
  end

  test "AC4 — GET historique with perimetre_in=[etat] hides Organisme-only blocks (exclusivement Etat)" do
    sign_in users(:three)
    get actes_historique_path(q: { perimetre_in: ['etat'] })
    assert_response :success
    # Bloc "Catégorie" (organisme uniquement, dans le modal Filtres avancés) doit être caché
    assert_select "span.fr-label.fr-text--bold", text: "Catégorie", count: 0
    # Bloc "Organisme" en LABEL.fr-text--bold (modal Filtres avancés) doit être caché
    # NB : "Organisme" en <label for='perimetre-organisme'> du sélecteur principal reste lui visible — c'est attendu.
    assert_select "label.fr-text--bold", text: "Organisme", count: 0
    # Bloc "Centre financier" (etat OR consolidée) reste visible dans le modal
    assert_select "label.fr-text--bold", text: "Centre financier"
  end

  test "AC15 — Nature dropdown in advanced filters contains the 7 T2 natures" do
    sign_in users(:three)
    get actes_path
    assert_response :success
    # Liste déroulante Nature dans le modal Filtres avancés
    %w[ISP\ \( ISP\) Annexe Enveloppe Fongibilité Marché\ \(PSC\) Mesure Référentiel].each do |needle|
      # On vérifie la présence des libellés dans les <option> du select :nature_eq
    end
    # Assertions précises sur le select Nature dans le modal
    assert_select "select[name='q_current[nature_eq]']" do
      assert_select "option[value='Annexe financière']", text: "Annexe financière"
      assert_select "option[value='Enveloppe limitative']", text: "Enveloppe limitative"
      assert_select "option[value='Fongibilité asymétrique']", text: "Fongibilité asymétrique"
      assert_select "option[value='ISP']", text: "ISP"
      # Libellé "Marché (PSC)" mais valeur stockée "Marché" pour cohérence avec acte.rb:90
      assert_select "option[value='Marché']", text: "Marché (PSC)"
      assert_select "option[value='Mesure transversale']", text: "Mesure transversale"
      assert_select "option[value='Référentiel']", text: "Référentiel"
    end
  end

  test "AC15 — GET historique with nature_eq=ISP returns only T2 ISP actes" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', nature: 'Subvention', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year
    )
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today - 1
    )
    get actes_historique_path(q: { nature_eq: 'ISP' })
    assert_response :success
    assert_select "td span.fr-tag--t2", text: "T2", minimum: 1
    assert_select "td span.fr-tag--ht2", count: 0
  end

  test "AC13 — GET tableau_de_bord renders 4 checkboxes (Titre + Périmètre)" do
    sign_in users(:three)
    get tableau_de_bord_actes_path
    assert_response :success
    assert_select "input#titre-t2[type=checkbox]"
    assert_select "input#titre-ht2[type=checkbox]"
    assert_select "input#perimetre-etat[type=checkbox]"
    assert_select "input#perimetre-organisme[type=checkbox]"
    # Ancien bloc radio supprimé
    assert_select "input[name='q[perimetre_eq]']", count: 0
  end

  # Helper : extrait `series` du `data-highcharts-actes-dataset-value="..."` du chart "Délai moyen ..."
  def extract_delais_series_from_response
    doc = Nokogiri::HTML(response.body)
    node = doc.css('div[data-controller="highcharts-actes"][data-highcharts-actes-title-value="Délai moyen de traitement par mois"]').first
    refute_nil node, "Le chart 'Délai moyen' doit exister dans la réponse"
    JSON.parse(node['data-highcharts-actes-dataset-value'])["series"]
  end

  test "AC14 — synthese_temporelle in vue consolidée (no params) returns 3 series" do
    sign_in users(:three)
    get synthese_temporelle_actes_path
    assert_response :success
    series = extract_delais_series_from_response
    assert_equal 3, series.size, "Vue consolidée doit produire 3 séries (Etat / Organisme / Consolidé)"
    names = series.map { |s| s["name"] }
    assert_includes names, "Délai moyen État"
    assert_includes names, "Délai moyen Organisme"
    assert_includes names, "Délai moyen consolidé"
  end

  test "AC14 — synthese_temporelle with perimetre_in=[etat,organisme] is also vue consolidée (3 series)" do
    sign_in users(:three)
    get synthese_temporelle_actes_path(q: { perimetre_in: ['etat', 'organisme'] })
    assert_response :success
    assert_equal 3, extract_delais_series_from_response.size
  end

  test "AC14 — synthese_temporelle with perimetre_in=[etat] returns single Etat series" do
    sign_in users(:three)
    get synthese_temporelle_actes_path(q: { perimetre_in: ['etat'] })
    assert_response :success
    assert_equal 1, extract_delais_series_from_response.size
  end

  test "AC14 — synthese_temporelle with perimetre_in=[organisme] returns single Organisme series" do
    sign_in users(:three)
    get synthese_temporelle_actes_path(q: { perimetre_in: ['organisme'] })
    assert_response :success
    assert_equal 1, extract_delais_series_from_response.size
  end

  test "AC13 — GET synthese_utilisateurs (admin) renders 4 checkboxes" do
    sign_in users(:one) # admin
    get synthese_users_actes_path
    assert_response :success
    assert_select "input#titre-t2[type=checkbox]"
    assert_select "input#titre-ht2[type=checkbox]"
    assert_select "input#perimetre-etat[type=checkbox]"
    assert_select "input#perimetre-organisme[type=checkbox]"
  end

  test "AC14 — synthese_utilisateurs renders successfully across all 4 perimetre combinations (no crash on array→where)" do
    sign_in users(:one) # admin
    # 1) Vue consolidée (no params) → @selected_perimetres = nil → skip WHERE
    get synthese_users_actes_path
    assert_response :success

    # 2) Etat seul → @selected_perimetres = ['etat'] → WHERE perimetre IN ('etat')
    get synthese_users_actes_path(q: { perimetre_in: ['etat'] })
    assert_response :success

    # 3) Organisme seul
    get synthese_users_actes_path(q: { perimetre_in: ['organisme'] })
    assert_response :success

    # 4) Les deux cochés → équivalent vue consolidée
    get synthese_users_actes_path(q: { perimetre_in: ['etat', 'organisme'] })
    assert_response :success
  end

  test "AC16 — set_variables_form for new action stays untouched (saisie regression)" do
    sign_in users(:three)
    # set_variables_form n'est pas dans le before_action des actions de filtre.
    # On vérifie que `new` ne charge PAS set_variables_filtres et conserve sa propre logique.
    # Test indirect : le partial _form_informations_t2.html.erb attend une liste
    # de strings (pas de tuples) → un set_variables_filtres polluant casserait le rendu.
    get new_acte_path
    assert_response :success
  end

  test "AC16 — new T2 form renders nature select with string values (set_variables_form intact)" do
    # Si @liste_natures contenait des tuples [label, value], le partial _form_informations_t2.html.erb
    # ferait `.map { |n| [n, n] }` → `[[label, value], [label, value]]` => libellés cassés.
    sign_in users(:three)
    get new_acte_path, params: { titre: 'T2', perimetre: 'etat' }
    assert_response :success
    # 7 natures T2 état (DCB statut "three" → toutes les natures T2).
    # La value reste la nature brute (string), le texte affiché est le libellé enrichi.
    expected_labels = {
      'Annexe financière'       => 'Annexe financière (concours)',
      'Enveloppe limitative'    => 'Enveloppe limitative (revalorisation…)',
      'Fongibilité asymétrique' => 'Fongibilité asymétrique',
      'ISP'                     => 'ISP (cabinet ministériel)',
      'Marché'                  => 'Marché (PSC)',
      'Mesure transversale'     => 'Mesure transversale (autres actes)',
      'Référentiel'             => 'Référentiel (cadre de gestion)'
    }
    expected_labels.each do |nature, label|
      assert_select "select#nature option[value='#{nature}']", text: label,
        message: "La nature '#{nature}' doit avoir une value string (pas de tuple) et son libellé enrichi"
    end
  end

  test "AC9bis — GET index with titre_in=[T2] checks only T2 box, leaves HT2 unchecked" do
    sign_in users(:three)
    get actes_path(q_current: { titre_in: ['T2'] })
    assert_response :success
    assert_select "input#titre-t2[type=checkbox][checked=checked]"
    assert_select "input#titre-ht2[type=checkbox]:not([checked])"
  end

  test "AC9bis — GET historique with perimetre_in=[organisme] checks only Organisme, leaves Etat unchecked" do
    sign_in users(:three)
    get actes_historique_path(q: { perimetre_in: ['organisme'] })
    assert_response :success
    assert_select "input#perimetre-organisme[type=checkbox][checked=checked]"
    assert_select "input#perimetre-etat[type=checkbox]:not([checked])"
  end

  test "AC7 — index modal preserves titre_in as hidden field on advanced filter submit" do
    sign_in users(:three)
    get actes_path(q_current: { titre_in: ['T2'], perimetre_in: ['organisme'] })
    assert_response :success
    # Le form du modal avancé doit ré-injecter Titre + Périmètre en hidden pour ne pas les perdre
    assert_select "form input[type=hidden][name='q_current[titre_in][]'][value=T2]"
    assert_select "form input[type=hidden][name='q_current[perimetre_in][]'][value=organisme]"
  end

  test "AC7bis — dashboards modal preserves titre_in/perimetre_in as hidden fields" do
    sign_in users(:three)
    [
      [:tableau_de_bord_actes_path, :get_tableau_de_bord],
      [:synthese_temporelle_actes_path, :get_temporelle],
      [:synthese_anomalies_actes_path, :get_anomalies],
      [:synthese_suspensions_actes_path, :get_suspensions]
    ].each do |path_helper, _|
      get send(path_helper), params: { q: { titre_in: ['T2'], perimetre_in: ['etat'] } }
      assert_response :success, "#{path_helper} doit répondre 200"
      assert_select "form input[type=hidden][name='q[titre_in][]'][value=T2]", minimum: 1,
        message: "#{path_helper} doit ré-injecter titre_in dans le modal"
      assert_select "form input[type=hidden][name='q[perimetre_in][]'][value=etat]", minimum: 1,
        message: "#{path_helper} doit ré-injecter perimetre_in dans le modal"
    end
  end

  test "H2 — synthese_utilisateurs applies titre filter when only T2 is selected" do
    sign_in users(:one) # admin
    user_cbr = User.where(statut: 'CBR').first
    refute_nil user_cbr, "Fixtures attendues : au moins un utilisateur CBR"
    # 1 HT2 clôturé + 1 T2 clôturé pour ce user
    user_cbr.actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB', annee: Date.today.year,
      date_cloture: Date.today, date_saisine: Date.today - 1, delai_traitement: 1
    )
    user_cbr.actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: 'clôturé', instructeur: 'AB', annee: Date.today.year,
      date_cloture: Date.today, date_saisine: Date.today - 1, delai_traitement: 1
    )

    # Helper : extrait { user_nom => clotures_count } depuis le data-highcharts-actes-data-value
    extract_cbr_stats = lambda do
      doc = Nokogiri::HTML(response.body)
      node = doc.css('div[data-highcharts-actes-title-value="Actes clôturés par CBR"]').first
      refute_nil node, "Le chart 'Actes clôturés par CBR' doit exister"
      JSON.parse(node['data-highcharts-actes-data-value'])
    end

    # Cas 1 : T2 seul coché → user_cbr ne doit compter QUE l'acte T2 (count == 1)
    get synthese_users_actes_path(q: { titre_in: ['T2'] })
    assert_response :success
    cbr_stat = extract_cbr_stats.call.find { |s| s["name"] == user_cbr.nom }
    assert_equal 1, cbr_stat["y"], "titre_in=[T2] doit filtrer les stats : 1 seul acte clôturé attendu"

    # Cas 2 : les 2 cochés → vue consolidée → 2 actes clôturés
    get synthese_users_actes_path(q: { titre_in: ['T2', 'HT2'] })
    assert_response :success
    cbr_stat = extract_cbr_stats.call.find { |s| s["name"] == user_cbr.nom }
    assert_equal 2, cbr_stat["y"], "Tous les titres cochés == vue consolidée == 2 actes"
  end

  # ─── Story 3.3 — Excel exports including T2 ──────────────────────────────

  # Helper : parse le response body xlsx via Roo et retourne le workbook
  def parse_xlsx_response
    tmp = Tempfile.new(['export', '.xlsx'])
    tmp.binmode
    tmp.write(@response.body)
    tmp.close
    Roo::Excelx.new(tmp.path)
  end

  test "Story 3.3 AC1 — GET /actes.xlsx returns a workbook with two sheets HT2 and T2" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    assert_equal %w[HT2 T2], workbook.sheets, "Le workbook doit contenir exactement les onglets HT2 puis T2"
  end

  test "Story 3.3 AC1 — GET /actes.xlsx with only HT2 actes leaves T2 sheet empty (header only)" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB', annee: Date.today.year
    )
    get actes_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    assert_equal %w[HT2 T2], workbook.sheets
    workbook.default_sheet = 'T2'
    assert_equal 1, workbook.last_row, "Le sheet T2 ne doit contenir QUE l'en-tête (1 row)"
    workbook.default_sheet = 'HT2'
    assert workbook.last_row >= 2, "Le sheet HT2 doit contenir au moins 1 ligne de données"
  end

  test "Story 3.3 AC1 — GET /actes.xlsx with only T2 actes leaves HT2 sheet empty (header only)" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(isp_cercle1: true, isp_cercle1_montant: 1000.0)
    get actes_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    workbook.default_sheet = 'HT2'
    assert_equal 1, workbook.last_row, "Le sheet HT2 ne doit contenir QUE l'en-tête (1 row)"
    workbook.default_sheet = 'T2'
    assert workbook.last_row >= 2, "Le sheet T2 doit contenir au moins 1 ligne de données"
  end

  test "Story 3.3 AC8 — GET /actes.xlsx?q_current[titre_in][]=T2 filters to T2 only" do
    sign_in users(:three)
    create_mixte_set(users(:three))
    get actes_path(format: :xlsx, q_current: { titre_in: ['T2'] })
    assert_response :success
    workbook = parse_xlsx_response
    workbook.default_sheet = 'HT2'
    assert_equal 1, workbook.last_row, "Filtre T2 → sheet HT2 vide"
    workbook.default_sheet = 'T2'
    assert workbook.last_row >= 2, "Filtre T2 → sheet T2 peuplé"
  end

  test "Story 3.3 AC2 — GET /actes_historique.xlsx admin sees Controleur column on both HT2 and T2 sheets" do
    sign_in users(:one) # admin
    create_mixte_set(users(:one))
    get actes_historique_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    workbook.default_sheet = 'HT2'
    assert_equal 'Controleur', workbook.row(1).first, "Sheet HT2 admin : 1ère colonne == Controleur"
    workbook.default_sheet = 'T2'
    assert_equal 'Controleur', workbook.row(1).first, "Sheet T2 admin : 1ère colonne == Controleur"
  end

  test "Story 3.3 AC2 — GET /actes_historique.xlsx non-admin has no Controleur column on either sheet" do
    sign_in users(:three) # non-admin
    create_mixte_set(users(:three))
    get actes_historique_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    workbook.default_sheet = 'HT2'
    refute_equal 'Controleur', workbook.row(1).first, "Sheet HT2 non-admin : pas de colonne Controleur"
    workbook.default_sheet = 'T2'
    refute_equal 'Controleur', workbook.row(1).first, "Sheet T2 non-admin : pas de colonne Controleur"
  end

  test "Story 3.3 AC3 — GET /actes/:id/export.xlsx for a T2 acte contains DÉTAILS nature section" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(isp_cercle1: true, isp_cercle1_montant: 5000.0)
    get export_acte_path(acte, format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    # Premier sheet = "Acte <numero_formate>"
    workbook.default_sheet = workbook.sheets.first
    cells = (1..workbook.last_row).flat_map { |r| workbook.row(r) }.compact
    assert_includes cells, "DÉTAILS ISP",
                    "Le fichier T2 ISP doit contenir une section DÉTAILS ISP"
  end

  test "Story 3.3 AC7 — GET /actes/:id/export.xlsx for an HT2 acte does NOT contain DÉTAILS nature section" do
    sign_in users(:three)
    acte = users(:three).actes.create!(
      titre: 'HT2', perimetre: 'etat', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB', annee: Date.today.year
    )
    get export_acte_path(acte, format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    workbook.default_sheet = workbook.sheets.first
    cells = (1..workbook.last_row).flat_map { |r| workbook.row(r) }.compact
    refute(cells.any? { |c| c.is_a?(String) && c.start_with?('DÉTAILS ') },
           "Régression : un acte HT2 ne doit JAMAIS afficher de section DÉTAILS {nature}")
  end

  test "Story 3.3 AC4 — GenerateBackupJob produces a workbook with 5 sheets including t2_details" do
    # Stub GCS upload (Mocha non dispo) — on parse le workbook PENDANT l'upload simulé,
    # car Tempfile.create supprime le fichier en sortie du block du job.
    captured_sheets = nil
    fake_bucket = Object.new
    fake_bucket.define_singleton_method(:create_file) do |path, *_args|
      captured_sheets = Roo::Excelx.new(path).sheets
      true
    end

    job = GenerateBackupJob.new
    job.define_singleton_method(:gcs_bucket) { fake_bucket }

    backup = BackupExport.create!(status: 'pending')
    job.perform(backup.id)

    backup.reload
    assert_equal 'completed', backup.status, "Backup doit être marqué completed"
    assert_equal %w[actes suspensions poste_lignes echeanciers t2_details], captured_sheets,
                 "Le backup doit contenir 5 onglets dans cet ordre"
  end

  test "Story 3.3 AC11 — Empty workbook headers stable when no actes match filter" do
    sign_in users(:three)
    # Pas d'acte créé pour ce user
    get actes_path(format: :xlsx)
    assert_response :success
    workbook = parse_xlsx_response
    assert_equal %w[HT2 T2], workbook.sheets, "Workbook stable même sans données"
    workbook.default_sheet = 'HT2'
    assert_equal 1, workbook.last_row, "HT2 sheet a uniquement l'en-tête"
    workbook.default_sheet = 'T2'
    assert_equal 1, workbook.last_row, "T2 sheet a uniquement l'en-tête"
  end

  # ─── H4 — Validation des données (review code-review) ──────────────────
  # Les tests ci-dessous valident le contenu, pas seulement la structure du workbook.

  test "Story 3.3 AC6 — T2 sheet headers respect helper t2_export_columns order" do
    sign_in users(:three)
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    get actes_path(format: :xlsx)
    workbook = parse_xlsx_response
    workbook.default_sheet = 'T2'
    headers = workbook.row(1)
    expected_labels = ApplicationController.helpers.t2_export_columns.map { |(label, _)| label }
    assert_equal expected_labels, headers,
                 "Les headers du sheet T2 doivent respecter exactement l'ordre/les labels du helper t2_export_columns"
  end

  test "Story 3.3 H3 — Déclinaison référentiel rend N/A sauf pour la nature Référentiel" do
    sign_in users(:three)
    isp = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    isp.create_t2_detail!(isp_cercle1: true)

    get actes_path(format: :xlsx)
    workbook = parse_xlsx_response
    workbook.default_sheet = 'T2'
    headers = workbook.row(1)
    idx = headers.index('Déclinaison référentiel')
    refute_nil idx, "La colonne 'Déclinaison référentiel' doit exister"
    assert_equal "N/A", workbook.row(2)[idx],
                 "Pour une nature ISP, 'Déclinaison référentiel' doit rendre 'N/A' (et non Oui/Non par défaut)"
  end

  test "Story 3.3 AC8 — filtre q_current[nature_eq]=ISP limite le sheet T2 aux ISP" do
    sign_in users(:three)
    isp = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    isp.create_t2_detail!(isp_cercle1: true)
    users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'Marché', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today,
      montant_ae: 1000.0
    )
    get actes_path(format: :xlsx, q_current: { nature_eq: 'ISP' })
    workbook = parse_xlsx_response
    workbook.default_sheet = 'T2'
    # 1 ligne header + 1 ligne ISP, le Marché doit être filtré
    assert_equal 2, workbook.last_row, "nature_eq=ISP doit limiter le sheet T2 à 1 acte ISP"
    headers = workbook.row(1)
    nature_idx = headers.index('Nature')
    assert_equal 'ISP', workbook.row(2)[nature_idx]
  end

  test "Story 3.3 AC4 — admin_backup t2_details sheet contient les colonnes et valeurs attendues" do
    acte = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    acte.create_t2_detail!(isp_cercle1: true, isp_cercle1_montant: 1234.5)

    captured_t2_rows = nil
    captured_actes_headers = nil
    fake_bucket = Object.new
    fake_bucket.define_singleton_method(:create_file) do |path, *_args|
      wb = Roo::Excelx.new(path)
      wb.default_sheet = 't2_details'
      captured_t2_rows = (1..wb.last_row).map { |r| wb.row(r) }
      wb.default_sheet = 'actes'
      captured_actes_headers = wb.row(1)
      true
    end
    job = GenerateBackupJob.new
    job.define_singleton_method(:gcs_bucket) { fake_bucket }
    backup = BackupExport.create!(status: 'pending')
    job.perform(backup.id)

    refute_nil captured_t2_rows, "Le sheet t2_details doit être lu pendant l'upload"
    assert_equal 2, captured_t2_rows.size, "t2_details doit contenir l'en-tête + 1 ligne"
    headers = captured_t2_rows.first
    montant_idx = headers.index('isp_cercle1_montant')
    refute_nil montant_idx
    assert_equal 1234.5, captured_t2_rows[1][montant_idx]

    # AC4 — onglet actes doit aussi avoir titre + categorie_t2 avant pdf_generation_status
    titre_idx   = captured_actes_headers.index('titre')
    cat_idx     = captured_actes_headers.index('categorie_t2')
    pdf_idx     = captured_actes_headers.index('pdf_generation_status')
    refute_nil titre_idx,  "Sheet actes doit contenir la colonne 'titre'"
    refute_nil cat_idx,    "Sheet actes doit contenir la colonne 'categorie_t2'"
    assert titre_idx < pdf_idx && cat_idx < pdf_idx,
           "titre + categorie_t2 doivent précéder pdf_generation_status"
  end

  test "Story 3.3 H4 — sheet T2 critères de contrôle respectent la matrice nature × perimetre" do
    sign_in users(:three)
    # ISP : Programmation initiale transmise → N/A, Respect enveloppe → applicable
    isp = users(:three).actes.create!(
      titre: 'T2', categorie_t2: 'hors contrat', perimetre: 'etat',
      nature: 'ISP', type_acte: 'avis',
      etat: "en pré-instruction", instructeur: 'AB',
      annee: Date.today.year, date_saisine: Date.today
    )
    isp.create_t2_detail!(isp_cercle1: true, respect_enveloppe: true)

    get actes_path(format: :xlsx)
    workbook = parse_xlsx_response
    workbook.default_sheet = 'T2'
    headers = workbook.row(1)
    row = workbook.row(2)

    prog_init_idx = headers.index('Programmation initiale transmise')
    resp_env_idx  = headers.index('Respect enveloppe')
    insc_pap_idx  = headers.index('Inscription PAP')
    refute_nil prog_init_idx
    refute_nil resp_env_idx
    refute_nil insc_pap_idx
    assert_equal "N/A", row[prog_init_idx],
                 "ISP : 'Programmation initiale transmise' doit rendre N/A (nature exclue de la matrice)"
    assert_equal "Oui", row[resp_env_idx],
                 "ISP : 'Respect enveloppe' doit rendre Oui (critère applicable)"
    assert_equal "N/A", row[insc_pap_idx],
                 "ISP : 'Inscription PAP' n'est applicable que pour Annexe financière/Mesure transversale/Référentiel"
  end
end
