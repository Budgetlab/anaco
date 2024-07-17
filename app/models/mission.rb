class Mission < ApplicationRecord
  belongs_to :ministere
  has_many :programmes
end
