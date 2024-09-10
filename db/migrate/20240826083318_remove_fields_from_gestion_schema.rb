class RemoveFieldsFromGestionSchema < ActiveRecord::Migration[7.1]
  def self.up
    remove_column :gestion_schemas, :credits_reports_autre_ae
    remove_column :gestion_schemas, :credits_reports_autre_cp
  end

  def self.down
    add_column :gestion_schemas, :credits_reports_autre_ae, :float
    add_column :gestion_schemas, :credits_reports_autre_cp, :float
  end
end
