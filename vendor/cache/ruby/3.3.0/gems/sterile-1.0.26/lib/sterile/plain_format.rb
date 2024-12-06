# encoding: UTF-8

module Sterile

  class << self

    def plain_format(string)
      string = string.encode_entities
      plain_format_rules.each do |rule|
        string.gsub! rule[0], rule[1]
      end
      string
    end


    # Like +plain_format+, but works with HTML/XML (somewhat).
    #
    def plain_format_tags(string)
      string.gsub_tags do |text|
        text.plain_format.decode_entities
      end.encode_entities
    end


    private

    # Lazy load plain formatting rules
    #
    def plain_format_rules
      @plain_format_rules ||= begin
        require "sterile/data/plain_format_rules"
        Data.plain_format_rules
      end
    end

  end # class << self

end # module Sterile

