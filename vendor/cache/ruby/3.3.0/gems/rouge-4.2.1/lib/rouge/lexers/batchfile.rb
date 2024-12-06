# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Batchfile < RegexLexer
      title "Batchfile"
      desc "Windows Batch File"

      tag 'batchfile'
      aliases 'bat', 'batch', 'dosbatch', 'winbatch'
      filenames '*.bat', '*.cmd'

      mimetypes 'application/bat', 'application/x-bat', 'application/x-msdos-program'

      def self.keywords
        @keywords ||= %w(
          if else for in do goto call exit
        )
      end

      def self.operator_words
        @operator_words ||= %w(
          exist defined errorlevel cmdextversion not equ neq lss leq gtr geq
        )
      end

      def self.devices
        @devices ||= %w(
          con prn aux nul com1 com2 com3 com4 com5 com6 com7 com8 com9 lpt1 lpt2
          lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9
        )
      end

      def self.builtin_commands
        @builtin_commands ||= %w(
          assoc attrib break bcdedit cacls cd chcp chdir chkdsk chkntfs choice
          cls cmd color comp compact convert copy date del dir diskpart doskey
          dpath driverquery echo endlocal erase fc find findstr format fsutil
          ftype gpresult graftabl help icacls label md mkdir mklink mode more
          move openfiles path pause popd print prompt pushd rd recover ren
          rename replace rmdir robocopy setlocal sc schtasks shift shutdown sort
          start subst systeminfo takeown tasklist taskkill time timeout title
          tree type ver verify vol xcopy waitfor wmic
        )
      end

      def self.other_commands
        @other_commands ||= %w(
          addusers admodcmd ansicon arp at bcdboot bitsadmin browstat certreq
          certutil change cidiag cipher cleanmgr clip cmdkey compress convertcp
          coreinfo csccmd csvde cscript curl debug defrag delprof deltree devcon
          diamond dirquota diruse diskshadow diskuse dism dnscmd dsacls dsadd
          dsget dsquery dsmod dsmove dsrm dsmgmt dsregcmd edlin eventcreate
          expand extract fdisk fltmc forfiles freedisk ftp getmac gpupdate
          hostname ifmember inuse ipconfig kill lgpo lodctr logman logoff
          logtime makecab mapisend mbsacli mem mountvol moveuser msg mshta
          msiexec msinfo32 mstsc nbtstat net net1 netdom netsh netstat nlsinfo
          nltest now nslookup ntbackup ntdsutil ntoskrnl ntrights nvspbind
          pathping perms ping portqry powercfg pngout pnputil printbrm prncnfg
          prnmngr procdump psexec psfile psgetsid psinfo pskill pslist
          psloggedon psloglist pspasswd psping psservice psshutdown pssuspend
          qbasic qgrep qprocess query quser qwinsta rasdial reg reg1 regdump
          regedt32 regsvr32 regini reset restore rundll32 rmtshare route rpcping
          run runas scandisk setspn setx sfc share shellrunas shortcut sigcheck
          sleep slmgr strings subinacl sysmon telnet tftp tlist touch tracerpt
          tracert tscon tsdiscon tskill tttracer typeperf tzutil undelete
          unformat verifier vmconnect vssadmin w32tm wbadmin wecutil wevtutil
          wget where whoami windiff winrm winrs wpeutil wpr wusa wuauclt wscript
        )
      end

      def self.attributes
        @attributes ||= %w(
          on off disable enableextensions enabledelayedexpansion
        )
      end

      state :basic do
        # Comments
        rule %r/@?\brem\b.*$/i, Comment

        # Empty Labels
        rule %r/^::.*$/, Comment

        # Labels
        rule %r/:[a-z]+/i, Name::Label

        rule %r/([a-z]\w*)(\.exe|com|bat|cmd|msi)?/i do |m|
          if self.class.devices.include? m[1]
            groups Keyword::Reserved, Error
          elsif self.class.keywords.include? m[1]
            groups Keyword, Error
          elsif self.class.operator_words.include? m[1]
            groups Operator::Word, Error
          elsif self.class.builtin_commands.include? m[1]
            token Name::Builtin
          elsif self.class.other_commands.include? m[1]
            token Name::Builtin
          elsif self.class.attributes.include? m[1]
            groups Name::Attribute, Error
          elsif "set".casecmp m[1]
            groups Keyword::Declaration, Error
          else
            token Text
          end
        end

        rule %r/((?:[\/\+]|--?)[a-z]+)\s*/i, Name::Attribute

        mixin :expansions

        rule %r/[<>&|(){}\[\]\-+=;,~?*]/, Operator
      end

      state :escape do
        rule %r/\^./m, Str::Escape
      end

      state :expansions do
        # Normal and Delayed expansion
        rule %r/[%!]+([a-z_$@#]+)[%!]+/i, Name::Variable
        # For Variables
        rule %r/(\%+~?[a-z]+\d?)/i, Name::Variable::Magic
      end

      state :double_quotes do
        mixin :escape
        rule %r/["]/, Str::Double, :pop!
        mixin :expansions
        rule %r/[^\^"%!]+/, Str::Double
      end

      state :single_quotes do
        mixin :escape
        rule %r/[']/, Str::Single, :pop!
        mixin :expansions
        rule %r/[^\^'%!]+/, Str::Single
      end

      state :backtick do
        mixin :escape
        rule %r/[`]/, Str::Backtick, :pop!
        mixin :expansions
        rule %r/[^\^`%!]+/, Str::Backtick
      end

      state :data do
        rule %r/\s+/, Text
        rule %r/0x[0-9a-f]+/i, Literal::Number::Hex
        rule %r/[0-9]/, Literal::Number
        rule %r/["]/, Str::Double, :double_quotes
        rule %r/[']/, Str::Single, :single_quotes
        rule %r/[`]/, Str::Backtick, :backtick
        rule %r/[^\s&|()\[\]{}\^=;!%+\-,"'`~?*]+/, Text
        mixin :escape
      end

      state :root do
        mixin :basic
        mixin :data
      end
    end
  end
end
