# frozen_string_literal: true

require 'rails/generators/base'

class SerializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :attributes, type: :array, default: [], banner: 'field field'

  def create_serializer_file
    template 'serializer.rb.tt', File.join('app', 'serializers', class_path, "#{file_name}_serializer.rb")
  end

  private

  def attributes_names
    attributes.map { |a| a.name.to_sym.inspect }
  end
end
