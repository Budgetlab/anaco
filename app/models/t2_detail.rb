class T2Detail < ApplicationRecord
  belongs_to :acte

  validates :type_acte_t2, inclusion: { in: %w[Initial Complémentaire], allow_nil: true }
end
