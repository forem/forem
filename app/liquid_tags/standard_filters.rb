module StandardFilters
  def append(_input)
    raise StandardError, "Liquid#append filter is disabled"
  end

  def concat(_input)
    raise StandardError, "Liquid#concat filter is disabled"
  end

  def compact(_input)
    raise StandardError, "Liquid#compact filter is disabled"
  end

  def first(_input)
    raise StandardError, "Liquid#first filter is disabled"
  end

  def join(_input)
    raise StandardError, "Liquid#join filter is disabled"
  end

  def last(_input)
    raise StandardError, "Liquid#last filter is disabled"
  end

  def map(_input, _property)
    raise StandardError, "Liquid#map filter is disabled"
  end

  def prepend(_input, _string)
    raise StandardError, "Liquid#prepend filter is disabled"
  end

  def remove(_input)
    raise StandardError, "Liquid#remove filter is disabled"
  end

  def remove_first(_input)
    raise StandardError, "Liquid#remove_first filter is disabled"
  end

  def reverse(_input)
    raise StandardError, "Liquid#reverse filter is disabled"
  end

  def replace(_input)
    raise StandardError, "Liquid#replace filter is disabled"
  end

  def replace_first(_input)
    raise StandardError, "Liquid#replace_first filter is disabled"
  end

  def slice(_input)
    raise StandardError, "Liquid#slice filter is disabled"
  end

  def split(_input)
    raise StandardError, "Liquid#split filter is disabled"
  end

  def truncate(_input)
    raise StandardError, "Liquid#truncate filter is disabled"
  end

  def truncatewords(_input)
    raise StandardError, "Liquid#truncatewords filter is disabled"
  end

  def uniq(_input, _property)
    raise StandardError, "Liquid#uniq filter is disabled"
  end
end

Liquid::Template.register_filter(StandardFilters)
