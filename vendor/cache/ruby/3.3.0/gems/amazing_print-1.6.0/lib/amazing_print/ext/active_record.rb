# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module ActiveRecord
    def self.included(base)
      base.send :alias_method, :cast_without_active_record, :cast
      base.send :alias_method, :cast, :cast_with_active_record
    end

    # Add ActiveRecord class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_active_record(object, type)
      cast = cast_without_active_record(object, type)
      return cast unless defined?(::ActiveRecord::Base)

      if object.is_a?(::ActiveRecord::Base)
        cast = :active_record_instance
      elsif object.is_a?(::ActiveModel::Errors)
        cast = :active_model_error
      elsif object.is_a?(Class) && object.ancestors.include?(::ActiveRecord::Base)
        cast = :active_record_class
      elsif type == :activerecord_relation || object.class.ancestors.include?(::ActiveRecord::Relation)
        cast = :array
      end
      cast
    end

    private

    # Format ActiveRecord instance object.
    #
    # NOTE: by default only instance attributes (i.e. columns) are shown. To format
    # ActiveRecord instance as regular object showing its instance variables and
    # accessors use :raw => true option:
    #
    # ap record, :raw => true
    #
    #------------------------------------------------------------------------------
    def awesome_active_record_instance(object)
      return object.inspect unless defined?(::ActiveSupport::OrderedHash)
      return awesome_object(object) if @options[:raw]

      data = if object.class.column_names == object.attributes.keys
               object.class.column_names.each_with_object(::ActiveSupport::OrderedHash.new) do |name, hash|
                 if object.has_attribute?(name) || object.new_record?
                   value = object.respond_to?(name) ? object.send(name) : object.read_attribute(name)
                   hash[name.to_sym] = value
                 end
               end
             else
               object.attributes
             end
      [awesome_simple(object.to_s, :active_record_instance), awesome_hash(data)].join(' ')
    end

    # Format ActiveRecord class object.
    #------------------------------------------------------------------------------
    def awesome_active_record_class(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash) || !object.respond_to?(:columns) || object.to_s == 'ActiveRecord::Base'
      return awesome_class(object) if object.respond_to?(:abstract_class?) && object.abstract_class?

      data = object.columns.each_with_object(::ActiveSupport::OrderedHash.new) do |c, hash|
        hash[c.name.to_sym] = c.type
      end

      [awesome_simple("class #{object} < #{object.superclass}", :class), awesome_hash(data)].join(' ')
    end

    # Format ActiveModel error object.
    #------------------------------------------------------------------------------
    def awesome_active_model_error(object)
      return object.inspect unless defined?(::ActiveSupport::OrderedHash)
      return awesome_object(object) if @options[:raw]

      data = object.instance_variable_get('@base')
                   .attributes
                   .merge(details: object.details.to_h,
                          messages: object.messages.to_h.transform_values(&:to_a))

      [awesome_simple(object.to_s, :active_model_error), awesome_hash(data)].join(' ')
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::ActiveRecord
