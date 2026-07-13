class Bop < ApplicationRecord
  belongs_to :user
  belongs_to :dcb, class_name: 'User', foreign_key: 'dcb_id'
  has_many :avis, dependent: :destroy
  belongs_to :programme
  has_many :centre_financiers

  # Période d'activité d'un BOP : date_debut_activite (obligatoire en pratique),
  # date_fin_activite (nullable = encore actif).
  # Un BOP est "actif sur l'année N" si sa période chevauche l'année.
  # date_fin_activite est exclusive : un BOP avec date_fin_activite = 1er janvier N
  # est inactif sur N (et toute année postérieure).
  scope :actifs_en, ->(annee) {
    debut_annee = Date.new(annee, 1, 1)
    fin_annee   = Date.new(annee, 12, 31)
    where('date_debut_activite <= ?', fin_annee)
      .where('date_fin_activite IS NULL OR date_fin_activite > ?', debut_annee)
  }

  scope :inactifs_en, ->(annee) {
    debut_annee = Date.new(annee, 1, 1)
    fin_annee   = Date.new(annee, 12, 31)
    where('date_debut_activite IS NULL OR date_debut_activite > ? OR date_fin_activite <= ?',
          fin_annee, debut_annee)
  }

  def actif_en?(annee)
    return false if date_debut_activite.nil?
    return false if date_debut_activite > Date.new(annee, 12, 31)
    date_fin_activite.nil? || date_fin_activite > Date.new(annee, 1, 1)
  end

  def self.import(file)

    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      programme = Programme.find_by(numero: row_data['N°Programme'])
      user = User.find_by(nom: row_data['Identifiant ANACO Contrôleur BOP'])
      dcb  = User.find_by(nom: row_data['Identifant DCB Programme ANACO'].to_s)
      deconcentre = row_data['Déconcentré'].to_s.strip.downcase == 'oui'
      dotation = row_data['Dotation'].presence
      statut = row_data['Statut'].to_s.strip.downcase.presence_in(['actif', 'inactif']) || 'actif'
      # Colonnes optionnelles : si absentes, fallback intelligent ci-dessous.
      date_debut_activite = parse_date(row_data["Date début activité"])
      date_fin_activite   = parse_date(row_data["Date fin activité"])

      next if user.nil? || programme.nil?

      attrs = { user_id: user.id, dcb_id: dcb&.id, programme_id: programme.id,
                dotation: dotation, deconcentre: deconcentre, statut: statut }
      attrs[:date_debut_activite] = date_debut_activite if date_debut_activite
      attrs[:date_fin_activite]   = date_fin_activite   if date_fin_activite

      if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
        @bop = Bop.find_by(code: row_data['Code CHORUS du BOP'].to_s)
        @bop.update(attrs)
      else
        # BOP nouveau : date_debut_activite = colonne fournie OU début de l'année courante.
        attrs[:date_debut_activite] ||= Date.current.beginning_of_year
        bop = Bop.new(attrs.merge(
          code: row_data['Code CHORUS du BOP'].to_s,
          created_at: Date.current.beginning_of_year.to_datetime
        ))

        unless bop.save
          puts "Erreur lors de la création du Bop : #{bop.errors.full_messages.join(', ')}"
        end
      end

    end
    Bop.where(dotation: "\n").update_all(dotation: nil)
  end

  def self.parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)
    return value.to_date if value.is_a?(DateTime) || value.is_a?(Time)
    Date.strptime(value.to_s, '%d/%m/%Y')
  rescue ArgumentError
    nil
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "dcb", "created_at", "date_debut_activite", "date_fin_activite", "deconcentre", "dotation", "id", "id_value", "statut", "updated_at", "user_id", "dcb_id", "programme_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis", "centre_financiers", "dcb", "programme", "user"]
  end
end
