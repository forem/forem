# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Janet < RegexLexer
      title "Janet"
      desc "The Janet programming language (janet-lang.org)"

      tag 'janet'
      aliases 'jdn'

      filenames '*.janet', '*.jdn'

      mimetypes 'text/x-janet', 'application/x-janet'

      def self.specials
        @specials ||= Set.new %w(
          break def do fn if quote quasiquote splice set unquote var while
        )
      end

      def self.bundled
        @bundled ||= Set.new %w(
          % %= * *= + ++ += - -- -= -> ->> -?> -?>> / /= < <= = > >=
          abstract? accumulate accumulate2 all all-bindings
          all-dynamics and apply array array/concat array/ensure
          array/fill array/insert array/new array/new-filled
          array/peek array/pop array/push array/remove array/slice
          array? as-> as?-> asm assert bad-compile bad-parse band
          blshift bnot boolean? bor brshift brushift buffer buffer/bit
          buffer/bit-clear buffer/bit-set buffer/bit-toggle
          buffer/blit buffer/clear buffer/fill buffer/format
          buffer/new buffer/new-filled buffer/popn buffer/push-byte
          buffer/push-string buffer/push-word buffer/slice buffer?
          bxor bytes? case cfunction? chr cli-main comment comp
          compare compare= compare< compare<= compare> compare>=
          compile complement comptime cond coro count debug
          debug/arg-stack debug/break debug/fbreak debug/lineage
          debug/stack debug/stacktrace debug/step debug/unbreak
          debug/unfbreak debugger-env dec deep-not= deep= default
          default-peg-grammar def- defer defmacro defmacro- defn defn-
          defglobal describe dictionary? disasm distinct doc doc*
          doc-format dofile drop drop-until drop-while dyn each eachk
          eachp eachy edefer eflush empty? env-lookup eprin eprinf
          eprint eprintf error errorf eval eval-string even? every?
          extreme false? fiber/can-resume? fiber/current fiber/getenv
          fiber/maxstack fiber/new fiber/root fiber/setenv
          fiber/setmaxstack fiber/status fiber? file/close file/flush
          file/open file/popen file/read file/seek file/temp
          file/write filter find find-index first flatten flatten-into
          flush for forv freeze frequencies function? gccollect
          gcinterval gcsetinterval generate gensym get get-in getline
          hash idempotent? identity import import* if-let if-not
          if-with in inc indexed? int/s64 int/u64 int? interleave
          interpose invert janet/build janet/config-bits janet/version
          juxt juxt* keep keys keyword keyword? kvs label last length
          let load-image load-image-dict loop macex macex1 make-env
          make-image make-image-dict map mapcat marshal math/-inf
          math/abs math/acos math/acosh math/asin math/asinh math/atan
          math/atan2 math/atanh math/cbrt math/ceil math/cos math/cosh
          math/e math/erf math/erfc math/exp math/exp2 math/expm1
          math/floor math/gamma math/hypot math/inf math/log
          math/log10 math/log1p math/log2 math/next math/pi math/pow
          math/random math/rng math/rng-buffer math/rng-int
          math/rng-uniform math/round math/seedrandom math/sin
          math/sinh math/sqrt math/tan math/tanh math/trunc match max
          mean merge merge-into min mod module/add-paths module/cache
          module/expand-path module/find module/loaders module/loading
          module/paths nan? nat? native neg? net/chunk net/close
          net/connect net/read net/server net/write next nil? not not=
          number? odd? one? or os/arch os/cd os/chmod os/clock
          os/cryptorand os/cwd os/date os/dir os/environ os/execute
          os/exit os/getenv os/link os/lstat os/mkdir os/mktime
          os/perm-int os/perm-string os/readlink os/realpath os/rename
          os/rm os/rmdir os/setenv os/shell os/sleep os/stat
          os/symlink os/time os/touch os/umask os/which pairs parse
          parser/byte parser/clone parser/consume parser/eof
          parser/error parser/flush parser/has-more parser/insert
          parser/new parser/produce parser/state parser/status
          parser/where partial partition peg/compile peg/match pos?
          postwalk pp prewalk prin prinf print printf product prompt
          propagate protect put put-in quit range reduce reduce2
          repeat repl require resume return reverse reversed root-env
          run-context scan-number seq setdyn shortfn signal slice
          slurp some sort sort-by sorted sorted-by spit stderr stdin
          stdout string string/ascii-lower string/ascii-upper
          string/bytes string/check-set string/find string/find-all
          string/format string/from-bytes string/has-prefix?
          string/has-suffix? string/join string/repeat string/replace
          string/replace-all string/reverse string/slice string/split
          string/trim string/triml string/trimr string? struct struct?
          sum symbol symbol? table table/clone table/getproto
          table/new table/rawget table/setproto table/to-struct table?
          take take-until take-while tarray/buffer tarray/copy-bytes
          tarray/length tarray/new tarray/properties tarray/slice
          tarray/swap-bytes thread/close thread/current thread/new
          thread/receive thread/send trace tracev true? truthy? try
          tuple tuple/brackets tuple/setmap tuple/slice
          tuple/sourcemap tuple/type tuple? type unless unmarshal
          untrace update update-in use values var- varfn varglobal
          walk walk-ind walk-dict when when-let when-with with
          with-dyns with-syms with-vars yield zero? zipcoll
        )
      end

      def name_token(name)
        if self.class.specials.include? name
          Keyword
        elsif self.class.bundled.include? name
          Keyword::Reserved
        else
          Name::Function
        end
      end

      punctuation = %r/[_!$%^&*+=~<>.?\/-]/o
      symbol = %r/([[:alpha:]]|#{punctuation})([[:word:]]|#{punctuation}|:)*/o

      state :root do
        rule %r/#.*?$/, Comment::Single
        rule %r/\s+/m, Text::Whitespace

        rule %r/(true|false|nil)\b/, Name::Constant
        rule %r/(['~])(#{symbol})/ do
          groups Operator, Str::Symbol
        end
        rule %r/:([[:word:]]|#{punctuation}|:)*/, Keyword::Constant

        # radix-specified numbers
        rule %r/[+-]?\d{1,2}r[\w.]+(&[+-]?\w+)?/, Num::Float

        # hex numbers
        rule %r/[+-]?0x\h[\h_]*(\.\h[\h_]*)?/, Num::Hex
        rule %r/[+-]?0x\.\h[\h_]*/, Num::Hex

        # decimal numbers (Janet treats all decimals as floats)
        rule %r/[+-]?\d[\d_]*(\.\d[\d_]*)?([e][+-]?\d+)?/i, Num::Float
        rule %r/[+-]?\.\d[\d_]*([e][+-]?\d+)?/i, Num::Float

        rule %r/@?"/, Str::Double, :string
        rule %r/@?(`+).*?\1/m, Str::Heredoc

        rule %r/\(/, Punctuation, :function

        rule %r/(')(@?[(\[{])/ do
          groups Operator, Punctuation
          push :quote
        end

        rule %r/(~)(@?[(\[{])/ do
          groups Operator, Punctuation
          push :quasiquote
        end

        rule %r/[\#~,';\|]/, Operator

        rule %r/@?[(){}\[\]]/, Punctuation

        rule symbol, Name
      end

      state :string do
        rule %r/"/, Str::Double, :pop!
        rule %r/\\(u\h{4}|U\h{6})/, Str::Escape
        rule %r/\\./, Str::Escape
        rule %r/[^"\\]+/, Str::Double
      end

      state :function do
        rule %r/[\)]/, Punctuation, :pop!

        rule symbol do |m|
          case m[0]
          when "quote"
            token Keyword
            goto :quote
          when "quasiquote"
            token Keyword
            goto :quasiquote
          else
            token name_token(m[0])
            goto :root
          end
        end

        mixin :root
      end

      state :quote do
        rule %r/[(\[{]/, Punctuation, :push
        rule %r/[)\]}]/, Punctuation, :pop!
        rule symbol, Str::Escape
        mixin :root
      end

      state :quasiquote do
        rule %r/(,)(\()/ do
          groups Operator, Punctuation
          push :function
        end
        rule %r/(\()(\s*)(unquote)(\s+)(\()/ do
          groups Punctuation, Text, Keyword, Text, Punctuation
          push :function
        end

        rule %r/(,)(#{symbol})/ do
          groups Operator, Name
        end
        rule %r/(\()(\s*)(unquote)(\s+)(#{symbol})/ do
          groups Punctuation, Text, Keyword, Text, Name
        end

        mixin :quote
      end
    end
  end
end
