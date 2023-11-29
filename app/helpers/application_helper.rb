module ApplicationHelper
  def format_number(nombre)
    case nombre
    when nil, ''
      '-'
    else
      number_with_delimiter('%.11g' % ('%.1f' % nombre), locale: :fr)
    end
  end

  def format_date(date)
    unless date.nil?
      date = date.strftime('%d/%m/%Y')
    end
  end
end
