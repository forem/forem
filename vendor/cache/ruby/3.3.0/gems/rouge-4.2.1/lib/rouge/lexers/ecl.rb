# -*- codding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class ECL < RegexLexer
      tag 'ecl'
      filenames '*.ecl'
      mimetypes 'application/x-ecl'

      title "ECL"
      desc "Enterprise Control Language (hpccsystems.com)"

      id = /(#?)\b([a-z_][\w]*?)(\d*)\b/i

      def self.class_first
        @class_first ||= Set.new %w(
          file date str math metaphone metaphone3 uni audit blas system
        )
      end

      def self.class_second
        @class_second ||= Set.new %w(
          debug email job log thorlib util workunit
        )
      end

      def self.functions
        @functions ||= Set.new %w(
          abs acos aggregate allnodes apply ascii asin asstring atan _token ave
          case catch choose choosen choosesets clustersize combine correlation
          cos cosh count covariance cron dataset dedup define denormalize
          dictionary distribute distributed distribution ebcdic enth error
          evaluate event eventextra eventname exists exp failcode failmessage
          fetch fromunicode fromxml getenv getisvalid global graph group hash
          hashcrc having httpcall httpheader if iff index intformat isvalid
          iterate join keyunicode length library limit ln local log loop map
          matched matchlength matchposition matchtext matchunicode max merge
          mergejoin min nofold nolocal nonempty normalize parse pipe power
          preload process project pull random range rank ranked realformat
          recordof regexfind regexreplace regroup rejected rollup round roundup
          row rowdiff sample set sin sinh sizeof soapcall sort sorted sqrt
          stepped stored sum table tan tanh thisnode topn tounicode toxml
          transfer transform trim truncate typeof ungroup unicodeorder variance
          which workunit xmldecode xmlencode xmltext xmlunicode apply assert
          build buildindex evaluate fail keydiff keypatch loadxml nothor notify
          output parallel sequential soapcall wait
        )
      end

      def self.keywords
        @keywords ||= Set.new %w(
          and or in not all any as from atmost before best between case const
          counter csv descend encrypt end endmacro enum except exclusive expire
          export extend fail few first flat full function functionmacro group
          heading hole ifblock import joined keep keyed last left limit load
          local locale lookup many maxcount maxlength _token module interface
          named nocase noroot noscan nosort of only opt outer overwrite packed
          partition penalty physicallength pipe quote record repeat return
          right rows scan self separator service shared skew skip sql store
          terminator thor threshold token transform trim type unicodeorder
          unsorted validate virtual whole wild within xml xpath after cluster
          compressed compression default encoding escape fileposition forward
          grouped inner internal linkcounted literal lzw mofn multiple
          namespace wnotrim noxpath onfail prefetch retry rowset scope smart
          soapaction stable timelimit timeout unordered unstable update use
          width
        )
      end

      def self.template
        @template ||= Set.new %w(
          append apply break constant debug declare demangle else elseif end
          endregion error expand export exportxml for forall getdatatype if
          ifdefined inmodule isdefined isvalid line link loop mangle onwarning
          option region set stored text trace uniquename warning webservice
          workunit loadxml
        )
      end

      def self.type
        @type ||= Set.new %w(
          ascii big_endian boolean data decimal ebcdic grouped integer
          linkcounted pattern qstring real record rule set of streamed string
          token udecimal unicode utf8 unsigned varstring varunicode
        )
      end

      def self.typed
        @typed ||= Set.new %w(
          data string qstring varstring varunicode unicode utf8
        )
      end

      state :single_quote do
        rule %r([xDQUV]?'([^'\\]*(?:\\.[^'\\]*)*)'), Str::Single
        rule %r/\\(x\\h{2}|[0-2][0-7]{,2}|3[0-6][0-7]?|37[0-7]?|[4-7][0-7]?|.|$)/, Text
      end

      state :inline_whitespace do
        rule %r/[ \t\r]+/, Text
        rule %r/\\\n/, Text # line continuation
        rule %r(/[*].*?[*]/)m, Comment::Multiline
      end

      state :whitespace do
        rule %r/\n+/m, Text
        rule %r(//.*), Comment::Single
        mixin :inline_whitespace
      end

      state :root do
        mixin :whitespace
        mixin :single_quote

        rule %r(\b(?i:(and|not|or|in))\b), Operator::Word
        rule %r(:=|>|<|<>|/|\\|\+|-|=), Operator
        rule %r([\[\]{}();,\&\.\%]), Punctuation

        rule %r(\b(?i:(beginc\+\+.*?endc\+\+)))m, Str::Single
        rule %r(\b(?i:(embed.*?endembed)))m, Str::Single

        rule %r(\b(\w+)\.(\w+)\.(\w+)) do |m|
          if m[1] == "std" &&
             self.class.class_first.include?(m[2]) &&
             self.class.class_second.include?(m[3])
            token Name::Class
          else
            token Name::Variable
          end
        end

        rule %r(\b(?i:(u)?decimal)(\d+(_\d+)?)\b), Keyword::Type

        rule %r/\d+\.\d+(e[\+\-]?\d+)?/i, Num::Float
        rule %r/x[0-9a-f]+/i, Num::Hex

        rule %r/0x[0-9a-f]+/i, Num::Hex
        rule %r/0[0-9a-f]+x/i, Num::Hex
        rule %r(0[bB][01]+), Num::Bin
        rule %r([01]+[bB]), Num::Bin
        rule %r(\d+), Num::Integer

        rule id do |m|
          name_only = m[2].downcase
          name      = name_only + m[3]
          number    = (m[3] == "") ? nil : m[3].to_i
          if m[1] == "#"
            if self.class.template.include? name
              token Keyword::Type
            else
              token Error
            end
          elsif self.class.typed.include?(name_only) && number != nil
            token Keyword::Type
          elsif self.class.type.include? name
            token Keyword::Type
          elsif self.class.keywords.include? name
            token Keyword
          elsif self.class.functions.include? name
            token Name::Function
          elsif ["integer", "unsigned"].include?(name_only) && (1..8).cover?(number)
            token Keyword::Type
          elsif name_only == "real" && [4, 8].include?(number)
            token Keyword::Type
          elsif ["true", "false"].include? name
            token Keyword::Constant
          else
            token Name::Other
          end
        end
      end
    end
  end
end
