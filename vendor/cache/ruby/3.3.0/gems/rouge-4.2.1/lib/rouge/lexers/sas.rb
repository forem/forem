# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class SAS < RegexLexer
      title "SAS"
      desc "SAS (Statistical Analysis Software)"
      tag 'sas'
      filenames '*.sas'
      mimetypes 'application/x-sas', 'application/x-stat-sas', 'application/x-sas-syntax'

      def self.data_step_statements
        # from Data step statements - SAS 9.4 Statements reference
        # http://support.sas.com/documentation/cdl/en/lestmtsref/68024/PDF/default/lestmtsref.pdf
        @data_step_statements ||= Set.new %w(
          ABORT ARRAY ATTRIB BY CALL CARDS CARDS4 CATNAME CHECKPOINT 
          EXECUTE_ALWAYS CONTINUE DATA DATALINES DATALINES4 DELETE DESCRIBE
          DISPLAY DM DO UNTIL WHILE DROP END ENDSAS ERROR EXECUTE FILE FILENAME
          FOOTNOTE FORMAT GO TO IF THEN ELSE INFILE INFORMAT INPUT
          KEEP LABEL LEAVE LENGTH LIBNAME LINK LIST LOCK LOSTCARD MERGE
          MISSING MODIFY OPTIONS OUTPUT PAGE PUT PUTLOG REDIRECT REMOVE RENAME
          REPLACE RESETLINE RETAIN RETURN RUN SASFILE SELECT SET SKIP STOP         
          SYSECHO TITLE UPDATE WHERE WINDOW X
         )
      # label:
      # Sum
      end

      def self.sas_functions
        # from SAS 9.4 Functions and CALL Routines reference
        # http://support.sas.com/documentation/cdl/en/lefunctionsref/67960/PDF/default/lefunctionsref.pdf
        @sas_functions ||= Set.new %w(
          ABS ADDR ADDRLONG AIRY ALLCOMB ALLPERM ANYALNUM ANYALPHA ANYCNTRL
          ANYDIGIT ANYFIRST ANYGRAPH ANYLOWER ANYNAME ANYPRINT ANYPUNCT
          ANYSPACE ANYUPPER ANYXDIGIT ARCOS ARCOSH ARSIN ARSINH ARTANH ATAN
          ATAN2 ATTRC ATTRN BAND BETA BETAINV BLACKCLPRC BLACKPTPRC
          BLKSHCLPRC BLKSHPTPRC BLSHIFT BNOT BOR BRSHIFT BXOR BYTE CAT CATQ
          CATS CATT CATX CDF CEIL CEILZ CEXIST CHAR CHOOSEC CHOOSEN CINV
          CLOSE CMISS CNONCT COALESCE COALESCEC COLLATE COMB COMPARE COMPBL
          COMPFUZZ COMPGED COMPLEV COMPOUND COMPRESS CONSTANT CONVX CONVXP
          COS COSH COT COUNT COUNTC COUNTW CSC CSS CUMIPMT CUMPRINC CUROBS
          CV DACCDB DACCDBSL DACCSL DACCSYD DACCTAB DAIRY DATDIF DATE
          DATEJUL DATEPART DATETIME DAY DCLOSE DCREATE DEPDB DEPDBSL DEPSL
          DEPSYD DEPTAB DEQUOTE DEVIANCE DHMS DIF DIGAMMA DIM DINFO DIVIDE
          DNUM DOPEN DOPTNAME DOPTNUM DOSUBL DREAD DROPNOTE DSNAME
          DSNCATLGD DUR DURP EFFRATE ENVLEN ERF ERFC EUCLID EXIST EXP FACT
          FAPPEND FCLOSE FCOL FCOPY FDELETE FETCH FETCHOBS FEXIST FGET
          FILEEXIST FILENAME FILEREF FINANCE FIND FINDC FINDW FINFO FINV
          FIPNAME FIPNAMEL FIPSTATE FIRST FLOOR FLOORZ FMTINFO FNONCT FNOTE
          FOPEN FOPTNAME FOPTNUM FPOINT FPOS FPUT FREAD FREWIND FRLEN FSEP
          FUZZ FWRITE GAMINV GAMMA GARKHCLPRC GARKHPTPRC GCD GEODIST
          GEOMEAN GEOMEANZ GETOPTION GETVARC GETVARN GRAYCODE HARMEAN
          HARMEANZ HBOUND HMS HOLIDAY HOLIDAYCK HOLIDAYCOUNT HOLIDAYNAME
          HOLIDAYNX HOLIDAYNY HOLIDAYTEST HOUR HTMLDECODE HTMLENCODE
          IBESSEL IFC IFN INDEX INDEXC INDEXW INPUT INPUTC INPUTN INT
          INTCINDEX INTCK INTCYCLE INTFIT INTFMT INTGET INTINDEX INTNX
          INTRR INTSEAS INTSHIFT INTTEST INTZ IORCMSG IPMT IQR IRR JBESSEL
          JULDATE JULDATE7 KURTOSIS LAG LARGEST LBOUND LCM LCOMB LEFT
          LENGTH LENGTHC LENGTHM LENGTHN LEXCOMB LEXCOMBI LEXPERK LEXPERM
          LFACT LGAMMA LIBNAME LIBREF LOG LOG1PX LOG10 LOG2 LOGBETA LOGCDF
          LOGISTIC LOGPDF LOGSDF LOWCASE LPERM LPNORM MAD MARGRCLPRC
          MARGRPTPRC MAX MD5 MDY MEAN MEDIAN MIN MINUTE MISSING MOD
          MODEXIST MODULE MODULEC MODULEN MODZ MONTH MOPEN MORT MSPLINT
          MVALID N NETPV NLITERAL NMISS NOMRATE NORMAL NOTALNUM NOTALPHA
          NOTCNTRL NOTDIGIT NOTE NOTFIRST NOTGRAPH NOTLOWER NOTNAME
          NOTPRINT NOTPUNCT NOTSPACE NOTUPPER NOTXDIGIT NPV NVALID NWKDOM
          OPEN ORDINAL PATHNAME PCTL PDF PEEK PEEKC PEEKCLONG PEEKLONG PERM
          PMT POINT POISSON PPMT PROBBETA PROBBNML PROBBNRM PROBCHI PROBF
          PROBGAM PROBHYPR PROBIT PROBMC PROBNEGB PROBNORM PROBT PROPCASE
          PRXCHANGE PRXMATCH PRXPAREN PRXPARSE PRXPOSN PTRLONGADD PUT PUTC
          PUTN PVP QTR QUANTILE QUOTE RANBIN RANCAU RAND RANEXP RANGAM
          RANGE RANK RANNOR RANPOI RANTBL RANTRI RANUNI RENAME REPEAT
          RESOLVE REVERSE REWIND RIGHT RMS ROUND ROUNDE ROUNDZ SAVING
          SAVINGS SCAN SDF SEC SECOND SHA256 SHA256HEX SHA256HMACHEX SIGN
          SIN SINH SKEWNESS SLEEP SMALLEST SOAPWEB SOAPWEBMETA
          SOAPWIPSERVICE SOAPWIPSRS SOAPWS SOAPWSMETA SOUNDEX SPEDIS SQRT
          SQUANTILE STD STDERR STFIPS STNAME STNAMEL STRIP SUBPAD SUBSTR
          SUBSTRN SUM SUMABS SYMEXIST SYMGET SYMGLOBL SYMLOCAL SYSEXIST
          SYSGET SYSMSG SYSPARM SYSPROCESSID SYSPROCESSNAME SYSPROD SYSRC
          SYSTEM TAN TANH TIME TIMEPART TIMEVALUE TINV TNONCT TODAY
          TRANSLATE TRANSTRN TRANWRD TRIGAMMA TRIM TRIMN TRUNC TSO TYPEOF
          TZONEID TZONENAME TZONEOFF TZONES2U TZONEU2S UNIFORM UPCASE
          URLDECODE URLENCODE USS UUIDGEN VAR VARFMT VARINFMT VARLABEL
          VARLEN VARNAME VARNUM VARRAY VARRAYX VARTYPE VERIFY VFORMAT
          VFORMATD VFORMATDX VFORMATN VFORMATNX VFORMATW VFORMATWX VFORMATX
          VINARRAY VINARRAYX VINFORMAT VINFORMATD VINFORMATDX VINFORMATN
          VINFORMATNX VINFORMATW VINFORMATWX VINFORMATX VLABEL VLABELX
          VLENGTH VLENGTHX VNAME VNAMEX VTYPE VTYPEX VVALUE VVALUEX WEEK
          WEEKDAY WHICHC WHICHN WTO YEAR YIELDP YRDIF YYQ ZIPCITY
          ZIPCITYDISTANCE ZIPFIPS ZIPNAME ZIPNAMEL ZIPSTATE
         )
      end

      def self.sas_macro_statements
        # from SAS 9.4 Macro Language Reference
        # Chapter 12
        @sas_macro_statements ||= Set.new %w(
          %COPY %DISPLAY %GLOBAL %INPUT %LET %MACRO %PUT %SYMDEL %SYSCALL
          %SYSEXEC %SYSLPUT %SYSMACDELETE %SYSMSTORECLEAR %SYSRPUT %WINDOW
          %ABORT %DO %TO %UNTIL %WHILE %END %GOTO %IF %THEN %ELSE %LOCAL
          %RETURN
          %INCLUDE %LIST %RUN
        )
        # Omitted:
        # %label: Identifies the destination of a %GOTO statement.
        # %MEND
      end

      def self.sas_macro_functions
        # from SAS 9.4 Macro Language Reference
        # Chapter 12

        @sas_macro_functions ||= Set.new %w(
          %BQUOTE %NRBQUOTE %EVAL %INDEX %LENGTH %QUOTE %NRQUOTE %SCAN
          %QSCAN %STR %NRSTR %SUBSTR %QSUBSTR %SUPERQ %SYMEXIST %SYMGLOBL
          %SYMLOCAL %SYSEVALF %SYSFUNC %QSYSFUNC %SYSGET %SYSMACEXEC
          %SYSMACEXIST %SYSMEXECDEPTH %SYSMEXECNAME %SYSPROD %UNQUOTE
          %UPCASE %QUPCASE
        )
      end

      def self.sas_auto_macro_vars
        # from SAS 9.4 Macro Language Reference
        # Chapter 12

        @sas_auto_macro_vars ||= Set.new %w(
          &SYSADDRBITS &SYSBUFFR &SYSCC &SYSCHARWIDTH &SYSCMD &SYSDATASTEPPHASE &SYSDATE
          &SYSDATE9 &SYSDAY &SYSDEVIC &SYSDMG &SYSDSN &SYSENCODING &SYSENDIAN &SYSENV
          &SYSERR &SYSERRORTEXT &SYSFILRC &SYSHOSTINFOLONG &SYSHOSTNAME &SYSINDEX
          &SYSINFO &SYSJOBID &SYSLAST &SYSLCKRC &SYSLIBRC &SYSLOGAPPLNAME &SYSMACRONAME
          &SYSMENV &SYSMSG &SYSNCPU &SYSNOBS &SYSODSESCAPECHAR &SYSODSPATH &SYSPARM
          &SYSPBUFF &SYSPRINTTOLIST &SYSPRINTTOLOG &SYSPROCESSID &SYSPROCESSMODE
          &SYSPROCESSNAME &SYSPROCNAME &SYSRC &SYSSCP &SYSSCPL &SYSSITE &SYSSIZEOFLONG
          &SYSSIZEOFPTR &SYSSIZEOFUNICODE &SYSSTARTID &SYSSTARTNAME &SYSTCPIPHOSTNAME
          &SYSTIME &SYSTIMEZONE &SYSTIMEZONEIDENT &SYSTIMEZONEOFFSET &SYSUSERID &SYSVER
          &SYSVLONG &SYSVLONG4 &SYSWARNINGTEXT
        )
      end

      def self.proc_keywords 
        # Create a hash with keywords for common PROCs, keyed by PROC name
        @proc_keywords ||= {}

	@proc_keywords["SQL"] ||= Set.new %w(
            ALTER TABLE CONNECT CREATE INDEX VIEW DELETE DESCRIBE DISCONNECT DROP EXECUTE
            INSERT RESET SELECT UPDATE VALIDATE ADD CONSTRAINT DROP FOREIGN KEY PRIMARY
            MODIFY LIKE AS ORDER BY USING FROM INTO SET VALUES RESET DISTINCT UNIQUE
            WHERE GROUP HAVING LEFT RIGHT INNER JOIN ON
          )
        # from SAS 9.4 SQL Procedure User's Guide

	@proc_keywords["MEANS"] ||= Set.new %w(
            BY CLASS FREQ ID OUTPUT OUT TYPES VAR WAYS WEIGHT
            ATTRIB FORMAT LABEL WHERE
            DESCENDING NOTSORTED 
            NOTHREADS NOTRAP PCTLDEF SUMSIZE THREADS CLASSDATA COMPLETETYPES
            EXCLUSIVE MISSING FW MAXDEC NONOBS NOPRINT ORDER FORMATTED FREQ
            UNFORMATTED PRINT PRINTALLTYPES PRINTIDVARS STACKODSOUTPUT
            CHARTYPE DESCENDTYPES IDMIN
            ALPHA EXCLNPWGT QMARKERS QMETHOD QNTLDEF VARDEF
            CLM CSS CV KURTOSIS KURT LCLM MAX MEAN MIN MODE N
            NMISS RANGE SKEWNESS SKEW STDDEV STD STDERR SUM SUMWGT UCLM USS VAR
            MEDIAN P50 Q1 P25 Q3 P75 P1 P90 P5 P95 P10 P99 P20 P30 P40 P60 P70
            P80 QRANGE
            PROBT PRT T
            ASCENDING GROUPINTERNAL MLF PRELOADFMT
            MAXID AUTOLABEL AUTONAME KEEPLEN LEVELS NOINHERIT
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["DATASETS"] ||= Set.new %w(
            AGE APPEND ATTRIB AUDIT CHANGE CONTENTS COPY DELETE EXCHANGE
            EXCLUDE FORMAT IC CREATE DELETE REACTIVATE INDEX CENTILES INFORMAT
            INITIATE LABEL LOG MODIFY REBUILD RENAME REPAIR RESUME SAVE SELECT
            SUSPEND TERMINATE USER_VAR XATTR ADD OPTIONS REMOVE SET
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["SORT"] ||= Set.new %w(
            BY DESCENDING KEY ASCENDING ASC DESC DATECOPY FORCE OVERWRITE 
            PRESORTED SORTSIZE TAGSORT DUPOUT OUT UNIQUEOUT NODUPKEY NOUNIQUEKEY 
            NOTHREADS THREADS EQUALS NOEQUALS
            ATTRIB FORMAT LABEL WHERE
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["PRINT"] ||= Set.new %w(
            BY DESCENDING NOTSORTED PAGEBY SUMBY ID STYLE SUM VAR CONTENTS DATA
            GRANDTOTAL_LABEL HEADING LABEL SPLIT SUMLABEL NOSUMLABEL
            BLANKLINE COUNT DOUBLE N NOOBS OBS ROUND
            ROWS UNIFORM WIDTH
            ATTRIB FORMAT LABEL WHERE
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["APPEND"] ||= Set.new %w(
            BASE APPENDVER DATA ENCRYPTKEY FORCE GETSORT NOWARN
            ATTRIB FORMAT LABEL WHERE
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["TRANSPOSE"] ||= Set.new %w(
            DELIMITER LABEL LET NAME OUT PREFIX SUFFIX BY DESCENDING NOTSORTED
            COPY ID IDLABEL VAR INDB
            ATTRIB FORMAT LABEL WHERE
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["FREQ"] ||= Set.new %w(
            BY EXACT OUTPUT TABLES TEST WEIGHT
            COMPRESS DATA FORMCHAR NLEVELS NOPRINT ORDER PAGE FORMATTED FREQ 
            INTERNAL
            AGREE BARNARD BINOMIAL BIN CHISQ COMOR EQOR ZELEN FISHER JT KAPPA
            KENTB TAUB LRCHI MCNEM MEASURES MHCHI OR ODDSRATIO PCHI PCORR RELRISK
            RISKDIFF SCORR SMDCR SMDRC STUTC TAUC TREND WTKAP WTKAPPA
            OUT AJCHI ALL BDCHI CMH CMH1 CMH2 CMHCOR CMHGA CMHRMS COCHQ CONTGY
            CRAMV EQKAP EQWKP GAMMA GS GAILSIMON LAMCR LAMDAS LAMRC LGOR LGRRC1
            LGRRC2 MHOR MHRRC1 MHRRC2 N NMISS PHI PLCORR RDIF1 RDIF2 RISKDIFF1
            RISKDIFF2 RRC1 RELRISK1 RRC2 RELRISK2 RSK1 RISK1 RSK11 RISK11 RSK12
            RISK12 RSK21 RISK21 RSK22 RISK22 TSYMM BOWKER U UCR URC
            CELLCHI2 CUMCOL DEVIATION EXPECTED MISSPRINT PEARSONREF PRINTWKTS
            SCOROUT SPARSE STDRES TOTPCT
            CONTENTS CROSSLIST FORMAT LIST MAXLEVELS NOCOL NOCUM NOFREQ NOPERCENT
            NOPRINT NOROW NOSPARSE NOWARN PLOTS OUT OUTCUM OUTEXPECT OUTPCT
            ZEROS
          )
        # from Base SAS 9.4 Procedures Guide: Statistical Procedures, Fourth Edition

	@proc_keywords["CORR"] ||= Set.new %w(
            BY FREQ ID PARTIAL VAR WEIGHT WITH
            DATA OUTH OUTK OUTP OUTPLC OUTPLS OUTS
            EXCLNPWGHT FISHER HOEFFDING KENDALL NOMISS PEARSON POLYCHORIC
            POLYSERIAL ALPHA COV CSSCP SINGULAR SSCP VARDEF PLOTS MATRIX SCATTER
            BEST NOCORR NOPRINT NOPROB NOSIMPLE RANK
          )
        # from Base SAS 9.4 Procedures Guide: Statistical Procedures, Fourth Edition

	@proc_keywords["REPORT"] ||= Set.new %w(
            BREAK BY DESCENDING NOTSORTED COLUMN COMPUTE STYLE LINE ENDCOMP
            CALL DEFINE _ROW_ FREQ RBREAK WEIGHT
            ATTRIB FORMAT LABEL WHERE
            DATA NOALIAS NOCENTER NOCOMPLETECOLS NOCOMPLETEROWS NOTHREADS 
            NOWINDOWS OUT PCTLDEF THREADS WINDOWS COMPLETECOLS NOCOMPLETECOLS
            COMPLETEROWS NOCOMPLETEROWS CONTENTS SPANROWS COMMAND HELP PROMPT
            BOX BYPAGENO CENTER NOCENTER COLWIDTH FORMCHAR LS MISSING PANELS PS
            PSPACE SHOWALL SPACING WRAP EXCLNPWGT QMARKERS QMETHOD QNTLDEF VARDEF
            NAMED NOHEADER SPLIT HEADLINE HEADSKIP LIST NOEXEC OUTREPT PROFILE
            REPORT
            COLOR DOL DUL OL PAGE SKIP SUMMARIZE SUPPRESS UL
            BLINK COMMAND HIGHLIGHT RVSVIDEO MERGE REPLACE URL URLBP URLP
            AFTER BEFORE _PAGE_ LEFT RIGHT CHARACTER LENGTH
            EXCLUSIVE MISSING MLF ORDER DATA FORMATTED FREQ INTERNAL PRELOADFMT
            WIDTH
            ACROSS ANALYSIS COMPUTED DISPLAY GROUP ORDER
            CONTENTS FLOW ID NOPRINT NOZERO PAGE
            CSS CV MAX MEAN MIN MODE N NMISS PCTN PCTSUM RANGE STD STDERR SUM
            SUMWGT USS VAR
            MEDIAN P50 Q1 P25 Q3 P75 P1 P90 P5 P95 P10 P99 P20 P30 P40 P60 P70
            P80 QRANGE
            PROBT PRT T
          )
        # from BASE SAS 9.4 Procedures Guide, Fifth Edition

	@proc_keywords["METALIB"] ||= Set.new %w(
            OMR DBAUTH DBUSER DBPASSWORD EXCLUDE SELECT READ FOLDER FOLDERID
            IMPACT_LIMIT NOEXEC PREFIX REPORT UPDATE_RULE DELETE NOADD NODELDUP
            NOUPDATE
            LIBID LIBRARY LIBURI
            TYPE DETAIL SUMMARY
          )
        # from SAS 9.4 Language Interfaces to Metadata, Third Edition

	@proc_keywords["GCHART"] ||= Set.new %w(
            DATA ANNOTATE GOUT IMAGEMAP BLOCK HBAR HBAR3D VBAR VBAR3D PIE PIE3D
            DONUT STAR ANNO
            BY NOTE FORMAT LABEL WHERE
            BLOCKMAX CAXIS COUTLINE CTEXT LEGEND NOHEADING NOLEGEND PATTERNID
            GROUP MIDPOINT SUBGROUP WOUTLINE DESCRIPTION NAME DISCRETE LEVELS
            OLD MISSING HTML_LEGEND HTML URL FREQ G100 SUMVAR TYPE
            CAUTOREF CERROR CFRAME CLM CREF FRAME NOFRAME GSPACE IFRAME
            IMAGESTYLE TILE FIT LAUTOREF NOSYMBOL PATTERNID SHAPE SPACE
            SUBOUTSIDE WAUTOREF WIDTH WOUTLINE WREF
            ASCENDING AUTOREF CLIPREF DESCENDING FRONTREF GAXIS MAXIS MINOR
            NOAXIS NOBASEREF NOZERO RANGE AXIS REF CFREQ CFREQLABEL NONE CPERCENT
            CPERCENTLABEL ERRORBAR BARS BOTH TOP FREQLABEL INSIDE MEAN MEANLABEL
            NOSTATS OUTSIDE PERCENT PERCENTLABEL PERCENTSUM SUM
            CFILL COUTLINE DETAIL_RADIUS EXPLODE FILL SOLID X INVISIBLE NOHEADING
            RADIUS WOUTLINE DETAIL_THRESHOLD DETAIL_PERCENT DETAIL_SLICE
            DETAIL_VALUE DONUTPCT LABEL ACROSS DOWN GROUP NOGROUPHEADING SUBGROUP
            MATCHCOLOR OTHERCOLOR OTHERLABEL PERCENT ARROW PLABEL PPERCENT SLICE
            VALUE
            ANGLE ASCENDING CLOCKWISE DESCENDING JSTYLE
            NOCONNECT STARMAX STARMIN 
          )
        # from SAS GRAPH 9.4 Reference, Fourth Edition

	@proc_keywords["GPLOT"] ||= Set.new %w(
            DATA ANNOTATE GOUT IMAGEMAP UNIFORM BUBBLE BUBBLE2 PLOT PLOT2
            BCOLOR BFILL BFONT BLABEL BSCALE AREA RADIUS BSIZE DESCRIPTION NAME
            AUTOHREF CAUTOHREF CHREF HAXIS HMINOR HREF HREVERSE HZERO LAUTOHREF
            LHREF WAUTOHREF WHREF HTML URL
            CAXIS CFRAME CTEXT DATAORDER FRAME NOFRAME FRONTREF GRID IFRAME
            IMAGESTYLE TILE FIT NOAXIS
            AUTOVREF CAUTOVREF CVREF LAUTOVREF LVREF VAXIS VMINOR VREF VREVERSE
            VZERO WAUTOVREF WVREF
            CBASELINE COUTLINE
            AREAS GRID LEGEND NOLASTAREA NOLEGEND OVERLAY REGEQN SKIPMISS
          )
        # from SAS GRAPH 9.4 Reference, Fourth Edition

	@proc_keywords["REG"] ||= Set.new %w(
            MODEL BY FREQ ID VAR WEIGHT ADD CODE DELETE MTEST OUTPUT PAINT
            PLOT PRINT REFIT RESTRICT REWEIGHT STORE TEST
          )
         # from SAS/STAT 15.1 User's Guide

	@proc_keywords["SGPLOT"] ||= Set.new %w(
            STYLEATTRS BAND X Y UPPER LOWER BLOCK BUBBLE DENSITY DOT DROPLINE
            ELLIPSE ELLIPSEPARM FRINGE GRADLEGEND HBAR HBARBASIC HBARPARM
            HBOX HEATMAP HEATMAPPARM HIGHLOW HISTOGRAM HLINE INSET KEYLEGEND
            LINEPARM LOESS NEEDLE PBSPLINE POLYGON REFLINE REG SCATTER SERIES
            SPLINE STEP SYMBOLCHAR SYMBOLIMAGE TEXT VBAR VBARBASIC VBARPARM
            VBOX VECTOR VLINE WATERFALL XAXIS X2AXIS XAXISTABLE YAXIS Y2AXIS
            YAXISTABLE
          )
         # from ODS Graphics: Procedures Guide, Sixth Edition
        return @proc_keywords
      end

      def self.sas_proc_names
        # from SAS Procedures by Name
        # http://support.sas.com/documentation/cdl/en/allprodsproc/68038/HTML/default/viewer.htm#procedures.htm

        @sas_proc_names ||= Set.new %w(
          ACCESS ACECLUS ADAPTIVEREG ALLELE ANOM ANOVA APPEND APPSRV ARIMA
          AUTHLIB AUTOREG BCHOICE BOM BOXPLOT BTL BUILD CALENDAR CALIS CALLRFC
          CANCORR CANDISC CAPABILITY CASECONTROL CATALOG CATMOD CDISC CDISC
          CHART CIMPORT CLP CLUSTER COMPARE COMPILE COMPUTAB CONTENTS CONVERT
          COPULA COPY CORR CORRESP COUNTREG CPM CPORT CUSUM CV2VIEW DATEKEYS
          DATASETS DATASOURCE DB2EXT DB2UTIL DBCSTAB DBF DBLOAD DELETE DIF
          DISCRIM DISPLAY DISTANCE DMSRVADM DMSRVDATASVC DMSRVPROCESSSVC
          DOCUMENT DOWNLOAD DQLOCLST DQMATCH DQSCHEME DS2 DTREE ENTROPY ESM
          EXPAND EXPLODE EXPORT FACTEX FACTOR FAMILY FASTCLUS FCMP FEDSQL FMM
          FONTREG FORECAST FORMAT FORMS FREQ FSBROWSE FSEDIT FSLETTER FSLIST
          FSVIEW G3D G3GRID GA GAM GAMPL GANNO GANTT GAREABAR GBARLINE GCHART
          GCONTOUR GDEVICE GEE GENESELECT GENMOD GEOCODE GFONT GINSIDE GIS GKPI
          GLIMMIX GLM GLMMOD GLMPOWER GLMSELECT GMAP GOPTIONS GPLOT GPROJECT
          GRADAR GREDUCE GREMOVE GREPLAY GROOVY GSLIDE GTILE HADOOP HAPLOTYPE
          HDMD HPBIN HPCANDISC HPCDM HPCOPULA HPCORR HPCOUNTREG HPDMDB HPDS2
          HPFMM HPGENSELECT HPIMPUTE HPLMIXED HPLOGISTIC HPMIXED HPNLMOD
          HPPANEL HPPLS HPPRINCOMP HPQUANTSELECT HPQLIM HPREG HPSAMPLE
          HPSEVERITY HPSPLIT HPSUMMARY HTSNP HTTP ICLIFETEST ICPHREG IML IMPORT
          IMSTAT IMXFER INBREED INFOMAPS INTPOINT IOMOPERATE IRT ISHIKAWA ITEMS
          JAVAINFO JSON KDE KRIGE2D LASR LATTICE LIFEREG LIFETEST LOAN
          LOCALEDATA LOESS LOGISTIC LP LUA MACONTROL MAPIMPORT MCMC MDC MDDB
          MDS MEANS METADATA METALIB METAOPERATE MI MIANALYZE MIGRATE MIXED
          MODECLUS MODEL MSCHART MULTTEST MVPDIAGNOSE MVPMODEL MVPMONITOR
          NESTED NETDRAW NETFLOW NLIN NLMIXED NLP NPAR1WAY ODSLIST ODSTABLE
          ODSTEXT OLAP OLAPCONTENTS OLAPOPERATE OPERATE OPTEX OPTGRAPH OPTIONS
          OPTLOAD OPTLP OPTLSO OPTMILP OPTMODEL OPTNET OPTQP OPTSAVE ORTHOREG
          PANEL PARETO PDLREG PDS PDSCOPY PHREG PLAN PLM PLOT PLS PM PMENU
          POWER PRESENV PRINCOMP PRINQUAL PRINT PRINTTO PROBIT PROTO PRTDEF
          PRTEXP PSMOOTH PWENCODE QDEVICE QLIM QUANTLIFE QUANTREG QUANTSELECT
          QUEST RANK RAREEVENTS RDC RDPOOL RDSEC RECOMMEND REG REGISTRY RELEASE
          RELIABILITY REPORT RISK ROBUSTREG RSREG SCAPROC SCORE SEQDESIGN
          SEQTEST SERVER SEVERITY SGDESIGN SGPANEL SGPLOT SGRENDER SGSCATTER
          SHEWHART SIM2D SIMILARITY SIMLIN SIMNORMAL SOAP SORT SOURCE SPECTRA
          SPP SQL SQOOP SSM STANDARD STATESPACE STDIZE STDRATE STEPDISC STP
          STREAM SUMMARY SURVEYFREQ SURVEYIMPUTE SURVEYLOGISTIC SURVEYMEANS
          SURVEYPHREG SURVEYREG SURVEYSELECT SYSLIN TABULATE TAPECOPY TAPELABEL
          TEMPLATE TIMEDATA TIMEID TIMEPLOT TIMESERIES TPSPLINE TRANSPOSE
          TRANSREG TRANTAB TREE TSCSREG TTEST UCM UNIVARIATE UPLOAD VARCLUS
          VARCOMP VARIOGRAM VARMAX VASMP X11 X12 X13 XSL
        )
      end

      state :basics do
        # Rules to be parsed before the keywords (which are different depending
        # on the context)

        rule %r/\s+/m, Text

        # Single-line comments (between * and ;) - these can actually go onto multiple lines
        # case 1 - where it starts a line
        rule %r/^\s*%?\*[^;]*;/m, Comment::Single
        # case 2 - where it follows the previous statement on the line (after a semicolon)
        rule %r/(;)(\s*)(%?\*[^;]*;)/m do
          groups Punctuation, Text, Comment::Single
        end

        # True multiline comments!
        rule %r(/[*].*?[*]/)m, Comment::Multiline

        # date/time constants (Language Reference pp91-2)
        rule %r/'[0-9a-z]+?'d/i, Literal::Date
        rule %r/'.+?'dt/i, Literal::Date
        rule %r/'[0-9:]+?([a|p]m)?'t/i, Literal::Date

        rule %r/'/, Str::Single, :single_string
        rule %r/"/, Str::Double, :double_string
        rule %r/&[a-z0-9_&.]+/i, Name::Variable

        # numeric constants (Language Reference p91)
        rule %r/\d[0-9a-f]*x/i, Num::Hex
        rule %r/\d[0-9e\-.]+/i, Num # scientific notation

        # auto variables from DATA step (Language Reference p46, p37)
        rule %r/\b(_n_|_error_|_file_|_infile_|_msg_|_iorc_|_cmd_)\b/i, Name::Builtin::Pseudo

        # auto variable list names
        rule %r/\b(_character_|_numeric_|_all_)\b/i, Name::Builtin

        # datalines/cards etc
        rule %r/\b(datalines|cards)(\s*)(;)/i do
          groups Keyword, Text, Punctuation
          push :datalines
        end
        rule %r/\b(datalines4|cards4)(\s*)(;)/i do
          groups Keyword, Text, Punctuation
          push :datalines4
        end


        # operators (Language Reference p96)
        rule %r(\*\*|[\*/\+-]), Operator
        rule %r/[^¬~]?=:?|[<>]=?:?/, Operator
        rule %r/\b(eq|ne|gt|lt|ge|le|in)\b/i, Operator::Word
        rule %r/[&|!¦¬∘~]/, Operator
        rule %r/\b(and|or|not)\b/i, Operator::Word
        rule %r/(<>|><)/, Operator # min/max
        rule %r/\|\|/, Operator # concatenation

        # The OF operator should also be highlighted (Language Reference p49)
        rule %r/\b(of)\b/i, Operator::Word
        rule %r/\b(like)\b/i, Operator::Word # Language Ref p181
      
        rule %r/\d+/, Num::Integer

        rule %r/\$/, Keyword::Type

        # Macro definitions
        rule %r/(%macro|%mend)(\s*)(\w+)/i do
          groups Keyword, Text, Name::Function
        end
        rule %r/%mend/, Keyword

        rule %r/%\w+/ do |m|
          if self.class.sas_macro_statements.include? m[0].upcase
            token Keyword
          elsif self.class.sas_macro_functions.include? m[0].upcase
            token Keyword
          else
            token Name
          end
        end
      end

      state :basics2 do
        # Rules to be parsed after the keywords (which are different depending
        # on the context)

        # Missing values (Language Reference p81)
        rule %r/\s\.[;\s]/, Keyword::Constant # missing
        rule %r/\s\.[a-z_]/, Name::Constant # user-defined missing

        rule %r/[\(\),;:\{\}\[\]\\\.]/, Punctuation

        rule %r/@/, Str::Symbol # line hold specifiers
        rule %r/\?/, Str::Symbol # used for format modifiers
        
        rule %r/[^\s]+/, Text # Fallback for anything we haven't matched so far
      end

      state :root do
        mixin :basics

        # PROC definitions
        rule %r!(proc)(\s+)(\w+)!ix do |m|
          @proc_name = m[3].upcase
          puts "    proc name: #{@proc_name}" if @debug
          if self.class.sas_proc_names.include? @proc_name
            groups Keyword, Text, Keyword
          else
            groups Keyword, Text, Name
          end
        
          push :proc
        end

        # Data step definitions
        rule %r/(data)(\s+)([\w\.]+)/i do
          groups Keyword, Text, Name::Variable
        end
        # Libname definitions
        rule %r/(libname)(\s+)(\w+)/i do
          groups Keyword, Text, Name::Variable
        end

        rule %r/\w+/ do |m|
          if self.class.data_step_statements.include? m[0].upcase
            token Keyword
          elsif self.class.sas_functions.include? m[0].upcase
            token Keyword
          else
            token Name
          end
        end

         mixin :basics2
      end


      state :single_string do
        rule %r/''/, Str::Escape
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/, Str::Single
      end

      state :double_string do
        rule %r/&[a-z0-9_&]+\.?/i, Str::Interpol
        rule %r/""/, Str::Escape
        rule %r/"/, Str::Double, :pop!

        rule %r/[^&"]+/, Str::Double
        # Allow & to be used as character if not already matched as macro variable
        rule %r/&/, Str::Double
      end

      state :datalines do
        rule %r/[^;]/, Literal::String::Heredoc
        rule %r/;/, Punctuation, :pop!
      end

      state :datalines4 do
        rule %r/;{4}/, Punctuation, :pop!
        rule %r/[^;]/, Literal::String::Heredoc
        rule %r/;{,3}/, Literal::String::Heredoc
      end


      # PROCS
      state :proc do
        rule %r/(quit|run)/i, Keyword, :pop!
        
        mixin :basics
        rule %r/\w+/ do |m|
          if self.class.data_step_statements.include? m[0].upcase
            token Keyword
          elsif self.class.sas_functions.include? m[0].upcase
            token Keyword
          elsif self.class.proc_keywords.has_key?(@proc_name) and self.class.proc_keywords[@proc_name].include? m[0].upcase
            token Keyword
          else
            token Name
          end
        end

         mixin :basics2
      end

    end #class SAS
  end #module Lexers
end #module Rouge
