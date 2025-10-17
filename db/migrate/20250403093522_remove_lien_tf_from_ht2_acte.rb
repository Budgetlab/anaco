class RemoveLienTfFromHt2Acte < ActiveRecord::Migration[7.2]
  def self.up
    remove_column :ht2_actes, :lien_tf
  end

  def self.down
    add_column :ht2_actes, :lien_tf, :boolean
  end
end
