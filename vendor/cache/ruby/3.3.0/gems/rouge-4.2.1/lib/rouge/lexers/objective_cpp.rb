# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'cpp.rb'
    load_lexer 'objective_c/common.rb'

    class ObjectiveCpp < Cpp
      extend ObjectiveCCommon

      tag 'objective_cpp'
      title "Objective-C++"
      desc 'an extension of C++ uncommonly used to write Apple software'
      aliases 'objcpp', 'obj-cpp', 'obj_cpp', 'objectivecpp',
              'objc++', 'obj-c++', 'obj_c++', 'objectivec++'
      filenames '*.mm', '*.h'

      mimetypes 'text/x-objective-c++', 'application/x-objective-c++'

      prepend :statements do
        rule %r/(\.)(class)/ do
          groups(Operator, Name::Builtin::Pseudo)
        end
        rule %r/(@selector)(\()(class)(\))/ do
          groups(Keyword, Punctuation, Name::Builtin::Pseudo, Punctuation)
        end
      end
    end
  end
end
