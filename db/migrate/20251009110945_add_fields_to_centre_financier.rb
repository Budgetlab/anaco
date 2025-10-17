class AddFieldsToCentreFinancier < ActiveRecord::Migration[7.2]
  def up
    # 1) Ajout des colonnes avec contraintes
    add_column :bops, :deconcentre, :boolean, default: false, null: false
    add_column :centre_financiers, :statut, :string, default: "Actif", null: false
    add_column :centre_financiers, :deconcentre, :boolean, default: false, null: false

    # 2) Backfill en SQL (sans charger les modèles)

    # a) bops.deconcentre = true quand le BOP est rattaché à un user CBR
    # (si bops.user_id existe)
    execute <<~SQL.squish
      UPDATE bops
      SET deconcentre = TRUE
      FROM users
      WHERE bops.user_id = users.id
        AND users.statut = 'CBR'
    SQL

    # b) centre_financiers.deconcentre = true quand le BOP parent est déconcentré
    execute <<~SQL.squish
      UPDATE centre_financiers
      SET deconcentre = TRUE
      FROM bops
      WHERE centre_financiers.bop_id = bops.id
        AND bops.deconcentre = TRUE
    SQL

    # (Optionnel) Index si tu filtres souvent dessus
    add_index :bops, :deconcentre
    add_index :centre_financiers, :deconcentre
    add_index :centre_financiers, :statut
  end

  def down
    remove_index :centre_financiers, :statut, if_exists: true
    remove_index :centre_financiers, :deconcentre, if_exists: true
    remove_index :bops, :deconcentre, if_exists: true

    remove_column :centre_financiers, :deconcentre, if_exists: true
    remove_column :centre_financiers, :statut, if_exists: true
    remove_column :bops, :deconcentre, if_exists: true
  end
end
