class AddProgrammationPrevueToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :programmation_prevue, :boolean, default: false
  end
end
