class AddGestionAnticipeeToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :gestion_anticipee, :boolean, default: false
  end
end
