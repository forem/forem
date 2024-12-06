# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Factor < RegexLexer
      title "Factor"
      desc "Factor, the practical stack language (factorcode.org)"
      tag 'factor'
      filenames '*.factor'
      mimetypes 'text/x-factor'

      def self.detect?(text)
        return true if text.shebang? 'factor'
      end

      def self.builtins
        @builtins ||= {}.tap do |builtins|
          builtins[:kernel] = Set.new %w(
            or 2bi 2tri while wrapper nip 4dip wrapper? bi*
            callstack>array both? hashcode die dupd callstack
            callstack? 3dup tri@ pick curry build ?execute 3bi prepose
            >boolean if clone eq? tri* ? = swapd 2over 2keep 3keep clear
            2dup when not tuple? dup 2bi* 2tri* call tri-curry object bi@
            do unless* if* loop bi-curry* drop when* assert= retainstack
            assert? -rot execute 2bi@ 2tri@ boa with either? 3drop bi
            curry?  datastack until 3dip over 3curry tri-curry* tri-curry@
            swap and 2nip throw bi-curry (clone) hashcode* compose 2dip if
            3tri unless compose? tuple keep 2curry equal? assert tri 2drop
            most <wrapper> boolean? identity-hashcode identity-tuple?
            null new dip bi-curry@ rot xor identity-tuple boolean
          )

          builtins[:assocs] = Set.new %w(
            ?at assoc? assoc-clone-like assoc= delete-at* assoc-partition
            extract-keys new-assoc value? assoc-size map>assoc push-at
            assoc-like key? assoc-intersect assoc-refine update
            assoc-union assoc-combine at* assoc-empty? at+ set-at
            assoc-all? assoc-subset?  assoc-hashcode change-at assoc-each
            assoc-diff zip values value-at rename-at inc-at enum? at cache
            assoc>map <enum> assoc assoc-map enum value-at* assoc-map-as
            >alist assoc-filter-as clear-assoc assoc-stack maybe-set-at
            substitute assoc-filter 2cache delete-at assoc-find keys
            assoc-any? unzip
          )

          builtins[:combinators] = Set.new %w(
            case execute-effect no-cond no-case? 3cleave>quot 2cleave
            cond>quot wrong-values? no-cond? cleave>quot no-case case>quot
            3cleave wrong-values to-fixed-point alist>quot case-find
            cond cleave call-effect 2cleave>quot recursive-hashcode
            linear-case-quot spread spread>quot
          )

          builtins[:math] = Set.new %w(
            number= if-zero next-power-of-2 each-integer ?1+
            fp-special? imaginary-part unless-zero float>bits number?
            fp-infinity? bignum? fp-snan? denominator fp-bitwise= *
            + power-of-2? - u>= / >= bitand log2-expects-positive <
            log2 > integer? number bits>double 2/ zero? (find-integer)
            bits>float float? shift ratio? even? ratio fp-sign bitnot
            >fixnum complex? /i /f byte-array>bignum when-zero sgn >bignum
            next-float u< u> mod recip rational find-last-integer >float
            (all-integers?) 2^ times integer fixnum? neg fixnum sq bignum
            (each-integer) bit? fp-qnan? find-integer complex <fp-nan>
            real double>bits bitor rem fp-nan-payload all-integers?
            real-part log2-expects-positive? prev-float align unordered?
            float fp-nan? abs bitxor u<= odd? <= /mod rational? >integer
            real? numerator
          )

          builtins[:sequences] = Set.new %w(
            member-eq? append assert-sequence= find-last-from
            trim-head-slice clone-like 3sequence assert-sequence? map-as
            last-index-from reversed index-from cut* pad-tail
            remove-eq! concat-as but-last snip trim-tail nths
            nth 2selector sequence slice?  <slice> partition
            remove-nth tail-slice empty? tail* if-empty
            find-from virtual-sequence? member? set-length
            drop-prefix unclip unclip-last-slice iota map-sum
            bounds-error? sequence-hashcode-step selector-for
            accumulate-as map start midpoint@ (accumulate) rest-slice
            prepend fourth sift accumulate! new-sequence follow map! like
            first4 1sequence reverse slice unless-empty padding virtual@
            repetition? set-last index 4sequence max-length set-second
            immutable-sequence first2 first3 replicate-as reduce-index
            unclip-slice supremum suffix! insert-nth trim-tail-slice
            tail 3append short count suffix concat flip filter sum
            immutable? reverse! 2sequence map-integers delete-all start*
            indices snip-slice check-slice sequence?  head map-find
            filter! append-as reduce sequence= halves collapse-slice
            interleave 2map filter-as binary-reduce slice-error? product
            bounds-check? bounds-check harvest immutable virtual-exemplar
            find produce remove pad-head last replicate set-fourth
            remove-eq shorten reversed?  map-find-last 3map-as
            2unclip-slice shorter? 3map find-last head-slice pop* 2map-as
            tail-slice* but-last-slice 2map-reduce iota? collector-for
            accumulate each selector append! new-resizable cut-slice
            each-index head-slice* 2reverse-each sequence-hashcode
            pop set-nth ?nth <flat-slice> second join when-empty
            collector immutable-sequence? <reversed> all? 3append-as
            virtual-sequence subseq? remove-nth! push-either new-like
            length last-index push-if 2all? lengthen assert-sequence
            copy map-reduce move third first 3each tail? set-first prefix
            bounds-error any? <repetition> trim-slice exchange surround
            2reduce cut change-nth min-length set-third produce-as
            push-all head? delete-slice rest sum-lengths 2each head*
            infimum remove! glue slice-error subseq trim replace-slice
            push repetition map-index trim-head unclip-last mismatch
          )

          builtins[:namespaces] = Set.new %w(
            global +@ change set-namestack change-global init-namespaces
            on off set-global namespace set with-scope bind with-variable
            inc dec counter initialize namestack get get-global make-assoc
          )

          builtins[:arrays] = Set.new %w(
            <array> 2array 3array pair >array 1array 4array pair?
            array resize-array array?
          )

          builtins[:io] = Set.new %w(
            +character+ bad-seek-type? readln each-morsel
            stream-seek read print with-output-stream contents
            write1 stream-write1 stream-copy stream-element-type
            with-input-stream stream-print stream-read stream-contents
            stream-tell tell-output bl seek-output bad-seek-type nl
            stream-nl write flush stream-lines +byte+ stream-flush
            read1 seek-absolute? stream-read1 lines stream-readln
            stream-read-until each-line seek-end with-output-stream*
            seek-absolute with-streams seek-input seek-relative?
            input-stream stream-write read-partial seek-end?
            seek-relative error-stream read-until with-input-stream*
            with-streams* tell-input each-block output-stream
            stream-read-partial each-stream-block each-stream-line
          )

          builtins[:strings] = Set.new %w(
            resize-string >string <string> 1string string string?
          )

          builtins[:vectors] = Set.new %w(
            with-return restarts return-continuation with-datastack
            recover rethrow-restarts <restart> ifcc set-catchstack
            >continuation< cleanup ignore-errors restart?
            compute-restarts attempt-all-error error-thread
            continue <continuation> attempt-all-error? condition?
            <condition> throw-restarts error catchstack continue-with
            thread-error-hook continuation rethrow callcc1
            error-continuation callcc0 attempt-all condition
            continuation? restart return
          )

          builtins[:continuations] = Set.new %w(
            with-return restarts return-continuation with-datastack
            recover rethrow-restarts <restart> ifcc set-catchstack
            >continuation< cleanup ignore-errors restart?
            compute-restarts attempt-all-error error-thread
            continue <continuation> attempt-all-error? condition?
            <condition> throw-restarts error catchstack continue-with
            thread-error-hook continuation rethrow callcc1
            error-continuation callcc0 attempt-all condition
            continuation? restart return
          )
        end
      end

      state :root do
        rule %r/\s+/m, Text

        rule %r/(:|::|MACRO:|MEMO:|GENERIC:|HELP:)(\s+)(\S+)/m do
          groups Keyword, Text, Name::Function
        end

        rule %r/(M:|HOOK:|GENERIC#)(\s+)(\S+)(\s+)(\S+)/m do
          groups Keyword, Text, Name::Class, Text, Name::Function
        end

        rule %r/\((?=\s)/, Name::Function, :stack_effect
        rule %r/;(?=\s)/, Keyword

        rule %r/(USING:)((?:\s|\\\s)+)/m do
          groups Keyword::Namespace, Text
          push :import
        end

        rule %r/(IN:|USE:|UNUSE:|QUALIFIED:|QUALIFIED-WITH:)(\s+)(\S+)/m do
          groups Keyword::Namespace, Text, Name::Namespace
        end

        rule %r/(FROM:|EXCLUDE:)(\s+)(\S+)(\s+)(=>)/m do
          groups Keyword::Namespace, Text, Name::Namespace, Text, Punctuation
        end

        rule %r/(?:ALIAS|DEFER|FORGET|POSTPONE):/, Keyword::Namespace

        rule %r/(TUPLE:)(\s+)(\S+)(\s+)(<)(\s+)(\S+)/m do
          groups(
            Keyword, Text,
            Name::Class, Text,
            Punctuation, Text,
            Name::Class
          )
          push :slots
        end

        rule %r/(TUPLE:)(\s+)(\S+)/m do
          groups Keyword, Text, Name::Class
          push :slots
        end

        rule %r/(UNION:|INTERSECTION:)(\s+)(\S+)/m do
          groups Keyword, Text, Name::Class
        end

        rule %r/(PREDICATE:)(\s+)(\S+)(\s+)(<)(\s+)(\S+)/m do
          groups(
            Keyword, Text,
            Name::Class, Text,
            Punctuation, Text,
            Name::Class
          )
        end

        rule %r/(C:)(\s+)(\S+)(\s+)(\S+)/m do
          groups(
            Keyword, Text,
            Name::Function, Text,
            Name::Class
          )
        end

        rule %r(
          (INSTANCE|SLOT|MIXIN|SINGLETONS?|CONSTANT|SYMBOLS?|ERROR|SYNTAX
           |ALIEN|TYPEDEF|FUNCTION|STRUCT):
        )x, Keyword

        rule %r/(?:<PRIVATE|PRIVATE>)/, Keyword::Namespace

        rule %r/(MAIN:)(\s+)(\S+)/ do
          groups Keyword::Namespace, Text, Name::Function
        end

        # strings
        rule %r/"(?:\\\\|\\"|[^"])*"/, Str
        rule %r/\S+"\s+(?:\\\\|\\"|[^"])*"/, Str
        rule %r/(CHAR:)(\s+)(\\[\\abfnrstv]*|\S)(?=\s)/, Str::Char

        # comments
        rule %r/!\s+.*$/, Comment
        rule %r/#!\s+.*$/, Comment

        # booleans
        rule %r/[tf](?=\s)/, Name::Constant

        # numbers
        rule %r/-?\d+\.\d+(?=\s)/, Num::Float
        rule %r/-?\d+(?=\s)/, Num::Integer

        rule %r/HEX:\s+[a-fA-F\d]+(?=\s)/m, Num::Hex
        rule %r/BIN:\s+[01]+(?=\s)/, Num::Bin
        rule %r/OCT:\s+[0-7]+(?=\s)/, Num::Oct

        rule %r([-+/*=<>^](?=\s)), Operator

        rule %r/(?:deprecated|final|foldable|flushable|inline|recursive)(?=\s)/,
          Keyword

        rule %r/\S+/ do |m|
          name = m[0]

          if self.class.builtins.values.any? { |b| b.include? name }
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :stack_effect do
        rule %r/\s+/, Text
        rule %r/\(/, Name::Function, :stack_effect
        rule %r/\)/, Name::Function, :pop!

        rule %r/--/, Name::Function
        rule %r/\S+/, Name::Variable
      end

      state :slots do
        rule %r/\s+/, Text
        rule %r/;(?=\s)/, Keyword, :pop!
        rule %r/\S+/, Name::Variable
      end

      state :import do
        rule %r/;(?=\s)/, Keyword, :pop!
        rule %r/\s+/, Text
        rule %r/\S+/, Name::Namespace
      end
    end
  end
end
