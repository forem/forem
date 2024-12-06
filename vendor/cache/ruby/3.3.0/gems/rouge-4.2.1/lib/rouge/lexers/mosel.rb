# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Mosel < RegexLexer
      tag 'mosel'
      filenames '*.mos'
      title "Mosel"
      desc "An optimization language used by Fico's Xpress."
      # http://www.fico.com/en/products/fico-xpress-optimization-suite
      filenames '*.mos'

      mimetypes 'text/x-mosel'

      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      ############################################################################################################################
      #  General language lements
      ############################################################################################################################

      core_keywords = %w(
        and array as
        boolean break
        case count counter
        declarations div do dynamic
        elif else end evaluation exit
        false forall forward from function
        if imports in include initialisations initializations integer inter is_binary is_continuous is_free is_integer is_partint is_semcont is_semint is_sos1 is_sos2
        linctr list
        max min mod model mpvar
        next not of options or
        package parameters procedure
        public prod range real record repeat requirements
        set string sum
        then to true
        union until uses
        version
        while with
      )

      core_functions = %w(
        abs arctan assert
        bitflip bitneg bitset bitshift bittest bitval
        ceil cos create currentdate currenttime cuthead cuttail
        delcell exists exit exp exportprob
        fclose fflush finalize findfirst findlast floor fopen fselect fskipline
        getact getcoeff getcoeffs getdual getfid getfirst gethead getfname getlast getobjval getparam getrcost getreadcnt getreverse getsize getslack getsol gettail gettype getvars
        iseof ishidden isodd ln log
        makesos1 makesos2 maxlist minlist
        publish
        random read readln reset reverse round
        setcoeff sethidden setioerr setname setparam setrandseed settype sin splithead splittail sqrt strfmt substr
        timestamp
        unpublish
        write writeln
      )

      ############################################################################################################################
      # mmxprs module elements
      ############################################################################################################################

      mmxprs_functions = %w(
        addmipsol
        basisstability
        calcsolinfo clearmipdir clearmodcut command copysoltoinit
        defdelayedrows defsecurevecs
        estimatemarginals
        fixglobal
        getbstat getdualray getiis getiissense getiistype getinfcause getinfeas getlb getloadedlinctrs getloadedmpvars getname getprimalray getprobstat getrange getsensrng getsize getsol getub getvars
        implies indicator isiisvalid isintegral loadbasis
        loadmipsol loadprob
        maximize minimize
        postsolve
        readbasis readdirs readsol refinemipsol rejectintsol repairinfeas resetbasis resetiis resetsol
        savebasis savemipsol savesol savestate selectsol setbstat setcallback setcbcutoff setgndata setlb setmipdir setmodcut setsol setub setucbdata stopoptimize
        unloadprob
        writebasis writedirs writeprob writesol
        xor
      )

      mmxpres_constants = %w(XPRS_OPT  XPRS_UNF  XPRS_INF XPRS_UNB XPRS_OTH)

      mmxprs_parameters = %w(XPRS_colorder XPRS_enumduplpol XPRS_enummaxsol XPRS_enumsols XPRS_fullversion XPRS_loadnames XPRS_problem XPRS_probname XPRS_verbose)


      ############################################################################################################################
      # mmsystem module elements
      ############################################################################################################################

      mmsystem_functions = %w(
        addmonths
        copytext cuttext
        deltext
        endswith expandpath
        fcopy fdelete findfiles findtext fmove
        getasnumber getchar getcwd getdate getday getdaynum getdays getdirsep
        getendparse setendparse
        getenv getfsize getfstat getftime gethour getminute getmonth getmsec getpathsep
        getqtype setqtype
        getsecond
        getsepchar setsepchar
        getsize
        getstart setstart
        getsucc setsucc
        getsysinfo getsysstat gettime
        gettmpdir
        gettrim settrim
        getweekday getyear
        inserttext isvalid
        makedir makepath newtar
        newzip nextfield
        openpipe
        parseextn parseint parsereal parsetext pastetext pathmatch pathsplit
        qsort quote
        readtextline regmatch regreplace removedir removefiles
        setchar setdate setday setenv sethour
        setminute setmonth setmsec setsecond settime setyear sleep startswith system
        tarlist textfmt tolower toupper trim
        untar unzip
        ziplist
      )

      mmsystem_parameters = %w(datefmt datetimefmt monthnames sys_endparse sys_fillchar sys_pid sys_qtype sys_regcache sys_sepchar)

      ############################################################################################################################
      # mmjobs  module elements
      ############################################################################################################################

      mmjobs_instance_mgmt_functions = %w(
        clearaliases connect
        disconnect
        findxsrvs
        getaliases getbanner gethostalias
        sethostalias
      )

      mmjobs_model_mgmt_functions = %w(
        compile
        detach
        getannidents getannotations getexitcode getgid getid getnode getrmtid getstatus getuid
        load
        reset resetmodpar run
        setcontrol setdefstream setmodpar setworkdir stop
        unload
      )

      mmjobs_synchornization_functions = %w(
        dropnextevent
        getclass getfromgid getfromid getfromuid getnextevent getvalue
        isqueueempty
        nullevent
        peeknextevent
        send setgid setuid
        wait waitfor
      )

      mmjobs_functions = mmjobs_instance_mgmt_functions + mmjobs_model_mgmt_functions + mmjobs_synchornization_functions

      mmjobs_parameters = %w(conntmpl defaultnode fsrvdelay fsrvnbiter fsrvport jobid keepalive nodenumber parentnumber)


      state :whitespace do
        # Spaces
        rule %r/\s+/m, Text
        # ! Comments
        rule %r((!).*$\n?), Comment::Single
        # (! Comments !)
        rule %r(\(!.*?!\))m, Comment::Multiline

      end


      # From Mosel documentation:
      # Constant strings of characters must be quoted with single (') or double quote (") and may extend over several lines. Strings enclosed in double quotes may contain C-like escape sequences introduced by the 'backslash'
      # character (\a \b \f \n \r \t \v \xxx with xxx being the character code as an octal number).
      # Each sequence is replaced by the corresponding control character (e.g. \n is the `new line' command) or, if no control character exists, by the second character of the sequence itself (e.g. \\ is replaced by '\').
      # The escape sequences are not interpreted if they are contained in strings that are enclosed in single quotes.

      state :single_quotes do
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/, Str::Single
      end

      state :double_quotes do
        rule %r/"/, Str::Double, :pop!
        rule %r/(\\"|\\[0-7]{1,3}\D|\\[abfnrtv]|\\\\)/, Str::Escape
        rule %r/[^"]/, Str::Double
      end

      state :base do

        rule %r{"}, Str::Double, :double_quotes
        rule %r{'}, Str::Single, :single_quotes

        rule %r{((0(x|X)[0-9a-fA-F]*)|(([0-9]+\.?[0-9]*)|(\.[0-9]+))((e|E)(\+|-)?[0-9]+)?)(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?}, Num
        rule %r{[~!@#\$%\^&\*\(\)\+`\-={}\[\]:;<>\?,\.\/\|\\]}, Punctuation
#        rule %r{'([^']|'')*'}, Str
#        rule %r/"(\\\\|\\"|[^"])*"/, Str



        rule %r/(true|false)\b/i, Name::Builtin
        rule %r/\b(#{core_keywords.join('|')})\b/i, Keyword
        rule %r/\b(#{core_functions.join('|')})\b/, Name::Builtin



        rule %r/\b(#{mmxprs_functions.join('|')})\b/, Name::Function
        rule %r/\b(#{mmxpres_constants.join('|')})\b/, Name::Constant
        rule %r/\b(#{mmxprs_parameters.join('|')})\b/i, Name::Property

        rule %r/\b(#{mmsystem_functions.join('|')})\b/i, Name::Function
        rule %r/\b(#{mmsystem_parameters.join('|')})\b/, Name::Property

        rule %r/\b(#{mmjobs_functions.join('|')})\b/i, Name::Function
        rule %r/\b(#{mmjobs_parameters.join('|')})\b/, Name::Property

        rule id, Name
      end

      state :root do
        mixin :whitespace
        mixin :base
      end
    end
  end
end
