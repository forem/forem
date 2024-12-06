def init
  super
  if object.has_tag?(:validates)
    create_tag_methods([:validates])
    sections << Section.new(:validates)
  end
end

def validates
  all_tags = object.tags(:validates)
  out = ''
  conditions = all_tags.map{| tag | tag.pair.to_s }.uniq.compact
  conditions.each do | condition |
    @tags = all_tags.select{|tag| tag.pair.to_s == condition }
    condition = @tags.first.pair.map do | type, check |
      check = linkify( check.gsub(/^:/,'#') ) if check =~/^:/ # it's a symbol, convert to link
      "#{type} => #{check}"
    end
    @condition = condition.empty? ? nil : condition.join(',')
    out << erb( :validations )
  end
  out
end
