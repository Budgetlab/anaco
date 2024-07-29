class Schema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  has_many :gestion_schemas, dependent: :destroy

  def incomplete?
    !self.gestion_schemas.empty? && self.statut != 'valide'
  end

  def complete?
    self.statut == 'valide'
  end

  def gestion_schemas_empty?
    self.gestion_schemas.empty?
  end

  def first_of_year?
    self.programme.schemas.where(annee: Date.today_year).count == 1
  end

  def last_gestion_schema
    self.gestion_schemas.order(created_at: :desc).first
  end

  def self.ransackable_associations(auth_object = nil)
    ["gestion_schemas", "programme", "user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["annee", "created_at", "id", "id_value", "programme_id", "statut", "updated_at", "user_id"]
  end

end
