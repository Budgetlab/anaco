class AddFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :statut, :string
    add_column :users, :nom, :string
  end
end
