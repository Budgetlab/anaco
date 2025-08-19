class AddTypeEngagementToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :type_engagement, :string
  end
end
