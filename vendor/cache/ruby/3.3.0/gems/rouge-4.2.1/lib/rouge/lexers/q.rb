# frozen_string_literal: true

module Rouge
  module Lexers
    class Q < RegexLexer
      title 'Q'
      desc 'The Q programming language (kx.com)'
      tag 'q'
      aliases 'kdb+'
      filenames '*.q'
      mimetypes 'text/x-q', 'application/x-q'

      identifier = /\.?[a-z][a-z0-9_.]*/i

      def self.keywords
        @keywords ||= %w[do if while select update delete exec from by]
      end

      def self.word_operators
        @word_operators ||= %w[
          and or except inter like each cross vs sv within where in asof bin binr cor cov cut ej fby
          div ij insert lj ljf mavg mcount mdev mmax mmin mmu mod msum over prior peach pj scan scov setenv ss
          sublist uj union upsert wavg wsum xasc xbar xcol xcols xdesc xexp xgroup xkey xlog xprev xrank
        ]
      end

      def self.builtins
        @builtins ||= %w[
          first enlist value type get set count string key max min sum prd last flip distinct raze neg
          desc differ dsave dev eval exit exp fills fkeys floor getenv group gtime hclose hcount hdel hopen hsym
          iasc idesc inv keys load log lsq ltime ltrim maxs md5 med meta mins next parse plist prds prev rand rank ratios
          read0 read1 reciprocal reverse rload rotate rsave rtrim save sdev show signum sin sqrt ssr sums svar system
          tables tan til trim txf ungroup var view views wj wj1 ww
        ]
      end

      state :root do
        # q allows a file to start with a shebang
        rule %r/#!(.*?)$/, Comment::Preproc, :top
        rule %r//, Text, :top
      end

      state :top do
        # indented lines at the top of the file are ignored by q
        rule %r/^[ \t\r]+.*$/, Comment::Special
        rule %r/\n+/, Text
        rule %r//, Text, :base
      end

      state :base do
        rule %r/\n+/m, Text
        rule(/^.\)/, Keyword::Declaration)

        # Identifiers, word operators, etc.
        rule %r/#{identifier}/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.word_operators.include? m[0]
            token Operator::Word
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          elsif /^\.[zQqho]\./ =~ m[0]
            token Name::Constant
          else
            token Name
          end
        end

        # White space and comments
        rule(%r{\s+/.*}, Comment::Single)
        rule(/[ \t\r]+/, Text::Whitespace)
        rule(%r{^/$.*?^\\$}m, Comment::Multiline)
        rule(%r{^\/[^\n]*$(\n[^\S\n]+.*$)*}, Comment::Multiline)
        # til EOF comment
        rule(/^\\$/, Comment, :bottom)
        rule(/^\\\\\s+/, Keyword, :bottom)

        # Literals
        ## strings
        rule(/"/, Str, :string)
        ## timespan/stamp constants
        rule(/(?:\d+D|\d{4}\.[01]\d\.[0123]\d[DT])(?:[012]\d:[0-5]\d(?::[0-5]\d(?:\.\d+)?)?|([012]\d)?)[zpn]?\b/,
             Literal::Date)
        ## time/minute/second constants
        rule(/[012]\d:[0-5]\d(?::[0-5]\d(\.\d+)?)?[uvtpn]?\b/, Literal::Date)
        ## date constants
        rule(/\d{4}\.[01]\d\.[0-3]\d[dpnzm]?\b/, Literal::Date)
        ## special values
        rule(/0[nNwW][hijefcpmdznuvt]?/, Keyword::Constant)

        # operators to match before numbers
        rule(%r{'|\/:|\\:|':|\\|\/|0:|1:|2:}, Operator)

        ## numbers
        rule(/(\d+[.]\d*|[.]\d+)(e[+-]?\d+)?[ef]?/, Num::Float)
        rule(/\d+e[+-]?\d+[ef]?/, Num::Float)
        rule(/\d+[ef]/, Num::Float)
        rule(/0x[0-9a-f]+/i, Num::Hex)
        rule(/[01]+b/, Num::Bin)
        rule(/[0-9]+[hij]?/, Num::Integer)
        ## symbols and paths
        rule(%r{(`:[:a-z0-9._\/]*|`(?:[a-z0-9.][:a-z0-9._]*)?)}i, Str::Symbol)
        rule(/(?:<=|>=|<>|::)|[?:$%&|@._#*^\-+~,!><=]:?/, Operator)

        rule %r/[{}\[\]();]/, Punctuation

        # commands
        rule(/\\.*\n/, Text)

      end

      state :string do
        rule %r/\\"/, Str
        rule %r/"/, Str, :pop!
        rule %r/\\([\\nr]|[01][0-7]{2})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\/, Str # stray backslash
      end

      state :bottom do
        rule %r/.+\z/m, Comment::Multiline
      end
    end
  end
end
