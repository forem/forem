# frozen_string_literal: true

require "ruby-next"
# Include RubyNext into TOPLEVEL_BINDING for polyfills to work
eval("using RubyNext", TOPLEVEL_BINDING, __FILE__, __LINE__)

require "ruby-next/language"

# IRB extension to transpile code before evaluating
module RubyNext
  module IRBExt
    def evaluate(context, statements, *args)
      new_statements = ::RubyNext::Language.transform(
        statements,
        rewriters: ::RubyNext::Language.current_rewriters,
        using: false
      )

      super(context, new_statements, *args)
    end
  end
end

IRB::WorkSpace.prepend(RubyNext::IRBExt)
