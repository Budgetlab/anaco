class ChangeNumeroToBeStringInProgrammes < ActiveRecord::Migration[7.1]
  def up
    change_column :programmes, :numero, :string
  end

  def down
    change_column :programmes, :numero, 'integer USING CAST(numero AS integer)'
  end
end
