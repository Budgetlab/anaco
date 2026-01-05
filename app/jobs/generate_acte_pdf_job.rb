class GenerateActePdfJob < ApplicationJob
  queue_as :default

  # Retry en cas d'erreur réseau ou temporaire (max 3 tentatives)
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Ne pas retenter si l'acte n'existe plus
  discard_on ActiveRecord::RecordNotFound

  def perform(acte_id)
    acte = Ht2Acte.find(acte_id)

    # Log de début
    Rails.logger.info "Génération PDF pour acte ##{acte_id}"

    # 1. Génération du PDF via Grover
    pdf_content = generate_pdf(acte)

    # 2. Attachement du PDF à l'acte via ActiveStorage
    attach_pdf_to_acte(acte, pdf_content)

    # 3. Mettre à jour le statut à "completed"
    acte.update(pdf_generation_status: 'completed')

    Rails.logger.info "PDF généré et attaché pour Acte ##{acte_id}"

  rescue Grover::Error => e
    Rails.logger.error "Erreur Grover pour Acte ##{acte_id}: #{e.message}"
    acte.update(pdf_generation_status: 'failed')
    raise e # Will trigger retry

  rescue ActiveStorage::Error => e
    Rails.logger.error "Erreur ActiveStorage pour Acte ##{acte_id}: #{e.message}"
    acte.update(pdf_generation_status: 'failed')
    raise e

  rescue => e
    Rails.logger.error "Erreur inattendue pour Acte ##{acte_id}: #{e.class} - #{e.message}"
    acte.update(pdf_generation_status: 'failed')
    raise e
  end

  private

  def generate_pdf(acte)
    # Charger les associations nécessaires pour éviter N+1
    acte = Ht2Acte.find(acte.id)

    # Rendu du partial (contenu uniquement)
    partial_content = ApplicationController.render(
      partial: 'ht2_actes/acte_pdf_content',
      locals: {
        acte: acte,
      },
      formats: [:html]
    )

    # Rendu du layout avec le contenu du partial
    html_content = ApplicationController.render(
      inline: partial_content,
      layout: 'pdf',
      formats: [:html]
    )

    # Grover génère le PDF avec la config globale (grover.rb)
    # Le timeout de 60s et les options Chromium sont déjà configurés
    Grover.new(html_content).to_pdf
  end

  def attach_pdf_to_acte(acte, pdf_content)
    # Créer un fichier temporaire en mémoire (StringIO)
    pdf_io = StringIO.new(pdf_content)
    pdf_io.rewind

    # Attacher le PDF avec ActiveStorage
    acte.pdf_files.attach(
      io: pdf_io,
      filename: acte.pdf_filename,
      content_type: 'application/pdf',
      metadata: {
        generated_at: Time.current.iso8601,
      }
    )
  end
end