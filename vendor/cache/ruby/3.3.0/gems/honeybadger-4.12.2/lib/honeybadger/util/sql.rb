module Honeybadger
  module Util
    class SQL
      EscapedQuotes = /(\\"|\\')/.freeze
      SQuotedData = /'(?:[^']|'')*'/.freeze
      DQuotedData = /"(?:[^"]|"")*"/.freeze
      NumericData = /\b\d+\b/.freeze
      Newline = /\n/.freeze
      Replacement = "?".freeze
      EmptyReplacement = "".freeze
      DoubleQuoters = /(postgres|sqlite|postgis)/.freeze

      def self.obfuscate(sql, adapter)
        force_utf_8(sql.dup).tap do |s|
          s.gsub!(EscapedQuotes, EmptyReplacement)
          s.gsub!(SQuotedData, Replacement)
          s.gsub!(DQuotedData, Replacement) if adapter =~ DoubleQuoters
          s.gsub!(NumericData, Replacement)
          s.gsub!(Newline, EmptyReplacement)
          s.squeeze!(' ')
        end
      end

      def self.force_utf_8(string)
        string.encode(
          Encoding.find('UTF-8'),
          invalid: :replace, 
          undef: :replace, 
          replace: ''
        )
      end
    end
  end
end
