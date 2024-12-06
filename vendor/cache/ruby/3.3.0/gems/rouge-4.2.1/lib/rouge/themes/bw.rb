# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    # A port of the bw style from Pygments.
    # See https://bitbucket.org/birkenfeld/pygments-main/src/default/pygments/styles/bw.py
    class BlackWhiteTheme < CSSTheme
      name 'bw'

      style Text,                        :fg => '#000000', :bg => '#ffffff'

      style Comment,                     :italic => true
      style Comment::Preproc,            :italic => false

      style Keyword,                     :bold => true
      style Keyword::Pseudo,             :bold => false
      style Keyword::Type,               :bold => false

      style Operator,                    :bold => true

      style Name::Class,                 :bold => true
      style Name::Namespace,             :bold => true
      style Name::Exception,             :bold => true
      style Name::Entity,                :bold => true
      style Name::Tag,                   :bold => true

      style Literal::String,             :italic => true
      style Literal::String::Affix,      :bold => true
      style Literal::String::Interpol,   :bold => true
      style Literal::String::Escape,     :bold => true

      style Generic::Heading,            :bold => true
      style Generic::Subheading,         :bold => true
      style Generic::Emph,               :italic => true
      style Generic::Strong,             :bold => true
      style Generic::Prompt,             :bold => true

      style Error,                       :fg => '#FF0000'
    end
  end
end
