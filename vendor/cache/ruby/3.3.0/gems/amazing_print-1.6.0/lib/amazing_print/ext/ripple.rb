# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module Ripple
    def self.included(base)
      base.send :alias_method, :cast_without_ripple, :cast
      base.send :alias_method, :cast, :cast_with_ripple
    end

    # Add Ripple class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_ripple(object, type)
      cast = cast_without_ripple(object, type)
      return cast unless defined?(::Ripple)

      case object
      when ::Ripple::AttributeMethods # Module used to access attributes across documents and embedded documents
        cast = :ripple_document_instance
      when ::Ripple::Properties # Used to access property metadata on Ripple classes
        cast = :ripple_document_class
      end
      cast
    end

    private

    # Format Ripple instance object.
    #
    # NOTE: by default only instance attributes are shown. To format a Ripple document instance
    # as a regular object showing its instance variables and accessors use :raw => true option:
    #
    # ap document, :raw => true
    #
    #------------------------------------------------------------------------------
    def awesome_ripple_document_instance(object)
      return object.inspect unless defined?(::ActiveSupport::OrderedHash)
      return awesome_object(object) if @options[:raw]

      (exclude_assoc = @options[:exclude_assoc]) || @options[:exclude_associations]

      data = object.attributes.each_with_object(::ActiveSupport::OrderedHash.new) do |(name, _value), hash|
        hash[name.to_sym] = object.send(name)
      end

      unless exclude_assoc
        data = object.class.embedded_associations.each_with_object(data) do |assoc, hash|
          hash[assoc.name] = object.get_proxy(assoc) # Should always be array or Ripple::EmbeddedDocument for embedded associations
        end
      end

      "#{object} " << awesome_hash(data)
    end

    # Format Ripple class object.
    #------------------------------------------------------------------------------
    def awesome_ripple_document_class(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash) || !object.respond_to?(:properties)

      name = "class #{awesome_simple(object.to_s, :class)}"
      base = "< #{awesome_simple(object.superclass.to_s, :class)}"

      [name, base, awesome_hash(data)].join(' ')
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::Ripple
