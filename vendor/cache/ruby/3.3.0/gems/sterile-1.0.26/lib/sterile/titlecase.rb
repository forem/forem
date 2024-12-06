# encoding: UTF-8

module Sterile

  class << self

    # Format text appropriately for titles. This method is much smarter
    # than ActiveSupport's +titlecase+. The algorithm is based on work done
    # by John Gruber et al (http://daringfireball.net/2008/08/title_case_update)
    #
    def titlecase(string)

      lsquo = [8216].pack("U")
      rsquo = [8217].pack("U")
      ldquo = [8220].pack("U")
      rdquo = [8221].pack("U")
      ndash = [8211].pack("U")

      string.strip!
      string.gsub!(/\s+/, " ")
      string.downcase! unless string =~ /[[:lower:]]/

      small_words = %w{ a an and as at(?!&t) but by en for if in nor of on or the to v[.]? via vs[.]? }.join("|")
      apos = / (?: ['#{rsquo}] [[:lower:]]* )? /xu

      string.gsub!(
        /
          \b
          ([_\*]*)
          (?:
            ( [-\+\w]+ [@.\:\/] [-\w@.\:\/]+ #{apos} )      # URL, domain, or email
            |
            ( (?i: #{small_words} ) #{apos} )               # or small word, case-insensitive
            |
            ( [[:alpha:]] [[:lower:]'#{rsquo}()\[\]{}]* #{apos} )  # or word without internal caps
            |
            ( [[:alpha:]] [[:alpha:]'#{rsquo}()\[\]{}]* #{apos} )  # or some other word
          )
          ([_\*]*)
          \b
        /xu
      ) do
        ($1 ? $1 : "") +
        ($2 ? $2 : ($3 ? $3.downcase : ($4 ? $4.downcase.capitalize : $5))) +
        ($6 ? $6 : "")
      end

      if RUBY_VERSION < "1.9.0"
        string.gsub!(
          /
            \b
            ([:alpha:]+)
            (#{ndash})
            ([:alpha:]+)
            \b
          /xu
        ) do
          $1.downcase.capitalize + $2 + $1.downcase.capitalize
        end
      end

      string.gsub!(
        /
          (
            \A [[:punct:]]*     # start of title
            | [:.;?!][ ]+       # or of subsentence
            | [ ]['"#{ldquo}#{lsquo}(\[][ ]*  # or of inserted subphrase
          )
          ( #{small_words} )    # followed by a small-word
          \b
        /xiu
      ) do
        $1 + $2.downcase.capitalize
      end

      string.gsub!(
        /
          \b
          ( #{small_words} )    # small-word
          (?=
            [[:punct:]]* \Z     # at the end of the title
            |
            ['"#{rsquo}#{rdquo})\]] [ ]       # or of an inserted subphrase
          )
        /xu
      ) do
        $1.downcase.capitalize
      end

      string.gsub!(
        /
          (
            \b
            [[:alpha:]]         # single first letter
            [\-#{ndash}]               # followed by a dash
          )
          ( [[:alpha:]] )       # followed by a letter
        /xu
      ) do
        $1 + $2.downcase
      end

      string.gsub!(/q&a/i, 'Q&A')

      string
    end
    alias_method :titleize, :titlecase

  end # class << self

end # module Sterile

