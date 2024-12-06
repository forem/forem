# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  class TexThemeRenderer
    def initialize(theme, opts={})
      @theme = theme
      @prefix = opts.fetch(:prefix) { 'RG' }
    end

    # Our general strategy is this:
    #
    # * First, define the \RG{tokname}{content} command, which will
    #   expand into \RG@tok@tokname{content}. We use \csname...\endcsname
    #   to interpolate into a command.
    #
    # * Define the default RG* environment, which will enclose the whole
    #   thing. By default this will simply set \ttfamily (select monospace font)
    #   but it can be overridden with \renewcommand by the user to be
    #   any other formatting.
    #
    # * Define all the colors using xcolors \definecolor command. First we define
    #   every palette color with a name such as RG@palette@themneame@colorname.
    #   Then we find all foreground and background colors that have literal html
    #   colors embedded in them and define them with names such as
    #   RG@palette@themename@000000. While html allows three-letter colors such
    #   as #FFF, xcolor requires all six characters to be present, so we make sure
    #   to normalize that as well as the case convention in #inline_name.
    #
    # * Define the token commands RG@tok@xx. These will take the content as the
    #   argument and format it according to the theme, referring to the color
    #   in the palette.
    def render(&b)
      yield <<'END'.gsub('RG', @prefix)
\makeatletter
\def\RG#1#2{\csname RG@tok@#1\endcsname{#2}}%
\newenvironment{RG*}{\ttfamily}{\relax}%
END

      base = @theme.class.base_style
      yield "\\definecolor{#{@prefix}@fgcolor}{HTML}{#{inline_name(base.fg || '#000000')}}"
      yield "\\definecolor{#{@prefix}@bgcolor}{HTML}{#{inline_name(base.bg || '#FFFFFF')}}"

      render_palette(@theme.palette, &b)

      @theme.styles.each do |tok, style|
        render_inline_pallete(style, &b)
      end

      Token.each_token do |tok|
        style = @theme.class.get_own_style(tok)
        style ? render_style(tok, style, &b) : render_blank(tok, &b)
      end
      yield '\makeatother'
    end

    def render_palette(palette, &b)
      palette.each do |name, color|
        hex = inline_name(color)

        yield "\\definecolor{#{palette_name(name)}}{HTML}{#{hex}}%"
      end
    end

    def render_inline_pallete(style, &b)
      gen_inline(style[:fg], &b)
      gen_inline(style[:bg], &b)
    end

    def inline_name(color)
      color =~ /^#(\h+)/ or return nil

      # xcolor does not support 3-character HTML colors,
      # so we convert them here
      case $1.size
      when 6
        $1
      when 3
        # duplicate every character: abc -> aabbcc
        $1.gsub(/\h/, '\0\0')
      else
        raise "invalid HTML color: #{$1}"
      end.upcase
    end

    def gen_inline(name, &b)
      # detect inline colors
      hex = inline_name(name)
      return unless hex

      @gen_inline ||= {}
      @gen_inline[hex] ||= begin
        yield "\\definecolor{#{palette_name(hex)}}{HTML}{#{hex}}%"
      end
    end

    def camelize(name)
      name.gsub(/_(.)/) { $1.upcase }
    end

    def palette_name(name)
      name = inline_name(name) || name.to_s

      "#{@prefix}@palette@#{camelize(@theme.name)}@#{camelize(name.to_s)}"
    end

    def token_name(tok)
      "\\csname #@prefix@tok@#{tok.shortname}\\endcsname"
    end

    def render_blank(tok, &b)
      "\\expandafter\\def#{token_name(tok)}#1{#1}"
    end

    def render_style(tok, style, &b)
      out = String.new('')
      out << "\\expandafter\\def#{token_name(tok)}#1{"
      out << "\\fboxsep=0pt\\colorbox{#{palette_name(style[:bg])}}{" if style[:bg]
      out << '\\textbf{' if style[:bold]
      out << '\\textit{' if style[:italic]
      out << "\\textcolor{#{palette_name(style[:fg])}}{" if style[:fg]
      out << "#1"
      # close the right number of curlies
      out << "}" if style[:bold]
      out << "}" if style[:italic]
      out << "}" if style[:fg]
      out << "}" if style[:bg]
      out << "}%"
      yield out
    end
  end
end
