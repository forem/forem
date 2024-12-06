# encoding: UTF-8

module Sterile

  class << self

    # Format text with proper "curly" quotes, m-dashes, copyright, trademark, etc.
    #
    #   q{"He said, 'Away with you, Drake!'"}.smart_format # => “He said, ‘Away with you, Drake!’”
    #
    def smart_format(string)
      string = string.to_s
      string = string.dup if string.frozen?
      smart_format_rules.each do |rule|
        string.gsub! rule[0], rule[1]
      end
      string
    end


    # Like +smart_format+, but works with HTML/XML (somewhat).
    #
    def smart_format_tags(string)
      string = string.gsub(/[\p{Z}\s]+(<\/[a-zA-Z]+>)(['"][a-zA-Z])/, "\\1 \\2") # Fixes quote after whitespace + tag "<em>Dan. </em>'And"
      string.gsub_tags do |text|
        text.smart_format
      end.encode_entities.gsub(/(\<\/\w+\>)&ldquo;/, "\\1&rdquo;").gsub(/(\<\/\w+\>)&lsquo;/, "\\1&rsquo;")
    end


    private

    # Lazy load smart formatting rules
    #
    def smart_format_rules
      @smart_format_rules ||= begin
        require "sterile/data/smart_format_rules"
        Data.smart_format_rules
      end
    end

  end # class << self

end # module Sterile

