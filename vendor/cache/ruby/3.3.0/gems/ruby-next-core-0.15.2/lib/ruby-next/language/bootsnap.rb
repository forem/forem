# frozen_string_literal: true

require "ruby-next"
require "ruby-next/utils"
require "ruby-next/language"

RubyNext::Language.runtime!

# Patch bootsnap to transform source code.
# Based on https://github.com/kddeisz/preval/blob/master/lib/preval.rb
load_iseq = RubyVM::InstructionSequence.method(:load_iseq)

if load_iseq.source_location[0].include?("/bootsnap/")
  Bootsnap::CompileCache::ISeq.singleton_class.prepend(
    Module.new do
      def input_to_storage(source, path, *)
        return super unless RubyNext::Language.transformable?(path)
        source = RubyNext::Language.transform(source, rewriters: RubyNext::Language.current_rewriters)

        RubyNext.debug_source(source, path)

        RubyVM::InstructionSequence.compile(source, path, path).to_binary
      rescue SyntaxError
        raise Bootsnap::CompileCache::Uncompilable, "syntax error"
      end
    end
  )
end
