class RenameChorusDateToSaisineInHt2Actes < ActiveRecord::Migration[8.1]
  def change
    rename_column :ht2_actes, :date_chorus, :date_saisine
  end
end
