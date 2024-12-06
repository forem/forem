# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class TCL < RegexLexer
      title "Tcl"
      desc "The Tool Command Language (tcl.tk)"
      tag 'tcl'
      filenames '*.tcl'
      mimetypes 'text/x-tcl', 'text/x-script.tcl', 'application/x-tcl'

      def self.detect?(text)
        return true if text.shebang? 'tclsh'
        return true if text.shebang? 'wish'
        return true if text.shebang? 'jimsh'
      end

      KEYWORDS = %w(
        after apply array break catch continue elseif else error
        eval expr for foreach global if namespace proc rename return
        set switch then trace unset update uplevel upvar variable
        vwait while
      )

      BUILTINS = %w(
        append bgerror binary cd chan clock close concat dde dict
        encoding eof exec exit fblocked fconfigure fcopy file
        fileevent flush format gets glob history http incr info interp
        join lappend lassign lindex linsert list llength load loadTk
        lrange lrepeat lreplace lreverse lsearch lset lsort mathfunc
        mathop memory msgcat open package pid pkg::create pkg_mkIndex
        platform platform::shell puts pwd re_syntax read refchan
        regexp registry regsub scan seek socket source split string
        subst tell time tm unknown unload
      )

      OPEN =  %w| \( \[ \{ " |
      CLOSE = %w| \) \] \} |
      ALL = OPEN + CLOSE
      END_LINE = CLOSE + %w(; \n)
      END_WORD = END_LINE + %w(\r \t \v)

      CHARS =     lambda { |list| Regexp.new %/[#{list.join}]/  }
      NOT_CHARS = lambda { |list| Regexp.new %/[^#{list.join}]/ }

      state :word do
        rule %r/\{\*\}/, Keyword

        mixin :brace_abort
        mixin :interp
        rule %r/\{/, Punctuation, :brace
        rule %r/\(/, Punctuation,   :paren
        rule %r/"/,  Str::Double, :string
        rule %r/#{NOT_CHARS[END_WORD]}+?(?=#{CHARS[OPEN+['\\\\']]})/, Text
      end

      def self.gen_command_state(name='')
        state(:"command#{name}") do
          mixin :word

          rule %r/##{NOT_CHARS[END_LINE]}+/, Comment::Single

          rule %r/(?=#{CHARS[END_WORD]})/ do
            push :"params#{name}"
          end

          rule %r/#{NOT_CHARS[END_WORD]}+/ do |m|
            if KEYWORDS.include? m[0]
              token Keyword
            elsif BUILTINS.include? m[0]
              token Name::Builtin
            else
              token Text
            end
          end

          mixin :whitespace
        end
      end

      def self.gen_delimiter_states(name, close, opts={})
        gen_command_state("_in_#{name}")

        state :"params_in_#{name}" do
          rule close do
            token Punctuation
            pop! 2
          end

          # mismatched delimiters.  Braced strings with mismatched
          # closing delimiters should be okay, since this is standard
          # practice, like {]]]]}
          if opts[:strict]
            rule CHARS[CLOSE - [close]], Error
          else
            rule CHARS[CLOSE - [close]], Text
          end

          mixin :params
        end

        state name do
          rule close, Punctuation, :pop!
          mixin :"command_in_#{name}"
        end
      end


      # tcl is freaking impossible.  If we're in braces and we encounter
      # a close brace, we have to drop everything and close the brace.
      # This is so silly things like {abc"def} and {abc]def} don't b0rk
      # everything after them.

      # TODO: TCL seems to have this aborting behavior quite a lot.
      # such things as [ abc" ] are a runtime error, but will still
      # parse.  Currently something like this will muck up the lex.
      state :brace_abort do
        rule %r/}/ do
          if in_state? :brace
            pop! until state? :brace
            pop!
            token Punctuation
          else
            token Error
          end
        end
      end

      state :params do
        rule %r/;/, Punctuation, :pop!
        rule %r/\n/, Text, :pop!
        rule %r/else|elseif|then/, Keyword
        mixin :word
        mixin :whitespace
        rule %r/#{NOT_CHARS[END_WORD]}+/, Text
      end

      gen_delimiter_states :brace,   /\}/, :strict => false
      gen_delimiter_states :paren,   /\)/, :strict => true
      gen_delimiter_states :bracket, /\]/, :strict => true
      gen_command_state

      state :root do
        mixin :command
      end

      state :whitespace do
        # not a multiline regex because we want to capture \n sometimes
        rule %r/\s+/, Text
      end

      state :interp do
        rule %r/\[/, Punctuation, :bracket
        rule %r/\$[a-z0-9.:-]+/, Name::Variable
        rule %r/\$\{.*?\}/m, Name::Variable
        rule %r/\$/, Text

        # escape sequences
        rule %r/\\[0-7]{3}/, Str::Escape
        rule %r/\\x[0-9a-f]{2}/i, Str::Escape
        rule %r/\\u[0-9a-f]{4}/i, Str::Escape
        rule %r/\\./m, Str::Escape
      end

      state :string do
        rule %r/"/, Str::Double, :pop!
        mixin :interp
        rule %r/[^\\\[\$"{}]+/m, Str::Double

        # strings have to keep count of their internal braces, to support
        # for example { "{ }" }.
        rule %r/{/ do
          @brace_count ||= 0
          @brace_count += 1

          token Str::Double
        end

        rule %r/}/ do
          if in_state? :brace and @brace_count.to_i == 0
            pop! until state? :brace
            pop!
            token Punctuation
          else
            @brace_count -= 1
            token Str::Double
          end
        end
      end
    end
  end
end
