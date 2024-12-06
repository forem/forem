# frozen_string_literal: true

module YARD::Handlers
  module Common
    # Shared functionality between Ruby and C method handlers.
    module MethodHandler
      # @param [MethodObject] obj
      def add_predicate_return_tag(obj)
        if obj.tag(:return) && (obj.tag(:return).types || []).empty?
          obj.tag(:return).types = ['Boolean']
        elsif obj.tag(:return).nil?
          unless obj.tags(:overload).any? {|overload| overload.tag(:return) }
            obj.add_tag(YARD::Tags::Tag.new(:return, "", "Boolean"))
          end
        end
      end
    end
  end
end
