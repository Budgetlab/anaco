class CreateBackupExports < ActiveRecord::Migration[8.1]
  def change
    create_table :backup_exports do |t|
      t.string :status
      t.string :filename
      t.text :error_message

      t.timestamps
    end
  end
end
