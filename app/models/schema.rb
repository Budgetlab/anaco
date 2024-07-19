class Schema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  has_many :gestion_schemas


end
