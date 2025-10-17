class CreateJoinTableHt2ActesCentreFinanciers < ActiveRecord::Migration[7.2]
  def change
    create_join_table :ht2_actes, :centre_financiers do |t|
      t.index [:ht2_acte_id, :centre_financier_id]
      t.index [:centre_financier_id, :ht2_acte_id]
    end
  end
end
