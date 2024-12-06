# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class Github < CSSTheme
      name 'github'

      # Primer primitives
      # https://github.com/primer/primitives/tree/main/src/tokens
      P_RED_0        = {:light => '#ffebe9', :dark => '#ffdcd7'}
      P_RED_3        = {:dark => '#ff7b72'}
      P_RED_5        = {:light => '#cf222e'}
      P_RED_7        = {:light => '#82071e', :dark => '#8e1519'}
      P_RED_8        = {:dark => '#67060c'}
      P_ORANGE_2     = {:dark => '#ffa657'}
      P_ORANGE_6     = {:light => '#953800'}
      P_GREEN_0      = {:light => '#dafbe1', :dark => '#aff5b4'}
      P_GREEN_1      = {:dark => '#7ee787'}
      P_GREEN_6      = {:light => '#116329'}
      P_GREEN_8      = {:dark => '#033a16'}
      P_BLUE_1       = {:dark => '#a5d6ff'}
      P_BLUE_2       = {:dark => '#79c0ff'}
      P_BLUE_5       = {:dark => '#1f6feb'}
      P_BLUE_6       = {:light => '#0550ae'}
      P_BLUE_8       = {:light => '#0a3069'}
      P_PURPLE_2     = {:dark => '#d2a8ff'}
      P_PURPLE_5     = {:light => '#8250df'}
      P_GRAY_0       = {:light => '#f6f8fa', :dark => '#f0f6fc'}
      P_GRAY_1       = {:dark => '#c9d1d9'}
      P_GRAY_3       = {:dark => '#8b949e'}
      P_GRAY_5       = {:light => '#6e7781'}
      P_GRAY_8       = {:dark => '#161b22'}
      P_GRAY_9       = {:light => '#24292f'}

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
        palette :comment     => P_GRAY_3[@mode]
        palette :constant    => P_BLUE_2[@mode]
        palette :entity      => P_PURPLE_2[@mode]
        palette :heading     => P_BLUE_5[@mode]
        palette :keyword     => P_RED_3[@mode]
        palette :string      => P_BLUE_1[@mode]
        palette :tag         => P_GREEN_1[@mode]
        palette :variable    => P_ORANGE_2[@mode]

        palette :fgDefault   => P_GRAY_1[@mode]
        palette :bgDefault   => P_GRAY_8[@mode]

        palette :fgInserted  => P_GREEN_0[@mode]
        palette :bgInserted  => P_GREEN_8[@mode]

        palette :fgDeleted   => P_RED_0[@mode]
        palette :bgDeleted   => P_RED_8[@mode]

        palette :fgError     => P_GRAY_0[@mode]
        palette :bgError     => P_RED_7[@mode]
      end

      def self.make_light!
        palette :comment     => P_GRAY_5[@mode]
        palette :constant    => P_BLUE_6[@mode]
        palette :entity      => P_PURPLE_5[@mode]
        palette :heading     => P_BLUE_6[@mode]
        palette :keyword     => P_RED_5[@mode]
        palette :string      => P_BLUE_8[@mode]
        palette :tag         => P_GREEN_6[@mode]
        palette :variable    => P_ORANGE_6[@mode]

        palette :fgDefault   => P_GRAY_9[@mode]
        palette :bgDefault   => P_GRAY_0[@mode]

        palette :fgInserted  => P_GREEN_6[@mode]
        palette :bgInserted  => P_GREEN_0[@mode]

        palette :fgDeleted   => P_RED_7[@mode]
        palette :bgDeleted   => P_RED_0[@mode]

        palette :fgError     => P_GRAY_0[@mode]
        palette :bgError     => P_RED_7[@mode]
      end

      light!

      style Text,                       :fg => :fgDefault, :bg => :bgDefault

      style Keyword,                    :fg => :keyword

      style Generic::Error,             :fg => :fgError

      style Generic::Deleted,           :fg => :fgDeleted, :bg => :bgDeleted

      style Name::Builtin,
            Name::Class,
            Name::Constant,
            Name::Namespace,            :fg => :variable

      style Literal::String::Regex,
            Name::Attribute,
            Name::Tag,                  :fg => :tag

      style Generic::Inserted,          :fg => :fgInserted, :bg => :bgInserted

      style Keyword::Constant,
            Literal,
            Literal::String::Backtick,
            Name::Builtin::Pseudo,
            Name::Exception,
            Name::Label,
            Name::Property,
            Name::Variable,
            Operator,                   :fg => :constant

      style Generic::Heading,
            Generic::Subheading,        :fg => :heading, :bold => true

      style Literal::String,            :fg => :string

      style Name::Decorator,
            Name::Function,             :fg => :entity

      style Error,                      :fg => :fgError, :bg => :bgError

      style Comment,
            Generic::Lineno,
            Generic::Traceback,         :fg => :comment

      style Name::Entity,
            Literal::String::Interpol,  :fg => :fgDefault

      style Generic::Emph,              :fg => :fgDefault, :italic => true

      style Generic::Strong,            :fg => :fgDefault, :bold => true

    end
  end
end
