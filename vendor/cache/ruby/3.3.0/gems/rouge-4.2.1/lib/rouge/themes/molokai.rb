# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class Molokai < CSSTheme
      name 'molokai'

      palette :black          => '#1b1d1e'
      palette :white          => '#f8f8f2'
      palette :blue           => '#66d9ef'
      palette :green          => '#a6e22e'
      palette :grey           => '#403d3d'
      palette :red            => '#f92672'
      palette :light_grey     => '#465457'
      palette :dark_blue      => '#5e5d83'
      palette :violet         => '#af87ff'
      palette :yellow         => '#d7d787'

      style Comment,
            Comment::Multiline,
            Comment::Single,                  :fg => :dark_blue, :italic => true
      style Comment::Preproc,                 :fg => :light_grey, :bold => true
      style Comment::Special,                 :fg => :light_grey, :italic => true, :bold => true
      style Error,                            :fg => :white, :bg => :grey
      style Generic::Inserted,                :fg => :green
      style Generic::Deleted,                 :fg => :red
      style Generic::Emph,                    :fg => :black, :italic => true
      style Generic::Error,
            Generic::Traceback,               :fg => :red
      style Generic::Heading,                 :fg => :grey
      style Generic::Output,                  :fg => :grey
      style Generic::Prompt,                  :fg => :blue
      style Generic::Strong,                  :bold => true
      style Generic::Subheading,              :fg => :light_grey
      style Keyword,
            Keyword::Constant,
            Keyword::Declaration,
            Keyword::Pseudo,
            Keyword::Reserved,
            Keyword::Type,                    :fg => :blue, :bold => true
      style Keyword::Namespace,
            Operator::Word,
            Operator,                         :fg => :red, :bold => true
      style Literal::Number::Float,
            Literal::Number::Hex,
            Literal::Number::Integer::Long,
            Literal::Number::Integer,
            Literal::Number::Oct,
            Literal::Number,
            Literal::String::Escape,          :fg => :violet
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
            Literal::String,                  :fg => :yellow
      style Name::Attribute,                  :fg => :green
      style Name::Class,
            Name::Decorator,
            Name::Exception,
            Name::Function,                   :fg => :green, :bold => true
      style Name::Constant,                   :fg => :blue
      style Name::Builtin::Pseudo,
            Name::Builtin,
            Name::Entity,
            Name::Namespace,
            Name::Variable::Class,
            Name::Variable::Global,
            Name::Variable::Instance,
            Name::Variable,
            Text::Whitespace,                 :fg => :white
      style Name::Label,                      :fg => :white, :bold => true
      style Name::Tag,                        :fg => :red
      style Text,                             :fg => :white, :bg => :black
    end
  end
end
