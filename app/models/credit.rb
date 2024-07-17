class Credit < ApplicationRecord
  belongs_to :user
  belongs_to :programme

  def self.ransackable_attributes(auth_object = nil)
    ["ae_i", "annee", "commentaire", "cp_i", "created_at", "date_document", "etat", "id", "id_value", "is_crg1", "phase", "programme_id", "statut", "t2_i", "updated_at", "user_id"]
  end
end
