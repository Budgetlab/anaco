class RenameCentreFinanciersActesToActesCentreFinanciers < ActiveRecord::Migration[8.1]
  # Aligne le nom de la table de jointure HABTM sur la convention Rails (ordre alphabétique
  # des deux classes: Acte + CentreFinancier → actes_centre_financiers).
  # Sans ce renommage, Rails infère 'actes_centre_financiers' depuis les classes mais
  # la table actuelle s'appelle 'centre_financiers_actes' (héritée du nom historique
  # 'centre_financiers_ht2_actes'), provoquant une PG::UndefinedTable.

  def change
    rename_table :centre_financiers_actes, :actes_centre_financiers
  end
end
