class GestionSchema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  belongs_to :schema
end
