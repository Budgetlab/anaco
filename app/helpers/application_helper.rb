module ApplicationHelper
  def format_number(number)
    unless number.nil?
      number = number_with_delimiter('%.11g' % ('%.1f' % number), locale: :fr)
    end
  end

  def format_date(date)
    unless date.nil?
      date = date.strftime('%d/%m/%Y')
    end
  end
end
