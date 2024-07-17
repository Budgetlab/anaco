class Ministere < ApplicationRecord
  has_many :missions
  has_many :programmes, through: :missions

  def self.ransackable_associations(auth_object = nil)
    ["missions", "programmes"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "nom", "updated_at"]
  end
end
