# This module provides a method for generating a configurable before_validation
# hook for cleaning up string attributes: all listed attributes will be
# replaced with `nil` if they are blank.
module StringAttributeCleaner
  # This method specifies the list of attributes that should be cleaned before
  # validation happens.
  #
  # @param attributes [Array<Symbol|String>]
  # @param on [Symbol] register the cleaning on the specified
  #        ActiveRecord::Base callback
  #
  # @return [void]
  #
  # @example Defining a list of attributes to be cleaned
  #   include StringAttributeCleaner.for(:attribute1, :attribute2)
  #   include StringAttributeCleaner.for(:attribute1, :attribute2, on: :before_save)
  def self.for(*attributes, on: :before_validation)
    Module.new do
      define_singleton_method(:included) do |klass|
        return unless klass < ActiveRecord::Base

        klass.public_send(on, :nullify_blank_attributes)
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
