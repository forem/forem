# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CommonLisp < RegexLexer
      title "Common Lisp"
      desc "The Common Lisp variant of Lisp (common-lisp.net)"
      tag 'common_lisp'
      aliases 'cl', 'common-lisp', 'elisp', 'emacs-lisp', 'lisp'

      filenames '*.cl', '*.lisp', '*.asd', '*.el' # used for Elisp too
      mimetypes 'text/x-common-lisp'

      # 638 functions
      BUILTIN_FUNCTIONS = Set.new %w(
        < <= = > >= - / /= * + 1- 1+ abort abs acons acos acosh add-method
        adjoin adjustable-array-p adjust-array allocate-instance
        alpha-char-p alphanumericp append apply apropos apropos-list
        aref arithmetic-error-operands arithmetic-error-operation
        array-dimension array-dimensions array-displacement
        array-element-type array-has-fill-pointer-p array-in-bounds-p
        arrayp array-rank array-row-major-index array-total-size
        ash asin asinh assoc assoc-if assoc-if-not atan atanh atom
        bit bit-and bit-andc1 bit-andc2 bit-eqv bit-ior bit-nand
        bit-nor bit-not bit-orc1 bit-orc2 bit-vector-p bit-xor boole
        both-case-p boundp break broadcast-stream-streams butlast
        byte byte-position byte-size caaaar caaadr caaar caadar
        caaddr caadr caar cadaar cadadr cadar caddar cadddr caddr
        cadr call-next-method car cdaaar cdaadr cdaar cdadar cdaddr
        cdadr cdar cddaar cddadr cddar cdddar cddddr cdddr cddr cdr
        ceiling cell-error-name cerror change-class char char< char<=
        char= char> char>= char/= character characterp char-code
        char-downcase char-equal char-greaterp char-int char-lessp
        char-name char-not-equal char-not-greaterp char-not-lessp
        char-upcase cis class-name class-of clear-input clear-output
        close clrhash code-char coerce compile compiled-function-p
        compile-file compile-file-pathname compiler-macro-function
        complement complex complexp compute-applicable-methods
        compute-restarts concatenate concatenated-stream-streams conjugate
        cons consp constantly constantp continue copy-alist copy-list
        copy-pprint-dispatch copy-readtable copy-seq copy-structure
        copy-symbol copy-tree cos cosh count count-if count-if-not
        decode-float decode-universal-time delete delete-duplicates
        delete-file delete-if delete-if-not delete-package denominator
        deposit-field describe describe-object digit-char digit-char-p
        directory directory-namestring disassemble documentation dpb
        dribble echo-stream-input-stream echo-stream-output-stream
        ed eighth elt encode-universal-time endp enough-namestring
        ensure-directories-exist ensure-generic-function eq
        eql equal equalp error eval evenp every exp export expt
        fboundp fceiling fdefinition ffloor fifth file-author
        file-error-pathname file-length file-namestring file-position
        file-string-length file-write-date fill fill-pointer find
        find-all-symbols find-class find-if find-if-not find-method
        find-package find-restart find-symbol finish-output first
        float float-digits floatp float-precision float-radix
        float-sign floor fmakunbound force-output format fourth
        fresh-line fround ftruncate funcall function-keywords
        function-lambda-expression functionp gcd gensym gentemp get
        get-decoded-time get-dispatch-macro-character getf gethash
        get-internal-real-time get-internal-run-time get-macro-character
        get-output-stream-string get-properties get-setf-expansion
        get-universal-time graphic-char-p hash-table-count hash-table-p
        hash-table-rehash-size hash-table-rehash-threshold
        hash-table-size hash-table-test host-namestring identity
        imagpart import initialize-instance input-stream-p inspect
        integer-decode-float integer-length integerp interactive-stream-p
        intern intersection invalid-method-error invoke-debugger
        invoke-restart invoke-restart-interactively isqrt keywordp
        last lcm ldb ldb-test ldiff length lisp-implementation-type
        lisp-implementation-version list list* list-all-packages listen
        list-length listp load load-logical-pathname-translations
        log logand logandc1 logandc2 logbitp logcount logeqv
        logical-pathname logical-pathname-translations logior
        lognand lognor lognot logorc1 logorc2 logtest logxor
        long-site-name lower-case-p machine-instance machine-type
        machine-version macroexpand macroexpand-1 macro-function
        make-array make-broadcast-stream make-concatenated-stream
        make-condition make-dispatch-macro-character make-echo-stream
        make-hash-table make-instance make-instances-obsolete make-list
        make-load-form make-load-form-saving-slots make-package
        make-pathname make-random-state make-sequence make-string
        make-string-input-stream make-string-output-stream make-symbol
        make-synonym-stream make-two-way-stream makunbound map mapc
        mapcan mapcar mapcon maphash map-into mapl maplist mask-field
        max member member-if member-if-not merge merge-pathnames
        method-combination-error method-qualifiers min minusp mismatch mod
        muffle-warning name-char namestring nbutlast nconc next-method-p
        nintersection ninth no-applicable-method no-next-method not notany
        notevery nreconc nreverse nset-difference nset-exclusive-or
        nstring-capitalize nstring-downcase nstring-upcase nsublis
        nsubst nsubst-if nsubst-if-not nsubstitute nsubstitute-if
        nsubstitute-if-not nth nthcdr null numberp numerator nunion
        oddp open open-stream-p output-stream-p package-error-package
        package-name package-nicknames packagep package-shadowing-symbols
        package-used-by-list package-use-list pairlis parse-integer
        parse-namestring pathname pathname-device pathname-directory
        pathname-host pathname-match-p pathname-name pathnamep
        pathname-type pathname-version peek-char phase plusp
        position position-if position-if-not pprint pprint-dispatch
        pprint-fill pprint-indent pprint-linear pprint-newline pprint-tab
        pprint-tabular prin1 prin1-to-string princ princ-to-string print
        print-object probe-file proclaim provide random random-state-p
        rassoc rassoc-if rassoc-if-not rational rationalize rationalp
        read read-byte read-char read-char-no-hang read-delimited-list
        read-from-string read-line read-preserving-whitespace
        read-sequence readtable-case readtablep realp realpart
        reduce reinitialize-instance rem remhash remove
        remove-duplicates remove-if remove-if-not remove-method
        remprop rename-file rename-package replace require rest
        restart-name revappend reverse room round row-major-aref
        rplaca rplacd sbit scale-float schar search second set
        set-difference set-dispatch-macro-character set-exclusive-or
        set-macro-character set-pprint-dispatch set-syntax-from-char
        seventh shadow shadowing-import shared-initialize
        short-site-name signal signum simple-bit-vector-p
        simple-condition-format-arguments simple-condition-format-control
        simple-string-p simple-vector-p sin sinh sixth sleep slot-boundp
        slot-exists-p slot-makunbound slot-missing slot-unbound slot-value
        software-type software-version some sort special-operator-p
        sqrt stable-sort standard-char-p store-value stream-element-type
        stream-error-stream stream-external-format streamp string string<
        string<= string= string> string>= string/= string-capitalize
        string-downcase string-equal string-greaterp string-left-trim
        string-lessp string-not-equal string-not-greaterp string-not-lessp
        stringp string-right-trim string-trim string-upcase sublis subseq
        subsetp subst subst-if subst-if-not substitute substitute-if
        substitute-if-not subtypepsvref sxhash symbol-function
        symbol-name symbolp symbol-package symbol-plist symbol-value
        synonym-stream-symbol syntax: tailp tan tanh tenth terpri third
        translate-logical-pathname translate-pathname tree-equal truename
        truncate two-way-stream-input-stream two-way-stream-output-stream
        type-error-datum type-error-expected-type type-of
        typep unbound-slot-instance unexport unintern union
        unread-char unuse-package update-instance-for-different-class
        update-instance-for-redefined-class upgraded-array-element-type
        upgraded-complex-part-type upper-case-p use-package
        user-homedir-pathname use-value values values-list vector vectorp
        vector-pop vector-push vector-push-extend warn wild-pathname-p
        write write-byte write-char write-line write-sequence write-string
        write-to-string yes-or-no-p y-or-n-p zerop
      ).freeze

      SPECIAL_FORMS = Set.new %w(
        block catch declare eval-when flet function go if labels lambda
        let let* load-time-value locally macrolet multiple-value-call
        multiple-value-prog1 progn progv quote return-from setq
        symbol-macrolet tagbody the throw unwind-protect
      )

      MACROS = Set.new %w(
        and assert call-method case ccase check-type cond ctypecase decf
        declaim defclass defconstant defgeneric define-compiler-macro
        define-condition define-method-combination define-modify-macro
        define-setf-expander define-symbol-macro defmacro defmethod
        defpackage defparameter defsetf defstruct defsystem deftype defun defvar
        destructuring-bind do do* do-all-symbols do-external-symbols
        dolist do-symbols dotimes ecase etypecase formatter
        handler-bind handler-case ignore-errors incf in-package
        lambda loop loop-finish make-method multiple-value-bind
        multiple-value-list multiple-value-setq nth-value or pop
        pprint-exit-if-list-exhausted pprint-logical-block pprint-pop
        print-unreadable-object prog prog* prog1 prog2 psetf psetq
        push pushnew remf restart-bind restart-case return rotatef
        setf shiftf step time trace typecase unless untrace when
        with-accessors with-compilation-unit with-condition-restarts
        with-hash-table-iterator with-input-from-string with-open-file
        with-open-stream with-output-to-string with-package-iterator
        with-simple-restart with-slots with-standard-io-syntax
      )

      LAMBDA_LIST_KEYWORDS = Set.new %w(
        &allow-other-keys &aux &body &environment &key &optional &rest
        &whole
      )

      DECLARATIONS = Set.new %w(
        dynamic-extent ignore optimize ftype inline special ignorable
        notinline type
      )

      BUILTIN_TYPES = Set.new %w(
        atom boolean base-char base-string bignum bit compiled-function
        extended-char fixnum keyword nil signed-byte short-float
        single-float double-float long-float simple-array
        simple-base-string simple-bit-vector simple-string simple-vector
        standard-char unsigned-byte

        arithmetic-error cell-error condition control-error
        division-by-zero end-of-file error file-error
        floating-point-inexact floating-point-overflow
        floating-point-underflow floating-point-invalid-operation
        parse-error package-error print-not-readable program-error
        reader-error serious-condition simple-condition simple-error
        simple-type-error simple-warning stream-error storage-condition
        style-warning type-error unbound-variable unbound-slot
        undefined-function warning
      )

      BUILTIN_CLASSES = Set.new %w(
        array broadcast-stream bit-vector built-in-class character
        class complex concatenated-stream cons echo-stream file-stream
        float function generic-function hash-table integer list
        logical-pathname method-combination method null number package
        pathname ratio rational readtable real random-state restart
        sequence standard-class standard-generic-function standard-method
        standard-object string-stream stream string structure-class
        structure-object symbol synonym-stream t two-way-stream vector
      )

      nonmacro = /\\.|[a-zA-Z0-9!$%&*+-\/<=>?@\[\]^_{}~]/
      constituent = /#{nonmacro}|[#.:]/
      terminated = /(?=[ "'()\n,;`])/ # whitespace or terminating macro chars
      symbol = /(\|[^\|]+\||#{nonmacro}#{constituent}*)/

      state :root do
        rule %r/\s+/m, Text
        rule %r/;.*$/, Comment::Single
        rule %r/#\|/, Comment::Multiline, :multiline_comment

        # encoding comment
        rule %r/#\d*Y.*$/, Comment::Special
        rule %r/"(\\.|[^"\\])*"/, Str

        rule %r/[:']#{symbol}/, Str::Symbol
        rule %r/['`]/, Operator

        # numbers
        rule %r/[-+]?\d+\.?#{terminated}/, Num::Integer
        rule %r([-+]?\d+/\d+#{terminated}), Num::Integer
        rule %r(
          [-+]?
          (\d*\.\d+([defls][-+]?\d+)?
          |\d+(\.\d*)?[defls][-+]?\d+)
          #{terminated}
        )x, Num::Float

        # sharpsign strings and characters
        rule %r/#\\.#{terminated}/, Str::Char
        rule %r/#\\#{symbol}/, Str::Char

        rule %r/#\(/, Operator, :root

        # bitstring
        rule %r/#\d*\*[01]*/, Other

        # uninterned symbol
        rule %r/#:#{symbol}/, Str::Symbol

        # read-time and load-time evaluation
        rule %r/#[.,]/, Operator

        # function shorthand
        rule %r/#'/, Name::Function

        # binary rational
        rule %r/#b[+-]?[01]+(\/[01]+)?/i, Num

        # octal rational
        rule %r/#o[+-]?[0-7]+(\/[0-7]+)?/i, Num::Oct

        # hex rational
        rule %r/#x[+-]?[0-9a-f]+(\/[0-9a-f]+)?/i, Num

        # complex
        rule %r/(#c)(\()/i do
          groups Num, Punctuation
          push :root
        end

        # arrays and structures
        rule %r/(#(?:\d+a|s))(\()/i do
          groups Str::Other, Punctuation
          push :root
        end

        # path
        rule %r/#p?"(\\.|[^"])*"/i, Str::Symbol

        # reference
        rule %r/#\d+[=#]/, Operator

        # read-time comment
        rule %r/#+nil#{terminated}\s*\(/, Comment, :commented_form

        # read-time conditional
        rule %r/#[+-]/, Operator

        # special operators that should have been parsed already
        rule %r/(,@|,|\.)/, Operator

        # special constants
        rule %r/(t|nil)#{terminated}/, Name::Constant

        # functions and variables
        # note that these get filtered through in stream_tokens
        rule %r/\*#{symbol}\*/, Name::Variable::Global
        rule symbol do |m|
          sym = m[0]

          if BUILTIN_FUNCTIONS.include? sym
            token Name::Builtin
          elsif SPECIAL_FORMS.include? sym
            token Keyword
          elsif MACROS.include? sym
            token Name::Builtin
          elsif LAMBDA_LIST_KEYWORDS.include? sym
            token Keyword
          elsif DECLARATIONS.include? sym
            token Keyword
          elsif BUILTIN_TYPES.include? sym
            token Keyword::Type
          elsif BUILTIN_CLASSES.include? sym
            token Name::Class
          else
            token Name::Variable
          end
        end

        rule %r/\(/, Punctuation, :root
        rule %r/\)/, Punctuation do
          if stack.size == 1
            token Error
          else
            token Punctuation
            pop!
          end
        end
      end

      state :multiline_comment do
        rule %r/#\|/, Comment::Multiline, :multiline_comment
        rule %r/\|#/, Comment::Multiline, :pop!
        rule %r/[^\|#]+/, Comment::Multiline
        rule %r/[\|#]/, Comment::Multiline
      end

      state :commented_form do
        rule %r/\(/, Comment, :commented_form
        rule %r/\)/, Comment, :pop!
        rule %r/[^()]+/, Comment
      end
    end
  end
end
