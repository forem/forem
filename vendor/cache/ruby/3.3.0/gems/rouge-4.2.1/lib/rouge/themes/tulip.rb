# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class Tulip < CSSTheme
      name 'tulip'

      palette :purple      => '#766DAF'
      palette :lpurple     => '#9f93e6'
      palette :orange      => '#FAAF4C'
      palette :green       => '#3FB34F'
      palette :lgreen      => '#41ff5b'
      palette :yellow      => '#FFF02A'
      palette :black       => '#000000'
      palette :gray        => '#6D6E70'
      palette :red         => '#CC0000'
      palette :dark_purple => '#231529'
      palette :lunicorn    => '#faf8ed'
      palette :white       => '#FFFFFF'
      palette :earth       => '#181a27'
      palette :dune        => '#fff0a6'

      style Text, :fg => :white, :bg => :dark_purple

      style Comment, :fg => :gray, :italic => true
      style Comment::Preproc, :fg => :lgreen, :bold => true
      style Error,
            Generic::Error, :fg => :white, :bg => :red
      style Keyword, :fg => :yellow, :bold => true
      style Operator,
            Punctuation, :fg => :lgreen
      style Generic::Deleted, :fg => :red
      style Generic::Inserted, :fg => :green
      style Generic::Emph, :italic => true
      style Generic::Strong, :bold => true
      style Generic::Traceback,
            Generic::Lineno, :fg => :white, :bg => :purple
      style Keyword::Constant, :fg => :lpurple, :bold => true
      style Keyword::Namespace,
            Keyword::Pseudo,
            Keyword::Reserved,
            Generic::Heading,
            Generic::Subheading, :fg => :white, :bold => true
      style Keyword::Type,
            Name::Constant,
            Name::Class,
            Name::Decorator,
            Name::Namespace,
            Name::Builtin::Pseudo,
            Name::Exception, :fg => :orange, :bold => true
      style Name::Label,
            Name::Tag, :fg => :lpurple, :bold => true
      style Literal::Number,
            Literal::Date,
            Literal::String::Symbol, :fg => :lpurple, :bold => true
      style Literal::String, :fg => :dune, :bold => true
      style Literal::String::Affix, :fg => :yellow, :bold => true
      style Literal::String::Escape,
            Literal::String::Char,
            Literal::String::Interpol, :fg => :orange, :bold => true
      style Name::Builtin, :bold => true
      style Name::Entity, :fg => '#999999', :bold => true
      style Text::Whitespace, :fg => '#BBBBBB'
      style Name::Function,
            Name::Property,
            Name::Attribute, :fg => :lgreen
      style Name::Variable, :fg => :lgreen, :bold => true
    end
  end
end
