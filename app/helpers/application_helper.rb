module ApplicationHelper
  def format_number(nombre)
    case nombre
    when nil, ''
      '-'
    else
      number_with_delimiter('%.12g' % ('%.1f' % nombre), locale: :fr)
    end
  end

  def format_date(date)
    unless date.nil?
      date = date.strftime('%d/%m/%Y')
    end
  end

  # fonction qui met à jour l'année à afficher
  def annee_a_afficher
    params[:date] && [2023, 2024].include?(params[:date].to_i) ? params[:date].to_i : @annee
  end
end
