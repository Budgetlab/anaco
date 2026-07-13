class Suspension < ApplicationRecord
  belongs_to :acte

  validates :date_suspension, presence: true
  validate :motif_must_have_non_blank_value
  validate :date_reprise_not_before_date_suspension

  def self.ransackable_attributes(auth_object = nil)
    ["commentaire_reprise", "created_at", "date_reprise", "date_suspension", "acte_id", "id", "id_value", "motif", "observations", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["acte"]
  end

  private

  def motif_must_have_non_blank_value
    if Array(motif).reject(&:blank?).empty?
      errors.add(:motif, "doit contenir au moins une valeur")
    end
  end

  def date_reprise_not_before_date_suspension
    return if date_reprise.blank? || date_suspension.blank?
    if date_reprise.to_date < date_suspension.to_date
      errors.add(:date_reprise, "ne peut pas être antérieure à la date de suspension")
    end
  end
end
