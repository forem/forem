# frozen_string_literal: true

# rubocop:disable Style/HashTransformValues

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module NoBrainer
    def self.included(base)
      base.send :alias_method, :cast_without_nobrainer, :cast
      base.send :alias_method, :cast, :cast_with_nobrainer
    end

    # Add NoBrainer class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_nobrainer(object, type)
      cast = cast_without_nobrainer(object, type)
      if defined?(::NoBrainer::Document)
        if object.is_a?(Class) && object < ::NoBrainer::Document
          cast = :nobrainer_class
        elsif object.is_a?(::NoBrainer::Document)
          cast = :nobrainer_document
        end
      end
      cast
    end

    # Format NoBrainer class object.
    #------------------------------------------------------------------------------
    def awesome_nobrainer_class(object)
      name = "#{awesome_simple(object, :class)} < #{awesome_simple(object.superclass, :class)}"
      data = object.fields.map do |field, options|
        [field, (options[:type] || Object).to_s.underscore.to_sym]
      end.to_h

      name = "class #{awesome_simple(object.to_s, :class)}"
      base = "< #{awesome_simple(object.superclass.to_s, :class)}"

      [name, base, awesome_hash(data)].join(' ')
    end

    # Format NoBrainer Document object.
    #------------------------------------------------------------------------------
    def awesome_nobrainer_document(object)
      data = object.inspectable_attributes.symbolize_keys
      data = { errors: object.errors, attributes: data } if object.errors.present?
      "#{object} #{awesome_hash(data)}"
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::NoBrainer

# rubocop:enable Style/HashTransformValues
