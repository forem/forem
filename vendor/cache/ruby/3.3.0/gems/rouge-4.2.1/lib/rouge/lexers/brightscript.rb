# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Brightscript < RegexLexer
      title "BrightScript"
      desc "BrightScript Programming Language (https://developer.roku.com/en-ca/docs/references/brightscript/language/brightscript-language-reference.md)"
      tag 'brightscript'
      aliases 'bs', 'brs'
      filenames '*.brs'

      # https://developer.roku.com/en-ca/docs/references/brightscript/language/global-utility-functions.md
      # https://developer.roku.com/en-ca/docs/references/brightscript/language/global-string-functions.md
      # https://developer.roku.com/en-ca/docs/references/brightscript/language/global-math-functions.md
      def self.name_builtin
        @name_builtin ||= Set.new %w(
          ABS ASC ATN CDBL CHR CINT CONTROL COPYFILE COS CREATEDIRECTORY CSNG
          DELETEDIRECTORY DELETEFILE EXP FINDMEMBERFUNCTION FINDNODE FIX
          FORMATDRIVEFORMATJSON GETINTERFACE INSTR INT LCASE LEFT LEN LISTDIR
          LOG MATCHFILES MID MOVEFILE OBSERVEFIELD PARSEJSON PARSEXML
          READASCIIFILE REBOOTSYSTEM RIGHT RND RUNGARBAGECOLLECTOR SGN SIN
          SLEEP SQR STR STRI STRING STRINGI STRTOI SUBSTITUTE TANTEXTTOP TEXT
          TRUCASE UPTIME VALVISIBLE VISIBLE WAIT
        )
      end

      # https://developer.roku.com/en-ca/docs/references/brightscript/language/reserved-words.md
      def self.keyword_reserved
        @keyword_reserved ||= Set.new %w(
          BOX CREATEOBJECT DIM EACH ELSE ELSEIF END ENDFUNCTION ENDIF ENDSUB
          ENDWHILE EVAL EXIT EXITWHILE FALSE FOR FUNCTION GETGLOBALAA
          GETLASTRUNCOMPILEERROR GETLASTRUNRUNTIMEERROR GOTO IF IN INVALID LET
          LINE_NUM M NEXT OBJFUN POS PRINT REM RETURN RUN STEP STOP SUB TAB TO
          TRUE TYPE WHILE
        )
      end

      # These keywords are present in BrightScript, but not supported in standard .brs files
      def self.keyword_reserved_unsupported
        @keyword_reserved_unsupported ||= Set.new %w(
          CLASS CONST IMPORT LIBRARY NAMESPACE PRIVATE PROTECTED PUBLIC
        )
      end

      # https://developer.roku.com/en-ca/docs/references/brightscript/language/expressions-variables-types.md
      def self.keyword_type
        @keyword_type ||= Set.new %w(
          BOOLEAN DIM DOUBLE DYNAMIC FLOAT FUNCTION INTEGER INTERFACE INVALID
          LONGINTEGER OBJECT STRING VOID
        )
      end

      # https://developer.roku.com/en-ca/docs/references/brightscript/language/expressions-variables-types.md#operators
      def self.operator_word
        @operator_word ||= Set.new %w(
          AND AS MOD NOT OR THEN
        )
      end

      # Scene graph components configured as builtins. See BrightScript component documentation e.g.
      # https://developer.roku.com/en-ca/docs/references/brightscript/components/roappinfo.md
      def self.builtins
        @builtins ||= Set.new %w(
          roAppendFile roAppInfo roAppManager roArray roAssociativeArray
          roAudioGuide roAudioMetadata roAudioPlayer roAudioPlayerEvent
          roAudioResourceroBitmap roBoolean roBoolean roBrightPackage roBrSub
          roButton roByteArray roCaptionRenderer roCaptionRendererEvent
          roCecInterface roCECStatusEvent roChannelStore roChannelStoreEvent
          roClockWidget roCodeRegistrationScreen
          roCodeRegistrationScreenEventroCompositor roControlDown roControlPort
          roControlPort roControlUp roCreateFile roDatagramReceiver
          roDatagramSender roDataGramSocket roDateTime roDeviceInfo
          roDeviceInfoEvent roDoubleroEVPCipher roEVPDigest roFileSystem
          roFileSystemEvent roFloat roFont roFontMetrics roFontRegistry
          roFunction roGlobal roGpio roGridScreen roGridScreenEvent
          roHdmiHotPlugEventroHdmiStatus roHdmiStatusEvent roHMAC roHttpAgent
          roImageCanvas roImageCanvasEvent roImageMetadata roImagePlayer
          roImageWidgetroInput roInputEvent roInt roInt roInvalid roInvalid
          roIRRemote roKeyboard roKeyboardPress roKeyboardScreen
          roKeyboardScreenEventroList roListScreen roListScreenEvent
          roLocalization roLongInteger roMessageDialog roMessageDialogEvent
          roMessagePort roMicrophone roMicrophoneEvent roNetworkConfiguration
          roOneLineDialog roOneLineDialogEventroParagraphScreen
          roParagraphScreenEvent roPath roPinEntryDialog roPinEntryDialogEvent
          roPinentryScreen roPosterScreen roPosterScreenEventroProgramGuide
          roQuadravoxButton roReadFile roRectangleroRegexroRegion roRegistry
          roRegistrySection roResourceManager roRSA roRssArticle roRssParser
          roScreen roSearchHistory roSearchScreen roSearchScreenEvent
          roSerialPort roSGNode roSGNodeEvent roSGScreenroSGScreenEvent
          roSlideShowroSlideShowEvent roSNS5 roSocketAddress roSocketEvent
          roSpringboardScreen roSpringboardScreenEventroSprite roStorageInfo
          roStreamSocket roStringroSystemLogroSystemLogEvent roSystemTime
          roTextFieldroTextScreen roTextScreenEvent roTextToSpeech
          roTextToSpeechEvent roTextureManager roTextureRequest
          roTextureRequestEventroTextWidget roTimer roTimespan roTouchScreen
          roTunerroTunerEvent roUniversalControlEvent roUrlEvent roUrlTransfer
          roVideoEvent roVideoInput roVideoMode roVideoPlayer roVideoPlayerEvent
          roVideoScreen roVideoScreenEventroWriteFile roXMLElement roXMLList
        )
      end

      id = /[$a-z_][a-z0-9_]*/io

      state :root do
        rule %r/\s+/m, Text::Whitespace

        # https://developer.roku.com/en-ca/docs/references/brightscript/language/expressions-variables-types.md#comments
        rule %r/\'.*/, Comment::Single
        rule %r/REM.*/i, Comment::Single

        # https://developer.roku.com/en-ca/docs/references/brightscript/language/expressions-variables-types.md#operators
        rule %r([~!%^&*+=\|?:<>/-]), Operator

        rule %r/\d*\.\d+(e-?\d+)?/i, Num::Float
        rule %r/\d+[lu]*/i, Num::Integer

        rule %r/".*?"/, Str::Double

        rule %r/#{id}(?=\s*[(])/, Name::Function

        rule %r/[()\[\],.;{}]/, Punctuation

        rule id do |m|
          caseSensitiveChunk = m[0]
          caseInsensitiveChunk = m[0].upcase

          if self.class.builtins.include?(caseSensitiveChunk)
            token Keyword::Reserved
          elsif self.class.keyword_reserved.include?(caseInsensitiveChunk)
            token Keyword::Reserved
          elsif self.class.keyword_reserved_unsupported.include?(caseInsensitiveChunk)
            token Keyword::Reserved
          elsif self.class.keyword_type.include?(caseInsensitiveChunk)
            token Keyword::Type
          elsif self.class.name_builtin.include?(caseInsensitiveChunk)
            token Name::Builtin
          elsif self.class.operator_word.include?(caseInsensitiveChunk)
            token Operator::Word
          else
            token Name
          end
        end
      end
    end
  end
end
