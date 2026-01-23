class CreateJoinTableOrganismesHt2Actes < ActiveRecord::Migration[8.1]
  def change
    create_join_table :organismes, :ht2_actes do |t|
      t.index [:organisme_id, :ht2_acte_id]
      t.index [:ht2_acte_id, :organisme_id]
    end
  end
end
