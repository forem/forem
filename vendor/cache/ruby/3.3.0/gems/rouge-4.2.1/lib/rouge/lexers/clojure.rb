# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Clojure < RegexLexer
      title "Clojure"
      desc "The Clojure programming language (clojure.org)"

      tag 'clojure'
      aliases 'clj', 'cljs'

      filenames '*.clj', '*.cljs', '*.cljc', 'build.boot', '*.edn'

      mimetypes 'text/x-clojure', 'application/x-clojure'

      def self.keywords
        @keywords ||= Set.new %w(
          fn def defn defmacro defmethod defmulti defn- defstruct if
          cond let for
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          . ..  * + - -> / < <= = == > >= accessor agent agent-errors
          aget alength all-ns alter and append-child apply array-map
          aset aset-boolean aset-byte aset-char aset-double aset-float
          aset-int aset-long aset-short assert assoc await await-for bean
          binding bit-and bit-not bit-or bit-shift-left bit-shift-right
          bit-xor boolean branch?  butlast byte cast char children
          class clear-agent-errors comment commute comp comparator
          complement concat conj cons constantly construct-proxy
          contains? count create-ns create-struct cycle dec  deref
          difference disj dissoc distinct doall doc dorun doseq dosync
          dotimes doto double down drop drop-while edit end? ensure eval
          every? false? ffirst file-seq filter find find-doc find-ns
          find-var first float flush fnseq frest gensym get-proxy-class
          get hash-map hash-set identical? identity if-let import in-ns
          inc index insert-child insert-left insert-right inspect-table
          inspect-tree instance? int interleave intersection into
          into-array iterate join key keys keyword keyword? last lazy-cat
          lazy-cons left lefts line-seq list* list load load-file locking
          long loop macroexpand macroexpand-1 make-array make-node map
          map-invert map? mapcat max max-key memfn merge merge-with meta
          min min-key name namespace neg? new newline next nil? node not
          not-any? not-every? not= ns-imports ns-interns ns-map ns-name
          ns-publics ns-refers ns-resolve ns-unmap nth nthrest or parse
          partial path peek pop pos? pr pr-str print print-str println
          println-str prn prn-str project proxy proxy-mappings quot
          rand rand-int range re-find re-groups re-matcher re-matches
          re-pattern re-seq read read-line reduce ref ref-set refer rem
          remove remove-method remove-ns rename rename-keys repeat replace
          replicate resolve rest resultset-seq reverse rfirst right
          rights root rrest rseq second select select-keys send send-off
          seq seq-zip seq? set short slurp some sort sort-by sorted-map
          sorted-map-by sorted-set special-symbol? split-at split-with
          str string?  struct struct-map subs subvec symbol symbol?
          sync take take-nth take-while test time to-array to-array-2d
          tree-seq true? union up update-proxy val vals var-get var-set
          var? vector vector-zip vector? when when-first when-let
          when-not with-local-vars with-meta with-open with-out-str
          xml-seq xml-zip zero? zipmap zipper'
        )
      end

      identifier = %r([\w!$%*+,<=>?/.-]+)
      keyword = %r([\w!\#$%*+,<=>?/.-]+)

      def name_token(name)
        return Keyword if self.class.keywords.include?(name)
        return Name::Builtin if self.class.builtins.include?(name)
        nil
      end

      state :root do
        rule %r/;.*?$/, Comment::Single
        rule %r/\s+/m, Text::Whitespace

        rule %r/-?\d+\.\d+/, Num::Float
        rule %r/-?\d+/, Num::Integer
        rule %r/0x-?[0-9a-fA-F]+/, Num::Hex

        rule %r/"(\\.|[^"])*"/, Str
        rule %r/'#{keyword}/, Str::Symbol
        rule %r/::?#{keyword}/, Name::Constant
        rule %r/\\(.|[a-z]+)/i, Str::Char


        rule %r/~@|[`\'#^~&@]/, Operator

        rule %r/(\()(\s*)(#{identifier})/m do |m|
          token Punctuation, m[1]
          token Text::Whitespace, m[2]
          token(name_token(m[3]) || Name::Function, m[3])
        end

        rule identifier do |m|
          token name_token(m[0]) || Name
        end

        # vectors
        rule %r/[\[\]]/, Punctuation

        # maps
        rule %r/[{}]/, Punctuation

        # parentheses
        rule %r/[()]/, Punctuation
      end
    end
  end
end
