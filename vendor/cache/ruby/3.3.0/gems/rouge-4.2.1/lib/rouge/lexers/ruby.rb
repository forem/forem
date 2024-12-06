# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Ruby < RegexLexer
      title "Ruby"
      desc "The Ruby programming language (ruby-lang.org)"
      tag 'ruby'
      aliases 'rb'
      filenames '*.rb', '*.ruby', '*.rbw', '*.rake', '*.gemspec', '*.podspec',
                'Rakefile', 'Guardfile', 'Gemfile', 'Capfile', 'Podfile',
                'Vagrantfile', '*.ru', '*.prawn', 'Berksfile', '*.arb',
                'Dangerfile', 'Fastfile', 'Deliverfile', 'Appfile'

      mimetypes 'text/x-ruby', 'application/x-ruby'

      def self.detect?(text)
        return true if text.shebang? 'ruby'
      end

      state :symbols do
        # symbols
        rule %r(
          :  # initial :
          @{0,2} # optional ivar, for :@foo and :@@foo
          [a-z_]\w*[!?]? # the symbol
        )xi, Str::Symbol

        # special symbols
        rule %r(:(?:\*\*|[-+]@|[/\%&\|^`~]|\[\]=?|<<|>>|<=?>|<=?|===?)),
          Str::Symbol

        rule %r/:'(\\\\|\\'|[^'])*'/, Str::Symbol
        rule %r/:"/, Str::Symbol, :simple_sym
      end

      state :sigil_strings do
        # %-sigiled strings
        # %(abc), %[abc], %<abc>, %.abc., %r.abc., etc
        delimiter_map = { '{' => '}', '[' => ']', '(' => ')', '<' => '>' }
        rule %r/%([rqswQWxiI])?([^\w\s])/ do |m|
          open = Regexp.escape(m[2])
          close = Regexp.escape(delimiter_map[m[2]] || m[2])
          interp = /[rQWxI]/ === m[1] || !m[1]
          toktype = Str::Other

          puts "    open: #{open.inspect}" if @debug
          puts "    close: #{close.inspect}" if @debug

          # regexes
          if m[1] == 'r'
            toktype = Str::Regex
            push :regex_flags
          end

          token toktype

          push do
            uniq_chars = [open, close].uniq.join
            uniq_chars = '' if open == close && open == "\\#"
            rule %r/\\[##{uniq_chars}\\]/, Str::Escape
            # nesting rules only with asymmetric delimiters
            if open != close
              rule %r/#{open}/ do
                token toktype
                push
              end
            end
            rule %r/#{close}/, toktype, :pop!

            if interp
              mixin :string_intp_escaped
              rule %r/#/, toktype
            else
              rule %r/[\\#]/, toktype
            end

            rule %r/[^##{uniq_chars}\\]+/m, toktype
          end
        end
      end

      state :strings do
        mixin :symbols
        rule %r/\b[a-z_]\w*?[?!]?:\s+/, Str::Symbol, :expr_start
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Single
        rule %r/"/, Str::Double, :simple_string
        rule %r/(?<!\.)`/, Str::Backtick, :simple_backtick
      end

      state :regex_flags do
        rule %r/[mixounse]*/, Str::Regex, :pop!
      end

      # double-quoted string and symbol
      [[:string, Str::Double, '"'],
       [:sym, Str::Symbol, '"'],
       [:backtick, Str::Backtick, '`']].each do |name, tok, fin|
        state :"simple_#{name}" do
          mixin :string_intp_escaped
          rule %r/[^\\#{fin}#]+/m, tok
          rule %r/[\\#]/, tok
          rule %r/#{fin}/, tok, :pop!
        end
      end

      keywords = %w(
        BEGIN END alias begin break case defined\? do else elsif end
        ensure for if in next redo rescue raise retry return super then
        undef unless until when while yield
      )

      keywords_pseudo = %w(
        loop include extend raise
        alias_method attr catch throw private module_function
        public protected true false nil __FILE__ __LINE__
      )

      builtins_g = %w(
        attr_reader attr_writer attr_accessor

        __id__ __send__ abort ancestors at_exit autoload binding callcc
        caller catch chomp chop class_eval class_variables clone
        const_defined\? const_get const_missing const_set constants
        display dup eval exec exit extend fail fork format freeze
        getc gets global_variables gsub hash id included_modules
        inspect instance_eval instance_method instance_methods
        instance_variable_get instance_variable_set instance_variables
        lambda load local_variables loop method method_missing
        methods module_eval name object_id open p print printf
        private_class_method private_instance_methods private_methods proc
        protected_instance_methods protected_methods public_class_method
        public_instance_methods public_methods putc puts raise rand
        readline readlines require require_relative scan select self send set_trace_func
        singleton_methods sleep split sprintf srand sub syscall system
        taint test throw to_a to_s trace_var trap untaint untrace_var warn
      )

      builtins_q = %w(
        autoload block_given const_defined eql equal frozen
        include instance_of is_a iterator kind_of method_defined
        nil private_method_defined protected_method_defined
        public_method_defined respond_to tainted
      )

      builtins_b = %w(chomp chop exit gsub sub)

      start do
        push :expr_start
        @heredoc_queue = []
      end

      state :whitespace do
        mixin :inline_whitespace
        rule %r/\n\s*/m, Text, :expr_start
        rule %r/#.*$/, Comment::Single

        rule %r(=begin\b.*?\n=end\b)m, Comment::Multiline
      end

      state :inline_whitespace do
        rule %r/[ \t\r]+/, Text
      end

      state :root do
        mixin :whitespace
        rule %r/__END__/, Comment::Preproc, :end_part

        rule %r/0_?[0-7]+(?:_[0-7]+)*/, Num::Oct
        rule %r/0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*/, Num::Hex
        rule %r/0b[01]+(?:_[01]+)*/, Num::Bin

        decimal = %r/[\d]+(?:_\d+)*/
        exp = %r/e[+-]?\d+/i
        rule %r/#{decimal}(?:\.#{decimal}#{exp}?|#{exp})/, Num::Float
        rule decimal, Num::Integer

        # names
        rule %r/@@[a-z_]\w*/i, Name::Variable::Class
        rule %r/@[a-z_]\w*/i, Name::Variable::Instance
        rule %r/\$\w+/, Name::Variable::Global
        rule %r(\$[!@&`'+~=/\\,;.<>_*\$?:"]), Name::Variable::Global
        rule %r/\$-[0adFiIlpvw]/, Name::Variable::Global
        rule %r/::/, Operator

        mixin :strings

        rule %r/(?:#{keywords.join('|')})(?=\W|$)/, Keyword, :expr_start
        rule %r/(?:#{keywords_pseudo.join('|')})\b/, Keyword::Pseudo, :expr_start
        rule %r/(not|and|or)\b/, Operator::Word, :expr_start

        rule %r(
          (module)
          (\s+)
          ([a-zA-Z_][a-zA-Z0-9_]*(::[a-zA-Z_][a-zA-Z0-9_]*)*)
        )x do
          groups Keyword, Text, Name::Namespace
        end

        rule %r/(def\b)(\s*)/ do
          groups Keyword, Text
          push :funcname
        end

        rule %r/(class\b)(\s*)/ do
          groups Keyword, Text
          push :classname
        end

        rule %r/(?:#{builtins_q.join('|')})[?]/, Name::Builtin, :expr_start
        rule %r/(?:#{builtins_b.join('|')})!/,  Name::Builtin, :expr_start
        rule %r/(?<!\.)(?:#{builtins_g.join('|')})\b/,
          Name::Builtin, :method_call

        mixin :has_heredocs

        # `..` and `...` for ranges must have higher priority than `.`
        # Otherwise, they will be parsed as :method_call
        rule %r/\.{2,3}/, Operator, :expr_start

        rule %r/[A-Z][a-zA-Z0-9_]*/, Name::Constant, :method_call
        rule %r/(\.|::)(\s*)([a-z_]\w*[!?]?|[*%&^`~+-\/\[<>=])/ do
          groups Punctuation, Text, Name::Function
          push :method_call
        end

        rule %r/[a-zA-Z_]\w*[?!]/, Name, :expr_start
        rule %r/[a-zA-Z_]\w*/, Name, :method_call
        rule %r/\*\*|<<?|>>?|>=|<=|<=>|=~|={3}|!~|&&?|\|\||\./,
          Operator, :expr_start
        rule %r/[-+\/*%=<>&!^|~]=?/, Operator, :expr_start
        rule(/[?]/) { token Punctuation; push :ternary; push :expr_start }
        rule %r<[\[({,:\\;/]>, Punctuation, :expr_start
        rule %r<[\])}]>, Punctuation
      end

      state :has_heredocs do
        rule %r/(?<!\w)(<<[-~]?)(["`']?)([a-zA-Z_]\w*)(\2)/ do |m|
          token Operator, m[1]
          token Name::Constant, "#{m[2]}#{m[3]}#{m[4]}"
          @heredoc_queue << [['<<-', '<<~'].include?(m[1]), m[3]]
          push :heredoc_queue unless state? :heredoc_queue
        end

        rule %r/(<<[-~]?)(["'])(\2)/ do |m|
          token Operator, m[1]
          token Name::Constant, "#{m[2]}#{m[3]}#{m[4]}"
          @heredoc_queue << [['<<-', '<<~'].include?(m[1]), '']
          push :heredoc_queue unless state? :heredoc_queue
        end
      end

      state :heredoc_queue do
        rule %r/(?=\n)/ do
          goto :resolve_heredocs
        end

        mixin :root
      end

      state :resolve_heredocs do
        mixin :string_intp_escaped

        rule %r/\n/, Str::Heredoc, :test_heredoc
        rule %r/[#\\\n]/, Str::Heredoc
        rule %r/[^#\\\n]+/, Str::Heredoc
      end

      state :test_heredoc do
        rule %r/[^#\\\n]*$/ do |m|
          tolerant, heredoc_name = @heredoc_queue.first
          check = tolerant ? m[0].strip : m[0].rstrip

          # check if we found the end of the heredoc
          puts "    end heredoc check #{check.inspect} = #{heredoc_name.inspect}" if @debug
          if check == heredoc_name
            @heredoc_queue.shift
            # if there's no more, we're done looking.
            pop! if @heredoc_queue.empty?
            token Name::Constant
          else
            token Str::Heredoc
          end

          pop!
        end

        rule(//) { pop! }
      end

      state :funcname do
        rule %r/\s+/, Text
        rule %r/\(/, Punctuation, :defexpr
        rule %r(
          (?:([a-zA-Z_]\w*)(\.))?
          (
            [a-zA-Z_]\w*[!?]? |
            \*\*? | [-+]@? | [/%&\|^`~] | \[\]=? |
            <<? | >>? | <=>? | >= | ===?
          )
        )x do |m|
          puts "matches: #{[m[0], m[1], m[2], m[3]].inspect}" if @debug
          groups Name::Class, Operator, Name::Function
          pop!
        end

        rule(//) { pop! }
      end

      state :classname do
        rule %r/\s+/, Text
        rule %r/\w+(::\w+)+/, Name::Class

        rule %r/\(/ do
          token Punctuation
          push :defexpr
          push :expr_start
        end

        # class << expr
        rule %r/<</ do
          token Operator
          goto :expr_start
        end

        rule %r/[A-Z_]\w*/, Name::Class, :pop!

        rule(//) { pop! }
      end

      state :ternary do
        rule %r/(:)(\s+)/ do
          groups Punctuation, Text
          goto :expr_start
        end

        rule %r/:(?![^#\n]*?[:\\])/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end

      state :defexpr do
        rule %r/(\))(\.|::)?/ do
          groups Punctuation, Operator
          pop!
        end
        rule %r/\(/ do
          token Punctuation
          push :defexpr
          push :expr_start
        end

        mixin :root
      end

      state :in_interp do
        rule %r/}/, Str::Interpol, :pop!
        mixin :root
      end

      state :string_intp do
        rule %r/[#][{]/, Str::Interpol, :in_interp
        rule %r/#(@@?|\$)[a-z_]\w*/i, Str::Interpol
      end

      state :string_intp_escaped do
        mixin :string_intp
        rule %r/\\([\\abefnrstv#"']|x[a-fA-F0-9]{1,2}|[0-7]{1,3})/,
          Str::Escape
        rule %r/\\./, Str::Escape
      end

      state :method_call do
        rule %r(/|%) do
          token Operator
          goto :expr_start
        end

        rule(/(?=\n)/) { pop! }

        rule(//) { goto :method_call_spaced }
      end

      state :method_call_spaced do
        mixin :whitespace

        rule %r([%/]=) do
          token Operator
          goto :expr_start
        end

        rule %r((/)(?=\S|\s*/)) do
          token Str::Regex
          goto :slash_regex
        end

        mixin :sigil_strings

        rule(%r((?=\s*/))) { pop! }

        rule(/\s+/) { token Text; goto :expr_start }
        rule(//) { pop! }
      end

      state :expr_start do
        mixin :inline_whitespace

        rule %r(/) do
          token Str::Regex
          goto :slash_regex
        end

        # char operator.  ?x evaulates to "x", unless there's a digit
        # beforehand like x>=0?n[x]:""
        rule %r(
          [?](\\[MC]-)*     # modifiers
          (\\([\\abefnrstv\#"']|x[a-fA-F0-9]{1,2}|[0-7]{1,3})|\S)
          (?!\w)
        )x, Str::Char, :pop!

        # special case for using a single space.  Ruby demands that
        # these be in a single line, otherwise it would make no sense.
        rule %r/(\s*)(%[rqswQWxiI]? \S* )/ do
          groups Text, Str::Other
          pop!
        end

        mixin :sigil_strings

        rule(//) { pop! }
      end

      state :slash_regex do
        mixin :string_intp
        rule %r(\\\\), Str::Regex
        rule %r(\\/), Str::Regex
        rule %r([\\#]), Str::Regex
        rule %r([^\\/#]+)m, Str::Regex
        rule %r(/) do
          token Str::Regex
          goto :regex_flags
        end
      end

      state :end_part do
        # eat up the rest of the stream as Comment::Preproc
        rule %r/.+/m, Comment::Preproc, :pop!
      end
    end
  end
end
