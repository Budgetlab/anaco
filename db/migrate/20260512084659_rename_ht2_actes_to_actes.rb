class RenameHt2ActesToActes < ActiveRecord::Migration[8.1]
  # Index non renommés automatiquement par Rails lors de rename_table/rename_column.
  # Rails couvre la primary key, les index simple-colonne ainsi que les noms auto-générés
  # (idx_on_..., index_TABLE_on_COL...). Seuls les index multi-colonnes au nom custom
  # restent à renommer manuellement.
  INDEX_RENAMES = {
    "index_ht2_actes_on_user_cloture_annee" => "index_actes_on_user_cloture_annee",
    "index_ht2_actes_on_user_updated_at"    => "index_actes_on_user_updated_at",
    "index_ht2_actes_on_user_etat"          => "index_actes_on_user_etat",
  }.freeze

  def up
    # 1. Table principale (renomme automatiquement la pkey et les index simple-colonne)
    rename_table :ht2_actes, :actes

    # 2. Tables de jointure HABTM
    rename_table :centre_financiers_ht2_actes, :centre_financiers_actes
    rename_table :ht2_actes_organismes,        :actes_organismes

    # 3. Colonnes FK ht2_acte_id -> acte_id (renomme automatiquement les index correspondants)
    rename_column :centre_financiers_actes, :ht2_acte_id, :acte_id
    rename_column :actes_organismes,        :ht2_acte_id, :acte_id
    rename_column :echeanciers,             :ht2_acte_id, :acte_id
    rename_column :poste_lignes,            :ht2_acte_id, :acte_id
    rename_column :suspensions,             :ht2_acte_id, :acte_id

    # 4. Renommage explicite des index multi-colonnes restants
    INDEX_RENAMES.each do |old_name, new_name|
      execute %(ALTER INDEX "#{old_name}" RENAME TO "#{new_name}";)
    end

    # 5. Nouvelles colonnes T2 sur actes
    add_column :actes, :titre,        :string, default: 'HT2', null: false
    add_column :actes, :categorie_t2, :string
  end

  def down
    remove_column :actes, :categorie_t2
    remove_column :actes, :titre

    INDEX_RENAMES.each do |old_name, new_name|
      execute %(ALTER INDEX "#{new_name}" RENAME TO "#{old_name}";)
    end

    rename_column :suspensions,             :acte_id, :ht2_acte_id
    rename_column :poste_lignes,            :acte_id, :ht2_acte_id
    rename_column :echeanciers,             :acte_id, :ht2_acte_id
    rename_column :actes_organismes,        :acte_id, :ht2_acte_id
    rename_column :centre_financiers_actes, :acte_id, :ht2_acte_id

    rename_table :actes_organismes,        :ht2_actes_organismes
    rename_table :centre_financiers_actes, :centre_financiers_ht2_actes
    rename_table :actes,                   :ht2_actes
  end
end
