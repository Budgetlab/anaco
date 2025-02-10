class AddDateInactiviteToProgramme < ActiveRecord::Migration[7.2]
  def change
    add_column :programmes, :date_inactivite, :date
  end
end
