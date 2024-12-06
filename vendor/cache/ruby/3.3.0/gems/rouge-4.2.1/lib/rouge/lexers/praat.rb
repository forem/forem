# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Praat < RegexLexer
      title "Praat"
      desc "The Praat scripting language (praat.org)"

      tag 'praat'

      filenames '*.praat', '*.proc', '*.psc'

      def self.detect?(text)
        return true if text.shebang? 'praat'
      end

      def self.keywords
        @keywords ||= %w(
          if then else elsif elif endif fi for from to endfor endproc while
          endwhile repeat until select plus minus demo assert stopwatch
          nocheck nowarn noprogress editor endeditor clearinfo
        )
      end

      def self.functions_string
        @functions_string ||= %w(
          backslashTrigraphsToUnicode$ chooseDirectory$ chooseReadFile$
          chooseWriteFile$ date$ demoKey$ do$ environment$ extractLine$ extractWord$
          fixed$ info$ left$ mid$ percent$ readFile$ replace$ replace_regex$ right$
          selected$ string$ unicodeToBackslashTrigraphs$
        )
      end

      def self.functions_numeric
        @functions_numeric ||= %w(
          abs appendFile appendFileLine appendInfo appendInfoLine arccos arccosh
          arcsin arcsinh arctan arctan2 arctanh barkToHertz beginPause
          beginSendPraat besselI besselK beta beta2 binomialP binomialQ boolean
          ceiling chiSquareP chiSquareQ choice comment cos cosh createDirectory
          deleteFile demoClicked demoClickedIn demoCommandKeyPressed
          demoExtraControlKeyPressed demoInput demoKeyPressed
          demoOptionKeyPressed demoShiftKeyPressed demoShow demoWaitForInput
          demoWindowTitle demoX demoY differenceLimensToPhon do editor endPause
          endSendPraat endsWith erb erbToHertz erf erfc exitScript exp
          extractNumber fileReadable fisherP fisherQ floor gaussP gaussQ hash
          hertzToBark hertzToErb hertzToMel hertzToSemitones imax imin
          incompleteBeta incompleteGammaP index index_regex integer invBinomialP
          invBinomialQ invChiSquareQ invFisherQ invGaussQ invSigmoid invStudentQ
          length ln lnBeta lnGamma log10 log2 max melToHertz min minusObject
          natural number numberOfColumns numberOfRows numberOfSelected
          objectsAreIdentical option optionMenu pauseScript
          phonToDifferenceLimens plusObject positive randomBinomial randomGauss
          randomInteger randomPoisson randomUniform real readFile removeObject
          rindex rindex_regex round runScript runSystem runSystem_nocheck
          selectObject selected semitonesToHertz sentence sentencetext sigmoid
          sin sinc sincpi sinh soundPressureToPhon sqrt startsWith studentP
          studentQ tan tanh text variableExists word writeFile writeFileLine
          writeInfo writeInfoLine
        )
      end

      def self.functions_array
        @functions_array ||= %w(
          linear# randomGauss# randomInteger# randomUniform# zero#
        )
      end

      def self.functions_matrix
        @functions_matrix ||= %w(
          linear## mul## mul_fast## mul_metal## mul_nt## mul_tn## mul_tt## outer## peaks##
          randomGamma## randomGauss## randomInteger## randomUniform## softmaxPerRow##
          solve## transpose## zero##
        )
      end

      def self.functions_string_vector
        @functions_string_vector ||= %w(
          empty$# fileNames$# folderNames$# readLinesFromFile$# splitByWhitespace$#
        )
      end

      def self.functions_builtin
        @functions_builtin ||=
          self.functions_string |
          self.functions_numeric |
          self.functions_array |
          self.functions_matrix |
          self.functions_string_vector
      end

      def self.objects
        @objects ||= %w(
          Activation AffineTransform AmplitudeTier Art Artword Autosegment
          BarkFilter BarkSpectrogram CCA Categories Cepstrogram Cepstrum
          Cepstrumc ChebyshevSeries ClassificationTable Cochleagram Collection
          ComplexSpectrogram Configuration Confusion ContingencyTable Corpus
          Correlation Covariance CrossCorrelationTable CrossCorrelationTableList
          CrossCorrelationTables DTW DataModeler Diagonalizer Discriminant
          Dissimilarity Distance Distributions DurationTier EEG ERP ERPTier
          EditCostsTable EditDistanceTable Eigen Excitation Excitations
          ExperimentMFC FFNet FeatureWeights FileInMemory FilesInMemory Formant
          FormantFilter FormantGrid FormantModeler FormantPoint FormantTier
          GaussianMixture HMM HMM_Observation HMM_ObservationSequence HMM_State
          HMM_StateSequence HMMObservation HMMObservationSequence HMMState
          HMMStateSequence Harmonicity ISpline Index Intensity IntensityTier
          IntervalTier KNN KlattGrid KlattTable LFCC LPC Label LegendreSeries
          LinearRegression LogisticRegression LongSound Ltas MFCC MSpline ManPages
          Manipulation Matrix MelFilter MelSpectrogram MixingMatrix Movie Network
          OTGrammar OTHistory OTMulti PCA PairDistribution ParamCurve Pattern
          Permutation Photo Pitch PitchModeler PitchTier PointProcess Polygon
          Polynomial PowerCepstrogram PowerCepstrum Procrustes RealPoint RealTier
          ResultsMFC Roots SPINET SSCP SVD Salience ScalarProduct Similarity
          SimpleString SortedSetOfString Sound Speaker Spectrogram Spectrum
          SpectrumTier SpeechSynthesizer SpellingChecker Strings StringsIndex
          Table TableOfReal TextGrid TextInterval TextPoint TextTier Tier
          Transition VocalTract VocalTractTier Weight WordList
        )
      end

      def self.variables_numeric
        @variables_numeric ||= %w(
          all average e left macintosh mono pi praatVersion right stereo
          undefined unix windows
        )
      end

      def self.variables_string
        @variables_string ||= %w(
          praatVersion$ tab$ shellDirectory$ homeDirectory$
          preferencesDirectory$ newline$ temporaryDirectory$
          defaultDirectory$
        )
      end

      def self.object_attributes
        @object_attributes ||= %w(
          ncol nrow xmin ymin xmax ymax nx ny dx dy
        )
      end

      state :root do
        rule %r/(\s+)(#.*?$)/ do
          groups Text, Comment::Single
        end

        rule %r/^#.*?$/, Comment::Single
        rule %r/;[^\n]*/, Comment::Single
        rule %r/\s+/, Text

        rule %r/(\bprocedure)(\s+)/ do
          groups Keyword, Text
          push :procedure_definition
        end

        rule %r/(\bcall)(\s+)/ do
          groups Keyword, Text
          push :procedure_call
        end

        rule %r/@/, Name::Function, :procedure_call

        mixin :function_call

        rule %r/\b(?:select all)\b/, Keyword

        rule %r/(\bform\b)(\s+)([^\n]+)/ do
          groups Keyword, Text, Literal::String
          push :old_form
        end

        rule %r/(print(?:line|tab)?|echo|exit|asserterror|pause|send(?:praat|socket)|include|execute|system(?:_nocheck)?)(\s+)/ do
          groups Keyword, Text
          push :string_unquoted
        end

        rule %r/(goto|label)(\s+)(\w+)/ do
          groups Keyword, Text, Name::Label
        end

        mixin :variable_name
        mixin :number
        mixin :vector_literal

        rule %r/"/, Literal::String, :string

        rule %r/\b([A-Z][a-zA-Z0-9]+)(?=\s+\S+\n)/ do |m|
          match = m[0]
          if self.class.objects.include?(match)
            token Name::Class
            push :string_unquoted
          else
            token Keyword
          end
        end

        rule %r/\b(?=[A-Z])/, Text, :command
        rule %r/(\.{3}|[)(,\$])/, Punctuation

        rule %r/[a_z]+/ do |m|
          match = m[0]
          if self.class.keywords.include?(match)
            token Keyword
          else
            token Text
          end
        end
      end

      state :command do
        rule %r/( ?([^\s:\.'])+ ?)/, Keyword
        mixin :string_interpolated

        rule %r/\.{3}/ do
          token Keyword
          pop!
          push :old_arguments
        end

        rule %r/:/ do
          token Keyword
          pop!
          push :comma_list
        end

        rule %r/[\s]/, Text, :pop!
      end

      state :procedure_call do
        mixin :string_interpolated

        rule %r/(:|\s*\()/, Punctuation, :pop!

        rule %r/'/, Name::Function
        rule %r/[^:\('\s]+/, Name::Function

        rule %r/(?=\s+)/ do
          token Text
          pop!
          push :old_arguments
        end
      end

      state :procedure_definition do
        rule %r/(:|\s*\()/, Punctuation, :pop!

        rule %r/[^:\(\s]+/, Name::Function

        rule %r/(\s+)/, Text, :pop!
      end

      state :function_call do
        rule %r/\b([a-z][a-zA-Z0-9_.]+)(\$#|##|\$|#)?(?=\s*[:(])/ do |m|
          match = m[0]
          if self.class.functions_builtin.include?(match)
            token Name::Function
            push :function
          elsif self.class.keywords.include?(match)
            token Keyword
          else
            token Operator::Word
          end
        end
      end

      state :function do
        rule %r/\s+/, Text

        rule %r/(?::|\s*\()/ do
          token Text
          pop!
          push :comma_list
        end
      end

      state :comma_list do
        rule %r/(\s*\n\s*)(\.{3})/ do
          groups Text, Punctuation
        end

        rule %r/\s*[\]\})\n]/, Text, :pop!

        rule %r/\s+/, Text
        rule %r/"/, Literal::String, :string
        rule %r/\b(if|then|else|fi|endif)\b/, Keyword

        mixin :function_call
        mixin :variable_name
        mixin :operator
        mixin :number
        mixin :vector_literal

        rule %r/[()]/, Text
        rule %r/,/, Punctuation
      end

      state :old_arguments do
        rule %r/\n/, Text, :pop!

        mixin :variable_name
        mixin :operator
        mixin :number

        rule %r/"/, Literal::String, :string
        rule %r/[^\n]/, Text
      end

      state :number do
        rule %r/\n/, Text, :pop!
        rule %r/\b\d+(\.\d*)?([eE][-+]?\d+)?%?/, Literal::Number
      end

      state :variable_name do
        mixin :operator
        mixin :number

        rule %r/\b([A-Z][a-zA-Z0-9]+)_/ do |m|
          match = m[1]
          if (['Object'] | self.class.objects).include?(match)
            token Name::Builtin
            push :object_reference
          else
            token Name::Variable
          end
        end

        rule %r/\.?[a-z][a-zA-Z0-9_.]*(\$#|##|\$|#)?/ do |m|
          match = m[0]
          if self.class.variables_string.include?(match) ||
             self.class.variables_numeric.include?(match)
            token Name::Builtin
          elsif self.class.keywords.include?(match)
            token Keyword
          else
            token Name::Variable
          end
        end

        rule %r/[\[\]]/, Text, :comma_list
        mixin :string_interpolated
      end

      state :vector_literal do
        rule %r/(\{)/, Text, :comma_list
      end

      state :object_reference do
        mixin :string_interpolated
        rule %r/([a-z][a-zA-Z0-9_]*|\d+)/, Name::Builtin

        rule %r/\.([a-z]+)\b/ do |m|
          match = m[1]
          if self.class.object_attributes.include?(match)
            token Name::Builtin
            pop!
          end
        end

        rule %r/\$/, Name::Builtin
        rule %r/\[/, Text, :pop!
      end

      state :operator do
        # This rule incorrectly matches === or +++++, which are not operators
        rule %r/([+\/*<>=!-]=?|[&*|][&*|]?|\^|<>)/, Operator
        rule %r/(?<![\w.])(and|or|not|div|mod)(?![\w.])/, Operator::Word
      end

      state :string_interpolated do
        rule %r/'[\._a-z][^\[\]'":]*(\[([\d,]+|"[\w,]+")\])?(:[0-9]+)?'/, Literal::String::Interpol
      end

      state :string_unquoted do
        rule %r/\n\s*\.{3}/, Punctuation
        rule %r/\n/, Text, :pop!
        rule %r/\s/, Text

        mixin :string_interpolated

        rule %r/'/, Literal::String
        rule %r/[^'\n]+/, Literal::String
      end

      state :string do
        rule %r/\n\s*\.{3}/, Punctuation
        rule %r/"/, Literal::String, :pop!

        mixin :string_interpolated

        rule %r/'/, Literal::String
        rule %r/[^'"\n]+/, Literal::String
      end

      state :old_form do
        rule %r/(\s+)(#.*?$)/ do
          groups Text, Comment::Single
        end

        rule %r/\s+/, Text

        rule %r/(optionmenu|choice)([ \t]+\S+:[ \t]+)/ do
          groups Keyword, Text
          push :number
        end

        rule %r/(option|button)([ \t]+)/ do
          groups Keyword, Text
          push :string_unquoted
        end

        rule %r/(sentence|text)([ \t]+\S+)/ do
          groups Keyword, Text
          push :string_unquoted
        end

        rule %r/(word)([ \t]+\S+[ \t]*)(\S+)?([ \t]+.*)?/ do
          groups Keyword, Text, Literal::String, Text
        end

        rule %r/(boolean)(\s+\S+\s*)(0|1|"?(?:yes|no)"?)/ do
          groups Keyword, Text, Name::Variable
        end

        rule %r/(real|natural|positive|integer)([ \t]+\S+[ \t]*)([+-]?)/ do
          groups Keyword, Text, Operator
          push :number
        end

        rule %r/(comment)(\s+)/ do
          groups Keyword, Text
          push :string_unquoted
        end

        rule %r/\bendform\b/, Keyword, :pop!
      end
    end
  end
end
