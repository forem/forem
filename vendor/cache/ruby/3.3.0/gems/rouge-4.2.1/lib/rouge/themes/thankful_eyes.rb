# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    class ThankfulEyes < CSSTheme
      name 'thankful_eyes'

      # pallette, from GTKSourceView's ThankfulEyes
      palette :cool_as_ice    => '#6c8b9f'
      palette :slate_blue     => '#4e5d62'
      palette :eggshell_cloud => '#dee5e7'
      palette :krasna         => '#122b3b'
      palette :aluminum1      => '#fefeec'
      palette :scarletred2    => '#cc0000'
      palette :butter3        => '#c4a000'
      palette :go_get_it      => '#b2fd6d'
      palette :chilly         => '#a8e1fe'
      palette :unicorn        => '#faf6e4'
      palette :sandy          => '#f6dd62'
      palette :pink_merengue  => '#f696db'
      palette :dune           => '#fff0a6'
      palette :backlit        => '#4df4ff'
      palette :schrill        => '#ffb000'

      style Text, :fg => :unicorn, :bg => :krasna
      style Generic::Lineno, :fg => :eggshell_cloud, :bg => :slate_blue

      style Generic::Prompt, :fg => :chilly, :bold => true

      style Comment, :fg => :cool_as_ice, :italic => true
      style Comment::Preproc, :fg => :go_get_it, :bold => true
      style Error, :fg => :aluminum1, :bg => :scarletred2
      style Generic::Error, :fg => :scarletred2, :italic => true, :bold => true
      style Keyword, :fg => :sandy, :bold => true
      style Operator, :fg => :backlit, :bold => true
      style Punctuation, :fg => :backlit
      style Generic::Deleted, :fg => :scarletred2
      style Generic::Inserted, :fg => :go_get_it
      style Generic::Emph, :italic => true
      style Generic::Strong, :bold => true
      style Generic::Traceback, :fg => :eggshell_cloud, :bg => :slate_blue
      style Keyword::Constant, :fg => :pink_merengue, :bold => true
      style Keyword::Namespace,
            Keyword::Pseudo,
            Keyword::Reserved,
            Generic::Heading,
            Generic::Subheading, :fg => :schrill, :bold => true
      style Keyword::Type,
            Name::Constant,
            Name::Class,
            Name::Decorator,
            Name::Namespace,
            Name::Builtin::Pseudo,
            Name::Exception, :fg => :go_get_it, :bold => true
      style Name::Label,
            Name::Tag, :fg => :schrill, :bold => true
      style Literal::Number,
            Literal::Date,
            Literal::String::Symbol, :fg => :pink_merengue, :bold => true
      style Literal::String, :fg => :dune, :bold => true
      style Literal::String::Affix, :fg => :sandy, :bold => true
      style Literal::String::Escape,
            Literal::String::Char,
            Literal::String::Interpol, :fg => :backlit, :bold => true
      style Name::Builtin, :bold => true
      style Name::Entity, :fg => '#999999', :bold => true
      style Text::Whitespace,
            Generic::Output, :fg => '#BBBBBB'
      style Name::Function,
            Name::Property,
            Name::Attribute, :fg => :chilly
      style Name::Variable, :fg => :chilly, :bold => true
    end
  end
end
