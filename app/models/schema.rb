class Schema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  has_many :gestion_schemas

  def incomplete?
    self.statut != 'valide'
  end

  def complete?
    self.statut == 'valide'
  end

  def new?
    self.gestion_schemas.empty?
  end

  def first_of_year?
    self.programme.schemas.where(annee: Date.today_year).count == 1
  end

  def self.ransackable_associations(auth_object = nil)
    ["gestion_schemas", "programme", "user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["annee", "created_at", "id", "id_value", "programme_id", "statut", "updated_at", "user_id"]
  end

end
