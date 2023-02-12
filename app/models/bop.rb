class Bop < ApplicationRecord
  belongs_to :user
  has_many :avis

  def self.import(file)
		#Bop.destroy_all

	    data = Roo::Spreadsheet.open(file.path)
	    headers = data.row(1) # get header row
	    data.each_with_index do |row, idx|
	      	next if idx == 0 # skip header
	      	row_data = Hash[[headers, row].transpose]
	      
		  	if !User.where(nom: row_data['Identifiant']).first.nil?
					if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
						@bop = Bop.where(code: row_data['Code CHORUS du BOP'].to_s)
						@bop.update(user_id: User.where(nom: row_data['Identifiant']).first.id, consultant: User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id, ministere: row_data['MINISTERE'].to_s, nom_programme: row_data['Libellé programme'].to_s, numero_programme: row_data['N°Programme'].to_i )
					end
		       	Bop.where('code = ?',row_data['Code CHORUS du BOP'].to_s).first_or_create do |bop|         
		          	bop.user_id = User.where(nom: row_data['Identifiant']).first.id
		          	bop.consultant = User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id
		          	bop.ministere = row_data['MINISTERE'].to_s
		          	bop.nom_programme = row_data['Libellé programme'].to_s
		          	bop.numero_programme = row_data['N°Programme'].to_i
		          	bop.code = row_data['Code CHORUS du BOP'].to_s
		        end
		    end
      		
	      
	    end
  	end
end
