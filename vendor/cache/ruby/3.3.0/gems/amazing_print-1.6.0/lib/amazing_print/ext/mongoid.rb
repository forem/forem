# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module Mongoid
    def self.included(base)
      base.send :alias_method, :cast_without_mongoid, :cast
      base.send :alias_method, :cast, :cast_with_mongoid
    end

    # Add Mongoid class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_mongoid(object, type)
      cast = cast_without_mongoid(object, type)
      if defined?(::Mongoid::Document)
        if object.is_a?(Class) && object.ancestors.include?(::Mongoid::Document)
          cast = :mongoid_class
        elsif object.class.ancestors.include?(::Mongoid::Document)
          cast = :mongoid_document
        elsif (defined?(::BSON) && object.is_a?(::BSON::ObjectId)) || (defined?(::Moped::BSON) && object.is_a?(::Moped::BSON::ObjectId))
          cast = :mongoid_bson_id
        end
      end
      cast
    end

    # Format Mongoid class object.
    #------------------------------------------------------------------------------
    def awesome_mongoid_class(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash) || !object.respond_to?(:fields)

      aliases = object.aliased_fields.invert
      data = object.fields.sort.each_with_object(::ActiveSupport::OrderedHash.new) do |c, hash|
        name = c[1].name
        alias_name = aliases[name] unless name == '_id'
        printed_name = alias_name ? "#{alias_name}(#{name})" : name

        hash[printed_name.to_sym] = (c[1].type || 'undefined').to_s.underscore.intern
        hash
      end

      name = "class #{awesome_simple(object.to_s, :class)}"
      base = "< #{awesome_simple(object.superclass.to_s, :class)}"

      [name, base, awesome_hash(data)].join(' ')
    end

    # Format Mongoid Document object.
    #------------------------------------------------------------------------------
    def awesome_mongoid_document(object)
      return object.inspect unless defined?(::ActiveSupport::OrderedHash)

      aliases = object.aliased_fields.invert
      data = (object.attributes || {}).sort.each_with_object(::ActiveSupport::OrderedHash.new) do |c, hash|
        name = c[0]
        alias_name = aliases[name] unless name == '_id'
        printed_name = alias_name ? "#{alias_name}(#{name})" : name

        hash[printed_name.to_sym] = c[1]
        hash
      end
      data = { errors: object.errors, attributes: data } unless object.errors.empty?
      "#{object} #{awesome_hash(data)}"
    end

    # Format BSON::ObjectId
    #------------------------------------------------------------------------------
    def awesome_mongoid_bson_id(object)
      object.inspect
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::Mongoid
