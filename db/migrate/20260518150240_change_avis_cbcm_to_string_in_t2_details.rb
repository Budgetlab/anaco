class ChangeAvisCbcmToStringInT2Details < ActiveRecord::Migration[8.1]
  def up
    change_column :t2_details, :avis_cbcm, :string
  end

  def down
    change_column :t2_details, :avis_cbcm, :boolean, using: 'avis_cbcm::boolean'
  end
end
