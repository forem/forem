# frozen_string_literal: true

require 'jsonapi/serializer/errors'

module FastJsonapi
  require 'fast_jsonapi/object_serializer'
  if defined?(::Rails)
    require 'fast_jsonapi/railtie'
  elsif defined?(::ActiveRecord)
    require 'extensions/has_one'
  end
end
