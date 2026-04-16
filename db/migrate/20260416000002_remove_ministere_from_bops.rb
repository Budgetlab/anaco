class RemoveMinistereFromBops < ActiveRecord::Migration[7.0]
  def change
    remove_column :bops, :ministere, :string
  end
end
