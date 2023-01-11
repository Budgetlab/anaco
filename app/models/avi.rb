class Avi < ApplicationRecord
  belongs_to :bop
  belongs_to :user
  require 'axlsx'
end
