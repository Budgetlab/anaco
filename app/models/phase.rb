class Phase < ApplicationRecord
  # Noms canoniques utilisés dans le code et les vues.
  # Toute évolution se fait par création de lignes en base, pas par enum dur ici.
  NOMS_CONNUS = ['services votés', 'programmation initiale', 'CRG1', 'CRG2'].freeze

  # Libellé d'affichage en en-tête de colonne du tableau remplissage_avis.
  # Mappe les noms internes (lowercase) vers les intitulés "capitalisés"
  # affichés à l'utilisateur.
  LIBELLES_COLONNE = {
    'services votés'   => 'Services votés',
    'programmation initiale' => 'Programmation initiale',
    'CRG1'             => 'CRG1',
    'CRG2'             => 'CRG2'
  }.freeze

  def self.libelle_colonne(nom)
    LIBELLES_COLONNE.fetch(nom, nom)
  end

  has_many :avis, foreign_key: :phase_id, dependent: :nullify, inverse_of: :phase_periode

  validates :nom, presence: true, inclusion: { in: NOMS_CONNUS,
                                                message: "doit être un des suivants : #{NOMS_CONNUS.join(', ')}" }
  validates :annee, presence: true,
                    numericality: { only_integer: true, greater_than_or_equal_to: 2020, less_than_or_equal_to: 2100 }
  validates :date_debut, presence: true
  validates :date_debut, uniqueness: { scope: [:annee, :nom],
                                       message: 'doit être unique pour ce nom et cette année' }
  validate :date_debut_dans_annee

  scope :pour_annee, ->(annee) { where(annee: annee).order(:date_debut) }

  # Phases d'une année dont la date_debut est passée à la date de référence.
  # Sert au compteur "phase ouverte ?" et au calcul de la phase courante.
  scope :ouvertes_a, ->(reference_date = Date.today) {
    where('date_debut <= ?', reference_date).order(:date_debut)
  }

  # Phase courante pour une année donnée à une date de référence : la plus récente
  # parmi celles dont date_debut est passée. Retourne nil si aucune n'est ouverte
  # (cas d'une année dont aucune phase n'a démarré).
  def self.courante_pour(annee, reference_date = Date.today)
    pour_annee(annee).where('date_debut <= ?', reference_date).last
  end

  # Phase courante, ou une phase fictive par défaut si la table est vide pour
  # l'année (aucune phase en base) : une "programmation initiale" non persistée
  # démarrant au 1er janvier. Sert de socle générique à l'affichage de la
  # fenêtre d'ouverture sur la page d'accueil.
  def self.courante_ou_defaut(annee, reference_date = Date.today)
    courante_pour(annee, reference_date) ||
      new(nom: 'programmation initiale', annee: annee, date_debut: Date.new(annee, 1, 1))
  end

  # Phase suivante dans l'ordre chronologique parmi les phases de la même année.
  # Renvoie nil s'il n'y en a pas (phase la plus tardive de l'année).
  def phase_suivante
    return nil if date_debut.blank?
    Phase.where(annee: annee).where('date_debut > ?', date_debut).order(:date_debut).first
  end

  # Date de fermeture de la fenêtre couverte par cette phase : la veille du début
  # de la phase suivante, ou le 31 décembre de l'année s'il n'y a pas de suivante.
  def date_fermeture
    suivante = phase_suivante
    suivante ? suivante.date_debut.prev_day : Date.new(annee, 12, 31)
  end

  # Numéro d'ordre de cette phase parmi les phases de même nom dans la même année.
  # Sert à distinguer SV1 / SV2 quand plusieurs services votés existent dans l'année.
  # Renvoie nil si la phase n'est pas persistée.
  def numero_dans_annee
    return nil unless persisted?
    Phase.where(nom: nom, annee: annee).order(:date_debut).pluck(:id).index(id)&.+(1)
  end

  # Libellé d'affichage : ajoute le numéro uniquement si plusieurs phases du même nom
  # cohabitent dans l'année. Exemple : "services votés" seul → "services votés" ;
  # 2 SV dans l'année → "services votés 1" et "services votés 2".
  def libelle_avec_numero
    return nom unless persisted?
    freres = Phase.where(nom: nom, annee: annee).count
    freres > 1 ? "#{nom} #{numero_dans_annee}" : nom
  end

  # Variante courte pour préfixer un badge dans le tableau remplissage_avis
  # quand il y a plusieurs instances de la même phase dans l'année.
  # Mapping des abréviations : services votés → SV, programmation initiale → PI.
  # CRG1/CRG2 sont déjà courts → on retourne le nom tel quel.
  ABREVIATIONS = {
    'services votés'         => 'SV',
    'programmation initiale' => 'PI'
  }.freeze

  def libelle_court_avec_numero
    return nil unless persisted?
    abbrev = ABREVIATIONS.fetch(nom, nom)
    "#{abbrev}#{numero_dans_annee}"
  end

  # Vrai si la phase est ouverte (sa date_debut est passée) à une date de référence.
  def ouverte?(reference_date = Date.today)
    date_debut.present? && reference_date >= date_debut
  end

  def self.ransackable_attributes(auth_object = nil)
    ["annee", "created_at", "date_debut", "id", "nom", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis"]
  end

  private

  def date_debut_dans_annee
    return if date_debut.blank? || annee.blank?
    return if date_debut.year == annee
    errors.add(:date_debut, "doit appartenir à l'année #{annee}")
  end
end
