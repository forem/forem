# frozen_string_literal: true

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* This module is an internal implementation detail, with no
      #   guarantee of backward compatibility.
      #
      # Adds a +type+ keyword parameter to +attr_accessor+, to enforce that
      # config attributes have valid types, for example: boolean, numeric,
      # enumeration, non-nullable, etc.
      module AttrTypeCoercion
        # :stopdoc: internal APIs only

        module Macros # :nodoc: internal API
          def attr_accessor(attr, type: nil)
            super(attr)
            AttrTypeCoercion.attr_accessor(attr, type: type)
          end
        end
        private_constant :Macros

        def self.included(mod)
          mod.extend Macros
        end
        private_class_method :included

        def self.attr_accessor(attr, type: nil)
          return unless type
          if    :boolean == type then boolean attr
          elsif Integer  == type then integer attr
          elsif Array   === type then enum    attr, type
          else raise ArgumentError, "unknown type coercion %p" % [type]
          end
        end

        def self.boolean(attr)
          define_method :"#{attr}=" do |val| super !!val end
          define_method :"#{attr}?" do send attr end
        end

        def self.integer(attr)
          define_method :"#{attr}=" do |val| super Integer val end
        end

        def self.enum(attr, enum)
          enum = enum.dup.freeze
          expected = -"one of #{enum.map(&:inspect).join(", ")}"
          define_method :"#{attr}=" do |val|
            unless enum.include?(val)
              raise ArgumentError, "expected %s, got %p" % [expected, val]
            end
            super val
          end
        end

      end
    end
  end
end
