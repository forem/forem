# This module provides a method for generating a configurable before_validation
# hook for cleaning up string attributes: all listed attributes will be
# replaced with `nil` if they are blank.
module StringAttributeCleaner
  # This method specifies the list of attributes that should be cleaned before
  # validation happens.
  #
  # @param attributes [Array<Symbol|String>]
  #
  # @return [void]
  #
  # @example Defining a list of attributes to be cleaned
  #   include StringAttributeCleaner.for(:attribute1, :attribute2)
  def self.for(*attributes)
    Module.new do
      define_singleton_method(:included) do |klass|
        return unless klass < ActiveRecord::Base

        klass.before_validation(:nullify_blank_attributes)
      end

      define_method(:nullify_blank_attributes) do
        attributes.each do |attr|
          next unless respond_to?(attr)
          next if public_send(attr).present?

          public_send("#{attr}=", nil)
        end
      end
    end
  end
end
