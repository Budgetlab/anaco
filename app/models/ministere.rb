class Ministere < ApplicationRecord
  has_many :missions
  has_many :programmes, through: :missions
end
