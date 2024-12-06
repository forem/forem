# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class Magritte < CSSTheme
      name 'magritte'

      palette :dragon    => '#006c6c'
      palette :black     => '#000000'
      palette :forest    => '#007500'
      palette :candy     => '#ff0089'
      palette :wine      => '#7c0000'
      palette :grape     => '#4c48fe'
      palette :dark      => '#000707'
      palette :cherry    => '#f22700'
      palette :white     => '#ffffff'
      palette :royal     => '#19003a'

      palette :purple    => '#840084'
      palette :chocolate => '#920241'
      palette :lavender  => '#d8d9ff'
      palette :eggshell  => '#f3ffff'
      palette :yellow    => '#ffff3f'

      palette :lightgray => '#BBBBBB'
      palette :darkgray  => '#999999'

      style Text,                         :fg => :dark, :bg => :eggshell
      style Generic::Lineno,              :fg => :eggshell, :bg => :dark

      # style Generic::Prompt,            :fg => :chilly, :bold => true

      style Comment,                      :fg => :dragon, :italic => true
      style Comment::Preproc,             :fg => :chocolate, :bold => true
      style Error,                        :fg => :eggshell, :bg => :cherry
      style Generic::Error,               :fg => :cherry, :italic => true, :bold => true
      style Keyword,                      :fg => :royal, :bold => true
      style Operator,                     :fg => :grape, :bold => true
      style Punctuation,                  :fg => :grape
      style Generic::Deleted,             :fg => :cherry
      style Generic::Inserted,            :fg => :forest
      style Generic::Emph,                :italic => true
      style Generic::Strong,              :bold => true
      style Generic::Traceback,           :fg => :black, :bg => :lavender
      style Keyword::Constant,            :fg => :forest, :bold => true
      style Keyword::Namespace,
            Keyword::Pseudo,
            Keyword::Reserved,
            Generic::Heading,
            Generic::Subheading,          :fg => :forest, :bold => true
      style Keyword::Type,
            Name::Constant,
            Name::Class,
            Name::Decorator,
            Name::Namespace,
            Name::Builtin::Pseudo,
            Name::Exception,              :fg => :chocolate, :bold => true
      style Name::Label,
            Name::Tag,                    :fg => :purple, :bold => true
      style Literal::Number,
            Literal::Date,                :fg => :forest, :bold => true
      style Literal::String::Symbol,      :fg => :forest
      style Literal::String,              :fg => :wine, :bold => true
      style Literal::String::Affix,       :fg => :royal, :bold => true
      style Literal::String::Escape,
            Literal::String::Char,
            Literal::String::Interpol,    :fg => :purple, :bold => true
      style Name::Builtin,                :bold => true
      style Name::Entity,                 :fg => :darkgray, :bold => true
      style Text::Whitespace,             :fg => :lightgray
      style Generic::Output,              :fg => :royal
      style Name::Function,
            Name::Property,
            Name::Attribute,              :fg => :candy
      style Name::Variable,               :fg => :candy, :bold => true
    end
  end
end
