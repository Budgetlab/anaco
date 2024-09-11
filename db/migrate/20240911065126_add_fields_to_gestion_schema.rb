class AddFieldsToGestionSchema < ActiveRecord::Migration[7.2]
  def self.up
    add_column :gestion_schemas, :fongibilite_hcas, :float
    add_column :gestion_schemas, :fongibilite_cas, :float
    GestionSchema.find_each do |gs|
      gs.update!(fongibilite_hcas: 0.0, fongibilite_cas: 0.0)
    end
  end

  def self.down
    remove_column :gestion_schemas, :fongibilite_hcas
    remove_column :gestion_schemas, :fongibilite_cas
  end
end
