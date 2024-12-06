# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'html.rb'

    class Vue < HTML
      desc 'Vue.js single-file components'
      tag 'vue'
      aliases 'vuejs'
      filenames '*.vue'

      mimetypes 'text/x-vue', 'application/x-vue'

      def initialize(*)
        super
        @js = Javascript.new(options)
      end

      def lookup_lang(lang)
        lang.downcase!
        lang = lang.gsub(/["']*/, '')
        case lang
        when 'html' then HTML
        when 'css' then CSS
        when 'javascript' then Javascript
        when 'sass' then Sass
        when 'scss' then Scss
        when 'coffee' then Coffeescript
          # TODO: add more when the lexers are done
        else
          PlainText
        end
      end

      start { @js.reset! }

      prepend :root do
        rule %r/(<)(\s*)(template)/ do
          groups Name::Tag, Text, Keyword
          @lang = HTML
          push :template
          push :lang_tag
        end

        rule %r/(<)(\s*)(style)/ do
          groups Name::Tag, Text, Keyword
          @lang = CSS
          push :style
          push :lang_tag
        end

        rule %r/(<)(\s*)(script)/ do
          groups Name::Tag, Text, Keyword
          @lang = Javascript
          push :script
          push :lang_tag
        end
      end

      prepend :tag do
        rule %r/[a-zA-Z0-9_:#\[\]()*.-]+\s*=\s*/m, Name::Attribute, :attr
      end

      state :style do
        rule %r/(<\s*\/\s*)(style)(\s*>)/ do
          groups Name::Tag, Keyword, Name::Tag
          pop!
        end

        mixin :style_content
        mixin :embed
      end

      state :script do
        rule %r/(<\s*\/\s*)(script)(\s*>)/ do
          groups Name::Tag, Keyword, Name::Tag
          pop!
        end

        mixin :script_content
        mixin :embed
      end

      state :lang_tag do
        rule %r/(lang\s*=)(\s*)("(?:\\.|[^\\])*?"|'(\\.|[^\\])*?'|[^\s>]+)/ do |m|
          groups Name::Attribute, Text, Str
          @lang = lookup_lang(m[3])
        end

        mixin :tag
      end

      state :template do
        rule %r((<\s*/\s*)(template)(\s*>)) do
          groups Name::Tag, Keyword, Name::Tag
          pop!
        end

        rule %r/{{/ do
          token Str::Interpol
          push :template_interpol
          @js.reset!
        end

        mixin :embed
      end

      state :template_interpol do
        rule %r/}}/, Str::Interpol, :pop!
        rule %r/}/, Error
        mixin :template_interpol_inner
      end

      state :template_interpol_inner do
        rule(/{/) { delegate @js; push }
        rule(/}/) { delegate @js; pop! }
        rule(/[^{}]+/) { delegate @js }
      end

      state :embed do
        rule(/[^{<]+/) { delegate @lang }
        rule(/[<{][^<{]*/) { delegate @lang }
      end
    end
  end
end
