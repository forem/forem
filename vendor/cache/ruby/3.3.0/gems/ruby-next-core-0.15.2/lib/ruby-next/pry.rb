# frozen_string_literal: true

# This file contains patches for Pry integration.
# It's supposed to be required inside .pryrc files.

require "ruby-next/language/setup"
require "ruby-next/language/runtime"

# Enables refinements by injecting "using RubyNext"
# before Pry copies and memorizes the TOPLEVEL_BINDING.
Pry.singleton_class.prepend(Module.new do
  def toplevel_binding
    unless defined?(@_using_injected) && @_using_injected
      orig_binding = super

      # Copy TOPLEVEL_BINDING without local variables.
      TOPLEVEL_BINDING.eval <<-RUBY
        using RubyNext

        def self.__pry__
          binding
        end

        Pry.toplevel_binding = __pry__

        class << self; undef __pry__; end
      RUBY

      # Inject local variables from the original binding.
      orig_binding.local_variables.each do |var|
        value = orig_binding.local_variable_get(var)
        @toplevel_binding.local_variable_set(var, value)
      end

      @_using_injected = true
    end

    super
  end
end)

# Enables edge Ruby syntax by transpiling the code
# before it's evaluated in the context of a binding.
Pry.prepend(Module.new do
  def current_binding
    super.tap do |obj|
      next if obj.respond_to?(:__nextified__)

      obj.instance_eval do
        def eval(code, *args)
          new_code = ::RubyNext::Language::Runtime.transform(code, using: false)

          super(new_code, *args)
        end

        def __nextified__
        end
      end
    end
  end
end)

# Enables edge Ruby syntax for multi-line input.
Pry::Code.singleton_class.prepend(Module.new do
  def complete_expression?(str)
    silence_stderr do
      ::Parser::RubyNext.parse(str)
    end

    true
  rescue Parser::SyntaxError => ex
    case ex.message
    when /unexpected token \$end/
      false
    else
      true
    end
  end

  private

  def silence_stderr
    stderr = StringIO.new
    orig_stderr, $stderr = $stderr, stderr

    yield

    $stderr = orig_stderr
  end
end)
