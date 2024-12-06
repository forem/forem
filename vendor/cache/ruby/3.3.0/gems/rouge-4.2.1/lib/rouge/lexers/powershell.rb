# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers

    class Powershell < RegexLexer
      title 'powershell'
      desc 'powershell'
      tag 'powershell'
      aliases 'posh', 'microsoftshell', 'msshell'
      filenames '*.ps1', '*.psm1', '*.psd1', '*.psrc', '*.pssc'
      mimetypes 'text/x-powershell'

      # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-6
      ATTRIBUTES = %w(
        ConfirmImpact DefaultParameterSetName HelpURI PositionalBinding
        SupportsPaging SupportsShouldProcess
      )

      # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-6
      AUTO_VARS = %w(
        \$\$ \$\? \$\^ \$_
        \$args \$ConsoleFileName \$Error \$Event \$EventArgs \$EventSubscriber
        \$ExecutionContext \$false \$foreach \$HOME \$Host \$input \$IsCoreCLR
        \$IsLinux \$IsMacOS \$IsWindows \$LastExitCode \$Matches \$MyInvocation
        \$NestedPromptLevel \$null \$PID \$PROFILE \$PSBoundParameters \$PSCmdlet
        \$PSCommandPath \$PSCulture \$PSDebugContext \$PSHOME \$PSItem
        \$PSScriptRoot \$PSSenderInfo \$PSUICulture \$PSVersionTable \$PWD
        \$REPORTERRORSHOWEXCEPTIONCLASS \$REPORTERRORSHOWINNEREXCEPTION
        \$REPORTERRORSHOWSOURCE \$REPORTERRORSHOWSTACKTRACE
        \$SENDER \$ShellId \$StackTrace \$switch \$this \$true
      ).join('|')

      # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_reserved_words?view=powershell-6
      KEYWORDS = %w(
        assembly exit process base filter public begin finally return break for
        sequence catch foreach static class from switch command function throw
        configuration hidden trap continue if try data in type define
        inlinescript until do interface using dynamicparam module var else
        namespace while elseif parallel workflow end param enum private
      ).join('|')

      # https://devblogs.microsoft.com/scripting/powertip-find-a-list-of-powershell-type-accelerators/
      # ([PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get).Keys -join ' '
      KEYWORDS_TYPE = %w(
        Alias AllowEmptyCollection AllowEmptyString AllowNull ArgumentCompleter
        array bool byte char CmdletBinding datetime decimal double DscResource
        float single guid hashtable int int32 int16 long int64 ciminstance
        cimclass cimtype cimconverter IPEndpoint NullString OutputType
        ObjectSecurity Parameter PhysicalAddress pscredential PSDefaultValue
        pslistmodifier psobject pscustomobject psprimitivedictionary ref
        PSTypeNameAttribute regex DscProperty sbyte string SupportsWildcards
        switch cultureinfo bigint securestring timespan uint16 uint32 uint64
        uri ValidateCount ValidateDrive ValidateLength ValidateNotNull
        ValidateNotNullOrEmpty ValidatePattern ValidateRange ValidateScript
        ValidateSet ValidateTrustedData ValidateUserDrive version void
        ipaddress DscLocalConfigurationManager WildcardPattern X509Certificate
        X500DistinguishedName xml CimSession adsi adsisearcher wmiclass wmi
        wmisearcher mailaddress scriptblock psvariable type psmoduleinfo
        powershell runspacefactory runspace initialsessionstate psscriptmethod
        psscriptproperty psnoteproperty psaliasproperty psvariableproperty
      ).join('|')

      OPERATORS = %w(
        -split -isplit -csplit -join -is -isnot -as -eq -ieq -ceq -ne -ine -cne
        -gt -igt -cgt -ge -ige -cge -lt -ilt -clt -le -ile -cle -like -ilike
        -clike -notlike -inotlike -cnotlike -match -imatch -cmatch -notmatch
        -inotmatch -cnotmatch -contains -icontains -ccontains -notcontains
        -inotcontains -cnotcontains -replace -ireplace -creplace -shl -shr -band
        -bor -bxor -and -or -xor -not \+= -= \*= \/= %=
      ).join('|')

      MULTILINE_KEYWORDS = %w(
        synopsis description parameter example inputs outputs notes link
        component role functionality forwardhelptargetname forwardhelpcategory
        remotehelprunspace externalhelp
      ).join('|')

      state :variable do
        rule %r/#{AUTO_VARS}/, Name::Builtin::Pseudo
        rule %r/(\$)(?:(\w+)(:))?(\w+|\{(?:[^`]|`.)+?\})/ do
          groups Name::Variable, Name::Namespace, Punctuation, Name::Variable
        end
        rule %r/\$\w+/, Name::Variable
        rule %r/\$\{(?:[^`]|`.)+?\}/, Name::Variable
      end

      state :multiline do
        rule %r/\.(?:#{MULTILINE_KEYWORDS})/i, Comment::Special
        rule %r/#>/, Comment::Multiline, :pop!
        rule %r/[^#.]+?/m, Comment::Multiline
        rule %r/[#.]+/, Comment::Multiline
      end

      state :interpol do
        rule %r/\)/, Str::Interpol, :pop!
        mixin :root
      end

      state :dq do
        # NB: "abc$" is literally the string abc$.
        # Here we prevent :interp from interpreting $" as a variable.
        rule %r/(?:\$#?)?"/, Str::Double, :pop!
        rule %r/\$\(/, Str::Interpol, :interpol
        rule %r/`$/, Str::Escape # line continuation
        rule %r/`./, Str::Escape
        rule %r/[^"`$]+/, Str::Double
        mixin :variable
      end

      state :sq do
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/, Str::Single
      end

      state :heredoc do
        rule %r/(?:\$#?)?"@/, Str::Heredoc, :pop!
        rule %r/\$\(/, Str::Interpol, :interpol
        rule %r/`$/, Str::Escape # line continuation
        rule %r/`./, Str::Escape
        rule %r/[^"`$]+?/m, Str::Heredoc
        rule %r/"+/, Str::Heredoc
        mixin :variable
      end

      state :class do
        rule %r/\{/, Punctuation, :pop!
        rule %r/\s+/, Text::Whitespace
        rule %r/\w+/, Name::Class
        rule %r/[:,]/, Punctuation
      end

      state :expr do
        mixin :comments
        rule %r/"/, Str::Double, :dq
        rule %r/'/, Str::Single, :sq
        rule %r/@"/, Str::Heredoc, :heredoc
        rule %r/@'.*?'@/m, Str::Heredoc
        rule %r/\d*\.\d+/, Num::Float
        rule %r/\d+/, Num::Integer
        rule %r/@\{/, Punctuation, :hasht
        rule %r/@\(/, Punctuation, :array
        rule %r/{/, Punctuation, :brace
        rule %r/\[/, Punctuation, :bracket
      end

      state :hasht do
        rule %r/\}/, Punctuation, :pop!
        rule %r/=/, Operator
        rule %r/[,;]/, Punctuation
        mixin :expr
        rule %r/\w+/, Name::Other
        mixin :variable
      end

      state :array do
        rule %r/\s+/, Text::Whitespace
        rule %r/\)/, Punctuation, :pop!
        rule %r/[,;]/, Punctuation
        mixin :expr
        mixin :variable
      end

      state :brace do
        rule %r/[}]/, Punctuation, :pop!
        mixin :root
      end

      state :bracket do
        rule %r/\]/, Punctuation, :pop!
        rule %r/[A-Za-z]\w+\./, Name
        rule %r/([A-Za-z]\w+)/ do |m|
          if ATTRIBUTES.include? m[0]
            token Name::Builtin::Pseudo
          else
            token Name
          end
        end
        mixin :root
      end

      state :parameters do
        rule %r/`./m, Str::Escape
        rule %r/\)/ do
          token Punctuation
          pop!(2) if in_state?(:interpol) # pop :parameters and :interpol
        end
        rule %r/\s*?\n/, Text::Whitespace, :pop!
        rule %r/[;(){}\]]/, Punctuation, :pop!
        rule %r/[|=]/, Operator, :pop!
        rule %r/[\/\\~\w][-.:\/\\~\w]*/, Name::Other
        rule %r/\w[-\w]+/, Name::Other
        mixin :root
      end

      state :comments do
        rule %r/\s+/, Text::Whitespace
        rule %r/#.*/, Comment
        rule %r/<#/, Comment::Multiline, :multiline
      end

      state :root do
        mixin :comments
        rule %r/#requires\s-version \d(?:\.\d+)?/, Comment::Preproc

        rule %r/\.\.(?=\.?\d)/, Operator
        rule %r/(?:#{OPERATORS})\b/i, Operator

        rule %r/(class)(\s+)(\w+)/i do
          groups Keyword::Reserved, Text::Whitespace, Name::Class
          push :class
        end
        rule %r/(function)(\s+)(?:(\w+)(:))?(\w[-\w]+)/i do
          groups Keyword::Reserved, Text::Whitespace, Name::Namespace, Punctuation, Name::Function
        end
        rule %r/(?:#{KEYWORDS})\b(?![-.])/i, Keyword::Reserved

        rule %r/-{1,2}\w+/, Name::Tag

        rule %r/(\.)?([-\w]+)(\[)/ do |m|
          groups Operator, Name, Punctuation
          push :bracket
        end

        rule %r/([\/\\~[a-z]][-.:\/\\~\w]*)(\n)?/i do |m|
          groups Name, Text::Whitespace
          push :parameters
        end

        rule %r/(\.)([-\w]+)(?:(\()|(\n))?/ do |m|
          groups Operator, Name::Function, Punctuation, Text::Whitespace
          push :parameters unless m[3].nil?
        end

        rule %r/\?/, Name::Function, :parameters

        mixin :expr
        mixin :variable

        rule %r/[-+*\/%=!.&|]/, Operator
        rule %r/[{}(),:;]/, Punctuation

        rule %r/`$/, Str::Escape # line continuation
      end
    end
  end
end
