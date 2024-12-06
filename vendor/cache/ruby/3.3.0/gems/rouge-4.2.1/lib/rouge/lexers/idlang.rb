# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# vim: set ts=2 sw=2 et:

module Rouge
  module Lexers
    class IDLang < RegexLexer
      title "IDL"
      desc "Interactive Data Language"

      tag 'idlang'
      filenames '*.idl'

      name = /[_A-Z]\w*/i
      kind_param = /(\d+|#{name})/
      exponent = /[dDeE][+-]\d+/

      def self.exec_unit
        @exec_unit ||= Set.new %w(
          PRO FUNCTION
        )
      end

      def self.keywords
        @keywords ||= Set.new %w(
          STRUCT INHERITS
          RETURN CONTINUE BEGIN END BREAK GOTO
        )
      end

      def self.standalone_statements
        # Must not have a comma afterwards
        @standalone_statements ||= Set.new %w(
          COMMON FORWARD_FUNCTION
        )
      end

      def self.decorators
        # Must not have a comma afterwards
        @decorators ||= Set.new %w(
          COMPILE_OPT
        )
      end

      def self.operators
        @operators ||= Set.new %w(
          AND= EQ= GE= GT= LE= LT= MOD= NE= OR= XOR= NOT=
        )
      end

      def self.conditionals
        @conditionals ||= Set.new %w(
          OF DO ENDIF ENDELSE ENDFOR ENDFOREACH ENDWHILE ENDREP ENDCASE ENDSWITCH
          IF THEN ELSE FOR FOREACH WHILE REPEAT UNTIL CASE SWITCH
          AND EQ GE GT LE LT MOD NE OR XOR NOT
        )
      end

      def self.routines
        @routines ||= Set.new %w(
          A_CORRELATE ABS ACOS ADAPT_HIST_EQUAL ALOG ALOG10
          AMOEBA ANNOTATE ARG_PRESENT ARRAY_EQUAL
          ARRAY_INDICES ARROW ASCII_TEMPLATE ASIN ASSOC ATAN
          AXIS BAR_PLOT BESELI BESELJ BESELK BESELY BETA
          BILINEAR BIN_DATE BINARY_TEMPLATE BINDGEN BINOMIAL
          BLAS_AXPY BLK_CON BOX_CURSOR BREAK BREAKPOINT
          BROYDEN BYTARR BYTE BYTEORDER BYTSCL C_CORRELATE
          CALDAT CALENDAR CALL_EXTERNAL CALL_FUNCTION
          CALL_METHOD CALL_PROCEDURE CATCH CD CEIL CHEBYSHEV
          CHECK_MATH CHISQR_CVF CHISQR_PDF CHOLDC CHOLSOL
          CINDGEN CIR_3PNT CLOSE CLUST_WTS CLUSTER
          COLOR_CONVERT COLOR_QUAN COLORMAP_APPLICABLE COMFIT
          COMPLEX COMPLEXARR COMPLEXROUND
          COMPUTE_MESH_NORMALS COND CONGRID CONJ
          CONSTRAINED_MIN CONTOUR CONVERT_COORD CONVOL
          COORD2TO3 CORRELATE COS COSH CRAMER CREATE_STRUCT
          CREATE_VIEW CROSSP CRVLENGTH CT_LUMINANCE CTI_TEST
          CURSOR CURVEFIT CV_COORD CVTTOBM CW_ANIMATE
          CW_ANIMATE_GETP CW_ANIMATE_LOAD CW_ANIMATE_RUN
          CW_ARCBALL CW_BGROUP CW_CLR_INDEX CW_COLORSEL
          CW_DEFROI CW_FIELD CW_FILESEL CW_FORM CW_FSLIDER
          CW_LIGHT_EDITOR CW_LIGHT_EDITOR_GET
          CW_LIGHT_EDITOR_SET CW_ORIENT CW_PALETTE_EDITOR
          CW_PALETTE_EDITOR_GET CW_PALETTE_EDITOR_SET
          CW_PDMENU CW_RGBSLIDER CW_TMPL CW_ZOOM DBLARR
          DCINDGEN DCOMPLEX DCOMPLEXARR DEFINE_KEY DEFROI
          DEFSYSV DELETE_SYMBOL DELLOG DELVAR DERIV DERIVSIG
          DETERM DEVICE DFPMIN DIALOG_MESSAGE
          DIALOG_PICKFILE DIALOG_PRINTERSETUP
          DIALOG_PRINTJOB DIALOG_READ_IMAGE
          DIALOG_WRITE_IMAGE DICTIONARY DIGITAL_FILTER DILATE DINDGEN
          DISSOLVE DIST DLM_LOAD DLM_REGISTER
          DO_APPLE_SCRIPT DOC_LIBRARY DOUBLE DRAW_ROI EFONT
          EIGENQL EIGENVEC ELMHES EMPTY ENABLE_SYSRTN EOF
          ERASE ERODE ERRORF ERRPLOT EXECUTE EXIT EXP EXPAND
          EXPAND_PATH EXPINT EXTRAC EXTRACT_SLICE F_CVF
          F_PDF FACTORIAL FFT FILE_CHMOD FILE_DELETE
          FILE_EXPAND_PATH FILE_MKDIR FILE_TEST FILE_WHICH
          FILE_SEARCH PATH_SEP FILE_DIRNAME FILE_BASENAME
          FILE_INFO FILE_MOVE FILE_COPY FILE_LINK FILE_POLL_INPUT
          FILEPATH FINDFILE FINDGEN FINITE FIX FLICK FLOAT
          FLOOR FLOW3 FLTARR FLUSH FORMAT_AXIS_VALUES
          FORWARD_FUNCTION FREE_LUN FSTAT FULSTR FUNCT
          FV_TEST FX_ROOT FZ_ROOTS GAMMA GAMMA_CT
          GAUSS_CVF GAUSS_PDF GAUSS2DFIT GAUSSFIT GAUSSINT
          GET_DRIVE_LIST GET_KBRD GET_LUN GET_SCREEN_SIZE
          GET_SYMBOL GETENV GOTO GREG2JUL GRID_TPS GRID3 GS_ITER
          H_EQ_CT H_EQ_INT HANNING HASH HEAP_GC HELP HILBERT
          HIST_2D HIST_EQUAL HISTOGRAM HLS HOUGH HQR HSV
          IBETA IDENTITY IDL_CONTAINER IDLANROI
          IDLANROIGROUP IDLFFDICOM IDLFFDXF IDLFFLANGUAGECAT
          IDLFFSHAPE IDLGRAXIS IDLGRBUFFER IDLGRCLIPBOARD
          IDLGRCOLORBAR IDLGRCONTOUR IDLGRFONT IDLGRIMAGE
          IDLGRLEGEND IDLGRLIGHT IDLGRMODEL IDLGRMPEG
          IDLGRPALETTE IDLGRPATTERN IDLGRPLOT IDLGRPOLYGON
          IDLGRPOLYLINE IDLGRPRINTER IDLGRROI IDLGRROIGROUP
          IDLGRSCENE IDLGRSURFACE IDLGRSYMBOL
          IDLGRTESSELLATOR IDLGRTEXT IDLGRVIEW
          IDLGRVIEWGROUP IDLGRVOLUME IDLGRVRML IDLGRWINDOW
          IGAMMA IMAGE_CONT IMAGE_STATISTICS IMAGINARY
          INDGEN INT_2D INT_3D INT_TABULATED INTARR INTERPOL
          INTERPOLATE INVERT IOCTL ISA ISHFT ISOCONTOUR
          ISOSURFACE JOURNAL JUL2GREG JULDAY KEYWORD_SET KRIG2D
          KURTOSIS KW_TEST L64INDGEN LABEL_DATE LABEL_REGION
          LADFIT LAGUERRE LEEFILT LEGENDRE LINBCG LINDGEN
          LINFIT LINKIMAGE LIST LIVE_CONTOUR LIVE_CONTROL
          LIVE_DESTROY LIVE_EXPORT LIVE_IMAGE LIVE_INFO
          LIVE_LINE LIVE_LOAD LIVE_OPLOT LIVE_PLOT
          LIVE_PRINT LIVE_RECT LIVE_STYLE LIVE_SURFACE
          LIVE_TEXT LJLCT LL_ARC_DISTANCE LMFIT LMGR LNGAMMA
          LNP_TEST LOADCT LOCALE_GET LON64ARR LONARR LONG
          LONG64 LSODE LU_COMPLEX LUDC LUMPROVE LUSOL
          M_CORRELATE MACHAR MAKE_ARRAY MAKE_DLL MAP_2POINTS
          MAP_CONTINENTS MAP_GRID MAP_IMAGE MAP_PATCH
          MAP_PROJ_INFO MAP_SET MAX MATRIX_MULTIPLY MD_TEST MEAN
          MEANABSDEV MEDIAN MEMORY MESH_CLIP MESH_DECIMATE
          MESH_ISSOLID MESH_MERGE MESH_NUMTRIANGLES MESH_OBJ
          MESH_SMOOTH MESH_SURFACEAREA MESH_VALIDATE
          MESH_VOLUME MESSAGE MIN MIN_CURVE_SURF MK_HTML_HELP
          MODIFYCT MOMENT MORPH_CLOSE MORPH_DISTANCE
          MORPH_GRADIENT MORPH_HITORMISS MORPH_OPEN
          MORPH_THIN MORPH_TOPHAT MPEG_CLOSE MPEG_OPEN
          MPEG_PUT MPEG_SAVE MSG_CAT_CLOSE MSG_CAT_COMPILE
          MSG_CAT_OPEN MULTI N_ELEMENTS N_PARAMS N_TAGS
          NEWTON NORM OBJ_CLASS OBJ_DESTROY OBJ_ISA OBJ_NEW
          OBJ_VALID OBJARR ON_ERROR ON_IOERROR ONLINE_HELP
          OPEN OPENR OPENW OPENU OPLOT OPLOTERR ORDEREDHASH P_CORRELATE
          PARTICLE_TRACE PCOMP PLOT PLOT_3DBOX PLOT_FIELD
          PLOTERR PLOTS PNT_LINE POINT_LUN POLAR_CONTOUR
          POLAR_SURFACE POLY POLY_2D POLY_AREA POLY_FIT
          POLYFILL POLYFILLV POLYSHADE POLYWARP POPD POWELL
          PRIMES PRINT PRINTF PRINTD PRODUCT PROFILE PROFILER
          PROFILES PROJECT_VOL PS_SHOW_FONTS PSAFM PSEUDO
          PTR_FREE PTR_NEW PTR_VALID PTRARR PUSHD QROMB
          QROMO QSIMP QUERY_CSV R_CORRELATE R_TEST RADON RANDOMN
          RANDOMU RANKS RDPIX READ READF READ_ASCII
          READ_BINARY READ_BMP READ_CSV READ_DICOM READ_IMAGE
          READ_INTERFILE READ_JPEG READ_PICT READ_PNG
          READ_PPM READ_SPR READ_SRF READ_SYLK READ_TIFF
          READ_WAV READ_WAVE READ_X11_BITMAP READ_XWD READS
          READU REBIN RECALL_COMMANDS RECON3 REDUCE_COLORS
          REFORM REGRESS REPLICATE REPLICATE_INPLACE
          RESOLVE_ALL RESOLVE_ROUTINE RESTORE RETALL
          REVERSE REWIND RK4 ROBERTS ROT ROTATE ROUND
          ROUTINE_INFO RS_TEST S_TEST SAVE SAVGOL SCALE3
          SCALE3D SCOPE_LEVEL SCOPE_TRACEBACK SCOPE_VARFETCH
          SCOPE_VARNAME SEARCH2D SEARCH3D SET_PLOT SET_SHADING
          SET_SYMBOL SETENV SETLOG SETUP_KEYS SFIT
          SHADE_SURF SHADE_SURF_IRR SHADE_VOLUME SHIFT SHOW3
          SHOWFONT SIGNUM SIN SINDGEN SINH SIZE SKEWNESS SKIPF
          SLICER3 SLIDE_IMAGE SMOOTH SOBEL SOCKET SORT SPAWN
          SPH_4PNT SPH_SCAT SPHER_HARM SPL_INIT SPL_INTERP
          SPLINE SPLINE_P SPRSAB SPRSAX SPRSIN SPRSTP SQRT
          STANDARDIZE STDDEV STOP STRARR STRCMP STRCOMPRESS
          STREAMLINE STREGEX STRETCH STRING STRJOIN STRLEN
          STRLOWCASE STRMATCH STRMESSAGE STRMID STRPOS
          STRPUT STRSPLIT STRTRIM STRUCT_ASSIGN STRUCT_HIDE
          STRUPCASE SURFACE SURFR SVDC SVDFIT SVSOL
          SWAP_ENDIAN SWITCH SYSTIME T_CVF T_PDF T3D
          TAG_NAMES TAN TANH TAPRD TAPWRT TEK_COLOR
          TEMPORARY TETRA_CLIP TETRA_SURFACE TETRA_VOLUME
          THIN THREED TIME_TEST2 TIMEGEN TM_TEST TOTAL TRACE
          TRANSPOSE TRI_SURF TRIANGULATE TRIGRID TRIQL
          TRIRED TRISOL TRNLOG TS_COEF TS_DIFF TS_FCAST
          TS_SMOOTH TV TVCRS TVLCT TVRD TVSCL TYPENAME UINDGEN UINT
          UINTARR UL64INDGEN ULINDGEN ULON64ARR ULONARR
          ULONG ULONG64 UNIQ USERSYM VALUE_LOCATE VARIANCE
          VAX_FLOAT VECTOR_FIELD VEL VELOVECT VERT_T3D VOIGT
          VORONOI VOXEL_PROJ WAIT WARP_TRI WATERSHED WDELETE
          WEOF WF_DRAW WHERE WIDGET_BASE WIDGET_BUTTON
          WIDGET_CONTROL WIDGET_DRAW WIDGET_DROPLIST
          WIDGET_EVENT WIDGET_INFO WIDGET_LABEL WIDGET_LIST
          WIDGET_SLIDER WIDGET_TABLE WIDGET_TEXT WINDOW
          WRITE_BMP WRITE_CSV WRITE_IMAGE WRITE_JPEG WRITE_NRIF
          WRITE_PICT WRITE_PNG WRITE_PPM WRITE_SPR WRITE_SRF
          WRITE_SYLK WRITE_TIFF WRITE_WAV WRITE_WAVE WRITEU
          WSET WSHOW WTN WV_APPLET WV_CW_WAVELET WV_CWT
          WV_DENOISE WV_DWT WV_FN_COIFLET WV_FN_DAUBECHIES
          WV_FN_GAUSSIAN WV_FN_HAAR WV_FN_MORLET WV_FN_PAUL
          WV_FN_SYMLET WV_IMPORT_DATA WV_IMPORT_WAVELET
          WV_PLOT3D_WPS WV_PLOT_MULTIRES WV_PWT
          WV_TOOL_DENOISE XBM_EDIT XDISPLAYFILE XDXF XFONT
          XINTERANIMATE XLOADCT XMANAGER XMNG_TMPL XMTOOL
          XOBJVIEW XPALETTE XPCOLOR XPLOT3D XREGISTERED XROI
          XSQ_TEST XSURFACE XVAREDIT XVOLUME XVOLUME_ROTATE
          XVOLUME_WRITE_IMAGE XYOUTS ZOOM ZOOM_24
        )
      end

      state :root do
        rule %r/\s+/, Text::Whitespace
        # Normal comments
        rule %r/;.*$/, Comment::Single
        rule %r/\,\s*\,/, Error
        rule %r/\!#{name}/, Name::Variable::Global

        rule %r/[(),:\&\$]/, Punctuation

        ## Format statements are quite a strange beast.
        ## Better process them in their own state.
        #rule %r/\b(FORMAT)(\s*)(\()/mi do |m|
        #  token Keyword, m[1]
        #  token Text::Whitespace, m[2]
        #  token Punctuation, m[3]
        #  push :format_spec
        #end

        rule %r(
          [+-]? # sign
          (
            (\d+[.]\d*|[.]\d+)(#{exponent})?
            | \d+#{exponent} # exponent is mandatory
          )
          (_#{kind_param})? # kind parameter
        )xi, Num::Float

        rule %r/\d+(B|S|U|US|LL|L|ULL|UL)?/i, Num::Integer
        rule %r/"[0-7]+(B|O|U|ULL|UL|LL|L)?/i, Num::Oct
        rule %r/'[0-9A-F]+'X(B|S|US|ULL|UL|U|LL|L)?/i, Num::Hex
        rule %r/(#{kind_param}_)?'/, Str::Single, :string_single
        rule %r/(#{kind_param}_)?"/, Str::Double, :string_double

        rule %r{\#\#|\#|\&\&|\|\||/=|<=|>=|->|\@|\?|[-+*/<=~^{}]}, Operator
        # Structures and the like
        rule %r/(#{name})(\.)([^\s,]*)/i do
          groups Name, Operator, Name
          #delegate IDLang, m[3]
        end

        rule %r/(function|pro)((?:\s|\$\s)+)/i do
          groups Keyword, Text::Whitespace
          push :funcname
        end

        rule %r/#{name}/m do |m|
          match = m[0].upcase
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.conditionals.include? match
            token Keyword
          elsif self.class.decorators.include? match
            token Name::Decorator
          elsif self.class.standalone_statements.include? match
            token Keyword::Reserved
          elsif self.class.operators.include? match
            token Operator::Word
          elsif self.class.routines.include? match
            token Name::Builtin
          else
            token Name
          end
        end

      end

      state :funcname do
        rule %r/#{name}/, Name::Function

        rule %r/\s+/, Text::Whitespace
        rule %r/(:+|\$)/, Operator
        rule %r/;.*/, Comment::Single

        # Be done with this state if we hit EOL or comma
        rule %r/$/, Text::Whitespace, :pop!
        rule %r/,/, Operator, :pop!
      end

      state :string_single do
        rule %r/[^']+/, Str::Single
        rule %r/''/, Str::Escape
        rule %r/'/, Str::Single, :pop!
      end

      state :string_double do
        rule %r/[^"]+/, Str::Double
        rule %r/"/, Str::Double, :pop!
      end

      state :format_spec do
        rule %r/'/, Str::Single, :string_single
        rule %r/"/, Str::Double, :string_double
        rule %r/\(/, Punctuation, :format_spec
        rule %r/\)/, Punctuation, :pop!
        rule %r/,/, Punctuation
        rule %r/\s+/, Text::Whitespace
        # Edit descriptors could be seen as a kind of "format literal".
        rule %r/[^\s'"(),]+/, Literal
      end
    end
  end
end
