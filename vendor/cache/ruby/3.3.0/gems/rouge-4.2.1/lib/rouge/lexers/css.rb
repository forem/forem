# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CSS < RegexLexer
      title "CSS"
      desc "Cascading Style Sheets, used to style web pages"

      tag 'css'
      filenames '*.css'
      mimetypes 'text/css'

      # Documentation: https://www.w3.org/TR/CSS21/syndata.html#characters

      identifier = /[\p{L}_-][\p{Word}\p{Cf}-]*/
      number = /-?(?:[0-9]+(\.[0-9]+)?|\.[0-9]+)/

      def self.attributes
        @attributes ||= Set.new %w(
          align-content align-items align-self alignment-adjust
          alignment-baseline all anchor-point animation
          animation-delay animation-direction animation-duration
          animation-fill-mode animation-iteration-count animation-name
          animation-play-state animation-timing-function appearance
          azimuth backface-visibility background background-attachment
          background-clip background-color background-image
          background-origin background-position background-repeat
          background-size baseline-shift binding bleed bookmark-label
          bookmark-level bookmark-state bookmark-target border
          border-bottom border-bottom-color border-bottom-left-radius
          border-bottom-right-radius border-bottom-style
          border-bottom-width border-collapse border-color
          border-image border-image-outset border-image-repeat
          border-image-slice border-image-source border-image-width
          border-left border-left-color border-left-style
          border-left-width border-radius border-right
          border-right-color border-right-style border-right-width
          border-spacing border-style border-top border-top-color
          border-top-left-radius border-top-right-radius
          border-top-style border-top-width border-width bottom
          box-align box-decoration-break box-direction box-flex
          box-flex-group box-lines box-ordinal-group box-orient
          box-pack box-shadow box-sizing break-after break-before
          break-inside caption-side clear clip clip-path
          clip-rule color color-profile columns column-count
          column-fill column-gap column-rule column-rule-color
          column-rule-style column-rule-width column-span
          column-width content counter-increment counter-reset
          crop cue cue-after cue-before cursor direction display
          dominant-baseline drop-initial-after-adjust
          drop-initial-after-align drop-initial-before-adjust
          drop-initial-before-align drop-initial-size
          drop-initial-value elevation empty-cells filter fit
          fit-position flex flex-basis flex-direction flex-flow
          flex-grow flex-shrink flex-wrap float float-offset
          font font-family font-feature-settings
          font-kerning font-language-override font-size
          font-size-adjust font-stretch font-style font-synthesis
          font-variant font-variant-alternates font-variant-caps
          font-variant-east-asian font-variant-ligatures
          font-variant-numeric font-variant-position font-weight
          grid-cell grid-column grid-column-align grid-column-sizing
          grid-column-span grid-columns grid-flow grid-row
          grid-row-align grid-row-sizing grid-row-span
          grid-rows grid-template hanging-punctuation height
          hyphenate-after hyphenate-before hyphenate-character
          hyphenate-lines hyphenate-resource hyphens icon
          image-orientation image-rendering image-resolution
          ime-mode inline-box-align justify-content
          left letter-spacing line-break line-height
          line-stacking line-stacking-ruby line-stacking-shift
          line-stacking-strategy list-style list-style-image
          list-style-position list-style-type margin
          margin-bottom margin-left margin-right margin-top
          mark marker-offset marks mark-after mark-before
          marquee-direction marquee-loop marquee-play-count
          marquee-speed marquee-style mask max-height max-width
          min-height min-width move-to nav-down
          nav-index nav-left nav-right nav-up object-fit
          object-position opacity order orphans outline
          outline-color outline-offset outline-style
          outline-width overflow overflow-style overflow-wrap
          overflow-x overflow-y padding padding-bottom
          padding-left padding-right padding-top
          page page-break-after page-break-before
          page-break-inside page-policy pause pause-after
          pause-before perspective perspective-origin
          phonemes pitch pitch-range play-during pointer-events
          position presentation-level punctuation-trim quotes
          rendering-intent resize rest rest-after rest-before
          richness right rotation rotation-point ruby-align
          ruby-overhang ruby-position ruby-span size speak
          speak-as speak-header speak-numeral speak-punctuation
          speech-rate src stress string-set
          tab-size table-layout target target-name
          target-new target-position text-align
          text-align-last text-combine-horizontal
          text-decoration text-decoration-color
          text-decoration-line text-decoration-skip
          text-decoration-style text-emphasis
          text-emphasis-color text-emphasis-position
          text-emphasis-style text-height text-indent
          text-justify text-orientation text-outline
          text-overflow text-rendering text-shadow
          text-space-collapse text-transform
          text-underline-position text-wrap top
          transform transform-origin transform-style
          transition transition-delay transition-duration
          transition-property transition-timing-function
          unicode-bidi vertical-align
          visibility voice-balance voice-duration
          voice-family voice-pitch voice-pitch-range
          voice-range voice-rate voice-stress voice-volume
          volume white-space widows width word-break
          word-spacing word-wrap writing-mode z-index
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          above absolute always armenian aural auto avoid left bottom
          baseline behind below bidi-override blink block bold bolder
          both bottom capitalize center center-left center-right circle
          cjk-ideographic close-quote collapse condensed continuous crop
          cross crosshair cursive dashed decimal decimal-leading-zero
          default digits disc dotted double e-resize embed expanded
          extra-condensed extra-expanded fantasy far-left far-right fast
          faster fixed georgian groove hebrew help hidden hide high higher
          hiragana hiragana-iroha icon inherit inline inline-table inset
          inside invert italic justify katakana katakana-iroha landscape
          large larger left left-side leftwards level lighter line-through
          list-item loud low lower lower-alpha lower-greek lower-roman
          lowercase ltr medium message-box middle mix monospace n-resize
          narrower ne-resize no-close-quote no-open-quote no-repeat none
          normal nowrap nw-resize oblique once open-quote outset outside
          overline pointer portrait px relative repeat repeat-x repeat-y
          rgb ridge right right-side rightwards s-resize sans-serif scroll
          se-resize semi-condensed semi-expanded separate serif show
          silent slow slower small-caps small-caption smaller soft solid
          spell-out square static status-bar super sw-resize table-caption
          table-cell table-column table-column-group table-footer-group
          table-header-group table-row table-row-group text text-bottom
          text-top thick thin top transparent ultra-condensed
          ultra-expanded underline upper-alpha upper-latin upper-roman
          uppercase url visible w-resize wait wider x-fast x-high x-large
          x-loud x-low x-small x-soft xx-large xx-small yes
        )
      end

      def self.constants
        @constants ||= Set.new %w(
          indigo gold firebrick indianred yellow darkolivegreen
          darkseagreen mediumvioletred mediumorchid chartreuse
          mediumslateblue black springgreen crimson lightsalmon brown
          turquoise olivedrab cyan silver skyblue gray darkturquoise
          goldenrod darkgreen darkviolet darkgray lightpink teal
          darkmagenta lightgoldenrodyellow lavender yellowgreen thistle
          violet navy orchid blue ghostwhite honeydew cornflowerblue
          darkblue darkkhaki mediumpurple cornsilk red bisque slategray
          darkcyan khaki wheat deepskyblue darkred steelblue aliceblue
          gainsboro mediumturquoise floralwhite coral purple lightgrey
          lightcyan darksalmon beige azure lightsteelblue oldlace
          greenyellow royalblue lightseagreen mistyrose sienna lightcoral
          orangered navajowhite lime palegreen burlywood seashell
          mediumspringgreen fuchsia papayawhip blanchedalmond peru
          aquamarine white darkslategray ivory dodgerblue lemonchiffon
          chocolate orange forestgreen slateblue olive mintcream
          antiquewhite darkorange cadetblue moccasin limegreen saddlebrown
          darkslateblue lightskyblue deeppink plum aqua darkgoldenrod
          maroon sandybrown magenta tan rosybrown pink lightblue
          palevioletred mediumseagreen dimgray powderblue seagreen snow
          mediumblue midnightblue paleturquoise palegoldenrod whitesmoke
          darkorchid salmon lightslategray lawngreen lightgreen tomato
          hotpink lightyellow lavenderblush linen mediumaquamarine green
          blueviolet peachpuff
        )
      end

      # source: http://www.w3.org/TR/CSS21/syndata.html#vendor-keyword-history
      def self.vendor_prefixes
        @vendor_prefixes ||= Set.new %w(
          -ah- -atsc- -hp- -khtml- -moz- -ms- -o- -rim- -ro- -tc- -wap-
          -webkit- -xv- mso- prince-
        )
      end

      state :root do
        mixin :basics
        rule %r/{/, Punctuation, :stanza
        rule %r/:[:]?#{identifier}/, Name::Decorator
        rule %r/\.#{identifier}/, Name::Class
        rule %r/##{identifier}/, Name::Function
        rule %r/@#{identifier}/, Keyword, :at_rule
        rule identifier, Name::Tag
        rule %r([~^*!%&\[\]()<>|+=@:;,./?-]), Operator
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Single
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Double
      end

      state :value do
        mixin :basics
        rule %r/url\(.*?\)/, Str::Other
        rule %r/#[0-9a-f]{1,6}/i, Num # colors
        rule %r/#{number}(?:%|(?:em|px|pt|pc|in|mm|cm|ex|rem|ch|vw|vh|vmin|vmax|dpi|dpcm|dppx|deg|grad|rad|turn|s|ms|Hz|kHz)\b)?/, Num
        rule %r/[\[\]():\/.,]/, Punctuation
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Single
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Double
        rule(identifier) do |m|
          if self.class.constants.include? m[0]
            token Name::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :at_rule do
        rule %r/{(?=\s*#{identifier}\s*:)/m, Punctuation, :at_stanza
        rule %r/{/, Punctuation, :at_body
        rule %r/;/, Punctuation, :pop!
        mixin :value
      end

      state :at_body do
        mixin :at_content
        mixin :root
      end

      state :at_stanza do
        mixin :at_content
        mixin :stanza
      end

      state :at_content do
        rule %r/}/ do
          token Punctuation
          pop! 2
        end
      end

      state :basics do
        rule %r/\s+/m, Text
        rule %r(/\*(?:.*?)\*/)m, Comment
      end

      state :stanza do
        mixin :basics
        rule %r/}/, Punctuation, :pop!
        rule %r/(#{identifier})(\s*)(:)/m do |m|
          name_tok = if self.class.attributes.include? m[1]
            Name::Label
          elsif self.class.vendor_prefixes.any? { |p| m[1].start_with?(p) }
            Name::Label
          else
            Name::Property
          end

          groups name_tok, Text, Punctuation

          push :stanza_value
        end
      end

      state :stanza_value do
        rule %r/;/, Punctuation, :pop!
        rule(/(?=})/) { pop! }
        rule %r/!\s*important\b/, Comment::Preproc
        rule %r/^@.*?$/, Comment::Preproc
        mixin :value
      end
    end
  end
end
