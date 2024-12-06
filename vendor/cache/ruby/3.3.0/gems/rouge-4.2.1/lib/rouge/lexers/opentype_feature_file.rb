# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class OpenTypeFeatureFile < RegexLexer
      title "OpenType Feature File"
      desc "Feature specifications for an OpenType font (adobe-type-tools.github.io/afdko)"
      tag 'opentype_feature_file'
      aliases 'fea', 'opentype', 'opentypefeature'
      filenames '*.fea'

      def self.keywords
        @keywords ||= %w(
          Ascender Attach AxisValue CapHeight CaretOffset CodePageRange
          DesignAxis Descender ElidedFallbackName ElidedFallbackNameID
          ElidableAxisValueName FeatUILabelNameID FeatUITooltipTextNameID
          FontRevision FSType GlyphClassDef HorizAxis.BaseScriptList
          HorizAxis.BaseTagList HorizAxis.MinMax IgnoreBaseGlyphs
          IgnoreLigatures IgnoreMarks LigatureCaretByDev LigatureCaretByIndex
          LigatureCaretByPos LineGap MarkAttachClass MarkAttachmentType NULL
          OlderSiblingFontAttribute Panose ParamUILabelNameID RightToLeft
          SampleTextNameID TypoAscender TypoDescender TypoLineGap UnicodeRange
          UseMarkFilteringSet Vendor VertAdvanceY VertAxis.BaseScriptList
          VertAxis.BaseTagList VertAxis.MinMax VertOriginY VertTypoAscender
          VertTypoDescender VertTypoLineGap WeightClass WidthClass XHeight

          anchorDef anchor anonymous anon by contour cursive device enumerate
          enum exclude_dflt featureNames feature flag from ignore include_dflt
          include languagesystem language location lookupflag lookup markClass
          mark nameid name parameters position pos required reversesub rsub
          script sizemenuname substitute subtable sub table useExtension
          valueRecordDef winAscent winDescent
        )
      end


      identifier = %r/[a-z_][a-z0-9\/_.-]*/i

      state :root do
        rule %r/\s+/m, Text::Whitespace
        rule %r/#.*$/, Comment

        # feature <tag>
        rule %r/(anonymous|anon|feature|lookup|table)((?:\s)+)/ do
          groups Keyword, Text
          push :featurename
        end
        # } <tag> ;
        rule %r/(\})((?:\s))/ do
          groups Punctuation, Text
          push :featurename
        end
        # solve include( ../path)
        rule %r/include\b/i, Keyword, :includepath

        rule %r/[\-\[\]\/(){},.:;=%*<>']/, Punctuation

        rule %r/`.*?/, Str::Backtick
        rule %r/\"/, Str, :strings
        rule %r/\\[^.*\s]+/i, Str::Escape

        # classes, start with @<nameOfClass>
        rule %r/@#{identifier}/, Name::Class

        # using negative lookbehind so we don't match property names
        rule %r/(?<!\.)#{identifier}/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          else
            token Name
          end
        end

        rule identifier, Name
        rule %r/(?:0x|\\)[0-9A-Fa-f]+/, Num::Hex
        rule %r/-?\d+/, Num::Integer
      end

      state :featurename do
        rule identifier, Name::Function, :pop!
      end

      state :includepath do
        rule %r/\s+/, Text::Whitespace
        rule %r/\)/, Punctuation, :pop!
        rule %r/\(/, Punctuation
        rule %r/[^\s()]+/, Str
      end

      state :strings do
        rule %r/"/, Str, :pop!
        rule %r/[^"%\n]+/, Str
      end
    end
  end
end
