class Suspension < ApplicationRecord
  belongs_to :acte

  validates :date_suspension, presence: true
  validates :motif, presence: true, length: { minimum: 1 }

  def self.ransackable_attributes(auth_object = nil)
    ["commentaire_reprise", "created_at", "date_reprise", "date_suspension", "acte_id", "id", "id_value", "motif", "observations", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["acte"]
  end

end
