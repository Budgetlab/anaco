class Mission < ApplicationRecord
  belongs_to :ministere
  has_many :programmes

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "ministere_id", "nom", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["ministere", "programmes"]
  end
end
