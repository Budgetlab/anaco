class AddRenvoieInstructionToHt2Acte < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :renvoie_instruction, :boolean, default: false
  end
end
