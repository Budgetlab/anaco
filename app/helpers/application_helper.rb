module ApplicationHelper
  # Custom Pagy navigation compatible avec le DSFR (Système de Design de l'État français)
  def pagy_nav_custom(pagy, **opts)
    return '' unless pagy.pages > 1

    html = +%(<nav role="navigation" class="fr-pagination" aria-label="Pagination">)
    html << %(<ul class="fr-pagination__list">)

    # Bouton Première page
    if pagy.previous
      html << %(<li><a class="fr-pagination__link fr-pagination__link--first" href="#{pagy.page_url(:first, **opts)}" aria-label="Première page">Première page</a></li>)
    end

    # Bouton Page précédente
    if pagy.previous
      html << %(<li><a class="fr-pagination__link fr-pagination__link--prev fr-pagination__link--lg-label" href="#{pagy.page_url(:previous, **opts)}" aria-label="Page précédente">Page précédente</a></li>)
    end

    # Pages numérotées - génération manuelle de la série
    series = pagy_series(pagy, **opts)
    series.each do |item|
      case item
      when Integer
        if item == pagy.page
          html << %(<li><a class="fr-pagination__link" aria-current="page" title="Page #{item}">#{item}</a></li>)
        else
          html << %(<li><a class="fr-pagination__link" href="#{pagy.page_url(item, **opts)}" title="Page #{item}">#{item}</a></li>)
        end
      when String
        html << %(<li><a class="fr-pagination__link" aria-current="page" title="Page #{item}">#{item}</a></li>)
      when :gap
        html << %(<li><a class="fr-pagination__link">...</a></li>)
      end
    end

    # Bouton Page suivante
    if pagy.next
      html << %(<li><a class="fr-pagination__link fr-pagination__link--next fr-pagination__link--lg-label" href="#{pagy.page_url(:next, **opts)}" aria-label="Page suivante">Page suivante</a></li>)
    end

    # Bouton Dernière page
    if pagy.next
      html << %(<li><a class="fr-pagination__link fr-pagination__link--last" href="#{pagy.page_url(:last, **opts)}" aria-label="Dernière page">Dernière page</a></li>)
    end

    html << %(</ul>)
    html << %(</nav>)
    html.html_safe
  end

  # Helper pour générer la série de pages
  def pagy_series(pagy, slots: 7, **opts)
    return [] if pagy.pages <= 1

    series = []

    if slots >= pagy.pages
      series.push(*1..pagy.pages)
    else
      half = (slots - 1) / 2
      start = if pagy.page <= half
                1
              elsif pagy.page > (pagy.pages - slots + half)
                pagy.pages - slots + 1
              else
                pagy.page - half
              end
      series.push(*(start...(start + slots)))

      # Ajouter les gaps et première/dernière page
      unless slots < 7
        series[0] = 1
        series[1] = :gap unless series[1] == 2
        series[-2] = :gap unless series[-2] == pagy.pages - 1
        series[-1] = pagy.pages
      end
    end

    # Convertir la page courante en String
    current = series.index(pagy.page)
    series[current] = pagy.page.to_s if current

    series
  end

  # Pour formater une valeur simple
  def format_value(value, default = "Non renseigné")
    value.presence || default
  end

  # Calcule l'effet de l'enveloppe (%) : ratio montant_ae / impact_maximal_sans_enveloppe.
  # Retourne un entier arrondi (Integer) ou nil si le calcul n'est pas possible.
  # Réutilisé dans la vue _show_enveloppe_limitative et dans export.xlsx.axlsx.
  def effet_enveloppe_pct(montant_ae, impact_maximal_sans_enveloppe)
    impact = impact_maximal_sans_enveloppe.to_f
    return nil if impact <= 0
    ((montant_ae.to_f / impact) * 100).round
  end

  # Variante formatée pour affichage : "12 %" ou "—" si non calculable.
  def format_effet_enveloppe_pct(montant_ae, impact_maximal_sans_enveloppe, placeholder: "—")
    pct = effet_enveloppe_pct(montant_ae, impact_maximal_sans_enveloppe)
    pct.nil? ? placeholder : "#{pct} %"
  end

  # Pour afficher les effectifs (float) au format français : 11.0 → "11", 26363.3 → "26 363,3"
  def format_effectif(value, default = "Non renseigné")
    return default if value.nil?
    f = value.to_f
    if f % 1 == 0
      number_with_delimiter(f.to_i, delimiter: " ")
    else
      number_with_precision(f, precision: 10, strip_insignificant_zeros: true, delimiter: " ", separator: ',')
    end
  end

  # Pour assurer que les images et pièces jointes sont correctement affichées dans les PDFs
  def format_for_pdf(content)
    return content unless content.present?

    # Convertir les URL relatives en URL absolues pour les images
    content = content.gsub(/src="\/([^"]+)"/) do |match|
      "src=\"#{root_url.chomp('/')}\/#{$1}\""
    end

    # Assurer que les images ont une taille maximale
    content = content.gsub(/<img/) do |match|
      "#{match} style=\"max-width: 100%; height: auto;\""
    end

    content
  end

  def format_number(nombre)
    case nombre
    when nil, ''
      '-'
    else
      number_with_delimiter('%.12g' % ('%.1f' % nombre), locale: :fr)
    end
  end

  def percentage_of(count, total, precision: 1)
    return "0 %" if total.to_f.zero?

    number_to_percentage(
      (count.to_f / total.to_f) * 100,
      precision: precision,
      strip_insignificant_zeros: true
    )
  end
  def format_date_text(date, format = "%e/%m/%y", default = "Non renseigné")
    date.present? ? l(date, format: format) : default
  end

  # pour formulaire
  def format_date(date)
    unless date.nil?
      date = date.strftime('%d/%m/%Y')
    end
  end

  # fonction qui met à jour l'année à afficher
  def annee_a_afficher
    params[:date] && (2023..Date.today.year).to_a.include?(params[:date].to_i) ? params[:date].to_i : @annee
  end

  def format_boolean(string)
    case string
    when nil, ''
      'Non renseigné'
    when true, 'true'
      'Oui'
    when false, 'false'
      'Non'
    else
      string
    end
  end

  def render_tag_group(title, param_name, options)
    output = content_tag :div, title, class: 'fr-label fr-text--bold'
    output << content_tag(:ul, class: 'fr-tags-group fr-my-1w') do
      options.map do |val|
        content_tag(:li) do
          content_tag(:button, ' ', class: 'fr-tag', data: { action: 'click->request#checkTag' },
                      'aria-pressed' => (params[:q] && params[:q][param_name].present? && params[:q][param_name].include?(val) ? 'true' : 'false')) do
            content_tag(:label) do
              check_box_tag("q[#{param_name}][]", val, params[:q] && params[:q][param_name].present? && params[:q][param_name].include?(val) ? true : false,
                            { class: 'fr-hidden' }) + format_boolean(val)
            end
          end
        end
      end.join.html_safe
    end
    output
  end

  def render_select_group(title, param_name, options)
    select_group = content_tag :div, class: 'fr-select-group' do
      label = content_tag(:label, title, for: "#{param_name}_list", class: 'fr-label fr-text--bold')
      select = content_tag(:select, class: 'fr-select', id: "#{param_name}_list", data: { tag: "#{param_name}_tag", action: 'change->request#addTagSelected' }) do
        option_tags = content_tag(:option, '- sélectionner -', value: '')
        options.each { |option| option_tags.concat(content_tag(:option, option, value: option)) }
        option_tags
      end
      label.concat(select)
    end
    tags_group = content_tag(:ul, class: 'fr-tags-group', id: "#{param_name}_tag") do
      checkbox_tags = ''.html_safe
      options.each do |option|
        checkbox_tags << check_box_tag("q[#{param_name}][]", option, params[:q] && params[:q][param_name].present? && params[:q][param_name]&.include?(option) ? true : false, { class: "fr-hidden" })
      end
      button_tags = ''.html_safe
      if params[:q] && params[:q][param_name]
        params[:q][param_name].map do |option|
          button_tags << content_tag(:li, data: { action: 'click->request#removeTagSelected', value: option }) do
            content_tag(:button, option, class: 'fr-tag fr-tag--dismiss', aria_label: 'Retirer')
          end
        end
      end
      checkbox_tags.concat(button_tags)
    end
    select_group.concat(tags_group)
  end

  def sum_chiffres_avis(avis, phase)
    avis_phase = case phase
                 when 'CRG1'
                   avis.select { |avi| avi.phase == phase || (avi.phase == 'programmation initiale' && !avi.is_crg1) }
                 else
                   avis.select { |avi| avi.phase == phase }
                 end
    somme_chiffres_avis(avis_phase)
  end

  # Variante par instance de phase : agrège les chiffres des avis rattachés à
  # CETTE ligne Phase (via phase_id) plutôt que par nom. Permet un onglet distinct
  # par instance (ex. services votés 1 vs services votés 2) sur la page programme.
  # La règle métier CRG1 est conservée : une instance CRG1 inclut aussi les avis
  # de programmation initiale finalisés sans CRG1 (is_crg1 == false).
  def sum_chiffres_avis_instance(avis, phase)
    avis_phase = avis.select { |avi| avi.phase_id == phase.id }
    if phase.nom == 'CRG1'
      avis_phase += avis.select { |avi| avi.phase == 'programmation initiale' && !avi.is_crg1 }
    end
    somme_chiffres_avis(avis_phase)
  end

  # Somme des 8 agrégats budgétaires (initiaux + prévisionnels) sur une liste d'avis.
  def somme_chiffres_avis(avis_phase)
    return [0, 0, 0, 0, 0, 0, 0, 0] if avis_phase.empty?

    [:ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f].map do |attribute|
      avis_phase.map { |avis| avis.send(attribute) || 0 }.sum
    end
  end

  # Instances de phase à afficher en onglets de suivi_remplissage / show_avis (une
  # par phase existante, sans regroupement par nom : plusieurs "services votés" dans
  # l'année donnent plusieurs onglets — services votés 1, 2, …). Ordonnées phase la
  # plus récente d'abord (le 1er sert d'onglet sélectionné par défaut).
  #
  # - Année passée → toutes les phases connues pour cette année (saisie clôturée,
  #   on présente l'historique complet).
  # - Année courante → seulement les phases dont date_debut est passée (les autres
  #   ne sont pas encore ouvertes à la saisie, rien à montrer).
  def display_phase_instances(annee_a_afficher)
    phases_annee = Phase.pour_annee(annee_a_afficher).to_a
    visibles = annee_a_afficher < Date.today.year ? phases_annee
                                                  : phases_annee.select { |p| p.date_debut <= Date.today }
    visibles.sort_by(&:date_debut).reverse
  end

  def bops_actifs(bops, annee)
    bops.actifs_en(annee)
  end

  def colorful_card_css_class(amount)
    amount.negative? ? 'fr-card--red' : 'fr-card--blue'
  end

  def color_cells(sheet, range)
    sheet[range].each do |cell|
      color = cell.value.to_i < 0 ? "FFE9E9" : "dae1f2"
      cell.add_style bg_color: color
    end
  end

  # Helper simple pour nettoyer le contenu ActionText
  def clean_action_text(content)
    return '' if content.blank?

    # Supprimer les balises HTML et garder le texte
    text = ActionController::Base.helpers.strip_tags(content.to_s)

    # Supprimer les espaces en trop
    text.gsub(/\s+/, ' ').strip
  end
  def rich_text_has_images?(rich_text_content)
    return false if rich_text_content.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(rich_text_content.to_s)
    doc.css('action-text-attachment[content-type^="image"]').any?
  end

  def count_images_in_rich_text(rich_text_content)
    return 0 if rich_text_content.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(rich_text_content.to_s)
    doc.css('action-text-attachment[content-type^="image"]').count
  end

  def nature_chorus_prefixes
    {
      'Bail' => '20',
      'Bon de commande' => '14',
      'Décision diverse' => '19',
      'Marché unique' => '10',
      'Marché à tranches' => '11',
      'Marché mixte' => '12',
      'MAPA unique' => '15',
      'MAPA à tranches' => '16',
      'MAPA à bons de commande' => '17',
      'MAPA mixte' => '18',
      'Subvention' => '21',
      "Subvention pour charges d'investissement" => '21',
      'Subvention pour charges de service public' => '21',
      'Transfert' => '21',
      'Accord cadre à bons de commande' => '13',
      'Autre contrat' => '22'
    }
  end

  def get_expected_prefix(nature)
    nature_chorus_prefixes[nature]
  end

  def validate_chorus_prefix(nature, numero_chorus)
    expected_prefix = get_expected_prefix(nature)
    return true if expected_prefix.nil? || numero_chorus.blank?

    numero_chorus.start_with?(expected_prefix)
  end

  def return_variable(type_variable)
    case type_variable
    when 'decision'
      ['Visa accordé', "Visa accordé avec observations", 'Refus de visa', 'Favorable', 'Favorable avec observations', 'Défavorable', 'Retour sans décision (sans suite)', 'Saisine a posteriori']
    when 'motif_suspensions'
      tous_types_motifs_suspensions
    when 'motif_observations'
      tous_types_observations
    end
  end

  def count_for(counts, year, type)
    counts[[year, type]] || 0
  end

  def evolution_percent(old_value, new_value)
    return "-" if old_value.to_f == 0   # évite division par zéro
    (((new_value - old_value) / old_value.to_f) * 100).round(1)
  end

end
