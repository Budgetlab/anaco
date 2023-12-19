class RemoveEtptIInCredits < ActiveRecord::Migration[7.1]
  def change
    remove_column :credits, :etpt_i
  end
end
