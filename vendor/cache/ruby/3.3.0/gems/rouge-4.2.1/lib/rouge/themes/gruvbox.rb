# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# TODO how are we going to handle soft/hard contrast?

module Rouge
  module Themes
    # Based on https://github.com/morhetz/gruvbox, with help from
    # https://github.com/daveyarwood/gruvbox-pygments
    class Gruvbox < CSSTheme
      name 'gruvbox'

      # global Gruvbox colours {{{
      C_dark0_hard = '#1d2021'
      C_dark0 ='#282828'
      C_dark0_soft = '#32302f'
      C_dark1 = '#3c3836'
      C_dark2 = '#504945'
      C_dark3 = '#665c54'
      C_dark4 = '#7c6f64'
      C_dark4_256 = '#7c6f64'

      C_gray_245 = '#928374'
      C_gray_244 = '#928374'

      C_light0_hard = '#f9f5d7'
      C_light0 = '#fbf1c7'
      C_light0_soft = '#f2e5bc'
      C_light1 = '#ebdbb2'
      C_light2 = '#d5c4a1'
      C_light3 = '#bdae93'
      C_light4 = '#a89984'
      C_light4_256 = '#a89984'

      C_bright_red = '#fb4934'
      C_bright_green = '#b8bb26'
      C_bright_yellow = '#fabd2f'
      C_bright_blue = '#83a598'
      C_bright_purple = '#d3869b'
      C_bright_aqua = '#8ec07c'
      C_bright_orange = '#fe8019'

      C_neutral_red = '#cc241d'
      C_neutral_green = '#98971a'
      C_neutral_yellow = '#d79921'
      C_neutral_blue = '#458588'
      C_neutral_purple = '#b16286'
      C_neutral_aqua = '#689d6a'
      C_neutral_orange = '#d65d0e'

      C_faded_red = '#9d0006'
      C_faded_green = '#79740e'
      C_faded_yellow = '#b57614'
      C_faded_blue = '#076678'
      C_faded_purple = '#8f3f71'
      C_faded_aqua = '#427b58'
      C_faded_orange = '#af3a03'
      # }}}

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
        palette bg0: C_dark0
        palette bg1: C_dark1
        palette bg2: C_dark2
        palette bg3: C_dark3
        palette bg4: C_dark4

        palette gray: C_gray_245

        palette fg0: C_light0
        palette fg1: C_light1
        palette fg2: C_light2
        palette fg3: C_light3
        palette fg4: C_light4

        palette fg4_256: C_light4_256

        palette red: C_bright_red
        palette green: C_bright_green
        palette yellow: C_bright_yellow
        palette blue: C_bright_blue
        palette purple: C_bright_purple
        palette aqua: C_bright_aqua
        palette orange: C_bright_orange

      end

      def self.make_light!
        palette bg0: C_light0
        palette bg1: C_light1
        palette bg2: C_light2
        palette bg3: C_light3
        palette bg4: C_light4

        palette gray: C_gray_244

        palette fg0: C_dark0
        palette fg1: C_dark1
        palette fg2: C_dark2
        palette fg3: C_dark3
        palette fg4: C_dark4

        palette fg4_256: C_dark4_256

        palette red: C_faded_red
        palette green: C_faded_green
        palette yellow: C_faded_yellow
        palette blue: C_faded_blue
        palette purple: C_faded_purple
        palette aqua: C_faded_aqua
        palette orange: C_faded_orange
      end

      dark!
      mode :light

      style Text, :fg => :fg0, :bg => :bg0
      style Error, :fg => :red, :bg => :bg0, :bold => true
      style Comment, :fg => :gray, :italic => true

      style Comment::Preproc, :fg => :aqua

      style Name::Tag, :fg => :red

      style Operator,
            Punctuation, :fg => :fg0

      style Generic::Inserted, :fg => :green, :bg => :bg0
      style Generic::Deleted, :fg => :red, :bg => :bg0
      style Generic::Heading, :fg => :green, :bold => true

      style Keyword, :fg => :red
      style Keyword::Constant, :fg => :purple
      style Keyword::Type, :fg => :yellow

      style Keyword::Declaration, :fg => :orange

      style Literal::String,
            Literal::String::Interpol,
            Literal::String::Regex, :fg => :green, :italic => true

      style Literal::String::Affix, :fg => :red

      style Literal::String::Escape, :fg => :orange

      style Name::Namespace,
            Name::Class, :fg => :aqua

      style Name::Constant, :fg => :purple

      style Name::Attribute, :fg => :green

      style Literal::Number, :fg => :purple

      style Literal::String::Symbol, :fg => :blue

    end
  end
end
