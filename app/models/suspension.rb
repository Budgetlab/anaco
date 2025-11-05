class Suspension < ApplicationRecord
  belongs_to :ht2_acte

  validates :date_suspension, presence: true
  validates :motif, presence: true

  #validate :unicite_suspension_ouverte, on: :create

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "date_reprise", "date_suspension", "ht2_acte_id", "id", "id_value", "motif", "observations", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["ht2_acte"]
  end

  private

  def unicite_suspension_ouverte
    #todo update
  end
end
