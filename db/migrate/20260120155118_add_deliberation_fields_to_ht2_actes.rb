class AddDeliberationFieldsToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :deliberation_ca, :boolean, default: false
    add_column :ht2_actes, :numero_deliberation_ca, :string
    add_column :ht2_actes, :date_deliberation_ca, :date
    add_column :ht2_actes, :observations_deliberation_ca, :text
    add_column :ht2_actes, :destination, :string
    add_column :ht2_actes, :nomenclature, :string
    add_column :ht2_actes, :flux, :string
  end
end
