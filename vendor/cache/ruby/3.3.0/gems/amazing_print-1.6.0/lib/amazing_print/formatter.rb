# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
require_relative 'formatters'

module AmazingPrint
  class Formatter
    include Colorize

    attr_reader :inspector, :options

    CORE_FORMATTERS = %i[array bigdecimal class dir file hash method rational set struct unboundmethod].freeze

    def initialize(inspector)
      @inspector   = inspector
      @options     = inspector.options
    end

    # Main entry point to format an object.
    #------------------------------------------------------------------------------
    def format(object, type = nil)
      core_class = cast(object, type)
      if core_class == :self
        awesome_self(object, type) # Catch all that falls back to object.inspect.
      else
        send(:"awesome_#{core_class}", object) # Core formatters.
      end
    end

    # Hook this when adding custom formatters. Check out lib/amazing_print/ext
    # directory for custom formatters that ship with amazing_print.
    #------------------------------------------------------------------------------
    def cast(_object, type)
      CORE_FORMATTERS.include?(type) ? type : :self
    end

    private

    # Catch all method to format an arbitrary object.
    #------------------------------------------------------------------------------
    def awesome_self(object, type)
      if @options[:raw] && object.instance_variables.any?
        awesome_object(object)
      elsif (hash = convert_to_hash(object))
        awesome_hash(hash)
      else
        awesome_simple(object.inspect.to_s, type, @inspector)
      end
    end

    def awesome_bigdecimal(n)
      o = n.to_s('F')
      type = :bigdecimal
      awesome_simple(o, type, @inspector)
    end

    def awesome_rational(n)
      o = n.to_s
      type = :rational
      awesome_simple(o, type, @inspector)
    end

    def awesome_simple(o, type, inspector = @inspector)
      AmazingPrint::Formatters::SimpleFormatter.new(o, type, inspector).format
    end

    def awesome_array(a)
      Formatters::ArrayFormatter.new(a, @inspector).format
    end

    def awesome_set(s)
      Formatters::ArrayFormatter.new(s.to_a, @inspector).format
    end

    def awesome_hash(h)
      Formatters::HashFormatter.new(h, @inspector).format
    end

    def awesome_object(o)
      Formatters::ObjectFormatter.new(o, @inspector).format
    end

    def awesome_struct(s)
      Formatters::StructFormatter.new(s, @inspector).format
    end

    def awesome_method(m)
      Formatters::MethodFormatter.new(m, @inspector).format
    end
    alias awesome_unboundmethod awesome_method

    def awesome_class(c)
      Formatters::ClassFormatter.new(c, @inspector).format
    end

    def awesome_file(f)
      Formatters::FileFormatter.new(f, @inspector).format
    end

    def awesome_dir(d)
      Formatters::DirFormatter.new(d, @inspector).format
    end

    # Utility methods.
    #------------------------------------------------------------------------------
    def convert_to_hash(object)
      return nil unless object.respond_to?(:to_hash)

      return nil if object.method(:to_hash).arity != 0

      # ActionController::Parameters will raise if they are not yet permitted and
      # we try to convert to hash.
      # https://api.rubyonrails.org/classes/ActionController/Parameters.html
      return nil if object.respond_to?(:permitted?) && !object.permitted?

      hash = object.to_hash
      return nil if !hash.respond_to?(:keys) || !hash.respond_to?(:[])

      hash
    end
  end
end
