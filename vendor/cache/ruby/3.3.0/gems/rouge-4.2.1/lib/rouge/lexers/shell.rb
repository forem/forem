# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Shell < RegexLexer
      title "shell"
      desc "Various shell languages, including sh and bash"

      tag 'shell'
      aliases 'bash', 'zsh', 'ksh', 'sh'
      filenames '*.sh', '*.bash', '*.zsh', '*.ksh', '.bashrc',
                '.kshrc', '.profile',
                '.zshenv', '.zprofile', '.zshrc', '.zlogin', '.zlogout',
                'zshenv',  'zprofile',  'zshrc',  'zlogin',  'zlogout',
                'APKBUILD', 'PKGBUILD', '*.ebuild',
                '*.eclass', '*.exheres-0', '*.exlib'

      mimetypes 'application/x-sh', 'application/x-shellscript', 'text/x-sh',
                'text/x-shellscript'

      def self.detect?(text)
        return true if text.shebang?(/(ba|z|k)?sh/)
        return true if text.start_with?('#compdef', '#autoload')
      end

      KEYWORDS = %w(
        if fi else while do done for then return function
        select continue until esac elif in
      ).join('|')

      BUILTINS = %w(
        alias bg bind break builtin caller cd command compgen
        complete declare dirs disown enable eval exec exit
        export false fc fg getopts hash help history jobs let
        local logout mapfile popd pushd pwd read readonly set
        shift shopt source suspend test time times trap true type
        typeset ulimit umask unalias unset wait

        cat tac nl od base32 base64 fmt pr fold head tail split csplit
        wc sum cksum b2sum md5sum sha1sum sha224sum sha256sum sha384sum
        sha512sum sort shuf uniq comm ptx tsort cut paste join tr expand
        unexpand ls dir vdir dircolors cp dd install mv rm shred link ln
        mkdir mkfifo mknod readlink rmdir unlink chown chgrp chmod touch
        df du stat sync truncate echo printf yes expr tee basename dirname
        pathchk mktemp realpath pwd stty printenv tty id logname whoami
        groups users who date arch nproc uname hostname hostid uptime chcon
        runcon chroot env nice nohup stdbuf timeout kill sleep factor numfmt
        seq tar grep sudo awk sed gzip gunzip
      ).join('|')

      state :basic do
        rule %r/#.*$/, Comment

        rule %r/\b(#{KEYWORDS})\s*\b/, Keyword
        rule %r/\bcase\b/, Keyword, :case

        rule %r/\b(#{BUILTINS})\s*\b(?!(\.|-))/, Name::Builtin
        rule %r/[.](?=\s)/, Name::Builtin

        rule %r/(\b\w+)(=)/ do
          groups Name::Variable, Operator
        end

        rule %r/[\[\]{}()!=>]/, Operator
        rule %r/&&|\|\|/, Operator

        # here-string
        rule %r/<<</, Operator

        rule %r/(<<-?)(\s*)(['"]?)(\\?)(\w+)(\3)/ do |m|
          groups Operator, Text, Str::Heredoc, Str::Heredoc, Name::Constant, Str::Heredoc
          @heredocstr = Regexp.escape(m[5])
          push :heredoc
        end
      end

      state :heredoc do
        rule %r/\n/, Str::Heredoc, :heredoc_nl
        rule %r/[^$\n\\]+/, Str::Heredoc
        mixin :interp
        rule %r/[$]/, Str::Heredoc
      end

      state :heredoc_nl do
        rule %r/\s*(\w+)\s*\n/ do |m|
          if m[1] == @heredocstr
            token Name::Constant
            pop! 2
          else
            token Str::Heredoc
          end
        end

        rule(//) { pop! }
      end


      state :double_quotes do
        # NB: "abc$" is literally the string abc$.
        # Here we prevent :interp from interpreting $" as a variable.
        rule %r/(?:\$#?)?"/, Str::Double, :pop!
        mixin :interp
        rule %r/[^"`\\$]+/, Str::Double
      end

      state :ansi_string do
        rule %r/\\./, Str::Escape
        rule %r/[^\\']+/, Str::Single
        mixin :single_quotes
      end

      state :single_quotes do
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/, Str::Single
      end

      state :data do
        rule %r/\s+/, Text
        rule %r/\\./, Str::Escape
        rule %r/\$?"/, Str::Double, :double_quotes
        rule %r/\$'/, Str::Single, :ansi_string

        # single quotes are much easier than double quotes - we can
        # literally just scan until the next single quote.
        # POSIX: Enclosing characters in single-quotes ( '' )
        # shall preserve the literal value of each character within the
        # single-quotes. A single-quote cannot occur within single-quotes.
        rule %r/'/, Str::Single, :single_quotes

        rule %r/\*/, Keyword

        rule %r/;/, Punctuation

        rule %r/--?[\w-]+/, Name::Tag
        rule %r/[^=\*\s{}()$"'`;\\<]+/, Text
        rule %r/\d+(?= |\Z)/, Num
        rule %r/</, Text
        mixin :interp
      end

      state :curly do
        rule %r/}/, Keyword, :pop!
        rule %r/:-/, Keyword
        rule %r/[a-zA-Z0-9_]+/, Name::Variable
        rule %r/[^}:"`'$]+/, Punctuation
        mixin :root
      end

      # the state inside $(...)
      state :paren_interp do
        rule %r/\)/, Str::Interpol, :pop!
        rule %r/\(/, Operator, :paren_inner
        mixin :root
      end

      # used to balance parentheses inside interpolation
      state :paren_inner do
        rule %r/\(/, Operator, :push
        rule %r/\)/, Operator, :pop!
        mixin :root
      end

      state :math do
        rule %r/\)\)/, Keyword, :pop!
        rule %r([-+*/%^|&!]|\*\*|\|\|), Operator
        rule %r/\d+(#\w+)?/, Num
        mixin :root
      end

      state :case do
        rule %r/\besac\b/, Keyword, :pop!
        rule %r/\|/, Punctuation
        rule %r/\)/, Punctuation, :case_stanza
        mixin :root
      end

      state :case_stanza do
        rule %r/;;/, Punctuation, :pop!
        mixin :root
      end

      state :backticks do
        rule %r/`/, Str::Backtick, :pop!
        mixin :root
      end

      state :interp do
        rule %r/\\$/, Str::Escape # line continuation
        rule %r/\\./, Str::Escape
        rule %r/\$\(\(/, Keyword, :math
        rule %r/\$\(/, Str::Interpol, :paren_interp
        rule %r/\${#?/, Keyword, :curly
        rule %r/`/, Str::Backtick, :backticks
        rule %r/\$#?(\w+|.)/, Name::Variable
        rule %r/\$[*@]/, Name::Variable
      end

      state :root do
        mixin :basic
        mixin :data
      end
    end
  end
end
