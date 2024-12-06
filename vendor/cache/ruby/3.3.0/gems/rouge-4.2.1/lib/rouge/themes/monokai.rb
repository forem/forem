# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class Monokai < CSSTheme
      name 'monokai'

      palette :black          => '#000000'
      palette :bright_green   => '#a6e22e'
      palette :bright_pink    => '#f92672'
      palette :carmine        => '#960050'
      palette :dark           => '#49483e'
      palette :dark_grey      => '#888888'
      palette :dark_red       => '#aa0000'
      palette :dimgrey        => '#75715e'
      palette :dimgreen       => '#324932'
      palette :dimred         => '#493131'
      palette :emperor        => '#555555'
      palette :grey           => '#999999'
      palette :light_grey     => '#aaaaaa'
      palette :light_violet   => '#ae81ff'
      palette :soft_cyan      => '#66d9ef'
      palette :soft_yellow    => '#e6db74'
      palette :very_dark      => '#1e0010'
      palette :whitish        => '#f8f8f2'
      palette :orange         => '#f6aa11'
      palette :white          => '#ffffff'

      style Comment,
            Comment::Multiline,
            Comment::Single,                  :fg => :dimgrey, :italic => true
      style Comment::Preproc,                 :fg => :dimgrey, :bold => true
      style Comment::Special,                 :fg => :dimgrey, :italic => true, :bold => true
      style Error,                            :fg => :carmine, :bg => :very_dark
      style Generic::Inserted,                :fg => :white, :bg => :dimgreen
      style Generic::Deleted,                 :fg => :white, :bg => :dimred
      style Generic::Emph,                    :fg => :black, :italic => true
      style Generic::Error,
            Generic::Traceback,               :fg => :dark_red
      style Generic::Heading,                 :fg => :grey
      style Generic::Output,                  :fg => :dark_grey
      style Generic::Prompt,                  :fg => :emperor
      style Generic::Strong,                  :bold => true
      style Generic::Subheading,              :fg => :light_grey
      style Keyword,
            Keyword::Constant,
            Keyword::Declaration,
            Keyword::Pseudo,
            Keyword::Reserved,
            Keyword::Type,                    :fg => :soft_cyan, :bold => true
      style Keyword::Namespace,
            Operator::Word,
            Operator,                         :fg => :bright_pink, :bold => true
      style Literal::Number::Float,
            Literal::Number::Hex,
            Literal::Number::Integer::Long,
            Literal::Number::Integer,
            Literal::Number::Oct,
            Literal::Number,
            Literal::String::Escape,          :fg => :light_violet
      style Literal::String::Affix,           :fg => :soft_cyan, :bold => true
      style Literal::String::Backtick,
            Literal::String::Char,
            Literal::String::Doc,
            Literal::String::Double,
            Literal::String::Heredoc,
            Literal::String::Interpol,
            Literal::String::Other,
            Literal::String::Regex,
            Literal::String::Single,
            Literal::String::Symbol,
            Literal::String,                  :fg => :soft_yellow
      style Name::Attribute,                  :fg => :bright_green
      style Name::Class,
            Name::Decorator,
            Name::Exception,
            Name::Function,                   :fg => :bright_green, :bold => true
      style Name::Constant,                   :fg => :soft_cyan
      style Name::Builtin::Pseudo,
            Name::Builtin,
            Name::Entity,
            Name::Namespace,
            Name::Variable::Class,
            Name::Variable::Global,
            Name::Variable::Instance,
            Name::Variable,
            Text::Whitespace,                 :fg => :whitish
      style Name::Label,                      :fg => :whitish, :bold => true
      style Name::Tag,                        :fg => :bright_pink
      style Text,                             :fg => :whitish, :bg => :dark
    end
  end
end
