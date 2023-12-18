class Avi < ApplicationRecord
  belongs_to :bop
  belongs_to :user
  require 'axlsx'

  # fonction pour importer les avis d'exécution
  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      code_bop = row_data['Code BOP'].to_s
      bop = Bop.find_by(code: code_bop)
      next unless bop

      avis = Avi.new(bop_id: bop.id, user_id: bop.user_id, phase: row_data['phase'], annee: 2023)
      column_names_bis = %w[created_at etat date_envoi statut ae_i cp_i t2_i etpt_i ae_f cp_f t2_f etpt_f commentaire]
      # avis_debut_n1 = bop.avis.where(phase: 'début de gestion', annee: 2023).first
      # avis = Avi.where(bop_id: bop.id, phase: 'execution', annee: 2023).first || Avi.new(bop_id: bop.id, user_id: bop.user_id, phase: 'execution', annee: 2023, ae_i: avis_debut_n1.ae_i, cp_i: avis_debut_n1.cp_i, t2_i: avis_debut_n1.t2_i, etpt_i: avis_debut_n1.etpt_i)
      # column_names_bis = %w[ae_f cp_f t2_f etpt_f date_envoi]
      avis.attributes = row_data.slice(*column_names_bis)
      avis.save
    end
  end
end
