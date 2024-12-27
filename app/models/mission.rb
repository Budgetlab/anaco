class Mission < ApplicationRecord
  has_many :programmes

  def total_ae_rprog_ht2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.rprog_ht2&.first&.solde_total_ae || 0 }
  end
  def total_cp_rprog_ht2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.rprog_ht2&.first&.solde_total_cp || 0 }
  end
  def total_ae_rprog_t2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.rprog_t2&.first&.solde_total_ae || 0 }
  end
  def total_cp_rprog_t2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.rprog_t2&.first&.solde_total_cp || 0 }
  end
  def total_ae_cbcm_ht2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.cbcm_ht2&.first&.solde_total_ae || 0 }
  end
  def total_cp_cbcm_ht2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.cbcm_ht2&.first&.solde_total_cp || 0 }
  end
  def total_ae_cbcm_t2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.cbcm_t2&.first&.solde_total_ae || 0 }
  end
  def total_cp_cbcm_t2_for_mission(annee)
    self.programmes.sum { |programme| programme.last_schema_valid(annee)&.gestion_schemas&.cbcm_t2&.first&.solde_total_cp || 0 }
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "nom", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["programmes"]
  end

  ransacker :nom, type: :string do
    Arel.sql("unaccent(missions.\"nom\")")
  end
end
