# frozen_string_literal: true

require "ruby-next/config"
require "ruby-next/setup_self"
require "ruby-next/core"

# Monkey-patch core classes using the same patches as for refinements
RubyNext::Core.patches.extensions.each do |mod, patches|
  patches.each do |patch|
    next if patch.supported?

    if patch.prepend?
      mod.send(:prepend, patch.to_module)
    else
      mod.module_eval(patch.body, *patch.location)
    end
  end
end

RubyNext::Core.strategy = :core_ext unless RubyNext::Core.core_ext?
