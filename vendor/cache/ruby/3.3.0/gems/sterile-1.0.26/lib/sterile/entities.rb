# encoding: UTF-8

module Sterile

  class << self

    # Turn Unicode characters into their HTML equivilents.
    # If a valid HTML entity is not possible, it will create a numeric entity.
    #
    #   q{“Economy Hits Bottom,” ran the headline}.encode_entities # => &ldquo;Economy Hits Bottom,&rdquo; ran the headline
    #
    def encode_entities(string)
      transmogrify(string) do |mapping, codepoint|
        if (32..126).include?(codepoint)
          mapping[0]
        else
          "&" + (mapping[2] || "#" + codepoint.to_s) + ";"
        end
      end
    end


    # The reverse of +encode_entities+. Turns HTML or numeric entities into
    # their Unicode counterparts.
    #
    def decode_entities(string)
      string.gsub!(/&#x([a-zA-Z0-9]{1,7});/) { [$1.to_i(16)].pack("U") }
      string.gsub!(/&#(\d{1,7});/) { [$1.to_i].pack("U") }
      string.gsub(/&([a-zA-Z0-9]+);/) do
        codepoint = html_entities_data[$1]
        codepoint ? [codepoint].pack("U") : $&
      end
    end


    private

    # Lazy load html entities
    #
    def html_entities_data
      @html_entities_data ||= begin
        require "sterile/data/html_entities_data"
        Data.html_entities_data
      end
    end

  end # class << self

end # module Sterile

