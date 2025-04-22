class AddProgrammeToCf < ActiveRecord::Migration[7.2]
  def self.up
    add_reference :centre_financiers, :programme,null: true, foreign_key: true
  end

  def self.down
    remove_reference :centre_financiers, :programme, foreign_key: true
  end
end
