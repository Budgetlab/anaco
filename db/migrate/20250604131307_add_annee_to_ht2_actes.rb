class AddAnneeToHt2Actes < ActiveRecord::Migration[7.2]
  def up
    add_column :ht2_actes, :annee, :integer
    add_index :ht2_actes, :annee

    # Mettre à jour les données existantes
    # Story 1.1 a renommé Ht2Acte → Acte ; Story 1.4 a supprimé l'alias.
    # On résout la classe dynamiquement pour rester rejouable sur une DB vierge.
    model = Object.const_defined?(:Ht2Acte) ? Ht2Acte : Acte
    model.find_each do |acte|
      if acte.date_cloture.present?
        acte.update_column(:annee, acte.date_cloture.year)
      elsif acte.created_at.present?
        acte.update_column(:annee, acte.created_at.year)
      end
    end
  end

  def down
    remove_index :ht2_actes, :annee if index_exists?(:ht2_actes, :annee)
    remove_column :ht2_actes, :annee if column_exists?(:ht2_actes, :annee)
  end
end
