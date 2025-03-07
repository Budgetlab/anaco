class GestionSchema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  belongs_to :schema
  has_many :transferts, dependent: :destroy
  accepts_nested_attributes_for :transferts, reject_if: proc { |attributes| attributes['montant_ae'].blank? || attributes['montant_cp'].blank? || attributes['programme_id'].blank? }, allow_destroy: true

  scope :cbcm_t2, -> { where(vision: 'CBCM', profil: 'T2') }
  scope :cbcm_ht2, -> { where(vision: 'CBCM', profil: 'HT2') }
  scope :rprog_t2, -> { where(vision: 'RPROG', profil: 'T2') }
  scope :rprog_ht2, -> { where(vision: 'RPROG', profil: 'HT2') }

  before_save :set_nil_values_to_zero
  before_save :set_fongibilite

  def prevision_solde_budgetaire_ae
    (ressources_ae || 0) + (depenses_ae || 0)
  end

  def prevision_solde_budgetaire_cp
    (ressources_cp || 0) + (depenses_cp || 0)
  end
  def solde_prev_reports_ae
    prevision_solde_budgetaire_ae + reports_ae
  end
  def solde_prev_reports_cp
    prevision_solde_budgetaire_cp + reports_cp
  end
  def solde_total_ae
    prevision_solde_budgetaire_ae + mobilisation_mer_ae + mobilisation_surgel_ae + fongibilite_ae + fongibilite_hcas + transferts_entrant_ae + transferts_sortant_ae + decret_ae + credits_lfg_ae + reports_ae
  end
  def solde_total_cp
    prevision_solde_budgetaire_cp + mobilisation_mer_cp + mobilisation_surgel_cp + fongibilite_cp + fongibilite_cas + transferts_entrant_cp + transferts_sortant_cp + decret_cp + credits_lfg_cp + reports_cp
  end

  def transferts_entrant_ae
    transferts.select { |t| t.nature == 'entrant' }.sum(&:montant_ae)
  end

  def transferts_entrant_cp
    transferts.select { |t| t.nature == 'entrant' }.sum(&:montant_cp)
  end

  def transferts_sortant_ae
    transferts.select { |t| t.nature == 'sortant' }.sum(&:montant_ae)
  end

  def transferts_sortant_cp
    transferts.select { |t| t.nature == 'sortant' }.sum(&:montant_cp)
  end

  def step
    if profil == 'HT2'
      vision == 'RPROG' ? 1 : 2
    else
      vision == 'RPROG' ? 3 : 4
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["annee","schema_id", "updated_at", "user_id", "vision", "created_at", "profil", "programme_id","credits_lfg_ae", "credits_lfg_cp", "credits_reports_ae", "credits_reports_cp", "decret_ae", "decret_cp", "fongibilite_ae", "fongibilite_cp", "id", "id_value", "mer_ae", "mer_cp", "surgel_ae", "surgel_cp", "mobilisation_mer_ae", "mobilisation_mer_cp","mobilisation_surgel_ae", "mobilisation_surgel_cp", "ressources_ae", "ressources_cp","depenses_ae","depenses_cp", "reports_autre_ae","reports_ae", "reports_cp", "reports_autre_cp", "charges_a_payer_ae", "charges_a_payer_cp", "credits_reports_autre_ae", "credits_reports_autre_cp", "commentaire", "fongibilite_hcas", "fongibilite_cas"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["programme", "schema", "user", "transferts"]
  end

  private
  def set_nil_values_to_zero
    self.attributes.each do |attr_name, attr_value|
      next if %w[id programme_id schema_id user_id vision profil commentaire].include?(attr_name)

      self[attr_name] = 0 if attr_value.nil?
    end
  end

  def set_fongibilite
    self.fongibilite_cp = self.fongibilite_ae if self.profil == 'HT2'
    self.fongibilite_cas = -self.fongibilite_hcas if self.profil == 'T2' && self.fongibilite_hcas != 0.0
  end
end
