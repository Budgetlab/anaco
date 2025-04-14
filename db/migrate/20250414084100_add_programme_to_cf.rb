class AddProgrammeToCf < ActiveRecord::Migration[7.2]
  def self.up
    add_reference :centre_financiers, :programme,null: true, foreign_key: true
    CentreFinancier.find_each do |cf|
      numero_programme = cf.code[1..3]
      programme = Programme.find_by(numero: numero_programme)
      cf.update!(programme_id: programme.id) if programme
    end
  end

  def self.down
    remove_reference :centre_financiers, :programme, foreign_key: true
  end
end
