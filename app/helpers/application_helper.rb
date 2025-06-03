module ApplicationHelper
  include Pagy::Frontend

  # Pour formater une valeur simple
  def format_value(value, default = "Non renseigné")
    value.presence || default
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
                   avis.select { |avi| avi.phase == phase || (avi.phase == 'début de gestion' && !avi.is_crg1) }
                 else
                   avis.select { |avi| avi.phase == phase }
                 end
    if avis_phase.empty?
      [0, 0, 0, 0, 0, 0, 0, 0]
    else
      [:ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f].map do |attribute|
        avis_phase.map { |avis| avis.send(attribute) || 0 }.sum
      end
    end
    # avis_phase.empty? ? [0, 0, 0, 0, 0, 0, 0, 0] : avis_phase.pluck(:ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f).transpose.map(&:sum)
  end

  def display_phases(annee_a_afficher, annee, date_crg1, date_crg2, date_debut)
    if annee_a_afficher < annee || Date.today >= date_crg2
      ['CRG2', 'CRG1', 'début de gestion']
    elsif Date.today >= date_crg1
      ['CRG1', 'début de gestion']
    elsif Date.today >= date_debut
      ['début de gestion', 'services votés']
    else
      ['services votés']
    end
  end

  def bops_actifs(bops, annee)
    bops.where('created_at <= ?', Date.new(annee, 12, 31)).where.not(dotation: 'aucune')
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
end
