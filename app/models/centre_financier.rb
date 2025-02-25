class CentreFinancier < ApplicationRecord
  belongs_to :bop
  has_and_belongs_to_many :ht2_actes
end
