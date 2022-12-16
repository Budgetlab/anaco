class AddUserToAvi < ActiveRecord::Migration[7.0]
  def change
    add_reference :avis, :user, null: false, foreign_key: true
  end
end
