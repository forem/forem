# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
  class Response
    # Defines a new field. This is designed to be used by the subclass as a
    # mini-DSL.
    #
    # @example Default
    #   field :data
    #
    # @example With a mutator
    #   field :present, as: :present?
    #
    # @param n [Symbol] the name of the field
    # @option opts [Symbol] :as alias for method name
    #
    # @!visibility private
    def self.field(n, opts = {})
      self.fields[n] = opts

      if opts[:as].nil?
        attr_reader n
      else
        define_method(opts[:as]) do
          instance_variable_get(:"@#{n}")
        end
      end
    end

    # Returns the list of fields defined on this subclass.
    # @!visibility private
    def self.fields
      @fields ||= {}
    end

    # Decodes the given object (usually a Hash) into an instance of this class.
    #
    # @param object [Hash<Symbol, Object>]
    def self.decode(object)
      self.new(object)
    end

    def initialize(opts = {})
      # Initialize all fields as nil to start
      self.class.fields.each do |k, _|
        instance_variable_set(:"@#{k}", nil)
      end

      # For each supplied option, set the instance variable if it was defined
      # as a field.
      opts.each do |k, v|
        if self.class.fields.key?(k)
          opts = self.class.fields[k]

          if (m = opts[:load]) && !v.nil?
            v = m.call(v)
          end

          if opts[:freeze]
            v = v.freeze
          end

          instance_variable_set(:"@#{k}", v)
        end
      end
    end

    # Create a hash-bashed representation of this response.
    #
    # @return [Hash]
    def to_h
      self.class.fields.inject({}) do |h, (k, opts)|
        if opts[:as].nil?
          h[k] = self.public_send(k)
        else
          h[k] = self.public_send(opts[:as])
        end

        if !h[k].nil? && !h[k].is_a?(Array) && h[k].respond_to?(:to_h)
          h[k] = h[k].to_h
        end

        h
      end
    end

    def ==(other)
      self.to_h == other.to_h
    end
  end
end
