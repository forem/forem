# frozen_string_literal: true

module Rouge
  module Guessers
    class Disambiguation < Guesser
      include Util
      include Lexers

      def initialize(filename, source)
        @filename = File.basename(filename)
        @source = source
      end

      def filter(lexers)
        return lexers if lexers.size == 1
        return lexers if lexers.size == Lexer.all.size

        @analyzer = TextAnalyzer.new(get_source(@source))

        self.class.disambiguators.each do |disambiguator|
          next unless disambiguator.match?(@filename)

          filtered = disambiguator.decide!(self)
          return filtered if filtered
        end

        return lexers
      end

      def contains?(text)
        return @analyzer.include?(text)
      end

      def matches?(re)
        return !!(@analyzer =~ re)
      end

      @disambiguators = []
      def self.disambiguate(*patterns, &decider)
        @disambiguators << Disambiguator.new(patterns, &decider)
      end

      def self.disambiguators
        @disambiguators
      end

      class Disambiguator
        include Util

        def initialize(patterns, &decider)
          @patterns = patterns
          @decider = decider
        end

        def decide!(guesser)
          out = guesser.instance_eval(&@decider)
          case out
          when Array then out
          when nil then nil
          else [out]
          end
        end

        def match?(filename)
          @patterns.any? { |p| test_glob(p, filename) }
        end
      end

      disambiguate '*.pl' do
        next Perl if contains?('my $')
        next Prolog if contains?(':-')
        next Prolog if matches?(/\A\w+(\(\w+\,\s*\w+\))*\./)
      end

      disambiguate '*.h' do
        next ObjectiveC if matches?(/@(end|implementation|protocol|property)\b/)
        next ObjectiveC if contains?('@"')
        next Cpp if matches?(/^\s*(?:catch|class|constexpr|namespace|private|
                                   protected|public|template|throw|try|using)\b/x)

        C
      end

      disambiguate '*.m' do
        next ObjectiveC if matches?(/@(end|implementation|protocol|property)\b/)
        next ObjectiveC if contains?('@"')

        next Mathematica if contains?('(*')
        next Mathematica if contains?(':=')

        next Mason if matches?(/<%(def|method|text|doc|args|flags|attr|init|once|shared|perl|cleanup|filter)([^>]*)(>)/)

        next Matlab if matches?(/^\s*?%/)

        next Mason if matches? %r!(</?%|<&)!
      end

      disambiguate '*.php' do
        # PHP always takes precedence over Hack
        PHP
      end

      disambiguate '*.hh' do
        next Cpp if matches?(/^\s*#include/)
        next Hack if matches?(/^<\?hh/)
        next Hack if matches?(/(\(|, ?)\$\$/)

        Cpp
      end

      disambiguate '*.plist' do
        next XML if matches?(/\A<\?xml\b/)

        Plist
      end

      disambiguate '*.sc' do
        next Python if matches?(/^#/)
        next SuperCollider if matches?(/(?:^~|;$)/)

        next Python
      end

      disambiguate 'Messages' do
        next MsgTrans if matches?(/^[^\s:]+:[^\s:]+/)

        next PlainText
      end

      disambiguate '*.cls' do
        next TeX if matches?(/\A\s*(?:\\|%)/)
        next OpenEdge if matches?(/(no\-undo|BLOCK\-LEVEL|ROUTINE\-LEVEL|&ANALYZE\-SUSPEND)/i)
        next Apex
      end

      disambiguate '*.pp' do
        next Puppet if matches?(/(::)?([a-z]\w*::)/)
        next Pascal if matches?(/^(function|begin|var)\b/)
        next Pascal if matches?(/\b(end(;|\.))/)

        Puppet
      end
      
      disambiguate '*.p' do
        next Prolog if contains?(':-')
        next Prolog if matches?(/\A\w+(\(\w+\,\s*\w+\))*\./)
        next OpenEdge
      end
    end
  end
end
