class AddNumeroFormatToHt2Acte < ActiveRecord::Migration[7.2]
  def up
    # Ajouter la colonne et l'index
    add_column :ht2_actes, :numero_formate, :string
    add_index :ht2_actes, :numero_formate

    # Mettre à jour les données existantes
    # Story 1.1 a renommé Ht2Acte → Acte ; Story 1.4 a supprimé l'alias.
    # On résout la classe dynamiquement pour rester rejouable sur une DB vierge.
    model = Object.const_defined?(:Ht2Acte) ? Ht2Acte : Acte
    model.find_each do |acte|
      next if acte.numero_formate.present?

      # Déterminer l'année à partir de created_at ou utiliser l'année courante
      annee = acte.created_at&.year || Date.current.year
      annee_courte = annee.to_s.last(2)

      numero_formate = "#{annee_courte}-#{acte.numero_utilisateur.to_s.rjust(4, '0')}"
      acte.update_column(:numero_formate, numero_formate)
    end
  end

  def down
    # Supprimer l'index et la colonne
    remove_index :ht2_actes, :numero_formate
    remove_column :ht2_actes, :numero_formate
  end
end