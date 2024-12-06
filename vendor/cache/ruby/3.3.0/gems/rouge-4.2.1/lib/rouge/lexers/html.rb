# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class HTML < RegexLexer
      title "HTML"
      desc "HTML, the markup language of the web"
      tag 'html'
      filenames '*.htm', '*.html', '*.xhtml', '*.cshtml'
      mimetypes 'text/html', 'application/xhtml+xml'

      def self.detect?(text)
        return true if text.doctype?(/\bhtml\b/i)
        return false if text =~ /\A<\?xml\b/
        return true if text =~ /<\s*html\b/
      end

      start do
        @javascript = Javascript.new(options)
        @css = CSS.new(options)
      end

      state :root do
        rule %r/[^<&]+/m, Text
        rule %r/&\S*?;/, Name::Entity
        rule %r/<!DOCTYPE .*?>/im, Comment::Preproc
        rule %r/<!\[CDATA\[.*?\]\]>/m, Comment::Preproc
        rule %r/<!--/, Comment, :comment
        rule %r/<\?.*?\?>/m, Comment::Preproc # php? really?

        rule %r/<\s*script\s*/m do
          token Name::Tag
          @javascript.reset!
          push :script_content
          push :tag
        end

        rule %r/<\s*style\s*/m do
          token Name::Tag
          @css.reset!
          @lang = @css
          push :style_content
          push :tag
        end

        rule %r(</), Name::Tag, :tag_end
        rule %r/</, Name::Tag, :tag_start

        rule %r(<\s*[\p{L}:_-][\p{Word}\p{Cf}:.·-]*), Name::Tag, :tag # opening tags
        rule %r(<\s*/\s*[\p{L}:_-][\p{Word}\p{Cf}:.·-]*\s*>), Name::Tag # closing tags
      end

      state :tag_end do
        mixin :tag_end_end
        rule %r/[\p{L}:_-][\p{Word}\p{Cf}:.·-]*/ do
          token Name::Tag
          goto :tag_end_end
        end
      end

      state :tag_end_end do
        rule %r/\s+/, Text
        rule %r/>/, Name::Tag, :pop!
      end

      state :tag_start do
        rule %r/\s+/, Text

        rule %r/[\p{L}:_-][\p{Word}\p{Cf}:.·-]*/ do
          token Name::Tag
          goto :tag
        end

        rule(//) { goto :tag }
      end

      state :comment do
        rule %r/[^-]+/, Comment
        rule %r/-->/, Comment, :pop!
        rule %r/-/, Comment
      end

      state :tag do
        rule %r/\s+/m, Text
        rule %r/[\p{L}:_\[\]()*.-][\p{Word}\p{Cf}:.·\[\]()*-]*\s*=\s*/m, Name::Attribute, :attr
        rule %r/[\p{L}:_*#-][\p{Word}\p{Cf}:.·*#-]*/, Name::Attribute
        rule %r(/?\s*>)m, Name::Tag, :pop!
      end

      state :attr do
        # TODO: are backslash escapes valid here?
        rule %r/"/ do
          token Str
          goto :dq
        end

        rule %r/'/ do
          token Str
          goto :sq
        end

        rule %r/[^\s>]+/, Str, :pop!
      end

      state :dq do
        rule %r/"/, Str, :pop!
        rule %r/[^"]+/, Str
      end

      state :sq do
        rule %r/'/, Str, :pop!
        rule %r/[^']+/, Str
      end

      state :script_content do
        rule %r([^<]+) do
          delegate @javascript
        end

        rule %r(<\s*/\s*script\s*>)m, Name::Tag, :pop!

        rule %r(<) do
          delegate @javascript
        end
      end

      state :style_content do
        rule %r/[^<]+/ do
          delegate @lang
        end

        rule %r(<\s*/\s*style\s*>)m, Name::Tag, :pop!

        rule %r/</ do
          delegate @lang
        end
      end
    end
  end
end
