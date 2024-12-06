# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class MXML < RegexLexer
      title "MXML"
      desc "MXML"
      tag 'mxml'
      filenames '*.mxml'
      mimetypes 'application/xv+xml'

      state :root do
        rule %r/[^<&]+/, Text
        rule %r/&\S*?;/, Name::Entity

        rule %r/<!\[CDATA\[/m do
          token Comment::Preproc
          push :actionscript_content
        end

        rule %r/<!--/, Comment, :comment
        rule %r/<\?.*?\?>/, Comment::Preproc
        rule %r/<![^>]*>/, Comment::Preproc

        rule %r(<\s*[\w:.-]+)m, Name::Tag, :tag # opening tags
        rule %r(<\s*/\s*[\w:.-]+\s*>)m, Name::Tag # closing tags
      end

      state :comment do
        rule %r/[^-]+/m, Comment
        rule %r/-->/, Comment, :pop!
        rule %r/-/, Comment
      end

      state :tag do
        rule %r/\s+/m, Text
        rule %r/[\w.:-]+\s*=/m, Name::Attribute, :attribute
        rule %r(/?\s*>), Name::Tag, :root
      end

      state :attribute do
        rule %r/\s+/m, Text
        rule %r/(")({|@{)/m do
          groups Str, Punctuation
          push :actionscript_attribute
        end
        rule %r/".*?"|'.*?'|[^\s>]+/, Str, :tag
      end

      state :actionscript_content do
        rule %r/\]\]\>/m, Comment::Preproc, :pop!
        rule %r/.*?(?=\]\]\>)/m do
          delegate Actionscript
        end
      end

      state :actionscript_attribute do
        rule %r/(})(")/m do
          groups Punctuation, Str
          push :tag
        end
        rule %r/.*?(?=}")/m do
          delegate Actionscript
        end
      end
    end
  end
end
