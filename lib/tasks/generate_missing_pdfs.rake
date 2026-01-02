namespace :ht2_actes do
  desc "Génère les PDFs manquants pour tous les actes clôturés (usage: rails ht2_actes:generate_missing_pdfs[10] pour limiter à 10 actes)"
  task :generate_missing_pdfs, [:limit] => :environment do |t, args|
    # Par défaut, pas de limite (tous les actes)
    limit = args[:limit].to_i if args[:limit].present?

    puts "Recherche des actes clôturés sans PDF..."

    # Trouver tous les actes clôturés ou clôturés après pré-instruction sans PDF
    # Trier par date de clôture décroissante pour avoir les plus récents en premier
    tous_actes_clotures = Ht2Acte.where(etat: ['clôturé', 'clôturé après pré-instruction'])
                                  .order(date_cloture: :desc)

    actes_sans_pdf = tous_actes_clotures.select { |acte| !acte.pdf_attached? }

    # Appliquer la limite si spécifiée
    if limit && limit > 0
      actes_sans_pdf = actes_sans_pdf.take(limit)
      puts "Limite de #{limit} acte(s) appliquée."
    end

    total = actes_sans_pdf.count

    if total.zero?
      puts "Aucun acte clôturé sans PDF trouvé."
      return
    end

    puts "#{total} acte(s) trouvé(s) sans PDF."
    puts "Lancement de la génération des PDFs..."

    actes_sans_pdf.each_with_index do |acte, index|
      begin
        puts "[#{index + 1}/#{total}] Génération du PDF pour l'acte #{acte.numero_formate} (clôturé le #{acte.date_cloture})..."
        GenerateActePdfJob.perform_later(acte.id)
      rescue => e
        puts "  ❌ Erreur lors de la génération du PDF pour l'acte #{acte.numero_formate}: #{e.message}"
      end
    end

    puts "✓ Génération des PDFs lancée en arrière-plan pour #{total} acte(s)."
    puts "Les PDFs seront générés progressivement. Vérifiez les logs pour suivre la progression."
  end
end
