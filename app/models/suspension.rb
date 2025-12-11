class Suspension < ApplicationRecord
  belongs_to :ht2_acte

  validates :date_suspension, presence: true
  validates :motif, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["commentaire_reprise", "created_at", "date_reprise", "date_suspension", "ht2_acte_id", "id", "id_value", "motif", "observations", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["ht2_acte"]
  end

end
