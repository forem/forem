# frozen_string_literal: true
class Module
  # Returns the class name of a full module namespace path
  #
  # @example
  #   module A::B::C; class_name end # => "C"
  # @return [String] the last part of a module path
  def class_name
    name.split("::").last
  end
end
