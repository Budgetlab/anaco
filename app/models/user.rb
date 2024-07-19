class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :bops
  has_many :consulted_bops, class_name: 'Bop', foreign_key: 'consultant_id'
  has_many :avis
  has_many :programmes
  has_many :credits
  has_many :gestion_schemas
  has_many :schemas

  # fonction d'import des utilisateurs dans la bdd
  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]

      if User.exists?(nom: row_data['nom'].to_s)
        @user = User.where(nom: row_data['nom'].to_s)
        @user.update(statut: row_data['statut'].to_s)
      end

      User.where('nom = ?', row_data['nom'].to_s).first_or_create do |user|
        user.email = "user#{idx.to_s}@finances.gouv.fr"
        user.statut = row_data['statut'].to_s
        user.nom = row_data['nom'].to_s
        user.password = row_data['Mot de passe'].to_s
      end
    end
  end

  # fonction qui met à jour les noms des utilisateurs
  def self.import_nom(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      @user = User.where(nom: row_data['Ancien']).first
      @user.nom = row_data['Nouveau']
      @user.save
    end
  end

  def self.authentication_keys
    {statut: true, nom: false}
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis", "bops", "consulted_bops", "credits", "programmes"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "encrypted_password", "id", "id_value", "nom", "remember_created_at", "reset_password_sent_at", "reset_password_token", "statut", "updated_at"]
  end

  def programmes_without_gestion_schemas
    self.programmes.left_outer_joins(:gestion_schemas).where(gestion_schemas: { id: nil }).count
  end

end
