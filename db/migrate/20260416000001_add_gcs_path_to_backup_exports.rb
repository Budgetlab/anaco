class AddGcsPathToBackupExports < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_exports, :gcs_path, :string
  end
end
