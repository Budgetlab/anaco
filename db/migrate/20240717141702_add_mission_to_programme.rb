class AddMissionToProgramme < ActiveRecord::Migration[7.1]
  def change
    add_reference :programmes, :mission, foreign_key: true
    add_reference :programmes, :ministere, foreign_key: true
  end
end
