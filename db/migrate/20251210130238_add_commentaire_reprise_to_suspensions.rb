class AddCommentaireRepriseToSuspensions < ActiveRecord::Migration[7.2]
  def change
    add_column :suspensions, :commentaire_reprise, :string
  end
end
