# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Racket < RegexLexer
      title "Racket"
      desc "Racket is a Lisp descended from Scheme (racket-lang.org)"

      tag 'racket'
      filenames '*.rkt', '*.rktd', '*.rktl'
      mimetypes 'text/x-racket', 'application/x-racket'

      def self.detect?(text)
        text =~ /\A#lang\s*(.*?)$/
        lang_attr = $1
        return false unless lang_attr
        return true if lang_attr =~ /racket|scribble/
      end

      def self.keywords
        @keywords ||= Set.new %w(
          ... and begin begin-for-syntax begin0 case case-lambda cond
          datum->syntax-object define define-for-syntax define-logger
          define-struct define-syntax define-syntax-rule
          define-syntaxes define-values define-values-for-syntax delay
          do expand-path fluid-let force hash-table-copy
          hash-table-count hash-table-for-each hash-table-get
          hash-table-iterate-first hash-table-iterate-key
          hash-table-iterate-next hash-table-iterate-value
          hash-table-map hash-table-put! hash-table-remove!
          hash-table? if lambda let let* let*-values let-struct
          let-syntax let-syntaxes let-values let/cc let/ec letrec
          letrec-syntax letrec-syntaxes letrec-syntaxes+values
          letrec-values list-immutable make-hash-table
          make-immutable-hash-table make-namespace module module*
          module-identifier=? module-label-identifier=?
          module-template-identifier=? module-transformer-identifier=?
          namespace-transformer-require or parameterize parameterize*
          parameterize-break promise? prop:method-arity-error provide
          provide-for-label provide-for-syntax quasiquote quasisyntax
          quasisyntax/loc quote quote-syntax quote-syntax/prune
          require require-for-label require-for-syntax
          require-for-template set! set!-values syntax syntax-case
          syntax-case* syntax-id-rules syntax-object->datum
          syntax-rules syntax/loc tcp-abandon-port tcp-accept
          tcp-accept-evt tcp-accept-ready? tcp-accept/enable-break
          tcp-addresses tcp-close tcp-connect tcp-connect/enable-break
          tcp-listen tcp-listener? tcp-port? time transcript-off
          transcript-on udp-addresses udp-bind! udp-bound? udp-close
          udp-connect! udp-connected? udp-multicast-interface
          udp-multicast-join-group! udp-multicast-leave-group!
          udp-multicast-loopback? udp-multicast-set-interface!
          udp-multicast-set-loopback! udp-multicast-set-ttl!
          udp-multicast-ttl udp-open-socket udp-receive! udp-receive!*
          udp-receive!-evt udp-receive!/enable-break
          udp-receive-ready-evt udp-send udp-send* udp-send-evt
          udp-send-ready-evt udp-send-to udp-send-to* udp-send-to-evt
          udp-send-to/enable-break udp-send/enable-break udp? unless
          unquote unquote-splicing unsyntax unsyntax-splicing when
          with-continuation-mark with-handlers with-handlers*
          with-syntax λ)
      end

      def self.builtins
        @builtins ||= Set.new %w(
          * + - / < <= = > >=
          abort-current-continuation abs absolute-path? acos add1
          alarm-evt always-evt andmap angle append apply
          arithmetic-shift arity-at-least arity-at-least-value
          arity-at-least? asin assoc assq assv atan banner bitwise-and
          bitwise-bit-field bitwise-bit-set? bitwise-ior bitwise-not
          bitwise-xor boolean? bound-identifier=? box box-cas!
          box-immutable box? break-enabled break-thread build-path
          build-path/convention-type byte-pregexp byte-pregexp?
          byte-ready? byte-regexp byte-regexp? byte? bytes
          bytes->immutable-bytes bytes->list bytes->path
          bytes->path-element bytes->string/latin-1
          bytes->string/locale bytes->string/utf-8 bytes-append
          bytes-close-converter bytes-convert bytes-convert-end
          bytes-converter? bytes-copy bytes-copy!
          bytes-environment-variable-name? bytes-fill! bytes-length
          bytes-open-converter bytes-ref bytes-set! bytes-utf-8-index
          bytes-utf-8-length bytes-utf-8-ref bytes<? bytes=? bytes>?
          bytes? caaaar caaadr caaar caadar caaddr caadr caar cadaar
          cadadr cadar caddar cadddr caddr cadr call-in-nested-thread
          call-with-break-parameterization
          call-with-composable-continuation
          call-with-continuation-barrier call-with-continuation-prompt
          call-with-current-continuation
          call-with-default-reading-parameterization
          call-with-escape-continuation call-with-exception-handler
          call-with-immediate-continuation-mark call-with-input-file
          call-with-output-file call-with-parameterization
          call-with-semaphore call-with-semaphore/enable-break
          call-with-values call/cc call/ec car cdaaar cdaadr cdaar
          cdadar cdaddr cdadr cdar cddaar cddadr cddar cdddar cddddr
          cdddr cddr cdr ceiling channel-get channel-put
          channel-put-evt channel-put-evt? channel-try-get channel?
          chaperone-box chaperone-continuation-mark-key chaperone-evt
          chaperone-hash chaperone-of? chaperone-procedure
          chaperone-prompt-tag chaperone-struct chaperone-struct-type
          chaperone-vector chaperone? char->integer char-alphabetic?
          char-blank? char-ci<=? char-ci<? char-ci=? char-ci>=?
          char-ci>? char-downcase char-foldcase char-general-category
          char-graphic? char-iso-control? char-lower-case?
          char-numeric? char-punctuation? char-ready? char-symbolic?
          char-title-case? char-titlecase char-upcase char-upper-case?
          char-utf-8-length char-whitespace? char<=? char<? char=?
          char>=? char>? char? check-duplicate-identifier
          checked-procedure-check-and-extract choice-evt cleanse-path
          close-input-port close-output-port collect-garbage
          collection-file-path collection-path compile
          compile-allow-set!-undefined
          compile-context-preservation-enabled
          compile-enforce-module-constants compile-syntax
          compiled-expression? compiled-module-expression?
          complete-path? complex? cons continuation-mark-key?
          continuation-mark-set->context continuation-mark-set->list
          continuation-mark-set->list* continuation-mark-set-first
          continuation-mark-set? continuation-marks
          continuation-prompt-available? continuation-prompt-tag?
          continuation? copy-file cos current-break-parameterization
          current-code-inspector current-command-line-arguments
          current-compile current-compiled-file-roots
          current-continuation-marks current-custodian
          current-directory current-directory-for-user current-drive
          current-environment-variables current-error-port
          current-eval current-evt-pseudo-random-generator
          current-gc-milliseconds current-get-interaction-input-port
          current-inexact-milliseconds current-input-port
          current-inspector current-library-collection-paths
          current-load current-load-extension
          current-load-relative-directory current-load/use-compiled
          current-locale current-memory-use current-milliseconds
          current-module-declare-name current-module-declare-source
          current-module-name-resolver current-module-path-for-load
          current-namespace current-output-port
          current-parameterization
          current-preserved-thread-cell-values current-print
          current-process-milliseconds current-prompt-read
          current-pseudo-random-generator current-read-interaction
          current-reader-guard current-readtable current-seconds
          current-security-guard current-subprocess-custodian-mode
          current-thread current-thread-group
          current-thread-initial-stack-size
          current-write-relative-directory custodian-box-value
          custodian-box? custodian-limit-memory custodian-managed-list
          custodian-memory-accounting-available?
          custodian-require-memory custodian-shutdown-all custodian?
          custom-print-quotable-accessor custom-print-quotable?
          custom-write-accessor custom-write? date date*
          date*-nanosecond date*-time-zone-name date*? date-day
          date-dst? date-hour date-minute date-month date-second
          date-time-zone-offset date-week-day date-year date-year-day
          date? datum-intern-literal default-continuation-prompt-tag
          delete-directory delete-file denominator directory-exists?
          directory-list display displayln dump-memory-stats
          dynamic-require dynamic-require-for-syntax dynamic-wind
          environment-variables-copy environment-variables-names
          environment-variables-ref environment-variables-set!
          environment-variables? eof eof-object? ephemeron-value
          ephemeron? eprintf eq-hash-code eq? equal-hash-code
          equal-secondary-hash-code equal? equal?/recur eqv-hash-code
          eqv? error error-display-handler error-escape-handler
          error-print-context-length error-print-source-location
          error-print-width error-value->string-handler eval
          eval-jit-enabled eval-syntax even? evt? exact->inexact
          exact-integer? exact-nonnegative-integer?
          exact-positive-integer? exact? executable-yield-handler exit
          exit-handler exn exn-continuation-marks exn-message
          exn:break exn:break-continuation exn:break:hang-up
          exn:break:hang-up? exn:break:terminate exn:break:terminate?
          exn:break? exn:fail exn:fail:contract
          exn:fail:contract:arity exn:fail:contract:arity?
          exn:fail:contract:continuation
          exn:fail:contract:continuation?
          exn:fail:contract:divide-by-zero
          exn:fail:contract:divide-by-zero?
          exn:fail:contract:non-fixnum-result
          exn:fail:contract:non-fixnum-result?
          exn:fail:contract:variable exn:fail:contract:variable-id
          exn:fail:contract:variable? exn:fail:contract?
          exn:fail:filesystem exn:fail:filesystem:errno
          exn:fail:filesystem:errno-errno exn:fail:filesystem:errno?
          exn:fail:filesystem:exists exn:fail:filesystem:exists?
          exn:fail:filesystem:missing-module
          exn:fail:filesystem:missing-module-path
          exn:fail:filesystem:missing-module?
          exn:fail:filesystem:version exn:fail:filesystem:version?
          exn:fail:filesystem? exn:fail:network exn:fail:network:errno
          exn:fail:network:errno-errno exn:fail:network:errno?
          exn:fail:network? exn:fail:out-of-memory
          exn:fail:out-of-memory? exn:fail:read exn:fail:read-srclocs
          exn:fail:read:eof exn:fail:read:eof? exn:fail:read:non-char
          exn:fail:read:non-char? exn:fail:read? exn:fail:syntax
          exn:fail:syntax-exprs exn:fail:syntax:missing-module
          exn:fail:syntax:missing-module-path
          exn:fail:syntax:missing-module? exn:fail:syntax:unbound
          exn:fail:syntax:unbound? exn:fail:syntax?
          exn:fail:unsupported exn:fail:unsupported? exn:fail:user
          exn:fail:user? exn:fail? exn:missing-module-accessor
          exn:missing-module? exn:srclocs-accessor exn:srclocs? exn?
          exp expand expand-once expand-syntax expand-syntax-once
          expand-syntax-to-top-form expand-to-top-form
          expand-user-path explode-path expt file-exists?
          file-or-directory-identity file-or-directory-modify-seconds
          file-or-directory-permissions file-position file-position*
          file-size file-stream-buffer-mode file-stream-port?
          file-truncate filesystem-change-evt
          filesystem-change-evt-cancel filesystem-change-evt?
          filesystem-root-list find-executable-path
          find-library-collection-paths find-system-path fixnum?
          floating-point-bytes->real flonum? floor flush-output
          for-each format fprintf free-identifier=? gcd
          generate-temporaries gensym get-output-bytes
          get-output-string getenv global-port-print-handler guard-evt
          handle-evt handle-evt? hash hash-equal? hash-eqv?
          hash-has-key? hash-placeholder? hash-ref! hasheq hasheqv
          identifier-binding identifier-binding-symbol
          identifier-label-binding identifier-prune-lexical-context
          identifier-prune-to-source-module
          identifier-remove-from-definition-context
          identifier-template-binding identifier-transformer-binding
          identifier? imag-part immutable? impersonate-box
          impersonate-continuation-mark-key impersonate-hash
          impersonate-procedure impersonate-prompt-tag
          impersonate-struct impersonate-vector impersonator-ephemeron
          impersonator-of? impersonator-prop:application-mark
          impersonator-property-accessor-procedure?
          impersonator-property? impersonator? inexact->exact
          inexact-real? inexact? input-port? inspector? integer->char
          integer->integer-bytes integer-bytes->integer integer-length
          integer-sqrt integer-sqrt/remainder integer?
          internal-definition-context-seal
          internal-definition-context? keyword->string keyword<?
          keyword? kill-thread lcm length liberal-define-context?
          link-exists? list list* list->bytes list->string
          list->vector list-ref list-tail list? load load-extension
          load-on-demand-enabled load-relative load-relative-extension
          load/cd load/use-compiled local-expand
          local-expand/capture-lifts local-transformer-expand
          local-transformer-expand/capture-lifts
          locale-string-encoding log log-max-level magnitude
          make-arity-at-least make-bytes make-channel
          make-continuation-mark-key make-continuation-prompt-tag
          make-custodian make-custodian-box make-date make-date*
          make-derived-parameter make-directory
          make-environment-variables make-ephemeron make-exn
          make-exn:break make-exn:break:hang-up
          make-exn:break:terminate make-exn:fail
          make-exn:fail:contract make-exn:fail:contract:arity
          make-exn:fail:contract:continuation
          make-exn:fail:contract:divide-by-zero
          make-exn:fail:contract:non-fixnum-result
          make-exn:fail:contract:variable make-exn:fail:filesystem
          make-exn:fail:filesystem:errno
          make-exn:fail:filesystem:exists
          make-exn:fail:filesystem:missing-module
          make-exn:fail:filesystem:version make-exn:fail:network
          make-exn:fail:network:errno make-exn:fail:out-of-memory
          make-exn:fail:read make-exn:fail:read:eof
          make-exn:fail:read:non-char make-exn:fail:syntax
          make-exn:fail:syntax:missing-module
          make-exn:fail:syntax:unbound make-exn:fail:unsupported
          make-exn:fail:user make-file-or-directory-link
          make-hash-placeholder make-hasheq-placeholder make-hasheqv
          make-hasheqv-placeholder make-immutable-hasheqv
          make-impersonator-property make-input-port make-inspector
          make-known-char-range-list make-output-port make-parameter
          make-phantom-bytes make-pipe make-placeholder make-polar
          make-prefab-struct make-pseudo-random-generator
          make-reader-graph make-readtable make-rectangular
          make-rename-transformer make-resolved-module-path
          make-security-guard make-semaphore make-set!-transformer
          make-shared-bytes make-sibling-inspector
          make-special-comment make-srcloc make-string
          make-struct-field-accessor make-struct-field-mutator
          make-struct-type make-struct-type-property
          make-syntax-delta-introducer make-syntax-introducer
          make-thread-cell make-thread-group make-vector make-weak-box
          make-weak-hasheqv make-will-executor map max mcar mcdr mcons
          member memq memv min module->exports module->imports
          module->language-info module->namespace
          module-compiled-cross-phase-persistent?
          module-compiled-exports module-compiled-imports
          module-compiled-language-info module-compiled-name
          module-compiled-submodules module-declared?
          module-path-index-join module-path-index-resolve
          module-path-index-split module-path-index-submodule
          module-path-index? module-path? module-predefined?
          module-provide-protected? modulo mpair? nack-guard-evt
          namespace-attach-module namespace-attach-module-declaration
          namespace-base-phase namespace-mapped-symbols
          namespace-module-identifier namespace-module-registry
          namespace-require namespace-require/constant
          namespace-require/copy namespace-require/expansion-time
          namespace-set-variable-value! namespace-symbol->identifier
          namespace-syntax-introduce namespace-undefine-variable!
          namespace-unprotect-module namespace-variable-value
          namespace? negative? never-evt newline normal-case-path not
          null null? number->string number? numerator object-name odd?
          open-input-bytes open-input-file open-input-output-file
          open-input-string open-output-bytes open-output-file
          open-output-string ormap output-port? pair?
          parameter-procedure=? parameter? parameterization?
          path->bytes path->complete-path path->directory-path
          path->string path-add-suffix path-convention-type
          path-element->bytes path-element->string
          path-for-some-system? path-list-string->path-list
          path-replace-suffix path-string? path? peek-byte
          peek-byte-or-special peek-bytes peek-bytes!
          peek-bytes-avail! peek-bytes-avail!*
          peek-bytes-avail!/enable-break peek-char
          peek-char-or-special peek-string peek-string! phantom-bytes?
          pipe-content-length placeholder-get placeholder-set!
          placeholder? poll-guard-evt port-closed-evt port-closed?
          port-commit-peeked port-count-lines!
          port-count-lines-enabled port-counts-lines?
          port-display-handler port-file-identity port-file-unlock
          port-next-location port-print-handler port-progress-evt
          port-provides-progress-evts? port-read-handler
          port-try-file-lock? port-write-handler port-writes-atomic?
          port-writes-special? port? positive? prefab-key->struct-type
          prefab-key? prefab-struct-key pregexp pregexp?
          primitive-closure? primitive-result-arity primitive? print
          print-as-expression print-boolean-long-form print-box
          print-graph print-hash-table print-mpair-curly-braces
          print-pair-curly-braces print-reader-abbreviations
          print-struct print-syntax-width print-unreadable
          print-vector-length printf procedure->method procedure-arity
          procedure-arity-includes? procedure-arity?
          procedure-closure-contents-eq? procedure-extract-target
          procedure-reduce-arity procedure-rename
          procedure-struct-type? procedure? progress-evt?
          prop:arity-string prop:checked-procedure
          prop:custom-print-quotable prop:custom-write prop:equal+hash
          prop:evt prop:exn:missing-module prop:exn:srclocs
          prop:impersonator-of prop:input-port
          prop:liberal-define-context prop:output-port prop:procedure
          prop:rename-transformer prop:set!-transformer
          pseudo-random-generator->vector
          pseudo-random-generator-vector? pseudo-random-generator?
          putenv quotient quotient/remainder raise
          raise-argument-error raise-arguments-error raise-arity-error
          raise-mismatch-error raise-range-error raise-result-error
          raise-syntax-error raise-type-error raise-user-error random
          random-seed rational? rationalize read read-accept-bar-quote
          read-accept-box read-accept-compiled read-accept-dot
          read-accept-graph read-accept-infix-dot read-accept-lang
          read-accept-quasiquote read-accept-reader read-byte
          read-byte-or-special read-bytes read-bytes!
          read-bytes-avail! read-bytes-avail!*
          read-bytes-avail!/enable-break read-bytes-line
          read-case-sensitive read-char read-char-or-special
          read-curly-brace-as-paren read-decimal-as-inexact
          read-eval-print-loop read-language read-line
          read-on-demand-source read-square-bracket-as-paren
          read-string read-string! read-syntax read-syntax/recursive
          read/recursive readtable-mapping readtable?
          real->double-flonum real->floating-point-bytes
          real->single-flonum real-part real? regexp regexp-match
          regexp-match-peek regexp-match-peek-immediate
          regexp-match-peek-positions
          regexp-match-peek-positions-immediate
          regexp-match-peek-positions-immediate/end
          regexp-match-peek-positions/end regexp-match-positions
          regexp-match-positions/end regexp-match/end regexp-match?
          regexp-max-lookbehind regexp-replace regexp-replace* regexp?
          relative-path? remainder rename-file-or-directory
          rename-transformer-target rename-transformer? reroot-path
          resolve-path resolved-module-path-name resolved-module-path?
          reverse round seconds->date security-guard?
          semaphore-peek-evt semaphore-peek-evt? semaphore-post
          semaphore-try-wait? semaphore-wait
          semaphore-wait/enable-break semaphore?
          set!-transformer-procedure set!-transformer? set-box!
          set-mcar! set-mcdr! set-phantom-bytes!
          set-port-next-location! shared-bytes shell-execute
          simplify-path sin single-flonum? sleep special-comment-value
          special-comment? split-path sqrt srcloc srcloc->string
          srcloc-column srcloc-line srcloc-position srcloc-source
          srcloc-span srcloc? string string->bytes/latin-1
          string->bytes/locale string->bytes/utf-8
          string->immutable-string string->keyword string->list
          string->number string->path string->path-element
          string->symbol string->uninterned-symbol
          string->unreadable-symbol string-append string-ci<=?
          string-ci<? string-ci=? string-ci>=? string-ci>? string-copy
          string-copy! string-downcase
          string-environment-variable-name? string-fill!
          string-foldcase string-length string-locale-ci<?
          string-locale-ci=? string-locale-ci>? string-locale-downcase
          string-locale-upcase string-locale<? string-locale=?
          string-locale>? string-normalize-nfc string-normalize-nfd
          string-normalize-nfkc string-normalize-nfkd string-ref
          string-set! string-titlecase string-upcase
          string-utf-8-length string<=? string<? string=? string>=?
          string>? string? struct->vector struct-accessor-procedure?
          struct-constructor-procedure? struct-info
          struct-mutator-procedure? struct-predicate-procedure?
          struct-type-info struct-type-make-constructor
          struct-type-make-predicate
          struct-type-property-accessor-procedure?
          struct-type-property? struct-type? struct:arity-at-least
          struct:date struct:date* struct:exn struct:exn:break
          struct:exn:break:hang-up struct:exn:break:terminate
          struct:exn:fail struct:exn:fail:contract
          struct:exn:fail:contract:arity
          struct:exn:fail:contract:continuation
          struct:exn:fail:contract:divide-by-zero
          struct:exn:fail:contract:non-fixnum-result
          struct:exn:fail:contract:variable struct:exn:fail:filesystem
          struct:exn:fail:filesystem:errno
          struct:exn:fail:filesystem:exists
          struct:exn:fail:filesystem:missing-module
          struct:exn:fail:filesystem:version struct:exn:fail:network
          struct:exn:fail:network:errno struct:exn:fail:out-of-memory
          struct:exn:fail:read struct:exn:fail:read:eof
          struct:exn:fail:read:non-char struct:exn:fail:syntax
          struct:exn:fail:syntax:missing-module
          struct:exn:fail:syntax:unbound struct:exn:fail:unsupported
          struct:exn:fail:user struct:srcloc struct? sub1 subbytes
          subprocess subprocess-group-enabled subprocess-kill
          subprocess-pid subprocess-status subprocess-wait subprocess?
          substring symbol->string symbol-interned? symbol-unreadable?
          symbol? sync sync/enable-break sync/timeout
          sync/timeout/enable-break syntax->list syntax-arm
          syntax-column syntax-disarm syntax-e syntax-line
          syntax-local-bind-syntaxes syntax-local-certifier
          syntax-local-context syntax-local-expand-expression
          syntax-local-get-shadower syntax-local-introduce
          syntax-local-lift-context syntax-local-lift-expression
          syntax-local-lift-module-end-declaration
          syntax-local-lift-provide syntax-local-lift-require
          syntax-local-lift-values-expression
          syntax-local-make-definition-context
          syntax-local-make-delta-introducer
          syntax-local-module-defined-identifiers
          syntax-local-module-exports
          syntax-local-module-required-identifiers syntax-local-name
          syntax-local-phase-level syntax-local-submodules
          syntax-local-transforming-module-provides?
          syntax-local-value syntax-local-value/immediate
          syntax-original? syntax-position syntax-property
          syntax-property-symbol-keys syntax-protect syntax-rearm
          syntax-recertify syntax-shift-phase-level syntax-source
          syntax-source-module syntax-span syntax-taint
          syntax-tainted? syntax-track-origin
          syntax-transforming-module-expression? syntax-transforming?
          syntax? system-big-endian? system-idle-evt
          system-language+country system-library-subpath
          system-path-convention-type system-type tan terminal-port?
          thread thread-cell-ref thread-cell-set! thread-cell-values?
          thread-cell? thread-dead-evt thread-dead? thread-group?
          thread-resume thread-resume-evt thread-rewind-receive
          thread-running? thread-suspend thread-suspend-evt
          thread-wait thread/suspend-to-kill thread? time-apply
          truncate unbox uncaught-exception-handler
          use-collection-link-paths use-compiled-file-paths
          use-user-specific-search-paths values
          variable-reference->empty-namespace
          variable-reference->module-base-phase
          variable-reference->module-declaration-inspector
          variable-reference->module-path-index
          variable-reference->module-source
          variable-reference->namespace variable-reference->phase
          variable-reference->resolved-module-path
          variable-reference-constant? variable-reference? vector
          vector->immutable-vector vector->list
          vector->pseudo-random-generator
          vector->pseudo-random-generator! vector->values vector-fill!
          vector-immutable vector-length vector-ref vector-set!
          vector-set-performance-stats! vector? version void void?
          weak-box-value weak-box? will-execute will-executor?
          will-register will-try-execute with-input-from-file
          with-output-to-file wrap-evt write write-byte write-bytes
          write-bytes-avail write-bytes-avail* write-bytes-avail-evt
          write-bytes-avail/enable-break write-char write-special
          write-special-avail* write-special-evt write-string zero?
        )
      end

      # Since Racket allows identifiers to consist of nearly anything,
      # it's simpler to describe what an ID is _not_.
      id = /[^\s\(\)\[\]\{\}'`,.]+/i

      state :root do
        # comments
        rule %r/;.*$/, Comment::Single
        rule %r/#!.*/, Comment::Single
        rule %r/#\|/, Comment::Multiline, :block_comment
        rule %r/#;/, Comment::Multiline, :sexp_comment
        rule %r/\s+/m, Text

        rule %r/[+-]inf[.][f0]/, Num::Float
        rule %r/[+-]nan[.]0/, Num::Float
        rule %r/[-]min[.]0/, Num::Float
        rule %r/[+]max[.]0/, Num::Float

        rule %r/-?\d+\.\d+/, Num::Float
        rule %r/-?\d+/, Num::Integer

        rule %r/#:#{id}+/, Name::Tag  # keyword

        rule %r/#b[01]+/, Num::Bin
        rule %r/#o[0-7]+/, Num::Oct
        rule %r/#d[0-9]+/, Num::Integer
        rule %r/#x[0-9a-f]+/i, Num::Hex
        rule %r/#[ei][\d.]+/, Num::Other

        rule %r/"(\\\\|\\"|[^"])*"/, Str
        rule %r/['`]#{id}/i, Str::Symbol
        rule %r/#\\([()\/'"._!\$%& ?=+-]{1}|[a-z0-9]+)/i,
          Str::Char
        rule %r/#t(rue)?|#f(alse)?/i, Name::Constant
        rule %r/(?:'|#|`|,@|,|\.)/, Operator

        rule %r/(['#])(\s*)(\()/m do
          groups Str::Symbol, Text, Punctuation
        end

        # () [] {} are all permitted as like pairs
        rule %r/\(|\[|\{/, Punctuation, :command
        rule %r/\)|\]|\}/, Punctuation

        rule id, Name::Variable
      end

      state :block_comment do
        rule %r/[^|#]+/, Comment::Multiline
        rule %r/\|#/, Comment::Multiline, :pop!
        rule %r/#\|/, Comment::Multiline, :block_comment
        rule %r/[|#]/, Comment::Multiline
      end

      state :sexp_comment do
        rule %r/[({\[]/, Comment::Multiline, :sexp_comment_inner
        rule %r/"(?:\\"|[^"])*?"/, Comment::Multiline, :pop!
        rule %r/[^\s]+/, Comment::Multiline, :pop!
        rule(//) { pop! }
      end

      state :sexp_comment_inner do
        rule %r/[^(){}\[\]]+/, Comment::Multiline
        rule %r/[)}\]]/, Comment::Multiline, :pop!
        rule %r/[({\[]/, Comment::Multiline, :sexp_comment_inner
      end

      state :command do
        rule id, Name::Function do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Function
          end

          pop!
        end

        rule(//) { pop! }
      end

    end
  end
end
