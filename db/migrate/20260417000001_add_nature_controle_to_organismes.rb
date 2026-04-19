class AddNatureControleToOrganismes < ActiveRecord::Migration[8.1]
  def change
    add_column :organismes, :nature_controle, :string
  end
end
