class Transfert < ApplicationRecord
  belongs_to :gestion_schema
  belongs_to :programme

  scope :entrant, -> { where(nature: 'entrant') }
  scope :sortant, -> { where(nature: 'sortant') }

  def self.ransackable_associations(auth_object = nil)
    ["gestion_schema", "programme"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "gestion_schema_id", "id", "id_value", "montant_ae", "montant_cp", "nature", "programme_id", "updated_at"]
  end
end
