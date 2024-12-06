# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    # default base16 theme
    # by Chris Kempson (http://chriskempson.com)
    class Base16 < CSSTheme
      name 'base16'

      palette base00: "#151515"
      palette base01: "#202020"
      palette base02: "#303030"
      palette base03: "#505050"
      palette base04: "#b0b0b0"
      palette base05: "#d0d0d0"
      palette base06: "#e0e0e0"
      palette base07: "#f5f5f5"
      palette base08: "#ac4142"
      palette base09: "#d28445"
      palette base0A: "#f4bf75"
      palette base0B: "#90a959"
      palette base0C: "#75b5aa"
      palette base0D: "#6a9fb5"
      palette base0E: "#aa759f"
      palette base0F: "#8f5536"

      extend HasModes

      def self.light!
        mode :dark # indicate that there is a dark variant
        mode! :light
      end

      def self.dark!
        mode :light # indicate that there is a light variant
        mode! :dark
      end

      def self.make_dark!
        style Text, :fg => :base05, :bg => :base00
      end

      def self.make_light!
        style Text, :fg => :base02
      end

      light!

      style Error, :fg => :base00, :bg => :base08
      style Comment, :fg => :base03

      style Comment::Preproc,
            Name::Tag, :fg => :base0A

      style Operator,
            Punctuation, :fg => :base05

      style Generic::Inserted, :fg => :base0B
      style Generic::Deleted, :fg => :base08
      style Generic::Heading, :fg => :base0D, :bg => :base00, :bold => true

      style Keyword, :fg => :base0E
      style Keyword::Constant,
            Keyword::Type, :fg => :base09

      style Keyword::Declaration, :fg => :base09

      style Literal::String, :fg => :base0B
      style Literal::String::Affix, :fg => :base0E
      style Literal::String::Regex, :fg => :base0C

      style Literal::String::Interpol,
            Literal::String::Escape, :fg => :base0F

      style Name::Namespace,
            Name::Class,
            Name::Constant, :fg => :base0A

      style Name::Attribute, :fg => :base0D

      style Literal::Number,
            Literal::String::Symbol, :fg => :base0B

      class Solarized < Base16
        name 'base16.solarized'
        light!
        # author "Ethan Schoonover (http://ethanschoonover.com/solarized)"

        palette base00: "#002b36"
        palette base01: "#073642"
        palette base02: "#586e75"
        palette base03: "#657b83"
        palette base04: "#839496"
        palette base05: "#93a1a1"
        palette base06: "#eee8d5"
        palette base07: "#fdf6e3"
        palette base08: "#dc322f"
        palette base09: "#cb4b16"
        palette base0A: "#b58900"
        palette base0B: "#859900"
        palette base0C: "#2aa198"
        palette base0D: "#268bd2"
        palette base0E: "#6c71c4"
        palette base0F: "#d33682"
      end

      class Monokai < Base16
        name 'base16.monokai'
        dark!

        # author "Wimer Hazenberg (http://www.monokai.nl)"
        palette base00: "#272822"
        palette base01: "#383830"
        palette base02: "#49483e"
        palette base03: "#75715e"
        palette base04: "#a59f85"
        palette base05: "#f8f8f2"
        palette base06: "#f5f4f1"
        palette base07: "#f9f8f5"
        palette base08: "#f92672"
        palette base09: "#fd971f"
        palette base0A: "#f4bf75"
        palette base0B: "#a6e22e"
        palette base0C: "#a1efe4"
        palette base0D: "#66d9ef"
        palette base0E: "#ae81ff"
        palette base0F: "#cc6633"
      end
    end
  end
end
