# encoding: UTF-8

module Sterile

  class << self

    def transmogrify(string, &block)
      raise "No block given" unless block_given?

      result = ""
      string.unpack("U*").each do |codepoint|
        cg = codepoint >> 8
        cp = codepoint & 0xFF
        begin
          mapping = Array(codepoints_data[cg][cp])
          result << yield(mapping, codepoint)
        rescue
        end
      end

      result
    end

    # Transliterate Unicode [and accented ASCII] characters to their plain-text
    # ASCII equivalents. This is based on data from the stringex gem (https://github.com/rsl/stringex)
    # which is in turn a port of Perl's Unidecode and ostensibly provides
    # superior results to iconv. The optical conversion data is based on work
    # by Eric Boehs at https://github.com/ericboehs/to_slug
    # Passing an option of :optical => true will prefer optical mapping instead
    # of more pedantic matches.
    #
    #   "ýůçký".transliterate # => "yucky"
    #
    def transliterate(string, options = {})
      options = {
        :optical => false
      }.merge!(options)

      if options[:optical]
        transmogrify(string) do |mapping, codepoint|
          mapping[1] || mapping[0] || ""
        end
      else
        transmogrify(string) do |mapping, codepoint|
          mapping[0] || mapping[1] || ""
        end
      end
    end
    alias_method :to_ascii, :transliterate


    private

    # Lazy load codepoints data
    #
    def codepoints_data
      @codepoints_data ||= begin
        require "sterile/data/codepoints_data"
        Data.codepoints_data
      end
    end

  end # class << self

end # module Sterile

