# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Themes
    # stolen from pygments
    class Colorful < CSSTheme
      name 'colorful'

      style Text,                        :fg => "#bbbbbb", :bg => '#000'

      style Comment,                     :fg => "#888"
      style Comment::Preproc,            :fg => "#579"
      style Comment::Special,            :fg => "#cc0000", :bold => true

      style Keyword,                     :fg => "#080", :bold => true
      style Keyword::Pseudo,             :fg => "#038"
      style Keyword::Type,               :fg => "#339"

      style Operator,                    :fg => "#333"
      style Operator::Word,              :fg => "#000", :bold => true

      style Name::Builtin,               :fg => "#007020"
      style Name::Function,              :fg => "#06B", :bold => true
      style Name::Class,                 :fg => "#B06", :bold => true
      style Name::Namespace,             :fg => "#0e84b5", :bold => true
      style Name::Exception,             :fg => "#F00", :bold => true
      style Name::Variable,              :fg => "#963"
      style Name::Variable::Instance,    :fg => "#33B"
      style Name::Variable::Class,       :fg => "#369"
      style Name::Variable::Global,      :fg => "#d70", :bold => true
      style Name::Constant,              :fg => "#036", :bold => true
      style Name::Label,                 :fg => "#970", :bold => true
      style Name::Entity,                :fg => "#800", :bold => true
      style Name::Attribute,             :fg => "#00C"
      style Name::Tag,                   :fg => "#070"
      style Name::Decorator,             :fg => "#555", :bold => true

      style Literal::String,             :bg => "#fff0f0"
      style Literal::String::Affix,      :fg => "#080", :bold => true
      style Literal::String::Char,       :fg => "#04D"
      style Literal::String::Doc,        :fg => "#D42"
      style Literal::String::Interpol,   :bg => "#eee"
      style Literal::String::Escape,     :fg => "#666", :bold => true
      style Literal::String::Regex,      :fg => "#000", :bg => "#fff0ff"
      style Literal::String::Symbol,     :fg => "#A60"
      style Literal::String::Other,      :fg => "#D20"

      style Literal::Number,             :fg => "#60E", :bold => true
      style Literal::Number::Integer,    :fg => "#00D", :bold => true
      style Literal::Number::Float,      :fg => "#60E", :bold => true
      style Literal::Number::Hex,        :fg => "#058", :bold => true
      style Literal::Number::Oct,        :fg => "#40E", :bold => true

      style Generic::Heading,            :fg => "#000080", :bold => true
      style Generic::Subheading,         :fg => "#800080", :bold => true
      style Generic::Deleted,            :fg => "#A00000"
      style Generic::Inserted,           :fg => "#00A000"
      style Generic::Error,              :fg => "#FF0000"
      style Generic::Emph,               :italic => true
      style Generic::Strong,             :bold => true
      style Generic::Prompt,             :fg => "#c65d09", :bold => true
      style Generic::Output,             :fg => "#888"
      style Generic::Traceback,          :fg => "#04D"

      style Error,                       :fg => "#F00", :bg => "#FAA"
    end
  end
end
