# frozen_string_literal: true
# Handles 'private', 'protected', and 'public' calls.
class YARD::Handlers::Ruby::VisibilityHandler < YARD::Handlers::Ruby::Base
  include YARD::Handlers::Ruby::DecoratorHandlerMethods

  handles method_call(:private)
  handles method_call(:protected)
  handles method_call(:public)
  namespace_only

  process do
    return if (ident = statement.jump(:ident)) == statement
    case statement.type
    when :var_ref, :vcall
      self.visibility = ident.first.to_sym
    when :command
      if RUBY_VERSION >= '3.' && is_attribute_method?(statement.parameters.first)
        parse_block(statement.parameters.first, visibility: ident.first.to_sym)
        return
      end
      process_decorator do |method|
        method.visibility = ident.first if method.respond_to? :visibility=
      end
    when :fcall
      process_decorator do |method|
        method.visibility = ident.first if method.respond_to? :visibility=
      end
    end
  end

  def is_attribute_method?(node)
    node.type == :command && node.jump(:ident).first.to_s =~ /^attr_(accessor|writer|reader)$/
  end
end
