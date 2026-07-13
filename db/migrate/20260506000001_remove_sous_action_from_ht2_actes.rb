class RemoveSousActionFromHt2Actes < ActiveRecord::Migration[7.2]
  def change
    remove_column :ht2_actes, :sous_action, :string
  end
end
