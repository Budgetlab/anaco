class AddListeActesToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :liste_actes, :boolean, default: false
  end
end
