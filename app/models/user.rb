class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  	devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

     has_many :bops
     has_many :avis

    def self.import(file)
	    User.destroy_all 

	    data = Roo::Spreadsheet.open(file.path)
	    headers = data.row(1) # get header row
	    data.each_with_index do |row, idx|
	      	next if idx == 0 # skip header
	      	row_data = Hash[[headers, row].transpose]
	      
		  
	       	User.where('nom = ?',row_data['nom'].to_s).first_or_create do |user|         
	          	user.email = "user"+idx.to_s+"@finances.gouv.fr"
	          	user.statut = row_data['statut'].to_s
	          	user.nom = row_data['nom'].to_s
	          	user.password = row_data['Mot de passe'].to_s
	        end
      		
	      
	    end
  	end

end
