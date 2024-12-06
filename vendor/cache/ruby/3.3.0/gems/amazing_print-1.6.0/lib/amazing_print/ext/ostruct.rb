# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module OpenStruct
    def self.included(base)
      base.send :alias_method, :cast_without_ostruct, :cast
      base.send :alias_method, :cast, :cast_with_ostruct
    end

    def cast_with_ostruct(object, type)
      cast = cast_without_ostruct(object, type)
      cast = :open_struct_instance if defined?(::OpenStruct) && object.is_a?(::OpenStruct)
      cast
    end

    def awesome_open_struct_instance(object)
      "#{object.class} #{awesome_hash(object.marshal_dump)}"
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::OpenStruct
