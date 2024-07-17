class AddProgrammeToBop < ActiveRecord::Migration[7.1]
  def up
    add_reference :bops, :programme, foreign_key: true

    Bop.reset_column_information
    Bop.find_each do |bop|
      programme = Programme.find_by(numero: bop.numero_programme)
      bop.update!(programme_id: programme.id) if programme
    end
  end

  def down
    remove_reference :bops, :programme
  end
end
